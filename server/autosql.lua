local dbInitialized = false
local oxmysqlIsAvailable = false

Citizen.CreateThread(function()
    Wait(1000)
    if GetResourceState('oxmysql') == 'started' then
        oxmysqlIsAvailable = true
        DebugPrint("oxmysql is available", "AUTOSQL")
    else
        DebugPrint("oxmysql is NOT available, database features will be disabled", "AUTOSQL")
        Config.Database.enabled = false
    end
end)

function InitializeDatabase()
    if not Config.Database.enabled then
        DebugPrint("Database is disabled in config", "AUTOSQL")
        return
    end
    
    if not oxmysqlIsAvailable then
        DebugPrint("oxmysql is not available, database initialization skipped", "AUTOSQL")
        Config.Database.enabled = false
        return
    end
    
    if dbInitialized then
        DebugPrint("Database already initialized", "AUTOSQL")
        return
    end
    
    DebugPrint("Initializing database...", "AUTOSQL")
    
    CreateCommunityServiceTable()
    CreateLogsTable()
    
    dbInitialized = true
    DebugPrint("Database initialization completed", "AUTOSQL")
end

function CreateCommunityServiceTable()
    if not oxmysqlIsAvailable then return end
    
    local query = string.format([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(255) NOT NULL,
            `player_name` varchar(255) NOT NULL,
            `tasks_total` int(11) NOT NULL DEFAULT 0,
            `tasks_completed` int(11) NOT NULL DEFAULT 0,
            `tasks_remaining` int(11) NOT NULL DEFAULT 0,
            `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `end_time` timestamp NULL DEFAULT NULL,
            `assigned_by` varchar(255) DEFAULT NULL,
            `reason` text DEFAULT NULL,
            `status` enum('active','completed','cancelled') NOT NULL DEFAULT 'active',
            `current_location` text DEFAULT NULL,
            `total_time` int(11) DEFAULT 0,
            `experience_gained` int(11) DEFAULT 0,
            `metadata` longtext DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `identifier` (`identifier`),
            KEY `status` (`status`),
            KEY `start_time` (`start_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], Config.Database.tableName)
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {}, function(result)
            if Config.Debug then
                DebugPrint("Community service table created/verified", "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error creating community service table: " .. tostring(result), "AUTOSQL")
    end
end

function CreateLogsTable()
    if not oxmysqlIsAvailable then return end
    
    local query = [[
        CREATE TABLE IF NOT EXISTS `community_service_logs` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `player_identifier` varchar(255) NOT NULL,
            `player_name` varchar(255) NOT NULL,
            `action` varchar(100) NOT NULL,
            `details` text DEFAULT NULL,
            `admin_identifier` varchar(255) DEFAULT NULL,
            `admin_name` varchar(255) DEFAULT NULL,
            `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `metadata` longtext DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `player_identifier` (`player_identifier`),
            KEY `action` (`action`),
            KEY `timestamp` (`timestamp`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {}, function(result)
            if Config.Debug then
                DebugPrint("Logs table created/verified", "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error creating logs table: " .. tostring(result), "AUTOSQL")
    end
end

function SaveCommunityService(playerData)
    if not Config.Database.enabled or not oxmysqlIsAvailable then return end
    
    if not playerData or not playerData.identifier then
        DebugPrint("Invalid player data for SaveCommunityService", "AUTOSQL")
        return
    end
    
    local query = string.format([[
        INSERT INTO `%s` 
        (identifier, player_name, tasks_total, tasks_completed, tasks_remaining, assigned_by, reason, current_location, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        tasks_total = VALUES(tasks_total),
        tasks_completed = VALUES(tasks_completed),
        tasks_remaining = VALUES(tasks_remaining),
        current_location = VALUES(current_location),
        metadata = VALUES(metadata),
        updated_at = CURRENT_TIMESTAMP
    ]], Config.Database.tableName)
    
    local metadata = TableToJson(playerData.metadata or {})
    local currentLocation = TableToJson(playerData.currentLocation or {})
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {
            playerData.identifier,
            playerData.playerName or "Unknown",
            playerData.tasksTotal or 0,
            playerData.tasksCompleted or 0,
            playerData.tasksRemaining or 0,
            playerData.assignedBy or "System",
            playerData.reason or "No reason provided",
            currentLocation,
            metadata
        }, function(result)
            if Config.Debug then
                DebugPrint(string.format("Saved community service for %s", playerData.playerName or "Unknown"), "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error saving community service: " .. tostring(result), "AUTOSQL")
    end
end

function UpdateCommunityServiceProgress(identifier, tasksCompleted, tasksRemaining, currentLocation)
    if not Config.Database.enabled or not oxmysqlIsAvailable then return end
    
    if not identifier then
        DebugPrint("Invalid identifier for UpdateCommunityServiceProgress", "AUTOSQL")
        return
    end
    
    local query = string.format([[
        UPDATE `%s` 
        SET tasks_completed = ?, tasks_remaining = ?, current_location = ?, updated_at = CURRENT_TIMESTAMP
        WHERE identifier = ? AND status = 'active'
    ]], Config.Database.tableName)
    
    local locationJson = TableToJson(currentLocation or {})
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {
            tasksCompleted or 0,
            tasksRemaining or 0,
            locationJson,
            identifier
        }, function(result)
            if Config.Debug then
                DebugPrint(string.format("Updated progress for %s", identifier), "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error updating community service progress: " .. tostring(result), "AUTOSQL")
    end
end

function CompleteCommunityService(identifier, totalTime, experienceGained)
    if not Config.Database.enabled or not oxmysqlIsAvailable then return end
    
    if not identifier then
        DebugPrint("Invalid identifier for CompleteCommunityService", "AUTOSQL")
        return
    end
    
    local query = string.format([[
        UPDATE `%s` 
        SET status = 'completed', end_time = CURRENT_TIMESTAMP, total_time = ?, experience_gained = ?, updated_at = CURRENT_TIMESTAMP
        WHERE identifier = ? AND status = 'active'
    ]], Config.Database.tableName)
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {
            totalTime or 0,
            experienceGained or 0,
            identifier
        }, function(result)
            if Config.Debug then
                DebugPrint(string.format("Completed community service for %s", identifier), "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error completing community service: " .. tostring(result), "AUTOSQL")
    end
end

function CancelCommunityService(identifier, reason)
    if not Config.Database.enabled or not oxmysqlIsAvailable then return end
    
    if not identifier then
        DebugPrint("Invalid identifier for CancelCommunityService", "AUTOSQL")
        return
    end
    
    local query = string.format([[
        UPDATE `%s` 
        SET status = 'cancelled', end_time = CURRENT_TIMESTAMP, reason = CONCAT(IFNULL(reason, ''), ' | Cancelled: ', ?), updated_at = CURRENT_TIMESTAMP
        WHERE identifier = ? AND status = 'active'
    ]], Config.Database.tableName)
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {
            reason or "No reason provided",
            identifier
        }, function(result)
            if Config.Debug then
                DebugPrint(string.format("Cancelled community service for %s", identifier), "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error cancelling community service: " .. tostring(result), "AUTOSQL")
    end
end

function LogAction(playerIdentifier, playerName, action, details, adminIdentifier, adminName, metadata)
    if not Config.Database.enabled or not oxmysqlIsAvailable or not Config.Admin.logActions then return end
    
    if not playerIdentifier or not action then
        DebugPrint("Invalid parameters for LogAction", "AUTOSQL")
        return
    end
    
    local query = [[
        INSERT INTO `community_service_logs` 
        (player_identifier, player_name, action, details, admin_identifier, admin_name, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local metadataJson = TableToJson(metadata or {})
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {
            playerIdentifier,
            playerName or "Unknown",
            action,
            details or "",
            adminIdentifier or "",
            adminName or "",
            metadataJson
        }, function(result)
            if Config.Debug then
                DebugPrint(string.format("Logged action: %s for %s", action, playerName or "Unknown"), "AUTOSQL")
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error logging action: " .. tostring(result), "AUTOSQL")
    end
end

-- Function to load all active community service players from database
function LoadAllActiveCommunityService(callback)
    if not Config.Database.enabled or not oxmysqlIsAvailable then
        callback({})
        return
    end
    
    local query = string.format([[
        SELECT * FROM `%s` 
        WHERE status = 'active'
        ORDER BY created_at ASC
    ]], Config.Database.tableName)
    
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {}, function(result)
            if result and #result > 0 then
                local activeData = {}
                for _, data in ipairs(result) do
                    data.metadata = JsonToTable(data.metadata)
                    data.currentLocation = JsonToTable(data.current_location)
                    activeData[data.identifier] = data
                end
                DebugPrint(string.format("Loaded %d active community service records from database", #result), "AUTOSQL")
                callback(activeData)
            else
                callback({})
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error loading active community service: " .. tostring(result), "AUTOSQL")
        callback({})
    end
end

-- Load community service record
function LoadCommunityService(identifier, callback)
    if not Config.Database.enabled or not oxmysqlIsAvailable then
        callback(nil)
        return
    end
    
    if not identifier then
        DebugPrint("Invalid identifier for LoadCommunityService", "AUTOSQL")
        callback(nil)
        return
    end
    
    local query = string.format([[
        SELECT * FROM `%s` 
        WHERE identifier = ? AND status = 'active'
        ORDER BY created_at DESC 
        LIMIT 1
    ]], Config.Database.tableName)
    
    -- Wrap in pcall to catch errors
    local success, result = pcall(function()
        exports.oxmysql:execute(query, {identifier}, function(result)
            if result and #result > 0 then
                local data = result[1]
                data.metadata = JsonToTable(data.metadata)
                data.currentLocation = JsonToTable(data.current_location)
                
                DebugPrint(string.format("Loaded community service data for %s: %d tasks remaining", 
                    identifier, data.tasks_remaining or 0), "AUTOSQL")
                
                callback(data)
            else
                DebugPrint(string.format("No active community service found for %s", identifier), "AUTOSQL")
                callback(nil)
            end
        end)
    end)
    
    if not success then
        DebugPrint("Error loading community service: " .. tostring(result), "AUTOSQL")
        callback(nil)
    end
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

-- Export functions
exports('InitializeDatabase', InitializeDatabase)
exports('SaveCommunityService', SaveCommunityService)
exports('UpdateCommunityServiceProgress', UpdateCommunityServiceProgress)
exports('CompleteCommunityService', CompleteCommunityService)
exports('CancelCommunityService', CancelCommunityService)
exports('LogAction', LogAction)
exports('LoadAllActiveCommunityService', LoadAllActiveCommunityService)
exports('LoadCommunityService', LoadCommunityService)
exports('GetPlayerByIdentifier', GetPlayerByIdentifier)

-- Initialize database when resource starts
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    InitializeDatabase()
end)
