local ESX = exports["es_extended"]:getSharedObject()

local stateHour, stateMinute = 12, 0
local stateWeather = "CLEAR"

local function hasPerm(src, perm)
    if not Config.UseAcePerms then return true end
    return IsPlayerAceAllowed(src, perm)
end

local function notify(src, msg)
    TriggerClientEvent('chat:addMessage', src, { args = { Config.Prefix, msg } })
end

local function broadcastSync()
    TriggerClientEvent("utils:syncTimeWeather", -1, stateHour, stateMinute, stateWeather)
end

AddEventHandler("playerJoining", function()
    local src = source
    TriggerClientEvent("utils:syncTimeWeather", src, stateHour, stateMinute, stateWeather)
end)

-- /mpid <id> <message>
RegisterCommand("mpid", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.MPID) then return notify(source, "^1Tu n'as pas la permission.") end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(source, "^1Usage: /mpid <id> <message>")
    end

    table.remove(args, 1)
    local msg = table.concat(args, " ")
    if msg == "" then return notify(source, "^1Usage: /mpid <id> <message>") end

    local senderName = GetPlayerName(source)

    TriggerClientEvent("utils:mpidNotify", target, senderName, msg)
    notify(source, ("Message envoyé à l'ID ^2%d^7."):format(target))
end)


-- /time <heure> <minute>
RegisterCommand("time", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.Time) then return notify(source, "^1Tu n'as pas la permission.") end

    local h = tonumber(args[1])
    local m = tonumber(args[2])

    if h == nil or m == nil or h < 0 or h > 23 or m < 0 or m > 59 then
        return notify(source, "^1Usage: /time <0-23> <0-59>")
    end

    stateHour, stateMinute = h, m
    broadcastSync()
    notify(source, ("Heure changée: ^2%02d:%02d^7"):format(h, m))
end)

-- /weather <type>
RegisterCommand("weather", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.Weather) then return notify(source, "^1Tu n'as pas la permission.") end

    local w = (args[1] or ""):upper()
    if w == "" then return notify(source, "^1Usage: /weather <type>") end

    local ok = false
    for _, ww in ipairs(Config.AllowedWeather) do
        if ww == w then ok = true break end
    end
    if not ok then
        return notify(source, "^1Weather invalide. Ex: CLEAR, RAIN, EXTRASUNNY, THUNDER...")
    end

    stateWeather = w
    broadcastSync()
    notify(source, ("Météo changée: ^2%s^7"):format(w))
end)

-- /revive [id]
RegisterCommand("revive", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.Revive) then return notify(source, "^1Tu n'as pas la permission.") end

    local target = tonumber(args[1]) or source
    if not GetPlayerName(target) then
        return notify(source, "^1Usage: /revive [id]")
    end

    -- revive via event ambulance (client)
    TriggerClientEvent(Config.ReviveClientEvent, target)

    notify(source, ("Revive envoyé à l'ID ^2%d^7."):format(target))
    if target ~= source then
        notify(target, "^2Tu as été revive par un staff.")
    end
end)

-- /rpid [id] -> récupère prénom/nom RP (table users ESX)
local function fetchRPName(identifier, cb)
    if Config.DB == "oxmysql" and exports.oxmysql then
        exports.oxmysql:single("SELECT firstname, lastname FROM users WHERE identifier = ?", { identifier }, function(row)
            cb(row)
        end)
        return
    end

    if MySQL and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll("SELECT firstname, lastname FROM users WHERE identifier = @id", { ["@id"] = identifier }, function(rows)
            cb(rows and rows[1] or nil)
        end)
        return
    end

    cb(nil)
end

RegisterCommand("rpid", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.RPID) then return notify(source, "^1Tu n'as pas la permission.") end

    local target = tonumber(args[1]) or source
    if not GetPlayerName(target) then
        return notify(source, "^1Usage: /rpid [id]")
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return notify(source, "^1Joueur introuvable (ESX).") end

    local identifier = xTarget.identifier
    fetchRPName(identifier, function(row)
        if not row or not row.firstname or not row.lastname then
            return notify(source, "^1Nom RP introuvable (DB).")
        end
        notify(source, ("ID ^2%d^7 = ^2%s %s^7"):format(target, row.firstname, row.lastname))
    end)
end)

local function db_insert(query, params, cb)
    if Config.DB == "oxmysql" and exports.oxmysql then
        exports.oxmysql:insert(query, params, cb)
    else
        MySQL.Async.insert(query, params, cb)
    end
end

local function db_query(query, params, cb)
    if Config.DB == "oxmysql" and exports.oxmysql then
        exports.oxmysql:query(query, params, cb)
    else
        MySQL.Async.fetchAll(query, params, cb)
    end
end






RegisterCommand("warn", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.Warn) then return notify(source, "^1Tu n'as pas la permission.") end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(source, "^1Usage: /warn <id> <motif>")
    end

    table.remove(args, 1)
    local reason = table.concat(args, " ")
    if reason == "" then return notify(source, "^1Usage: /warn <id> <motif>") end

    local xTarget = ESX.GetPlayerFromId(target)
    local xStaff  = ESX.GetPlayerFromId(source)
    if not xTarget or not xStaff then return notify(source, "^1Joueur introuvable.") end

    local targetIdentifier = xTarget.identifier
    local staffIdentifier  = xStaff.identifier
    local staffName        = GetPlayerName(source)

    db_insert(
        "INSERT INTO player_warns (identifier, staff_identifier, staff_name, reason) VALUES (?, ?, ?, ?)",
        { targetIdentifier, staffIdentifier, staffName, reason },
        function(insertId)
            -- notif joueur (client event à ajouter plus bas)
            TriggerClientEvent("utils:warnNotify", target, staffName, reason)

            notify(source, ("Warn ajouté à l'ID ^2%d^7 (#%s)."):format(target, tostring(insertId or "?")))
        end
    )
end)


RegisterCommand("lwarn", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.LWarn) then return notify(source, "^1Tu n'as pas la permission.") end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(source, "^1Usage: /lwarn <id>")
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return notify(source, "^1Joueur introuvable (ESX).") end

    local identifier = xTarget.identifier
    local function db_execute(query, params, cb)
        if Config.DB == "oxmysql" and exports.oxmysql then
            exports.oxmysql:execute(query, params, cb)
        else
            MySQL.Async.execute(query, params, cb)
        end
    end

    db_query(
        "SELECT id, staff_name, reason, created_at FROM player_warns WHERE identifier = ? ORDER BY id DESC LIMIT ?",
        { identifier, Config.WarnListLimit or 20 },
        function(rows)
            if not rows or #rows == 0 then
                return notify(source, ("^2Aucun warn^7 pour l'ID %d."):format(target))
            end

            notify(source, ("^3Warns de l'ID %d^7 (max %d):"):format(target, Config.WarnListLimit or 20))

            for i = 1, #rows do
                local w = rows[i]
                -- format simple
                notify(source, ("#%d | %s | %s | %s"):format(
                    w.id,
                    tostring(w.created_at),
                    tostring(w.staff_name),
                    tostring(w.reason)
                ))
            end
        end
    )
end)


RegisterCommand("cwarn", function(source, args)
    if source == 0 then return end
    if not hasPerm(source, Config.Ace.CWarn) then return notify(source, "^1Tu n'as pas la permission.") end

    local warnId = tonumber(args[1])
    if not warnId then
        return notify(source, "^1Usage: /cwarn <warnId>")
    end

    db_execute("DELETE FROM player_warns WHERE id = ?", { warnId }, function(affected)
        if (affected or 0) > 0 then
            notify(source, ("^2Warn #%d supprimé.^7"):format(warnId))
        else
            notify(source, ("^1Warn #%d introuvable.^7"):format(warnId))
        end
    end)
end)




ESX.RegisterServerCallback("utils:getWarns", function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(tonumber(targetId) or -1)
    if not xTarget then
        cb(false, "Joueur introuvable.")
        return
    end

    local identifier = xTarget.identifier

    db_query(
        "SELECT id, staff_name, reason, created_at FROM player_warns WHERE identifier = ? ORDER BY id DESC LIMIT ?",
        { identifier, Config.WarnListLimit or 20 },
        function(rows)
            cb(true, rows or {}, GetPlayerName(xTarget.source) or ("ID "..targetId))
        end
    )
end)

ESX.RegisterServerCallback("utils:clearWarnById", function(source, cb, warnId)
    if not hasPerm(source, Config.Ace.CWarn) then
        cb(false, "Pas la permission.")
        return
    end

    warnId = tonumber(warnId)
    if not warnId then
        cb(false, "ID warn invalide.")
        return
    end

    db_execute("DELETE FROM player_warns WHERE id = ?", { warnId }, function(affected)
        if (affected or 0) > 0 then
            cb(true)
        else
            cb(false, "Warn introuvable.")
        end
    end)
end)

RegisterNetEvent("utils:clearWarnById", function(warnId)
    local src = source
    if not hasPerm(src, Config.Ace.CWarn) then return end

    warnId = tonumber(warnId)
    if not warnId then return end

    db_execute("DELETE FROM player_warns WHERE id = ?", { warnId }, function(affected)
        TriggerClientEvent("utils:clearWarnResult", src, warnId, affected > 0)
    end)
end)
