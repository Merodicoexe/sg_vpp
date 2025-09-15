local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
local versionURL = "https://raw.githubusercontent.com/Merodicoexe/version-checker/refs/heads/main/sg_vpp.txt" -- tady dej URL, kde máš uložený číslo verze

CreateThread(function()
    Wait(2000) -- malá prodleva po startu

    PerformHttpRequest(versionURL, function(errorCode, result, headers)
        if errorCode == 200 and result then
            local latestVersion = result:gsub("%s+", "") -- odstraní bílé znaky
            
            if latestVersion ~= currentVersion then
                print("^6[" .. resourceName .. "] ^1Je dostupná nová verze!^0")
                print("^6[" .. resourceName .. "] ^2Aktuální verze:^0 " .. currentVersion)
                print("^6[" .. resourceName .. "] ^3Nejnovější verze:^0 " .. latestVersion)
                print("^6[" .. resourceName .. "] ^5Stáhni update z:^0 " .. versionURL)
            else
                print("^6[" .. resourceName .. "] ^2Používáš nejnovější verzi (" .. currentVersion .. ")^0")
            end
        else
            print("^6[" .. resourceName .. "] ^1Nepodařilo se ověřit verzi (chyba HTTP)^0")
        end
    end, "GET")
end)
