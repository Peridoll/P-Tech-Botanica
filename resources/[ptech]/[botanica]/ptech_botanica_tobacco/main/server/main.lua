local activeSessions = {}
local inventory = exports.ox_inventory

local function notify(playerId, description, notifyType)
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = 'Botanica',
        description = description,
        type = notifyType or 'inform',
    })
end

if Config.Shop.enabled then
    local shopItems = {}
    for key, brand in pairs(Config.Brands) do
        local cartonPrice = Config.Shop.prices[key .. 'Carton']
        local boxPrice = Config.Shop.prices[key .. 'Box']
        shopItems[#shopItems + 1] = { name = brand.cartonItem, price = cartonPrice }
        shopItems[#shopItems + 1] = { name = brand.boxItem, price = boxPrice }
    end
    shopItems[#shopItems + 1] = { name = Config.Items.lighter, price = Config.Shop.prices.lighter }

    exports.ox_inventory:RegisterShop('ptech_botanica_tobacco', {
        name = Config.Shop.label,
        inventory = shopItems,
        locations = { Config.Shop.coords },
    })
end

local function brandForBox(itemName)
    for key, brand in pairs(Config.Brands) do
        if brand.boxItem == itemName then return key, brand end
    end
end

local function getUses(metadata, field, defaultValue)
    local value = tonumber(metadata and metadata[field])
    if not value then return defaultValue end
    return math.max(0, math.floor(value))
end

local function findLighter(playerId)
    local slots = inventory:GetSlotsWithItem(playerId, Config.Items.lighter) or {}
    for _, slot in pairs(slots) do
        local remaining = getUses(slot.metadata, 'uses', Config.Items.lighterUses)
        if remaining > 0 then return slot, remaining end
    end
end

local function spendOne(playerId, slot, itemName, metadata, field, remaining)
    if remaining <= 1 then
        return inventory:RemoveItem(playerId, itemName, 1, metadata, slot.slot, false, true)
    end

    metadata = metadata or {}
    metadata[field] = remaining - 1
    inventory:SetMetadata(playerId, slot.slot, metadata)
    return true
end

local function stopSession(playerId)
    if not activeSessions[playerId] then return false end
    activeSessions[playerId] = nil
    TriggerClientEvent('ptech_botanica_tobacco:client:stopSmoking', playerId)
    return true
end

lib.callback.register('ptech_botanica_tobacco:server:unpackCarton', function(playerId, slotId)
    slotId = tonumber(slotId)
    if not slotId then return false, 'カートンを確認できませんでした。' end

    local carton = inventory:GetSlot(playerId, slotId)
    if not carton then return false, 'カートンを確認できませんでした。' end

    local targetBrand
    for _, brand in pairs(Config.Brands) do
        if carton.name == brand.cartonItem then targetBrand = brand break end
    end
    if not targetBrand then return false, 'このアイテムは開封できません。' end

    local boxMetadata = { uses = Config.Items.cigarettesPerBox }
    if not inventory:CanCarryItem(playerId, targetBrand.boxItem, Config.Items.boxesPerCarton, boxMetadata) then
        return false, '煙草の箱を5つ持てる空きがありません。'
    end

    if not inventory:RemoveItem(playerId, carton.name, 1, carton.metadata, slotId, false, true) then
        return false, 'カートンを開封できませんでした。'
    end

    local added = 0
    for _ = 1, Config.Items.boxesPerCarton do
        if inventory:AddItem(playerId, targetBrand.boxItem, 1, { uses = Config.Items.cigarettesPerBox }) then
            added = added + 1
        else
            break
        end
    end

    if added ~= Config.Items.boxesPerCarton then
        if added > 0 then inventory:RemoveItem(playerId, targetBrand.boxItem, added, boxMetadata, nil, true, true) end
        inventory:AddItem(playerId, carton.name, 1, carton.metadata)
        return false, '空き状況が変わったため、カートンを開封できませんでした。'
    end

    notify(playerId, ('%sを5箱取り出しました。'):format(targetBrand.label), 'success')
    return true
end)

lib.callback.register('ptech_botanica_tobacco:server:startSmoking', function(playerId, slotId)
    slotId = tonumber(slotId)
    if not slotId then return false, '煙草の箱を確認できませんでした。' end
    if activeSessions[playerId] then return false, 'すでに煙草を吸っています。' end

    local pack = inventory:GetSlot(playerId, slotId)
    local brandKey, brand
    if pack then brandKey, brand = brandForBox(pack.name) end
    if not brand then return false, '煙草の箱を確認できませんでした。' end

    local packUses = getUses(pack.metadata, 'uses', Config.Items.cigarettesPerBox)
    if packUses < 1 then return false, 'この箱には煙草が残っていません。' end

    local lighter, lighterUses = findLighter(playerId)
    if not lighter then return false, '火をつけるためのライターがありません。' end

    if not spendOne(playerId, lighter, Config.Items.lighter, lighter.metadata, 'uses', lighterUses) then
        return false, 'ライターを使えませんでした。'
    end
    if not spendOne(playerId, pack, brand.boxItem, pack.metadata, 'uses', packUses) then
        if lighterUses > 1 then
            lighter.metadata = lighter.metadata or {}
            lighter.metadata.uses = lighterUses
            inventory:SetMetadata(playerId, lighter.slot, lighter.metadata)
        else
            inventory:AddItem(playerId, Config.Items.lighter, 1, { uses = lighterUses })
        end
        return false, '煙草を取り出せませんでした。'
    end

    activeSessions[playerId] = {
        startedAt = os.time(),
        lastHeartbeat = GetGameTimer(),
        brand = brandKey,
    }
    TriggerClientEvent('ptech_botanica_tobacco:client:beginSmoking', playerId, brand.label)
    notify(playerId, ('%sに火をつけました。何か操作すると途中で消えます。'):format(brand.label), 'success')
    return true
end)

RegisterNetEvent('ptech_botanica_tobacco:server:heartbeat', function()
    local session = activeSessions[source]
    if session then session.lastHeartbeat = GetGameTimer() end
end)

RegisterNetEvent('ptech_botanica_tobacco:server:stopSmoking', function()
    stopSession(source)
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = GetGameTimer()

        for playerId, session in pairs(activeSessions) do
            if not GetPlayerName(playerId) or now - session.lastHeartbeat > Config.Smoking.heartbeatTimeoutMs then
                stopSession(playerId)
            else
                local elapsed = os.time() - session.startedAt
                if elapsed < Config.Smoking.increasePerSecondAfter then
                    exports['nova-stress']:RelieveStress(playerId, Config.Smoking.recoveryPerSecond)
                else
                    exports['nova-stress']:GainStress(playerId, Config.Smoking.increasePerSecond)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    activeSessions[source] = nil
end)
