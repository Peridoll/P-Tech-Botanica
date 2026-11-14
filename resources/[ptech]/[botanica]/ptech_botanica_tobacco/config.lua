Config = {
    Items = {
        lighter = 'ptech_botanica_disposable_lighter',
        lighterUses = 20,
        cigarettesPerBox = 10,
        boxesPerCarton = 5,
    },

    Smoking = {
        recoveryPerSecond = 5,
        increasePerSecondAfter = 600,
        increasePerSecond = 1,
        heartbeatIntervalMs = 5000,
        heartbeatTimeoutMs = 15000,
    },

    Brands = {
        hokuto = {
            label = 'HOKUTO',
            boxItem = 'ptech_botanica_hokuto_box',
            cartonItem = 'ptech_botanica_hokuto_carton',
        },
        archimedes = {
            label = 'ARCHIMEDES',
            boxItem = 'ptech_botanica_archimedes_box',
            cartonItem = 'ptech_botanica_archimedes_carton',
        },
    },

    Shop = {
        enabled = true,
        label = 'タバコ屋',
        coords = vec3(189.86, -857.01, 31.56),
        heading = 29.51,
        model = `mp_m_shopkeep_01`,
        scenario = 'WORLD_HUMAN_SMOKING',
        interactionDistance = 2.0,
        spawnDistance = 50.0,
        blip = { enabled = true, sprite = 52, color = 2, scale = 0.7 },
        prices = {
            hokutoCarton = 200000,
            hokutoBox = 10000,
            archimedesCarton = 200000,
            archimedesBox = 10000,
            lighter = 10000,
        },
    },

    Animation = {
        dict = 'amb@world_human_smoking@male@male_a@base',
        clip = 'base',
        prop = `prop_cs_ciggy_01`,
        bone = 28422,
        position = vec3(0.03, 0.02, 0.02),
        rotation = vec3(0.0, 0.0, -30.0),
    },

    InterruptControls = {
        21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 37, 38, 44, 45, 47, 73, 75, 200,
    },
}
