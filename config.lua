Config = {}

-- Permissions ACE (recommandé)
Config.UseAcePerms = true

-- Noms des permissions ACE
Config.Ace = {
    Revive  = "utils.revive",
    MPID    = "utils.mpid",
    Time    = "utils.time",
    Weather = "utils.weather",
    RPID    = "utils.rpid",
}

-- Weather autorisés (GTA)
Config.AllowedWeather = {
    "EXTRASUNNY", "CLEAR", "NEUTRAL", "SMOG", "FOGGY",
    "OVERCAST", "CLOUDS", "CLEARING", "RAIN", "THUNDER",
    "SNOW", "BLIZZARD", "SNOWLIGHT", "XMAS", "HALLOWEEN"
}

-- DB driver: "oxmysql" ou "mysql-async"
Config.DB = "oxmysql"

-- Si tu utilises un script d’ambulance ESX qui expose un event revive, mets-le ici :
-- Exemple courant: "esx_ambulancejob:revive" (client event)
Config.ReviveClientEvent = "esx_ambulancejob:revive"

-- Affichage des messages
Config.Prefix = "^3[UTILS]^7 "

Config.Ace.Warn  = "utils.warn"
Config.Ace.LWarn = "utils.lwarn"

-- combien de warns à afficher dans /lwarn
Config.WarnListLimit = 20
Config.Ace.CWarn = "utils.cwarn"

