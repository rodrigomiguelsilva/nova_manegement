local ESX = exports['es_extended']:getSharedObject()
local Doors = {}
local menuOpen = false

local function notify(msg)
    ESX.ShowNotification(msg)
end

RegisterNetEvent('nova_management:notify', notify)
RegisterNetEvent('nova_management:setDoors', function(data) Doors = data or {} end)
RegisterNetEvent('nova_management:doorState', function(id, locked)
    if Doors[id] then Doors[id].locked = locked end
end)

RegisterNetEvent('nova_management:refresh', function()
    openMenu()
end)

local function requestData()
    ESX.TriggerServerCallback('nova_management:getData', function(data)
        if not data then notify('Sem permissões.') return end
        SendNUIMessage({action = 'open', data = data})
        SetNuiFocus(true, true)
        menuOpen = true
    end)
end

function openMenu()
    ESX.TriggerServerCallback('nova_management:isAdmin', function(ok)
        if not ok then notify('Não tens permissões para usar este painel.') return end
        requestData()
    end)
end

if Config.EnableCommand then
    RegisterCommand(Config.Command, function()
        if menuOpen then
            SetNuiFocus(false, false)
            SendNUIMessage({action='close'})
            menuOpen = false
        else
            openMenu()
        end
    end)
end

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    menuOpen = false
    cb('ok')
end)

RegisterNUICallback('createJob', function(data, cb)
    TriggerServerEvent('nova_management:createJob', data)
    cb('ok')
end)

RegisterNUICallback('deleteJob', function(data, cb)
    TriggerServerEvent('nova_management:deleteJob', data.name)
    cb('ok')
end)

RegisterNUICallback('updateJob', function(data, cb)
    TriggerServerEvent('nova_management:updateJob', data)
    cb('ok')
end)

RegisterNUICallback('addDoor', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hit, entity = getTargetEntity()
    if hit and entity and entity ~= 0 then
        coords = GetEntityCoords(entity)
        data.model = tostring(GetEntityModel(entity))
    else
        data.model = '0'
    end
    data.coords = {x=coords.x, y=coords.y, z=coords.z}
    TriggerServerEvent('nova_management:addDoor', data)
    cb('ok')
end)

RegisterNUICallback('deleteDoor', function(data, cb)
    TriggerServerEvent('nova_management:deleteDoor', data.id)
    cb('ok')
end)

function getTargetEntity()
    local camCoords = GetGameplayCamCoord()
    local direction = RotationToDirection(GetGameplayCamRot(2))
    local destination = camCoords + direction * 5.0
    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 16, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    return hit == 1, entity
end

function RotationToDirection(rotation)
    local adjusted = vector3(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
    local direction = vector3(-math.sin(adjusted.z) * math.abs(math.cos(adjusted.x)), math.cos(adjusted.z) * math.abs(math.cos(adjusted.x)), math.sin(adjusted.x))
    return direction
end

CreateThread(function()
    while true do
        Wait(Config.DoorCheckInterval)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, door in pairs(Doors) do
            local pos = door.coords
            if pos and #(coords - vector3(pos.x, pos.y, pos.z)) < Config.DoorDistance then
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('nova_management:toggleDoor', id)
                    Wait(500)
                end
                if door.locked then
                    local entity = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, tonumber(door.model) or 0, false, false, false)
                    if entity ~= 0 then
                        FreezeEntityPosition(entity, true)
                        SetEntityHeading(entity, GetEntityHeading(entity))
                    end
                else
                    local entity = GetClosestObjectOfType(pos.x, pos.y, pos.z, 1.5, tonumber(door.model) or 0, false, false, false)
                    if entity ~= 0 then FreezeEntityPosition(entity, false) end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
