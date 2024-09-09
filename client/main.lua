ESX = exports['es_extended']:getSharedObject()

local allBlips = {}
local currentGarage = nil

AddEventHandler('esx:setPlayerData', function(key, val, last)
    ESX.PlayerData[key] = val
end)

CreateThread(function()
    for k,v in pairs(Config.JobGarages) do
        local mainPoint = lib.points.new({ coords = v.coords, distance = v.distance['main'] })
        local parkPoint = lib.points.new({ coords = v.despawn, distance = v.distance['park'] })
        local bossPoint = lib.points.new({ coords = v.bossCoords, distance = v.distance['boss'] })

        -- Main Point
        function mainPoint:onEnter()
            local job = getJob()

            if job == v.job then
                lib.showTextUI('Press [E] To Open Garage', { icon = 'warehouse' })
            else
                lib.showTextUI('You don\'t have access to this garage')
            end
        end
         
        function mainPoint:nearby()
            DrawMarker(v.marker.markerId, v.coords.x, v.coords.y, v.coords.z, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.6, 0, 50, 150, 255, false, true, 0, 0)

            if IsControlJustReleased(0, 38) then
                local job = getJob()

                if job == v.job then
                    local vehicles = getVehicles(job)

                    for k,v in pairs(v.buyableVehicles) do
                        for _, vData in pairs(vehicles) do
                            if vehicles[_] and vehicles[_].model == v.model then
                                vehicles[_].showName = v.showName
                                vehicles[_].imageURL = v.imageURL
                                vehicles[_].price = v.price
                            end
                        end
                    end

                    currentGarage = k
                    SendNUIMessage({ type = 'setUI', name = k })
                    SendNUIMessage({ type = 'setOwnedVehicles', vehicles = vehicles })
                    SetNuiFocus(true, true)
                    SendNUIMessage({ type = 'showUI' })
                end
            end
        end
         
        -- Park Point
        function parkPoint:onEnter()
            local job = getJob()

            if job == v.job and IsPedSittingInAnyVehicle(PlayerPedId()) then
                lib.showTextUI('Press [E] To Park Vehicle', { icon = 'car' })
            end
        end
         
        function parkPoint:nearby()
            if self.currentDistance < 5 then
                DrawMarker(36, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 20, 60, 200, 50, false, false, 2, true, nil, nil, false)

                if IsControlJustReleased(0, 38) and IsPedSittingInAnyVehicle(PlayerPedId()) then
                    local job = getJob()
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    local success = lib.callback.await('buller-jobgarage:getVehicles', false, nil, plate)

                    if job == v.job and success ~= nil then
                        lib.callback.await('buller-jobgarage:updateVehicles', false, false, plate, string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))))
                        ESX.Game.DeleteVehicle(vehicle)
                    end
                end
            end
        end

            
        -- Boss Point
        function bossPoint:onEnter()
            local job, grade = getJob()

            if (job == v.bossJob.job) and (grade == v.bossJob.grade) then
                lib.showTextUI('Press [E] To Open Boss Menu', { icon = 'computer' })
            end 
        end
         
        function bossPoint:nearby()
            DrawMarker(v.marker.markerId, v.bossCoords.x, v.bossCoords.y, v.bossCoords.z, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.6, 0, 50, 150, 255, false, true, 0, 0)

            if IsControlJustReleased(0, 38) then
                currentGarage = k
                local job, grade = getJob()

                if (job == v.bossJob.job) and (grade == v.bossJob.grade) then
                    openBossMenu(v.job)
                end
            end
        end

        -- Exit Points
        function bossPoint:onExit() lib.hideTextUI() end
        function mainPoint:onExit() lib.hideTextUI() end
        function parkPoint:onExit() lib.hideTextUI() end


        --- Blip

        local blip = AddBlipForCoord(v.coords)
        SetBlipSprite(blip, v.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, v.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(v.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('buyVehicle', function(data)
    lib.callback.await('buller-jobgarage:buyVehicle', false, data, currentGarage)
end)

RegisterNUICallback('takeOutVehicle', function(data)
    local allowed = false
    local foundSpawn, SpawnPoint = GetAvailableVehicleSpawnPoint(Config.JobGarages[currentGarage].spawnPoints)

    for k,v in pairs(Config.JobGarages[currentGarage].buyableVehicles) do
        if v.model == data.model then
            allowed = true
            break
        end
    end

    if not allowed then
        return Config.Notify('You shouldn\'t be able to choose this vehicle?', 'error', 2500)
    end

    if foundSpawn and allowed then
        ESX.Game.SpawnVehicle(GetHashKey(data.model), SpawnPoint, SpawnPoint.w, function(vehicle) 
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
            lib.callback.await('buller-jobgarage:updateVehicles', false, true, GetVehicleNumberPlateText(vehicle), data.model)
            Config.Notify('You took out a vehicle', 'info', 2500)
            Config.GiveKeys(vehicle)
        end)
    else
        Config.Notify('Theres no space available - Clear the area and try again', 'error', 2500)
    end
end)

function GetAvailableVehicleSpawnPoint(SpawnCoords)
	local found, foundSpawnPoint = false, nil
	for i = 1, #SpawnCoords, 1 do
		if ESX.Game.IsSpawnPointClear(vector3(SpawnCoords[i].x, SpawnCoords[i].y, SpawnCoords[i].z), 2.5) then
			found, foundSpawnPoint = true, SpawnCoords[i]
			break
		end
	end
	if found then
		return true, foundSpawnPoint
	else
		return false
	end
end

function getJob()
    return lib.callback.await('buller-jobgarage:getJob', false)
end

function getVehicles(job)
    return lib.callback.await('buller-jobgarage:getVehicles', false, job)
end

function openBossMenu(job)
    SendNUIMessage({ type = 'setUI', name = currentGarage })
    SendNUIMessage({ type = 'setBuyableVehicles', vehicles = Config.JobGarages[currentGarage].buyableVehicles })
    SendNUIMessage({ type = 'showUI' })
    SetNuiFocus(true, true)
end