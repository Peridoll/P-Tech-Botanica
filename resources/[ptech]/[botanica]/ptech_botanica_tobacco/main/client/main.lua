local smoking = false
local cigaretteObject

local function notifyError(message)
    lib.notify({ title = 'Botanica', description = message or '使用できませんでした。', type = 'error' })
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function removeCigaretteProp()
    if cigaretteObject and DoesEntityExist(cigaretteObject) then DeleteEntity(cigaretteObject) end
    cigaretteObject = nil
end

local function stopSmoking()
    if not smoking then return end
    smoking = false
    StopAnimTask(PlayerPedId(), Config.Animation.dict, Config.Animation.clip, 1.0)
    ClearPedSecondaryTask(PlayerPedId())
    removeCigaretteProp()
    TriggerServerEvent('ptech_botanica_tobacco:server:stopSmoking')
end

RegisterNetEvent('ptech_botanica_tobacco:client:beginSmoking', function()
    if smoking then return end
    local ped = PlayerPedId()
    if not loadAnimDict(Config.Animation.dict) then
        TriggerServerEvent('ptech_botanica_tobacco:server:stopSmoking')
        notifyError('煙草の動作を読み込めませんでした。')
        return
    end

    smoking = true
    TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.clip, 2.0, 2.0, -1, 49, 0, false, false, false)

    local model = Config.Animation.prop
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    if HasModelLoaded(model) then
        cigaretteObject = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(cigaretteObject, ped, GetPedBoneIndex(ped, Config.Animation.bone),
            Config.Animation.position.x, Config.Animation.position.y, Config.Animation.position.z,
            Config.Animation.rotation.x, Config.Animation.rotation.y, Config.Animation.rotation.z,
            true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
    end

    CreateThread(function()
        local heartbeatAt = GetGameTimer()
        while smoking do
            Wait(0)
            local currentPed = PlayerPedId()
            if IsEntityDead(currentPed)
                or IsPauseMenuActive()
                or IsNuiFocused()
                or not IsEntityPlayingAnim(currentPed, Config.Animation.dict, Config.Animation.clip, 3) then
                stopSmoking()
                break
            end

            for _, control in ipairs(Config.InterruptControls) do
                if IsControlJustPressed(0, control) then
                    stopSmoking()
                    break
                end
            end

            if smoking and GetGameTimer() - heartbeatAt >= Config.Smoking.heartbeatIntervalMs then
                TriggerServerEvent('ptech_botanica_tobacco:server:heartbeat')
                heartbeatAt = GetGameTimer()
            end
        end
    end)
end)

RegisterNetEvent('ptech_botanica_tobacco:client:stopSmoking', function()
    if not smoking then return end
    smoking = false
    StopAnimTask(PlayerPedId(), Config.Animation.dict, Config.Animation.clip, 1.0)
    ClearPedSecondaryTask(PlayerPedId())
    removeCigaretteProp()
end)

AddEventHandler('ox_inventory:usedItem', function(name)
    if smoking then stopSmoking() end
end)

local function unpackCarton(data)
    local success, message = lib.callback.await('ptech_botanica_tobacco:server:unpackCarton', false, data and data.slot)
    if not success then notifyError(message) end
end

local function useCigaretteBox(data)
    if smoking then return notifyError('すでに煙草を吸っています。') end
    local success, message = lib.callback.await('ptech_botanica_tobacco:server:startSmoking', false, data and data.slot)
    if not success then notifyError(message) end
end

exports('unpackCarton', unpackCarton)
exports('useCigaretteBox', useCigaretteBox)

local shop = Config.Shop
if shop.enabled then
    local ped
    local useTarget = GetResourceState('ox_target') == 'started'

    local function openShop()
        exports.ox_inventory:openInventory('shop', { type = 'ptech_botanica_tobacco', id = 1 })
    end

    local function spawnShopPed()
        if ped and DoesEntityExist(ped) then return end
        lib.requestModel(shop.model)
        ped = CreatePed(4, shop.model, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.heading, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if shop.scenario then TaskStartScenarioInPlace(ped, shop.scenario, 0, true) end
        SetModelAsNoLongerNeeded(shop.model)

        if useTarget then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'ptech_botanica_tobacco_shop',
                    icon = 'fa-solid fa-smoking',
                    label = 'タバコを買う',
                    distance = shop.interactionDistance,
                    onSelect = openShop,
                },
            })
        end
    end

    local function deleteShopPed()
        if not ped then return end
        if useTarget then exports.ox_target:removeLocalEntity(ped, 'ptech_botanica_tobacco_shop') end
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        ped = nil
    end

    local spawnPoint = lib.points.new({ coords = shop.coords, distance = shop.spawnDistance })
    function spawnPoint:onEnter() spawnShopPed() end
    function spawnPoint:onExit() deleteShopPed() end

    if not useTarget then
        local interactPoint = lib.points.new({ coords = shop.coords, distance = shop.interactionDistance })
        function interactPoint:onEnter() lib.showTextUI('[E] タバコを買う') end
        function interactPoint:onExit() lib.hideTextUI() end
        function interactPoint:nearby()
            if IsControlJustReleased(0, 38) then openShop() end
        end
    end

    CreateThread(function()
        if not shop.blip.enabled then return end
        local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
        SetBlipSprite(blip, shop.blip.sprite)
        SetBlipColour(blip, shop.blip.color)
        SetBlipScale(blip, shop.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(shop.label)
        EndTextCommandSetBlipName(blip)
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end
        deleteShopPed()
        if not useTarget then lib.hideTextUI() end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    smoking = false
    removeCigaretteProp()
    ClearPedSecondaryTask(PlayerPedId())
end)
