local isInCommunityService = false
local tasksRemaining = 0
local currentTaskLocation = nil
local currentTaskType = nil
local blips = {}

-- Function to get locale text
function GetLocaleText(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['cs']
    local text = locale[key] or key
    if ... then
        return string.format(text, ...)
    end
    return text
end

-- Function to show VPP admin context menu
function ShowVPPAdminMenu()
    lib.registerContext({
        id = 'vpp_admin_menu',
        title = GetLocaleText('menuTitle'),
        options = {
            {
                title = GetLocaleText('menuAssign'),
                description = GetLocaleText('menuAssignDesc'),
                icon = 'fas fa-user-plus',
                onSelect = function()
                    ShowAssignDialog()
                end
            },
            {
                title = GetLocaleText('menuCancel'),
                description = GetLocaleText('menuCancelDesc'),
                icon = 'fas fa-user-minus',
                onSelect = function()
                    ShowCancelDialog()
                end
            },
            {
                title = GetLocaleText('menuPlayerList'),
                description = GetLocaleText('menuPlayerListDesc'),
                icon = 'fas fa-list',
                onSelect = function()
                    ShowVPPPlayerList()
                end
            }
        }
    })
    lib.showContext('vpp_admin_menu')
end

-- Function to show VPP player list
function ShowVPPPlayerList()
    -- Show loading notification
    lib.notify({
        title = 'VPP',
        description = 'Probíhá načítání',
        type = 'info',
        duration = 3000
    })
    
    -- Request player list from server
    TriggerServerEvent('community_service:requestPlayerList')
end

-- Function to display player list as context menu
function DisplayVPPPlayerList(players)
    if not players or #players == 0 then
        lib.notify({
            title = 'VPP',
            description = GetLocaleText('noActivePlayers'),
            type = 'info'
        })
        return
    end

    -- Create context menu options
    local options = {}
    
    -- Add search option at the top
    table.insert(options, {
        title = "🔍 " .. GetLocaleText('searchPlayer'),
        description = GetLocaleText('searchPlayerDesc'),
        icon = 'fas fa-search',
        onSelect = function()
            ShowPlayerSearch(players)
        end
    })
    
    -- Add separator
    table.insert(options, {
        title = "Hráči s VPP:",
        disabled = true
    })

    -- Add players to menu
    for _, player in ipairs(players) do
        table.insert(options, {
            title = string.format("%s (ID: %d)", player.name, player.id),
            description = string.format("VPP: %d | Čas od přiřazení: %s",
                player.tasksRemaining, player.timeText),
            icon = 'fas fa-user',
            metadata = player,
            onSelect = function()
                ShowPlayerVPPOptions(player)
            end
        })
    end

    -- Show context menu
    lib.registerContext({
        id = 'vpp_player_list',
        title = GetLocaleText('playerListTitle') .. " (" .. #players .. ")",
        menu = 'vpp_admin_menu',
        options = options
    })
    
    lib.showContext('vpp_player_list')
end

-- Function to show player search
function ShowPlayerSearch(players)
    local input = lib.inputDialog(GetLocaleText('searchPlayer'), {
        {
            type = 'input',
            label = GetLocaleText('searchPlayerLabel'),
            description = GetLocaleText('searchPlayerPlaceholder'),
            required = false,
            max = 50
        }
    })

    if input and input[1] then
        local searchTerm = string.lower(input[1])
        local filteredPlayers = {}
        
        for _, player in ipairs(players) do
            local playerName = string.lower(player.name)
            local playerId = tostring(player.id)
            
            if string.find(playerName, searchTerm) or string.find(playerId, searchTerm) then
                table.insert(filteredPlayers, player)
            end
        end
        
        if #filteredPlayers > 0 then
            DisplayVPPPlayerList(filteredPlayers)
        else
            lib.notify({
                title = 'VPP Search',
                description = 'Žádní hráči nenalezeni pro: "' .. input[1] .. '"',
                type = 'warning'
            })
            -- Show original list again
            DisplayVPPPlayerList(players)
        end
    else
        -- Show original list again if cancelled
        DisplayVPPPlayerList(players)
    end
end

-- Function to show options for specific player
function ShowPlayerVPPOptions(playerData)
    if not playerData then return end
    
    lib.registerContext({
        id = 'vpp_player_options',
        title = string.format("%s", playerData.name),
        menu = 'vpp_player_list',
        options = {
            {
                title = GetLocaleText('playerInfo'),
                description = string.format("ID: %d | VPP: %d | Čas od přiřazení: %s",
                    playerData.id, playerData.tasksRemaining, playerData.timeText),
                icon = 'fas fa-info-circle',
                disabled = true
            },
            {
                title = GetLocaleText('playerReason'),
                description = playerData.reason or "Neznámý důvod",
                icon = 'fas fa-clipboard',
                disabled = true
            },
            {
                title = GetLocaleText('removeVPP'),
                description = GetLocaleText('removeVPPDesc'),
                icon = 'fas fa-user-times',
                iconColor = '#e74c3c',
                onSelect = function()
                    ConfirmRemoveVPP(playerData)
                end
            },
            {
                title = GetLocaleText('refreshInfo'),
                description = GetLocaleText('refreshInfoDesc'),
                icon = 'fas fa-sync-alt',
                onSelect = function()
                    ShowVPPPlayerList()
                end
            }
        }
    })
    lib.showContext('vpp_player_options')
end

-- Function to confirm VPP removal
function ConfirmRemoveVPP(playerData)
    local alert = lib.alertDialog({
        header = GetLocaleText('confirmRemoval'),
        content = string.format(GetLocaleText('confirmRemovalText'), playerData.name, playerData.id),
        centered = true,
        cancel = true,
        labels = {
            confirm = GetLocaleText('confirmYes'),
            cancel = GetLocaleText('confirmNo')
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('community_service:cancelVPP', playerData.id)
        lib.notify({
            title = 'VPP',
            description = string.format(GetLocaleText('vppRemoved'), playerData.name),
            type = 'success'
        })
    end
end

-- Function to show assign dialog
function ShowAssignDialog()
    local input = lib.inputDialog(GetLocaleText('dialogTitle'), {
        {
            type = 'number',
            label = GetLocaleText('dialogPlayerID'),
            description = GetLocaleText('dialogPlayerIDPlaceholder'),
            required = true,
            min = 1,
            max = 1024
        },
        {
            type = 'number',
            label = GetLocaleText('dialogTaskCount'),
            description = GetLocaleText('dialogTaskCountPlaceholder'),
            required = true,
            min = Config.Tasks.minCount,
            max = Config.Tasks.maxCount,
            default = Config.Tasks.defaultCount
        },
        {
            type = 'input',
            label = GetLocaleText('dialogReason'),
            description = GetLocaleText('dialogReasonPlaceholder'),
            required = true,
            max = 255
        }
    })
    
    if input then
        TriggerServerEvent('community_service:processDialog', {
            playerId = input[1],
            taskCount = input[2],
            reason = input[3]
        })
    end
end

-- Function to show cancel dialog
function ShowCancelDialog()
    local input = lib.inputDialog(GetLocaleText('cancelDialogTitle'), {
        {
            type = 'number',
            label = GetLocaleText('cancelDialogPlayerID'),
            description = GetLocaleText('cancelDialogPlayerIDPlaceholder'),
            required = true,
            min = 1,
            max = 1024
        }
    })
    
    if input then
        TriggerServerEvent('community_service:cancelVPP', input[1])
    end
end

-- Event to show VPP admin menu
RegisterNetEvent('community_service:showVPPMenu')
AddEventHandler('community_service:showVPPMenu', function()
    ShowVPPAdminMenu()
end)

-- Event to receive player list from server
RegisterNetEvent('community_service:receivePlayerList')
AddEventHandler('community_service:receivePlayerList', function(players)
    if Config.Debug then
        print("[VPP CLIENT] Received player list with " .. (#players or 0) .. " players")
    end
    
    -- Small delay to ensure UI is ready
    Citizen.SetTimeout(100, function()
        DisplayVPPPlayerList(players)
    end)
end)

-- Function to start community service
RegisterNetEvent("community_service:start")
AddEventHandler("community_service:start", function(tasks)
    isInCommunityService = true
    tasksRemaining = tasks
    
    if Config.Teleport and Config.Teleport.enabled then
        local coords = Config.Teleport.spawnLocation
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    end
    
    Citizen.CreateThread(function()
        Wait(1000)
        CreateAllTaskMarkers()
        StartCommunityServiceLoop()
    end)
end)

-- Function to start the main loop
function StartCommunityServiceLoop()
    Citizen.CreateThread(function()
        while isInCommunityService do
            Citizen.Wait(0)
            
            ApplyRestrictions()
            
            if GetGameTimer() % 500 < 100 then
                if Config.Restrictions and Config.Restrictions.restrictedArea and Config.Restrictions.restrictedArea.enabled then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    if not IsInRestrictedArea(playerCoords) then
                        lib.notify({
                            title = 'VPP',
                            description = Config.Restrictions.restrictedArea.warningMessage,
                            type = 'error'
                        })
                        local coords = Config.Teleport.spawnLocation
                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                    end
                end
            end
        end
        DebugPrint("Community service loop ended", "CLIENT")
    end)
end

-- Function to apply restrictions
function ApplyRestrictions()
    if not Config.Restrictions then return end
    
    if Config.Restrictions.disableWeapons then
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 45, true)
        DisableControlAction(0, 37, true)
    end
    
    if Config.Restrictions.disablePhone then
        DisableControlAction(0, 288, true)
    end
    
    if Config.Restrictions.disableInventory then
        DisableControlAction(0, 289, true)
    end
    
    if Config.Restrictions.disableJump then
        DisableControlAction(0, 22, true)
    end
    
    if Config.Restrictions.disableCover then
        DisableControlAction(0, 44, true)
    end
    
    DisableControlAction(0, 170, true)
    DisableControlAction(0, 167, true)
    DisableControlAction(0, 168, true)
end

-- Function to update tasks remaining
RegisterNetEvent("community_service:updateTasksRemaining")
AddEventHandler("community_service:updateTasksRemaining", function(tasks, completedLocation)
    tasksRemaining = tasks
    
    if completedLocation then
        RemoveCompletedTaskMarker(completedLocation)
    end
    
    if tasksRemaining > 0 and #blips == 0 then
        CreateAllTaskMarkers()
    end
end)

-- Function to finish community service
RegisterNetEvent("community_service:finish")
AddEventHandler("community_service:finish", function()
    isInCommunityService = false
    tasksRemaining = 0
    
    RemoveAllTaskMarkers()
    ClearPedTasks(PlayerPedId())
    RemoveNearbyProps()
    
    if Config.Teleport and Config.Teleport.enabled then
        local coords = Config.Teleport.releaseLocation
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    end
end)

-- Function to create all task markers and blips
function CreateAllTaskMarkers()
    RemoveAllTaskMarkers()
    
    for i, location in ipairs(Config.Locations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, Config.Blips.sprite)
        SetBlipColour(blip, Config.Blips.color)
        SetBlipScale(blip, Config.Blips.scale)
        SetBlipRoute(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(blips, {
            blip = blip,
            location = location,
            index = i
        })
    end
    
    StartMarkerThread()
end

-- Function to start marker drawing thread
function StartMarkerThread()
    Citizen.CreateThread(function()
        while isInCommunityService do
            Citizen.Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for _, blipData in ipairs(blips) do
                if blipData.location and blipData.location.coords then
                    local location = blipData.location
                    local distance = #(playerCoords - vector3(location.coords.x, location.coords.y, location.coords.z))
                    
                    if distance < 100.0 then
                        DrawMarker(
                            21,
                            location.coords.x, location.coords.y, location.coords.z - 0.2,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            Config.Markers.size.x, Config.Markers.size.y, Config.Markers.size.z,
                            Config.Markers.color.r, Config.Markers.color.g, Config.Markers.color.b, Config.Markers.color.a,
                            Config.Markers.bobUpAndDown, Config.Markers.faceCamera, 2, Config.Markers.rotate, nil, nil, false
                        )
                    end
                    
                    if distance < 1.5 then
                        local taskConfig = GetTaskTypeConfig(location.type or "cleanup")
                        DrawTextOnScreen(GetLocaleText('taskInstruction', taskConfig.name), 0.5, 0.95, Config.UI.textScale, Config.UI.textColor)
                        
                        if IsControlJustReleased(0, 38) then
                            currentTaskLocation = location
                            currentTaskType = location.type or "cleanup"
                            PerformTask()
                        end
                    end
                end
            end
        end
        DebugPrint("Marker thread ended", "CLIENT")
    end)
end

-- Function to remove completed task marker
function RemoveCompletedTaskMarker(completedLocation)
    for i = #blips, 1, -1 do
        local blipData = blips[i]
        if blipData.location and completedLocation and 
           blipData.location.coords.x == completedLocation.coords.x and
           blipData.location.coords.y == completedLocation.coords.y and
           blipData.location.coords.z == completedLocation.coords.z then
            
            if DoesBlipExist(blipData.blip) then
                RemoveBlip(blipData.blip)
            end
            table.remove(blips, i)
            DebugPrint("Removed completed task marker", "CLIENT")
            break
        end
    end
end

-- Function to remove all task markers
function RemoveAllTaskMarkers()
    for _, blipData in ipairs(blips) do
        if DoesBlipExist(blipData.blip) then
            RemoveBlip(blipData.blip)
        end
    end
    blips = {}
    currentTaskLocation = nil
end

-- Function to perform task
function PerformTask()
    local taskConfig = GetTaskTypeConfig(currentTaskType)
    
    RequestAnimDict(taskConfig.animation.dict)
    local timeout = 0
    while not HasAnimDictLoaded(taskConfig.animation.dict) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if timeout >= 50 then
        DebugPrint("Failed to load animation dictionary: " .. taskConfig.animation.dict, "CLIENT")
        lib.notify({
            title = 'VPP',
            description = 'Chyba při načítání animace. Zkuste to znovu.',
            type = 'error'
        })
        return
    end
    
    local prop = nil
    if taskConfig.prop then
        local playerPed = PlayerPedId()
        local x, y, z = table.unpack(GetEntityCoords(playerPed))
        
        local propHash = GetHashKey(taskConfig.prop)
        RequestModel(propHash)
        timeout = 0
        while not HasModelLoaded(propHash) and timeout < 50 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        
        if timeout >= 50 then
            DebugPrint("Failed to load prop model: " .. taskConfig.prop, "CLIENT")
            lib.notify({
                title = 'VPP',
                description = 'Chyba při načítání objektu. Zkuste to znovu.',
                type = 'error'
            })
            return
        end
        
        prop = CreateObject(propHash, x, y, z + 0.2, true, true, true)
        AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end
    
    local playerPed = PlayerPedId()
    TaskPlayAnim(playerPed, taskConfig.animation.dict, taskConfig.animation.name, 8.0, -8.0, -1, 0, 0, false, false, false)
    
    if lib.progressBar then
        lib.progressBar({
            duration = taskConfig.duration,
            label = GetLocaleText('cleaning', taskConfig.name, math.ceil(taskConfig.duration / 1000)),
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
    else
        Citizen.Wait(taskConfig.duration)
    end
    
    ClearPedTasks(playerPed)
    if prop then
        DeleteEntity(prop)
    end
    
    TriggerServerEvent("community_service:completeTask", currentTaskType, currentTaskLocation)
    currentTaskLocation = nil
end

-- Function to remove nearby props
function RemoveNearbyProps()
    for taskType, config in pairs(Config.Tasks.types) do
        if config.prop then
            local prop = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 2.0, GetHashKey(config.prop), false, false, false)
            if prop ~= 0 then
                DeleteEntity(prop)
            end
        end
    end
end

-- Function to draw text on screen
function DrawTextOnScreen(text, x, y, scale, color)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Function to check if player is in restricted area
function IsInRestrictedArea(playerCoords)
    if not Config.Restrictions or not Config.Restrictions.restrictedArea or not Config.Restrictions.restrictedArea.enabled then
        return true
    end
    
    local area = Config.Restrictions.restrictedArea
    if not area.center then return true end
    
    local distance = #(playerCoords - vector3(area.center.x, area.center.y, area.center.z))
    return distance <= area.radius
end

-- Function to get task type config
function GetTaskTypeConfig(taskType)
    if not taskType or not Config.Tasks.types[taskType] then
        return Config.Tasks.types["cleanup"]
    end
    return Config.Tasks.types[taskType]
end
