local tipPool = nil
local categoryPools = nil
local aliasesMap = nil


function init()  -- hook into chat
    message.setHandler("/tip", function(_, _, args)
        if not tipPool then
            buildTipPool()
        end
        
        if #tipPool == 0 then
            return "No tips available."
        end
        
        args = (args and type(args) == "string") and args:match("^%s*(.-)%s*$") or ""
        
        if args == "" then  -- default behavior
            return tipPool[math.random(#tipPool)]
        end
        
        local lowerArgs = string.lower(args)
        
-- information
        if lowerArgs == "help" then
            local available = {"vanilla"}
            for modKey, pool in pairs(categoryPools) do
                if modKey ~= "vanilla" and #pool > 0 then
                    table.insert(available, modKey)
                end
            end
            table.sort(available)
            return "Available categories: ^green;" .. table.concat(available, "^reset;, ^green;") .. "^reset;\nType ^cyan;/tip <category>^reset; for a random tip from that category, ^cyan;/tip^reset; for any."
        end
        
-- lookup in aliases hashmap
        local targetCategory = aliasesMap[lowerArgs]
        
        if targetCategory and categoryPools[targetCategory] and #categoryPools[targetCategory] > 0 then
            local pool = categoryPools[targetCategory]
            return pool[math.random(#pool)]
        else
            return "Unknown category: ^orange;" .. args .. "^reset;! Type ^cyan;/tip help^reset; for a list."
        end
    end)
end


local function isModInstalled(checkPath)
    if not checkPath then return false end

    if root.assetsScan then
        local ok, list = pcall(root.assetsScan, checkPath)
        if ok and type(list) == "table" and #list > 0 then
            for _, path in ipairs(list) do
                if path == checkPath then return true end
            end
        end
        return false
    end

    local isJson = checkPath:match("%.%w+$") and not (    -- direct pass prevents cpp exception wrapper bullshitto
        checkPath:match("%.png$") or checkPath:match("%.ogg$") or checkPath:match("%.wav$")
    )

    if isJson then
        local ok, res = pcall(root.assetJson, checkPath)
        if ok and type(res) == "table" and next(res) ~= nil and not res.exception and not res.error then
            return true  -- ensures the return isnt an engine error container masqueradin as a valid table
        end
    else
        local ok, res = pcall(root.imageSize, checkPath)
        if ok and type(res) == "table" and res[1] and res[1] > 0 then
            return true
        end
    end

    return false
end


function buildTipPool()
    tipPool = {}
    categoryPools = { vanilla = {} }
    aliasesMap = {}
    
    local configOk, config = pcall(root.assetJson, "/splash_tips.config")
    if not configOk or type(config) ~= "table" then return end
    
    local vanillaAliases = config.vanillaAliases or {"vanilla", "base"}
    for _, alias in ipairs(vanillaAliases) do
        aliasesMap[string.lower(alias)] = "vanilla"
    end
    
    for _, tip in ipairs(config.vanillaTips or {}) do
        local formattedTip = "Tip: " .. tip
        table.insert(tipPool, formattedTip)
        table.insert(categoryPools.vanilla, formattedTip)
    end
    
    local modTipsData = config.modTipsData or {}
    
    for modKey, mod in pairs(modTipsData) do
        if isModInstalled(mod.checkPath) then
            categoryPools[modKey] = {}
            
            aliasesMap[string.lower(modKey)] = modKey  -- auto-alias 1
            
            if mod.aliases and type(mod.aliases) == "table" then  -- auto-alias 2
                for _, alias in ipairs(mod.aliases) do
                    aliasesMap[string.lower(alias)] = modKey
                end
            end
            
-- formatting
            local coloredspecialName
            if mod.specialName then  -- unified coloring logic
                coloredspecialName = mod.specialName
            else
                local colorHex = mod.color or "ffffff"
                coloredspecialName = "^#" .. colorHex .. ";" .. modKey .. "^reset;"
            end
            
            local prefix = "Tip (" .. coloredspecialName .. "): "
            
            for _, tip in ipairs(mod.tips or {}) do
                local finalTip = prefix .. tip
                table.insert(tipPool, finalTip)
                table.insert(categoryPools[modKey], finalTip)
            end
        end
    end
end
