ESX = exports['es_extended']:getSharedObject()
local AllGarages = {}
local AllVehicles = {}

lib.callback.register('buller-jobgarage:getJob', function(src)
    local jobInfo = ESX.GetPlayerFromId(src).getJob()
    return jobInfo.name, jobInfo.grade
end)

lib.callback.register('buller-jobgarage:getVehicles', function(src, job, plate)

    if job == nil then
        return AllVehicles[plate] or nil
    else
        return AllGarages[job]?.vehicles or {}
    end
end)

lib.callback.register('buller-jobgarage:updateVehicles', function(src, saveVeh, plate, model)
    local job = ESX.GetPlayerFromId(src).getJob().name

    if saveVeh then
        AllVehicles[plate] = true
        local copy = AllGarages[job].vehicles
        local copyTable = {}

        for k,v in pairs(copy) do
            if v.model == model then
                copyTable = v
                break
            end
        end

        copyTable.amount = copyTable.amount - 1

        if copyTable.amount <= 0 then
            copyTable = nil
        end

        for k,v in pairs(copy) do
            if v.model == model then
                if copyTable == nil then
                    table.remove(AllGarages[job].vehicles, k)
                else
                    copy[k] = copyTable
                end
                
                break
            end
        end

        AllGarages[job].vehicles = copy
    elseif saveVeh == false then
        AllVehicles[plate] = nil

        for k,v in pairs(AllGarages[job].vehicles) do
            if v.model == model then
                AllGarages[job].vehicles[k].amount = v.amount + 1
                break
            end
        end

    elseif saveVeh == nil then
        return AllVehicles[plate]
    end
end)

lib.callback.register('buller-jobgarage:buyVehicle', function(src, data, garage)
    local xPlayer = ESX.GetPlayerFromId(src)
    local job = xPlayer.getJob().name
    local found = false
    local payed = false

    for k,v in pairs(Config.JobGarages[garage].buyableVehicles) do
        if v.model == data.model then
            found = true
            data.price = v.price
            break
        end
    end

    if not found then
        Config.Notify('You cannot buy this vehicle', 'error', 2500, xPlayer)
        return
    end

    if Config.PayBank then
        if xPlayer.getAccount('bank').money >= data.price then
            xPlayer.removeAccountMoney('bank', data.price)
            payed = true
        else
            xPlayer.showNotification('You do not have enough money to order these vehicles')
        end
    else
        if xPlayer.getMoney() >= data.price or xPlayer.getAccount('bank') >= data.price then
            xPlayer.removeMoney(data.price)
        else
            xPlayer.showNotification('You do not have enough money to order these vehicles')
        end
    end

    if payed then
        Config.Notify('You bought a ' .. data.model .. ' for $' .. data.price, 'info', 2500, xPlayer)
        local garage = AllGarages[job].vehicles
        local alreadyExists = false

        for k,v in pairs(garage) do
            if v.model == data.model then
                garage[k].amount = garage[k].amount + data.amount
                alreadyExists = true
                break
            end
        end

        if not alreadyExists then
            garage[#garage+1] = { model = data.model, amount = data.amount }
        end
    end
end)

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
        print('Waiting for oxmysql to load')
    end

    exports.oxmysql:query([[
        CREATE TABLE IF NOT EXISTS `buller_jobgarage` (
            `job` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            `vehicles` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci'
        ) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
    ]], {}, function()
        local data = exports.oxmysql:query_async('SELECT * FROM buller_jobgarage')

        for k,v in pairs(data) do
            AllGarages[v.job] = { vehicles = json.decode(v.vehicles) or {} }
        end

        for k,v in pairs(Config.JobGarages) do
            if not AllGarages[v.job] then
                AllGarages[v.job] = { vehicles = {} }
            end
        end

        Wait(5000)
        print('')
        print('---------------------------------------------')
        print('         Buller - Jobgarage loaded           ')
        print('---------------------------------------------')
        print('')
    end)
end)

CreateThread(function()
    while true do
        Wait(5000)
        
        saveAllVehicles()
    end
end)

function saveAllVehicles()
    for k,v in pairs(AllGarages) do
        if Config.Debug then
            print('Saving vehicles for job: ' .. k)
        end

        exports.oxmysql:query('SELECT * FROM buller_jobgarage WHERE job = ?', { k }, function(data)
            if #data > 0 then
                exports.oxmysql:query('UPDATE buller_jobgarage SET vehicles = ? WHERE job = ?', { json.encode(v.vehicles), k })
            else
                exports.oxmysql:query('INSERT INTO buller_jobgarage (job, vehicles) VALUES (?, ?)', { k, json.encode(v.vehicles) })
            end
        end)
    end
end