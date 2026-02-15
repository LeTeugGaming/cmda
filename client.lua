local currentWeather = "CLEAR"
local currentHour, currentMinute = 12, 0

RegisterNetEvent("utils:syncTimeWeather", function(hour, minute, weather)
    currentHour = hour
    currentMinute = minute
    currentWeather = weather
end)

CreateThread(function()
    while true do
        -- Time
        NetworkOverrideClockTime(currentHour, currentMinute, 0)

        -- Weather
        SetWeatherTypeOvertimePersist(currentWeather, 5.0)
        SetWeatherTypePersist(currentWeather)
        SetWeatherTypeNowPersist(currentWeather)

        Wait(1000)
    end
end)

local function ShowTopRightNotification(title, subtitle, msg)
    -- style GTA (au dessus de la mini-map)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)

    -- optionnel: notification "advanced" avec icône (souvent encore plus stylé)
    -- ESX.ShowAdvancedNotification(title, subtitle, msg, "CHAR_CHAT_CALL", 1)
end

RegisterNetEvent("utils:mpidNotify", function(fromName, message)
    -- 🔊 Son d’alerte (choisis celui que tu préfères)
    PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    -- 🧾 Notification avancée (icône à gauche)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)

    -- Icône + titre/sous-titre
    -- Icônes possibles: "CHAR_CHAT_CALL", "CHAR_CALL911", "CHAR_DEFAULT", "CHAR_SOCIAL_CLUB"
    EndTextCommandThefeedPostMessagetext("CHAR_CHAT_CALL", "CHAR_CHAT_CALL", false, 1, "MP Staff", ("De: %s"):format(fromName))
    EndTextCommandThefeedPostTicker(false, true)
end)


RegisterNetEvent("utils:warnNotify", function(staffName, reason)
    -- son d'alerte
    PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    -- notif advanced (icône message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(("Motif:\n%s"):format(reason))
    EndTextCommandThefeedPostMessagetext("CHAR_CHAT_CALL", "CHAR_CHAT_CALL", false, 1, "Avertissement", ("Par: %s"):format(staffName))
    EndTextCommandThefeedPostTicker(false, true)
end)


local ESX = exports["es_extended"]:getSharedObject()

-- Retour suppression (envoyé par le serveur)
RegisterNetEvent("utils:clearWarnResult", function(warnId, ok)
    PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(ok and ("Warn #" .. warnId .. " supprimé.") or ("Warn #" .. warnId .. " introuvable."))
    EndTextCommandThefeedPostTicker(false, true)
end)

local function openWarnDetail(warn, targetId, targetLabel)
    local elements = {
        { label = ("🧑‍⚖️ Staff : <span style='color:yellow'>%s</span>"):format(warn.staff_name or "N/A"), value = "noop" },
        { label = ("🕒 Date : <span style='color:deepskyblue'>%s</span>"):format(warn.created_at or "N/A"), value = "noop" },
        { label = ("📝 Motif : <span style='color:white'>%s</span>"):format(warn.reason or "N/A"), value = "noop" },
        { label = "<span style='color:tomato'>🗑️ Clear ce warn</span>", value = "clear" },
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'warn_detail', {
        title = ("Warn #%s - %s"):format(warn.id, targetLabel),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "clear" then
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'warn_confirm', {
                title = ("Supprimer warn #%s ?"):format(warn.id),
                align = 'top-left',
                elements = {
                    { label = "<span style='color:tomato'>Oui, supprimer</span>", value = "yes" },
                    { label = "Annuler", value = "no" }
                }
            }, function(d2, m2)
                if d2.current.value == "yes" then
                    TriggerServerEvent("utils:clearWarnById", warn.id)
                    m2.close()
                    menu.close()
                    -- refresh de la liste après suppression
                    ExecuteCommand("lwarn " .. tostring(targetId))
                else
                    m2.close()
                end
            end, function(d2, m2)
                m2.close()
            end)
        end
    end, function(data, menu)
        menu.close()
    end)
end

local function openWarnList(targetId, targetLabel, warns)
    local elements = {}

    for _, w in ipairs(warns) do
        local shortReason = w.reason or ""
        if #shortReason > 42 then shortReason = shortReason:sub(1, 42) .. "..." end

        elements[#elements+1] = {
            label = ("#%s | <span style='color:deepskyblue'>%s</span> | <span style='color:yellow'>%s</span> | %s")
                :format(w.id, w.created_at or "N/A", w.staff_name or "N/A", shortReason),
            warn = w
        }
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'warn_list', {
        title = ("Warns - %s (ID %s)"):format(targetLabel, targetId),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current and data.current.warn then
            openWarnDetail(data.current.warn, targetId, targetLabel)
        end
    end, function(data, menu)
        menu.close()
    end)
end

RegisterCommand("lwarn", function(_, args)
    local targetId = tonumber(args[1])
    if not targetId then
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName("Usage: /lwarn [id]")
        EndTextCommandThefeedPostTicker(false, true)
        return
    end

    ESX.TriggerServerCallback("utils:getWarns", function(ok, data, targetLabel)
        if not ok then
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName(tostring(data))
            EndTextCommandThefeedPostTicker(false, true)
            return
        end

        local warns = data or {}
        if #warns == 0 then
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName(("Aucun warn pour %s (ID %s)."):format(targetLabel, targetId))
            EndTextCommandThefeedPostTicker(false, true)
            return
        end

        openWarnList(targetId, targetLabel, warns)
    end, targetId)
end, false)


