Config = {}

Config.PayBank = true -- Hvis du vil betale fra banken, ellers fra pungen.
Config.Debug = false -- Hvis du vil have debug beskeder i consolen.

Config.JobGarages = {
    ['Mission Row - Police Station'] = {
        coords = vector3(459.2149, -1007.956, 28.25848),
        bossCoords = vector3(441.7038, -1014.068, 28.64097),
        despawn = vector3(445.8666, -1020.067, 28.54889),

        distance = {
            ['main'] = 3,
            ['park'] = 5,
            ['boss'] = 3
        },
        
        job = 'police',
        bossJob = {
            job = 'police',
            grade = 4
        },

        blip = { sprite = 1, color = 1, label = 'Mission Row Garage' },
        marker = { markerId = 2 },

        spawnPoints = { vector4(446.0745, -1024.746, 28.64413, 182.9556) },

        buyableVehicles = {
            {
                model = 'police',
                showName = 'Police Cruiser',
                imageURL = '',
                price = 1000,
            },
            {
                model = 'policeb',
                showName = 'Police Motorcycle',
                imageURL = '',
                price = 1000,
            }
        }
    }
}

Config.Notify = function(message, _type, time, xPlayer) -- This is the notify the script uses (Can be changed)
    if xPlayer then
        xPlayer.showNotification(message, _type, time)
    else
        ESX.ShowNotification(message, _type, time)
    end
end

Config.GiveKeys = function(vehicle) -- This is the function the scripts uses to give carkeys to the player when spawned (Client)
    
end