function patch(inJson, assetPath)
    local config = {}
    local configPath = "/splash_tips.config"
    
	
    local ok, res = pcall(function()
        if type(assets) == "userdata" or type(assets) == "table" then
            if type(assets.json) == "function" then
                return assets.json(configPath)
            end
        end
        return nil
    end)
    
    if ok and type(res) == "table" then
        config = res
    else
        return inJson
    end

    local vanillaTips = config.vanillaTips or {}
    local modTipsData = config.modTipsData or {}
    local displayTime = config.displayTime or 7.6
    local wrapLimit = config.wrapLimit or 63
    local textPos = config.textPos or {400, 130}
    local finalPool = {}
    
	
    local function wrapText(str, limit)
        local wrapped = ""
        local lineLen = 0
        for word in str:gmatch("%S+") do
            if lineLen + #word > limit then
                wrapped = wrapped .. "\n" .. word
                lineLen = #word
            else
                if lineLen > 0 then
                    wrapped = wrapped .. " " .. word
                    lineLen = lineLen + 1 + #word
                else
                    wrapped = word
                    lineLen = #word
                end
            end
        end
        return wrapped
    end


    local function isModInstalled(path)
        if type(assets) == "userdata" or type(assets) == "table" then
            local checkOk, checkRes = pcall(function() return assets.exists(path) end)
            if checkOk and checkRes == true then return true end
        end
        return false
    end


    for _, tip in ipairs(vanillaTips) do
        table.insert(finalPool, wrapText("Tip (Vanilla): " .. tip, wrapLimit))
    end
    
    for _, mod in ipairs(modTipsData) do
        if isModInstalled(mod.checkPath) then
            for _, tip in ipairs(mod.tips) do
                table.insert(finalPool, wrapText("Tip (" .. mod.modName .. "): " .. tip, wrapLimit))
            end
        end
    end

-- just in case
    if #finalPool == 0 then return inJson end


    pcall(function() math.randomseed(os.time()) end)
    for i = #finalPool, 2, -1 do
        local j = math.random(i)
        finalPool[i], finalPool[j] = finalPool[j], finalPool[i]
    end

    if not inJson.panels then inJson.panels = {} end
    
	
    local totalTipsInTimeline = 0
    for loopCount = 1, 10 do
        for _, formattedTip in ipairs(finalPool) do
            
            local startTimeOffset = totalTipsInTimeline * displayTime
            
            table.insert(inJson.panels, {
                text = formattedTip,
                fontSize = 14,
                startTime = startTimeOffset,
                keyframes = {
                    {timecode = 0,                   position = textPos, alpha = 0},
                    {timecode = 0.5,                 alpha = 1},  -- f in
                    {timecode = displayTime - 0.5,   alpha = 1},  -- halt
                    {timecode = displayTime,         alpha = 0}   -- f out
                }
            })
            
            totalTipsInTimeline = totalTipsInTimeline + 1
        end
    end
    
    return inJson
end
