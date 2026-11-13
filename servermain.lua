local ESX = exports['es_extended']:getSharedObject()
local Doors = {}

local function refreshESXJobs()
    -- ESX Legacy mantém os empregos em cache; atualizar o cache permite usar /setjob
    -- imediatamente sem reiniciar o servidor.
    if ESX.RefreshJobs then
        ESX.RefreshJobs()
    else
        print('[nova_management] AVISO: ESX.RefreshJobs() não existe nesta versão do es_extended. Reinicia o resource es_extended/servidor.')
    end
end


local function isAdmin(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    return Config.AllowedGroups[group] == true
end

local function notify(src, msg)
    TriggerClientEvent('nova_management:notify', src, msg)
end

local function loadDoors()
    local rows = MySQL.query.await('SELECT * FROM nova_doorlocks', {})
    Doors = {}
    for _, row in ipairs(rows or {}) do
        row.coords = json.decode(row.coords or '{}')
        row.jobs = json.decode(row.jobs or '[]')
        row.locked = row.locked == 1
        Doors[tonumber(row.id)] = row
    end
    TriggerClientEvent('nova_management:setDoors', -1, Doors)
end

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `nova_doorlocks` (
            `id` int NOT NULL AUTO_INCREMENT,
            `label` varchar(100) NOT NULL,
            `model` varchar(100) NOT NULL,
            `coords` longtext NOT NULL,
            `jobs` longtext NOT NULL,
            `locked` tinyint(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`)
        )
    ]])
    loadDoors()
end)

ESX.RegisterServerCallback('nova_management:isAdmin', function(src, cb)
    cb(isAdmin(src))
end)

ESX.RegisterServerCallback('nova_management:getData', function(src, cb)
    if not isAdmin(src) then cb(nil) return end
    local jobs = MySQL.query.await('SELECT name, label FROM jobs ORDER BY name')
    local grades = MySQL.query.await('SELECT job_name, grade, name, label, salary FROM job_grades ORDER BY job_name, grade')
    cb({ jobs = jobs or {}, grades = grades or {}, doors = Doors })
end)

RegisterNetEvent('nova_management:createJob', function(data)
    local src = source
    if not isAdmin(src) then return end
    if type(data) ~= 'table' or type(data.name) ~= 'string' or type(data.label) ~= 'string' then return end
    local name = string.lower(data.name):gsub('[^%w_]', '')
    local label = data.label:sub(1, 50)
    if #name < 2 or #name > 32 or label == '' then notify(src, 'Nome ou label inválido.') return end

    local exists = MySQL.scalar.await('SELECT name FROM jobs WHERE name = ?', {name})
    if exists then notify(src, 'Esse job já existe.') return end

    local grades = data.grades
    if type(grades) ~= 'table' or #grades == 0 then
        grades = {{name = 'employee', label = 'Employee', salary = 0}}
    end

    MySQL.insert.await('INSERT INTO jobs (name, label) VALUES (?, ?)', {name, label})
    for i, grade in ipairs(grades) do
        if i > 20 then break end
        local gradeName = tostring(grade.name or ('grade' .. (i - 1))):lower():gsub('[^%w_]', '')
        local gradeLabel = tostring(grade.label or gradeName):sub(1, 50)
        local salary = math.max(0, math.min(1000000, math.floor(tonumber(grade.salary) or 0)))
        MySQL.insert.await(
            'INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)',
            {name, i - 1, gradeName, gradeLabel, salary}
        )
    end
    refreshESXJobs()
    notify(src, 'Job criado e registado no ESX. Já podes usar /setjob.')
    TriggerClientEvent('nova_management:refresh', src)
end)

RegisterNetEvent('nova_management:deleteJob', function(jobName)
    local src = source
    if not isAdmin(src) then
        notify(src, 'Não tens permissões para apagar empregos.')
        return
    end

    if type(jobName) ~= 'string' then
        notify(src, 'Nome de emprego inválido.')
        return
    end

    jobName = jobName:lower():gsub('[^%w_]', '')
    if jobName == '' or jobName == 'unemployed' then
        notify(src, 'Não podes apagar este emprego.')
        return
    end

    local exists = MySQL.scalar.await('SELECT name FROM jobs WHERE name = ? LIMIT 1', {jobName})
    if not exists then
        notify(src, 'O emprego não existe na base de dados.')
        TriggerClientEvent('nova_management:refresh', src)
        return
    end

    local success = MySQL.transaction.await({
        { query = 'DELETE FROM job_grades WHERE job_name = ?', values = {jobName} },
        { query = 'DELETE FROM jobs WHERE name = ?', values = {jobName} }
    })

    if not success then
        notify(src, 'Erro ao apagar o emprego. Verifica a consola e a base de dados.')
        return
    end

    refreshESXJobs()
    notify(src, 'Emprego ' .. jobName .. ' apagado com sucesso.')
    TriggerClientEvent('nova_management:refresh', src)
end)

RegisterNetEvent('nova_management:updateJob', function(data)
    local src = source
    if not isAdmin(src) then notify(src, 'Não tens permissões para editar empregos.') return end
    if type(data) ~= 'table' or type(data.name) ~= 'string' or type(data.grades) ~= 'table' then return end
    local jobName = data.name:lower():gsub('[^%w_]', '')
    if jobName == '' then notify(src, 'Nome de emprego inválido.') return end
    local exists = MySQL.scalar.await('SELECT name FROM jobs WHERE name = ? LIMIT 1', {jobName})
    if not exists then notify(src, 'Esse emprego já não existe.') return end
    if #data.grades < 1 or #data.grades > 20 then notify(src, 'O emprego tem de ter entre 1 e 20 grades.') return end

    local seen = {}
    local queries = {{query='DELETE FROM job_grades WHERE job_name = ?', values={jobName}}}
    for i, grade in ipairs(data.grades) do
        local gradeName = tostring(grade.name or ''):lower():gsub('[^%w_]', '')
        local gradeLabel = tostring(grade.label or ''):sub(1, 50)
        local salary = math.max(0, math.min(1000000, math.floor(tonumber(grade.salary) or 0)))
        if gradeName == '' or gradeLabel == '' or seen[gradeName] then
            notify(src, 'Nome/label de grade inválido ou repetido.')
            return
        end
        seen[gradeName] = true
        queries[#queries+1] = {query='INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', values={jobName, i-1, gradeName, gradeLabel, salary}}
    end
    local success = MySQL.transaction.await(queries)
    if not success then notify(src, 'Não foi possível guardar os grades. Consulta a consola.') return end
    refreshESXJobs()
    notify(src, 'Grades atualizados. Podes usar /setjob ' .. jobName .. ' 0-' .. tostring(#data.grades-1) .. '.')
    TriggerClientEvent('nova_management:refresh', src)
end)

RegisterNetEvent('nova_management:addDoor', function(data)
    local src = source
    if not isAdmin(src) then return end
    if type(data) ~= 'table' or type(data.label) ~= 'string' or type(data.model) ~= 'string' or type(data.coords) ~= 'table' then return end
    local coords = data.coords
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return end
    local jobs = {}
    for _, job in ipairs(data.jobs or {}) do
        if type(job) == 'string' and #job <= 32 then jobs[#jobs+1] = job end
    end
    local id = MySQL.insert.await(
        'INSERT INTO nova_doorlocks (label, model, coords, jobs, locked) VALUES (?, ?, ?, ?, 1)',
        {data.label:sub(1, 100), data.model, json.encode({x=x,y=y,z=z}), json.encode(jobs)}
    )
    notify(src, 'Doorlock criado com ID ' .. tostring(id))
    loadDoors()
    TriggerClientEvent('nova_management:refresh', src)
end)

RegisterNetEvent('nova_management:deleteDoor', function(id)
    local src = source
    if not isAdmin(src) then return end
    id = tonumber(id)
    if not id then return end
    MySQL.update.await('DELETE FROM nova_doorlocks WHERE id = ?', {id})
    notify(src, 'Doorlock eliminado.')
    loadDoors()
    TriggerClientEvent('nova_management:refresh', src)
end)

RegisterNetEvent('nova_management:toggleDoor', function(id)
    local src = source
    id = tonumber(id)
    local door = id and Doors[id]
    if not door then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local allowed = #door.jobs == 0
    for _, job in ipairs(door.jobs) do
        if xPlayer.job and xPlayer.job.name == job then allowed = true break end
    end
    if not allowed and not isAdmin(src) then
        notify(src, 'Não tens acesso a esta porta.')
        return
    end

    door.locked = not door.locked
    MySQL.update.await('UPDATE nova_doorlocks SET locked = ? WHERE id = ?', {door.locked and 1 or 0, id})
    TriggerClientEvent('nova_management:doorState', -1, id, door.locked)
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    TriggerClientEvent('nova_management:setDoors', playerId, Doors)
end)
