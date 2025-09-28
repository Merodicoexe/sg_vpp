Config = {}

-- Framework Configuration
Config.Framework = 'ESX' -- ESX, QB, QBX
Config.Notify = 'Ox_lib' -- Default, ESX, QB, QBX, OkokNotify, Ox_lib, Custom
Config.Locale = 'cs' -- en, cs, pl
Config.Debug = false -- Enable/disable debug messages

-- Announcement Configuration
Config.AnnouncementIcon = 'fas fa-gavel'
Config.AnnouncementMessageTitle = 'VPP OZNÁMENÍ'
Config.AnnouncementEnabled = true

-- Database Configuration
Config.Database = {
    enabled = true,
    tableName = 'community_service',
    autoCreateTable = true
}

-- Community Service Locations
Config.Locations = {
    {
        name = "Úklid smety",
        coords = vector3(1746.0977, 2517.5525, 45.5650),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1753.7289, 2530.6414, 45.5650),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1767.7104, 2549.8228, 45.5650),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1753.8975, 2561.5908, 45.5650),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1726.1710, 2561.3313, 45.5649),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1731.6879, 2544.8628, 45.5649),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1723.3629, 2539.2542, 45.5649),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1719.1958, 2513.4541, 45.5649),
        type = "cleanup"
    },
    {
        name = "Úklid smety",
        coords = vector3(1704.5160, 2527.9255, 45.5649),
        type = "cleanup"
    }
}

-- Task Configuration
Config.Tasks = {
    defaultCount = 5,
    minCount = 0,
    maxCount = 999999999999999999,
    
    types = {
        cleanup = {
            name = "Úklid",
            duration = 2000,
            prop = "prop_tool_broom",
            animation = {
                dict = "anim@amb@drug_field_workers@rake@male_a@base",
                name = "base"
            },
            experience = 1
        }
    }
}

-- Teleport Configuration
Config.Teleport = {
    enabled = true,
    spawnLocation = vector3(1746.7706, 2516.1172, 45),
    releaseLocation = vector3(1846.7151, 2585.7354, 45.6720)
}

-- Marker Configuration
Config.Markers = {
    type = 1,
    size = vector3(1.5, 1.5, 1.0),
    color = {r = 90, g = 175, b = 155, a = 100},
    bobUpAndDown = false,
    faceCamera = true,
    rotate = false
}

-- Blip Configuration
Config.Blips = {
    Enable = false, -- nebo false pro zakázání
    sprite = 1,
    color = 5,
    scale = 0.8,
    route = true,
    name = "VPP"
}

-- Restrictions during community service
Config.Restrictions = {
    disableWeapons = true,
    disableVehicles = false,
    disablePhone = true,
    disableInventory = true,
    disableJump = false,
    disableCover = true,
    restrictedArea = {
        enabled = true,
        center = vector3(1746.7706, 2516.1172, 45.9386),
        radius = 100.0,
        warningMessage = "Nemůžeš opustit oblast!"
    }
}

-- Admin Configuration
Config.Admin = {
    acePermission = "command.communityservice",
    allowedGroups = {"admin", "moderator"},
    logActions = true
}

-- Jobs Configuration for police/sheriff access
Config.Jobs = {
    Enable = true,
    Target = true, -- = true = ox_target , false = 3d text
    Jobs = {'police','sheriff'},
    Coords = vec(0,0,0),
    npc = 's_m_m_prisguard_01'
}

-- UI Configuration
Config.UI = {
    textScale = 0.6,
    textColor = {r = 255, g = 255, b = 255, a = 255},
    progressBar = {
        width = 0.2,
        height = 0.02,
        backgroundColor = {r = 0, g = 0, b = 0, a = 180},
        fillColor = {r = 0, g = 255, b = 0, a = 180}
    }
}

-- Locales
Config.Locales = {
    cs = {
        assigned = "Byli jste přiřazeni k %s VPP. GLHF",
        completed = "Všechny VPP dokončeny!",
        taskCompleted = "VPP dokončeno! zbývá: %s",
        taskInstruction = "Stiskni ~g~E~w~ pro %s",
        tasksRemaining = "Zbývající úkoly: %s",
        cleaning = "Probíhá %s",
        noPermission = "Nemáš oprávnění použít tento příkaz.",
        invalidPlayer = "Neplatné ID hráče.",
        playerAssigned = "%s %s VPP",
        playerReleased = "%s dokončeny VPP",
        alreadyInService = "Hráč již vykonává veřejně prospěšné práce.",
        notInService = "Hráč nevykonává veřejně prospěšné práce.",
        dialogTitle = "Přidelit VPP",
        dialogPlayerID = "ID hráče",
        dialogTaskCount = "Počet VPP",
        dialogReason = "Důvod",
        dialogPlayerIDPlaceholder = "Zadejte ID hráče",
        dialogTaskCountPlaceholder = "Zadejte počet VPP",
        dialogReasonPlaceholder = "Zadejte důvod trestu",
        dialogCancel = "Zrušeno",
        announce = "Hráč s ID: %s (%s) obdržel trest ve formě VPP\nDůvod: %s\nPočet úkolů: %s",
        menuTitle = "VPP Menu",
        menuAssign = "Přidelit VPP",
        menuCancel = "Zrušit VPP (FAST)",
        menuPlayerList = "Seznam hráčů s VPP",
        menuAssignDesc = "Přidat VPP hráči",
        menuCancelDesc = "Odebrat VPP hráči",
        menuPlayerListDesc = "Seznam všech hráčů s VPP",
        cancelDialogTitle = "Zrušit VPP",
        cancelDialogPlayerID = "ID hráče",
        cancelDialogPlayerIDPlaceholder = "Zadejte ID hráče",
        playerNotFound = "Hráč nebyl nalezen.",
        permissionDenied = "Přístup odepřen - nemáte dostatečná oprávnění.",
        playerListTitle = "Seznam hráčů s VPP",
        selectPlayer = "Vyberte hráče",
        selectPlayerDesc = "Klikněte na hráče pro zobrazení možností",
        noActivePlayers = "Žádní hráči momentálně nevykonávají VPP",
        playerInfo = "Informace o hráči",
        playerReason = "Důvod přiřazení",
        removeVPP = "Odebrat VPP",
        removeVPPDesc = "Okamžitě ukončit VPP pro tohoto hráče",
        refreshInfo = "Obnovit seznam",
        refreshInfoDesc = "Znovu načíst aktuální seznam hráčů",
        confirmRemoval = "Odebrání VPP",
        confirmRemovalText = "Opravdu chcete odebrat VPP pro %s (ID: %d)?",
        confirmYes = "Ano, odebrat",
        confirmNo = "Ne, zrušit",
        vppRemoved = "VPP odebrány pro %s",
        searchPlayer = "Vyhledat hráče",
        searchPlayerDesc = "Vyhledat hráče podle jména nebo ID",
        searchPlayerLabel = "ID/Jméno hráče",
        searchPlayerPlaceholder = "Zadejte jméno nebo ID hráče"
    },
    en = {
        assigned = "You have been sentenced to %s community service tasks.",
        completed = "You have completed your community service. You are now free!",
        taskCompleted = "Task completed! Remaining: %s tasks",
        taskInstruction = "Press ~g~E~w~ to %s",
        tasksRemaining = "Remaining tasks: %s",
        cleaning = "%s in progress... %ss",
        noPermission = "You don't have permission to use this command.",
        invalidPlayer = "Invalid player ID.",
        playerAssigned = "Player %s has been sentenced to %s community service tasks.",
        playerReleased = "Player %s has been released from community service.",
        alreadyInService = "Player is already in community service.",
        notInService = "Player is not in community service.",
        dialogTitle = "VPP",
        dialogPlayerID = "Player ID",
        dialogTaskCount = "Task Count",
        dialogReason = "Reason",
        dialogPlayerIDPlaceholder = "Enter player ID",
        dialogTaskCountPlaceholder = "Enter task count (5-50)",
        dialogReasonPlaceholder = "Enter assignment reason",
        dialogCancel = "Cancelled",
        announce = "Player %s received community service punishment\nReason: %s\nCount: %s tasks",
        menuTitle = "VPP Admin Menu",
        menuAssign = "Assign VPP",
        menuCancel = "Cancel VPP",
        menuPlayerList = "VPP",
        menuAssignDesc = "Assign community service to player",
        menuCancelDesc = "Cancel VPP for player",
        menuPlayerListDesc = "Show list of all players with active VPP",
        cancelDialogTitle = "Cancel VPP",
        cancelDialogPlayerID = "Player ID",
        cancelDialogPlayerIDPlaceholder = "Enter player ID to cancel VPP",
        playerNotFound = "Player not found.",
        permissionDenied = "Access denied - insufficient permissions.",
        playerListTitle = "VPP",
        selectPlayer = "Select Player",
        selectPlayerDesc = "Click on a player to view options",
        noActivePlayers = "No players are currently doing community service",
        playerInfo = "Player Information",
        playerReason = "Assignment Reason",
        removeVPP = "Remove VPP",
        removeVPPDesc = "Immediately end VPP for this player",
        refreshInfo = "Refresh List",
        refreshInfoDesc = "Reload current player list",
        confirmRemoval = "Confirm VPP Removal",
        confirmRemovalText = "Do you really want to remove VPP from player %s (ID: %d)?",
        confirmYes = "Yes, remove",
        confirmNo = "No, cancel",
        vppRemoved = "VPP was successfully removed from player %s",
        searchPlayer = "Search Player",
        searchPlayerDesc = "Search player by name or ID",
        searchPlayerLabel = "Search term",
        searchPlayerPlaceholder = "Enter player name or ID"
    }
}
-- Debug Function
function DebugPrint(message, type)
    if Config.Debug then
        print(string.format("[%s] %s", type or "DEBUG", message))
    end
end
