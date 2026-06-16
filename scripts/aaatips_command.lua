local tipPool = nil


function init()  -- hook into chat
    message.setHandler("/tip", function(_, _)
        if not tipPool then
            buildTipPool()
        end
        
        if #tipPool == 0 then
            return "No tips available."
        end
        
        return tipPool[math.random(#tipPool)]
    end)
end


local function isModInstalled(checkPath)
    if not checkPath then return false end

    if root.assetsScan then
        local ok, list = pcall(root.assetsScan, checkPath)
        if ok and type(list) == "table" and #list > 0 then
            for _, path in ipairs(list) do
                if path == checkPath then
                    return true
                end
            end
        end
        return false
    end

    local isJson = checkPath:match("%.%w+$") and not (  -- direct pass prevents cpp exception wrapper bullshitto
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
    
    local configOk, config = pcall(root.assetJson, "/splash_tips.config")
    if not configOk or type(config) ~= "table" then return end
    
    for _, tip in ipairs(config.vanillaTips or {}) do
        table.insert(tipPool, "Tip: " .. tip)
    end
    
    local modTipsData = config.modTipsData or {}
    
    for modKey, mod in pairs(modTipsData) do
        if isModInstalled(mod.checkPath) then
            local coloredspecialName  
            if mod.specialName then  -- unified coloring logic
                coloredspecialName = mod.specialName
            else
                local colorHex = mod.color or "ffffff"
                coloredspecialName = "^#" .. colorHex .. ";" .. modKey .. "^reset;"
            end
            
            local prefix = "Tip (" .. coloredspecialName .. "): "
            for _, tip in ipairs(mod.tips or {}) do
                table.insert(tipPool, prefix .. tip)
            end
        end
    end
end
