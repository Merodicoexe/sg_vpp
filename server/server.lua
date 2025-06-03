local communityServicePlayers = {}
local Framework = nil

-- Initialize Framework
Citizen.CreateThread(function()
    if Config.Framework == 'ESX' then
        while ESX == nil do
            ESX = exports['es_extended']:getSharedObject()
            Citizen.Wait(100)
        end
        Framework = ESX
        DebugPrint("ESX Framework loaded successfully", "SERVER")
    elseif Config.Framework == 'QB' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = QBCore
        DebugPrint("QBCore Framework loaded successfully", "SERVER")
    elseif Config.Framework == 'QBX' then
        Framework = exports['qbx-core']:GetCoreObject()
        DebugPrint("QBX Framework loaded successfully", "SERVER")
    else
        DebugPrint("No framework specified or supported", "SERVER")
    end
end)

-- Function to get locale text
function GetLocaleText(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['cs']
    local text = locale[key] or key
    if ... then
        return string.format(text, ...)
    end
    return text
end

-- Function to send notification
function SendNotification(source, message, type)
    type = type or 'info'
    
    if Config.Notify == 'Ox_lib' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'VPP',
            description = message,
            type = type
        })
    elseif Config.Notify == 'ESX' and Framework then
        TriggerClientEvent('esx:showNotification', source, message)
    elseif Config.Notify == 'QB' then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif Config.Notify == 'QBX' then
        TriggerClientEvent('qbx_core:notify', source, message, type)
    elseif Config.Notify == 'OkokNotify' then
        TriggerClientEvent('okokNotify:Alert', source, 'VPP', message, 5000, type)
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^2SYSTEM', message}
        })
    end
end

-- Function to check permissions
function HasPermission(source, permission)
    if source == 0 then return true end
    
    -- Check ACE permission
    if IsPlayerAceAllowed(source, permission or Config.Admin.acePermission) then
        return true
    end
    
    -- Check group permissions
    for _, group in ipairs(Config.Admin.allowedGroups) do
        if IsPlayerAceAllowed(source, "group." .. group) then
            return true
        end
    end
    
    DebugPrint(string.format("Permission denied for player %s", GetPlayerName(source) or "Unknown"), "PERMS")
    return false
end

-- Function to validate player
function ValidatePlayer(source, targetId)
    if not targetId or not GetPlayerName(targetId) then
        SendNotification(source, GetLocaleText('playerNotFound'), 'error')
        return false
    end
    return true
end

-- Function to get player from framework
function GetFrameworkPlayer(source)
    if not Framework then return nil end
    
    if Config.Framework == 'ESX' then
        return Framework.GetPlayerFromId(source)
    elseif Config.Framework == 'QB' or Config.Framework == 'QBX' then
        return Framework.Functions.GetPlayer(source)
    end
    
    return nil
end

-- Function to get player identifier
function GetPlayerIdentifier(source, idType)
    local fwPlayer = GetFrameworkPlayer(source)
    
    if fwPlayer then
        if Config.Framework == 'ESX' then
            return fwPlayer.identifier
        elseif Config.Framework == 'QB' or Config.Framework == 'QBX' then
            return fwPlayer.PlayerData.citizenid
        end
    end
    
    idType = idType or "license"
    local identifiers = GetPlayerIdentifiers(source)
    
    if not identifiers then return nil end
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, idType) then
            return identifier
        end
    end
    
    return nil
end

-- Function to get player name
function GetFrameworkPlayerName(source)
    local fwPlayer = GetFrameworkPlayer(source)
    
    if fwPlayer then
        if Config.Framework == 'ESX' then
            return fwPlayer.getName and fwPlayer.getName() or GetPlayerName(source)
        elseif Config.Framework == 'QB' or Config.Framework == 'QBX' then
            return fwPlayer.PlayerData.charinfo.firstname .. ' ' .. fwPlayer.PlayerData.charinfo.lastname
        end
    end
    
    return GetPlayerName(source)
end

-- Function to get current time formatted
function GetFormattedTime()
    local time = os.date("*t")
    return string.format("%02d:%02d", time.hour, time.min)
end

-- Function to get VPP player list
function GetVPPPlayerList()
    local playerList = {}
    
    for playerId, playerData in pairs(communityServicePlayers) do
        if GetPlayerName(playerId) then -- Check if player is still online
            local timeElapsed = os.time() - (playerData.startTime or os.time())
            local timeText = FormatTime(timeElapsed)
            
            table.insert(playerList, {
                id = playerId,
                name = GetPlayerName(playerId),
                tasksRemaining = playerData.tasksRemaining or 0,
                tasksTotal = playerData.tasksTotal or 0,
                startTime = playerData.startTime or os.time(),
                timeElapsed = timeElapsed,
                timeText = timeText,
                reason = playerData.reason or "Neznámý důvod",
                assignedBy = playerData.assignedBy or "System"
            })
        end
    end
    
    -- Sort by start time (newest first)
    table.sort(playerList, function(a, b)
        return a.startTime > b.startTime
    end)
    
    return playerList
end

-- Command to show VPP admin menu
RegisterCommand('vpp', function(source, args, rawCommand)
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    TriggerClientEvent('community_service:showVPPMenu', source)
end, false)

-- Event to handle player list request
RegisterNetEvent('community_service:requestPlayerList')
AddEventHandler('community_service:requestPlayerList', function()
    local source = source
    
    if Config.Debug then
        print("[VPP SERVER] Player " .. GetPlayerName(source) .. " requested player list")
    end
    
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    local playerList = GetVPPPlayerList()
    
    if Config.Debug then
        print("[VPP SERVER] Sending player list with " .. #playerList .. " players to " .. GetPlayerName(source))
    end
    
    TriggerClientEvent('community_service:receivePlayerList', source, playerList)
end)

-- Event to handle cancel VPP
RegisterNetEvent('community_service:cancelVPP')
AddEventHandler('community_service:cancelVPP', function(playerId)
    local source = source
    
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    local targetId = tonumber(playerId)
    
    if not ValidatePlayer(source, targetId) then return end
    
    if not communityServicePlayers[targetId] then
        SendNotification(source, GetLocaleText('notInService'), 'warning')
        return
    end
    
    ReleaseCommunityService(source, targetId, "Zrušeno administrátorem", true)
    SendNotification(source, GetLocaleText('playerReleased', GetPlayerName(targetId)), 'success')
end)

-- Event to handle dialog response
RegisterNetEvent('community_service:processDialog')
AddEventHandler('community_service:processDialog', function(data)
    local source = source
    
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    if not data then
        SendNotification(source, GetLocaleText('dialogCancel'), 'info')
        return
    end
    
    local targetId = tonumber(data.playerId)
    local tasksCount = ValidateTaskCount(tonumber(data.taskCount))
    local reason = data.reason or "Porušení pravidel serveru"
    
    if not ValidatePlayer(source, targetId) then return end
    
    if communityServicePlayers[targetId] then
        SendNotification(source, GetLocaleText('alreadyInService'), 'warning')
        return
    end
    
    AssignCommunityService(source, targetId, tasksCount, reason)
    SendNotification(source, GetLocaleText('playerAssigned', GetPlayerName(targetId), tasksCount), 'success')
end)

-- Command to check community service status
RegisterCommand("csstatus", function(source, args, rawCommand)
    local targetId = tonumber(args[1]) or source
    
    if not HasPermission(source, Config.Admin.acePermission) and targetId ~= source then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    if communityServicePlayers[targetId] then
        local data = communityServicePlayers[targetId]
        local timeElapsed = os.time() - (data.startTime or os.time())
        
        SendNotification(source, string.format("Hráč: %s | Zbývá úkolů: %d | Čas: %s", 
            GetPlayerName(targetId), 
            data.tasksRemaining or 0, 
            FormatTime(timeElapsed)
        ), 'info')
    else
        SendNotification(source, "Hráč nevykonává veřejně prospěšné práce.", 'info')
    end
end, false)

-- Function to assign community service
function AssignCommunityService(adminSource, playerId, tasksCount, reason)
    if not playerId then
        DebugPrint("Invalid player ID in AssignCommunityService", "SERVER")
        return
    end
    
    local playerName = GetFrameworkPlayerName(playerId)
    local playerIdentifier = GetPlayerIdentifier(playerId, "license")
    
    if not playerName or not playerIdentifier then
        DebugPrint("Could not get player data in AssignCommunityService", "SERVER")
        return
    end
    
    local adminName = adminSource > 0 and GetFrameworkPlayerName(adminSource) or "Console"
    local adminIdentifier = adminSource > 0 and GetPlayerIdentifier(adminSource, "license") or "console"
    
    communityServicePlayers[playerId] = {
        tasksRemaining = tasksCount,
        tasksTotal = tasksCount,
        startTime = os.time(),
        identifier = playerIdentifier,
        assignedBy = adminName,
        reason = reason,
        experienceGained = 0
    }
    
    if Config.Database and Config.Database.enabled then
        local playerData = {
            identifier = playerIdentifier,
            playerName = playerName,
            tasksTotal = tasksCount,
            tasksCompleted = 0,
            tasksRemaining = tasksCount,
            assignedBy = adminName,
            reason = reason,
            metadata = {
                adminSource = adminSource,
                assignTime = os.time()
            }
        }
        SaveCommunityService(playerData)
    end
    
    if Config.Database and Config.Database.enabled and Config.Admin.logActions then
        LogAction(playerIdentifier, playerName, "ASSIGNED", 
            string.format("Tasks: %d, Reason: %s", tasksCount, reason),
            adminIdentifier, adminName, {
                tasksCount = tasksCount,
                reason = reason
            })
    end
    
    TriggerClientEvent("community_service:start", playerId, tasksCount)
    SendNotification(playerId, GetLocaleText('assigned', tasksCount), 'info')
    
    DebugPrint(string.format("Assigned %d tasks to %s by %s", tasksCount, playerName, adminName), "SERVER")
    
    -- Send announcement if enabled
    if Config.AnnouncementEnabled then
        SendAnnounce(playerName, reason, tasksCount, playerId)
    end
end

-- Function to release from community service
function ReleaseCommunityService(adminSource, playerId, reason, isManual)
    local playerData = communityServicePlayers[playerId]
    if not playerData then return end
    
    local playerName = GetFrameworkPlayerName(playerId)
    local playerIdentifier = playerData.identifier
    
    if not playerName then
        DebugPrint("Invalid player ID in ReleaseCommunityService", "SERVER")
        return
    end
    
    local adminName = adminSource > 0 and GetFrameworkPlayerName(adminSource) or "System"
    local adminIdentifier = adminSource > 0 and GetPlayerIdentifier(adminSource, "license") or "system"
    local totalTime = os.time() - (playerData.startTime or os.time())
    
    if Config.Database and Config.Database.enabled then
        if isManual then
            CancelCommunityService(playerIdentifier, reason)
        else
            CompleteCommunityService(playerIdentifier, totalTime, playerData.experienceGained or 0)
        end
    end
    
    if Config.Database and Config.Database.enabled and Config.Admin.logActions then
        LogAction(playerIdentifier, playerName, isManual and "RELEASED" or "COMPLETED",
            string.format("Total time: %s, Reason: %s", FormatTime(totalTime), reason or "Completed all tasks"),
            adminIdentifier, adminName, {
                totalTime = totalTime,
                tasksCompleted = (playerData.tasksTotal or 0) - (playerData.tasksRemaining or 0),
                experienceGained = playerData.experienceGained or 0
            })
    end
    
    communityServicePlayers[playerId] = nil
    TriggerClientEvent("community_service:finish", playerId)
    SendNotification(playerId, GetLocaleText('completed'), 'success')
    
    DebugPrint(string.format("Released %s from community service", playerName), "SERVER")
end

-- Event when player completes a task
RegisterNetEvent("community_service:completeTask")
AddEventHandler("community_service:completeTask", function(taskType, location)
    local playerId = source
    local playerData = communityServicePlayers[playerId]
    
    if not playerData then
        DebugPrint("Player not in community service tried to complete task", "SERVER")
        return
    end
    
    local playerIdentifier = GetPlayerIdentifier(playerId, "license")
    local taskConfig = GetTaskTypeConfig(taskType or "cleanup")
    
    playerData.tasksRemaining = (playerData.tasksRemaining or 0) - 1
    playerData.experienceGained = (playerData.experienceGained or 0) + (taskConfig.experience or 1)
    
    if Config.Database and Config.Database.enabled then
        local tasksCompleted = (playerData.tasksTotal or 0) - (playerData.tasksRemaining or 0)
        UpdateCommunityServiceProgress(playerIdentifier, tasksCompleted, playerData.tasksRemaining, location)
    end
    
    if playerData.tasksRemaining <= 0 then
        ReleaseCommunityService(0, playerId, "Completed all tasks", false)
    else
        TriggerClientEvent("community_service:updateTasksRemaining", playerId, playerData.tasksRemaining, location)
        SendNotification(playerId, GetLocaleText('taskCompleted', playerData.tasksRemaining), 'info')
    end
    
    DebugPrint(string.format("Player %s completed task %s, %d remaining", 
        GetPlayerName(playerId), taskType or "unknown", playerData.tasksRemaining), "SERVER")
end)

-- Function to send announce
function SendAnnounce(playerName, reason, taskCount, playerId)
    if not Config.AnnouncementEnabled then return end
    
    -- Get player's connection name (Steam name, etc.)
    local connectionName = GetPlayerName(playerId) or "Neznámý"
    local message = GetLocaleText('announce', playerId, connectionName, reason, taskCount)
    local time = GetFormattedTime()
    
    -- Send styled chat message to all players with multiline support
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message server-msg"><div style="display: flex; align-items: center; margin-bottom: 5px;"><i class="'..Config.AnnouncementIcon..'" style="margin-right: 8px; color: #cc3d3d;"></i><b><span style="color: #cc3d3d;">['..Config.AnnouncementMessageTitle..']</span>&nbsp;<span class="time" style="color: #999;">{1}</span></b></div><div class="message" style="white-space: pre-line; line-height: 1.4;">{0}</div></div>',
        args = { message, time }
    })
    
    -- Also send to server console
    print(string.format("^3[%s]^7 %s", Config.AnnouncementMessageTitle, message:gsub('\n', ' | ')))
    
    -- Log to database if enabled
    if Config.Database and Config.Database.enabled and Config.Admin.logActions then
        LogAction("system", "System", "ANNOUNCE", 
            string.format("Player ID: %s (%s), Reason: %s, Tasks: %d", playerId, connectionName, reason, taskCount),
            "console", "Console", {
                playerId = playerId,
                connectionName = connectionName,
                reason = reason,
                taskCount = taskCount,
                timestamp = os.time()
            })
    end
end

-- Player disconnect handler
AddEventHandler("playerDropped", function(reason)
    local playerId = source
    local playerData = communityServicePlayers[playerId]
    
    if playerData then
        local playerName = GetPlayerName(playerId) or "Unknown"
        local playerIdentifier = playerData.identifier
        
        if Config.Database and Config.Database.enabled then
            local tasksCompleted = (playerData.tasksTotal or 0) - (playerData.tasksRemaining or 0)
            UpdateCommunityServiceProgress(playerIdentifier, tasksCompleted, playerData.tasksRemaining, nil)
        end
        
        DebugPrint(string.format("Player %s disconnected with %d tasks remaining", 
            playerName, playerData.tasksRemaining or 0), "SERVER")
        
        communityServicePlayers[playerId] = nil
    end
end)

-- Function to save all active community service players to database
function SaveAllActiveCommunityService(activePlayers)
    if not Config.Database.enabled then return end
    
    if not activePlayers or type(activePlayers) ~= "table" then
        DebugPrint("Invalid active players data for SaveAllActiveCommunityService", "SERVER")
        return
    end
    
    local count = 0
    for playerId, playerData in pairs(activePlayers) do
        if playerData and playerData.identifier then
            local playerName = GetPlayerName(playerId) or "Unknown"
            
            local saveData = {
                identifier = playerData.identifier,
                playerName = playerName,
                tasksTotal = playerData.tasksTotal or 0,
                tasksCompleted = (playerData.tasksTotal or 0) - (playerData.tasksRemaining or 0),
                tasksRemaining = playerData.tasksRemaining or 0,
                assignedBy = playerData.assignedBy or "System",
                reason = playerData.reason or "No reason provided",
                metadata = {
                    startTime = playerData.startTime,
                    experienceGained = playerData.experienceGained or 0,
                    savedOnStop = true,
                    saveTime = os.time()
                }
            }
            
            SaveCommunityService(saveData)
            count = count + 1
        end
    end
    
    DebugPrint(string.format("Saved %d active community service records to database", count), "SERVER")
end

-- Function to restore community service for online players
function RestoreActiveCommunityService()
    if not Config.Database.enabled then return end
    
    DebugPrint("Starting restoration of active community service...", "SERVER")
    
    LoadAllActiveCommunityService(function(activeData)
        local restoredCount = 0
        
        for identifier, data in pairs(activeData) do
            local playerId = GetPlayerByIdentifier(identifier)
            
            if playerId then
                -- Player is online, restore their community service
                local playerName = GetPlayerName(playerId) or "Unknown"
                
                -- Restore to active players table
                communityServicePlayers[playerId] = {
                    tasksRemaining = data.tasks_remaining or 0,
                    tasksTotal = data.tasks_total or 0,
                    startTime = data.metadata and data.metadata.startTime or os.time(),
                    identifier = identifier,
                    assignedBy = data.assigned_by or "System",
                    reason = data.reason or "No reason provided",
                    experienceGained = data.metadata and data.metadata.experienceGained or 0
                }
                
                -- Notify player and start community service
                TriggerClientEvent("community_service:start", playerId, data.tasks_remaining)
                SendNotification(playerId, string.format("Tvoje VPP byly obnoveny po restartu. Zbývá: %d úkolů", data.tasks_remaining), 'info')
                
                restoredCount = restoredCount + 1
                DebugPrint(string.format("Restored community service for %s (%s)", playerName, identifier), "SERVER")
            else
                -- Player is offline, keep data in database for when they connect
                DebugPrint(string.format("Player with identifier %s is offline, keeping data in database", identifier), "SERVER")
            end
        end
        
        DebugPrint(string.format("Restored community service for %d online players", restoredCount), "SERVER")
    end)
end

-- Function to get player by identifier
function GetPlayerByIdentifier(identifier)
    if not identifier then return nil end
    
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdentifier = GetPlayerIdentifier(tonumber(playerId), "license")
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    
    return nil
end

-- Export functions for other resources
exports('AssignCommunityService', function(playerId, tasksCount, reason)
    AssignCommunityService(0, playerId, tasksCount, reason or "External assignment")
end)

exports('ReleaseCommunityService', function(playerId, reason)
    ReleaseCommunityService(0, playerId, reason or "External release", true)
end)

exports('IsPlayerInCommunityService', function(playerId)
    return communityServicePlayers[playerId] ~= nil
end)

exports('GetPlayerCommunityServiceData', function(playerId)
    return communityServicePlayers[playerId]
end)

exports('GetVPPPlayerList', function()
    return GetVPPPlayerList()
end)

-- Resource stop handler - save all active community service to database
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint("Resource stopping, saving active community service data...", "SERVER")
    
    -- Count active players
    local activeCount = 0
    for _ in pairs(communityServicePlayers) do
        activeCount = activeCount + 1
    end
    
    if activeCount > 0 then
        DebugPrint(string.format("Saving %d active community service players to database", activeCount), "SERVER")
        
        -- Save all active players to database
        if Config.Database and Config.Database.enabled then
            SaveAllActiveCommunityService(communityServicePlayers)
        end
        
        -- Notify all active players
        for playerId, playerData in pairs(communityServicePlayers) do
            if GetPlayerName(playerId) then
                SendNotification(playerId, "VPP script se restartuje. Tvůj pokrok byl uložen.", 'info')
                TriggerClientEvent("community_service:finish", playerId)
            end
        end
        
        DebugPrint("All active community service data saved successfully", "SERVER")
    else
        DebugPrint("No active community service players to save", "SERVER")
    end
end)

-- Resource start handler - restore active community service from database
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint("Resource started, checking for active community service data...", "SERVER")
    
    -- Wait for database to be ready
    Citizen.CreateThread(function()
        Citizen.Wait(5000) -- Wait 5 seconds for everything to initialize
        
        if Config.Database and Config.Database.enabled then
            RestoreActiveCommunityService()
        else
            DebugPrint("Database disabled, skipping community service restoration", "SERVER")
        end
    end)
end)

-- Enhanced player connecting handler for ESX
if Config.Framework == 'ESX' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
        local playerIdentifier = xPlayer.identifier
        
        DebugPrint(string.format("Player %s loaded, checking for active community service", xPlayer.getName()), "SERVER")
        
        -- Check if player already has active community service in memory
        if communityServicePlayers[playerId] then
            DebugPrint(string.format("Player %s already has active community service in memory", xPlayer.getName()), "SERVER")
            return
        end
        
        -- Check database for active community service
        if Config.Database and Config.Database.enabled then
            Citizen.CreateThread(function()
                Citizen.Wait(2000) -- Wait a bit for player to fully load
                
                local success, result = pcall(function()
                    LoadCommunityService(playerIdentifier, function(data)
                        if data and data.status == 'active' then
                            DebugPrint(string.format("Restoring community service for %s from database", xPlayer.getName()), "SERVER")
                            
                            -- Restore community service
                            communityServicePlayers[playerId] = {
                                tasksRemaining = data.tasks_remaining,
                                tasksTotal = data.tasks_total,
                                startTime = data.metadata and data.metadata.startTime or os.time(),
                                identifier = playerIdentifier,
                                assignedBy = data.assigned_by,
                                reason = data.reason,
                                experienceGained = data.experience_gained or 0
                            }
                            
                            -- Notify player and start community service
                            TriggerClientEvent("community_service:start", playerId, data.tasks_remaining)
                            SendNotification(playerId, string.format("Máš nedokončené VPP. Zbývá: %d úkolů", data.tasks_remaining), 'info')
                        end
                    end)
                end)
                
                if not success then
                    DebugPrint("Error in esx:playerLoaded community service check: " .. tostring(result), "SERVER")
                end
            end)
        end
    end)
end

-- Enhanced player connecting handler for QB/QBX
if Config.Framework == 'QB' or Config.Framework == 'QBX' then
    RegisterNetEvent('QBCore:Server:PlayerLoaded')
    AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
        local playerId = Player.PlayerData.source
        local playerIdentifier = Player.PlayerData.citizenid
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        
        DebugPrint(string.format("Player %s loaded, checking for active community service", playerName), "SERVER")
        
        -- Check if player already has active community service in memory
        if communityServicePlayers[playerId] then
            DebugPrint(string.format("Player %s already has active community service in memory", playerName), "SERVER")
            return
        end
        
        -- Check database for active community service
        if Config.Database and Config.Database.enabled then
            Citizen.CreateThread(function()
                Citizen.Wait(2000) -- Wait a bit for player to fully load
                
                local success, result = pcall(function()
                    LoadCommunityService(playerIdentifier, function(data)
                        if data and data.status == 'active' then
                            DebugPrint(string.format("Restoring community service for %s from database", playerName), "SERVER")
                            
                            -- Restore community service
                            communityServicePlayers[playerId] = {
                                tasksRemaining = data.tasks_remaining,
                                tasksTotal = data.tasks_total,
                                startTime = data.metadata and data.metadata.startTime or os.time(),
                                identifier = playerIdentifier,
                                assignedBy = data.assigned_by,
                                reason = data.reason,
                                experienceGained = data.experience_gained or 0
                            }
                            
                            -- Notify player and start community service
                            TriggerClientEvent("community_service:start", playerId, data.tasks_remaining)
                            SendNotification(playerId, string.format("Máš nedokončené VPP. Zbývá: %d úkolů", data.tasks_remaining), 'info')
                        end
                    end)
                end)
                
                if not success then
                    DebugPrint("Error in QB player loaded community service check: " .. tostring(result), "SERVER")
                end
            end)
        end
    end)
end

-- Fallback for servers without framework
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local playerId = source
    
    deferrals.defer()
    deferrals.update("Kontrola VPP dat...")
    
    Citizen.CreateThread(function()
        Citizen.Wait(1000)
        
        if not Framework and Config.Database and Config.Database.enabled then
            local playerIdentifier = GetPlayerIdentifier(playerId, "license")
            
            if playerIdentifier then
                LoadCommunityService(playerIdentifier, function(data)
                    if data and data.status == 'active' then
                        DebugPrint(string.format("Will restore community service for %s when fully connected", name), "SERVER")
                        
                        -- Set a timer to restore when player is fully loaded
                        Citizen.CreateThread(function()
                            Citizen.Wait(10000) -- Wait 10 seconds for full connection
                            
                            if GetPlayerName(playerId) then
                                communityServicePlayers[playerId] = {
                                    tasksRemaining = data.tasks_remaining,
                                    tasksTotal = data.tasks_total,
                                    startTime = data.metadata and data.metadata.startTime or os.time(),
                                    identifier = playerIdentifier,
                                    assignedBy = data.assigned_by,
                                    reason = data.reason,
                                    experienceGained = data.experience_gained or 0
                                }
                                
                                TriggerClientEvent("community_service:start", playerId, data.tasks_remaining)
                                SendNotification(playerId, string.format("Máš nedokončené VPP. Zbývá: %d úkolů", data.tasks_remaining), 'info')
                            end
                        end)
                    end
                end)
            end
        end
        
        deferrals.done()
    end)
end)

-- Command to check database status and active VPP
RegisterCommand("vppstatus", function(source, args, rawCommand)
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    local memoryCount = 0
    for _ in pairs(communityServicePlayers) do
        memoryCount = memoryCount + 1
    end
    
    if Config.Database and Config.Database.enabled then
        LoadAllActiveCommunityService(function(dbData)
            local dbCount = 0
            for _ in pairs(dbData) do
                dbCount = dbCount + 1
            end
            
            local statusMessage = string.format(
                "VPP Status:\n- V paměti: %d aktivních\n- V databázi: %d aktivních\n- Databáze: %s",
                memoryCount,
                dbCount,
                Config.Database.enabled and "Zapnuta" or "Vypnuta"
            )
            
            SendNotification(source, statusMessage, 'info')
        end)
    else
        local statusMessage = string.format(
            "VPP Status:\n- V paměti: %d aktivních\n- Databáze: Vypnuta",
            memoryCount
        )
        
        SendNotification(source, statusMessage, 'info')
    end
end, false)

-- Command to manually save all active VPP to database
RegisterCommand("vppsave", function(source, args, rawCommand)
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    if not Config.Database or not Config.Database.enabled then
        SendNotification(source, "Databáze je vypnuta", 'error')
        return
    end
    
    local count = 0
    for _ in pairs(communityServicePlayers) do
        count = count + 1
    end
    
    if count > 0 then
        SaveAllActiveCommunityService(communityServicePlayers)
        SendNotification(source, string.format("Uloženo %d aktivních VPP do databáze", count), 'success')
    else
        SendNotification(source, "Žádné aktivní VPP k uložení", 'info')
    end
end, false)

-- Command to manually restore VPP from database
RegisterCommand("vpprestore", function(source, args, rawCommand)
    if not HasPermission(source, Config.Admin.acePermission) then
        SendNotification(source, GetLocaleText('permissionDenied'), 'error')
        return
    end
    
    if not Config.Database or not Config.Database.enabled then
        SendNotification(source, "Databáze je vypnuta", 'error')
        return
    end
    
    RestoreActiveCommunityService()
    SendNotification(source, "Probíhá obnovení VPP z databáze...", 'info')
end, false)
