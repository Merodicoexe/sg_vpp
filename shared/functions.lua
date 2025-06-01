-- Shared utility functions

-- Function to get random location
function GetRandomLocation()
    local availableLocations = {}
    
    for i, location in ipairs(Config.Locations) do
        table.insert(availableLocations, location)
    end
    
    if #availableLocations > 0 then
        local randomIndex = math.random(1, #availableLocations)
        return availableLocations[randomIndex]
    end
    
    return nil
end

-- Function to get task type configuration
function GetTaskTypeConfig(taskType)
    if not taskType or not Config.Tasks.types[taskType] then
        return Config.Tasks.types["cleanup"]
    end
    return Config.Tasks.types[taskType]
end

-- Function to validate task count
function ValidateTaskCount(count)
    if not count or count < Config.Tasks.minCount then
        return Config.Tasks.minCount
    elseif count > Config.Tasks.maxCount then
        return Config.Tasks.maxCount
    end
    return count
end

-- Function to format time
function FormatTime(seconds)
    if not seconds or type(seconds) ~= "number" then
        return "0s"
    end
    
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- Function to get distance between two points
function GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return 999999.9 end
    
    if not pos1.x or not pos1.y or not pos1.z or not pos2.x or not pos2.y or not pos2.z then
        return 999999.9
    end
    
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

-- Function to check if player is in restricted area
function IsInRestrictedArea(coords)
    if not Config.Restrictions or not Config.Restrictions.restrictedArea or not Config.Restrictions.restrictedArea.enabled then
        return true
    end
    
    if not coords or not Config.Restrictions.restrictedArea.center then
        return true
    end
    
    local distance = GetDistance(coords, Config.Restrictions.restrictedArea.center)
    return distance <= Config.Restrictions.restrictedArea.radius
end

-- Function to log debug messages
function DebugPrint(message, category)
    if Config.Debug and Config.Debug.enabled then
        print(string.format("[COMMUNITY_SERVICE][%s] %s", category or "DEBUG", message))
    end
end

-- Function to generate unique identifier
function GenerateUniqueId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 8 do
        local rand = math.random(#chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id .. "_" .. os.time()
end

-- Function to validate coordinates
function ValidateCoords(coords)
    return coords and coords.x and coords.y and coords.z
end

-- Function to round number
function Round(num, decimals)
    if not num then return 0 end
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Function to get player identifier (server-side only)
if IsDuplicityVersion() then
    function GetPlayerIdentifier(source, idType)
        idType = idType or "license"
        
        if not source then
            return nil
        end
        
        local identifiers = GetPlayerIdentifiers(source)
        
        if not identifiers then
            return nil
        end
        
        for _, identifier in pairs(identifiers) do
            if string.find(identifier, idType) then
                return identifier
            end
        end
        
        return nil
    end
    
    -- Function to get all player identifiers
    function GetAllPlayerIdentifiers(source)
        local identifiers = {}
        
        if not source then
            return identifiers
        end
        
        local playerIdentifiers = GetPlayerIdentifiers(source)
        
        if not playerIdentifiers then
            return identifiers
        end
        
        for _, identifier in pairs(playerIdentifiers) do
            local idType = string.match(identifier, "([^:]+):")
            if idType then
                identifiers[idType] = identifier
            end
        end
        
        return identifiers
    end

    -- Function to validate task count (server-side only)
    function ValidateTaskCount(count)
        if not count or count < Config.Tasks.minCount then
            return Config.Tasks.minCount
        elseif count > Config.Tasks.maxCount then
            return Config.Tasks.maxCount
        end
        return count
    end
end

-- Function to create notification data
function CreateNotification(message, type, duration)
    return {
        message = message or "",
        type = type or "info",
        duration = duration or 5000,
        timestamp = os.time()
    }
end

-- Function to sanitize string for SQL
function SanitizeString(str)
    if not str then return "" end
    return string.gsub(str, "'", "''")
end

-- Function to convert table to JSON string (enhanced)
function TableToJson(tbl)
    if type(tbl) ~= "table" then
        if type(tbl) == "string" then
            return '"' .. tbl .. '"'
        else
            return tostring(tbl or "")
        end
    end
    
    local result = "{"
    local first = true
    
    for k, v in pairs(tbl) do
        if not first then
            result = result .. ","
        end
        first = false
        
        if type(k) == "string" then
            result = result .. '"' .. k .. '":'
        else
            result = result .. tostring(k) .. ":"
        end
        
        if type(v) == "table" then
            result = result .. TableToJson(v)
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        elseif type(v) == "boolean" then
            result = result .. (v and "true" or "false")
        else
            result = result .. tostring(v)
        end
    end
    
    result = result .. "}"
    return result
end

-- Function to convert JSON string to table (enhanced)
function JsonToTable(jsonStr)
    if not jsonStr or jsonStr == "" then return {} end
    
    -- Try to use built-in json decoder first
    local success, result = pcall(function()
        return json.decode(jsonStr)
    end)
    
    if success and type(result) == "table" then
        return result
    else
        DebugPrint("Failed to decode JSON: " .. tostring(jsonStr), "JSON")
        return {}
    end
end
