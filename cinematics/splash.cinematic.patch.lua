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
    
    if ok and type(res) == "table" then config = res else return inJson end

    local vanillaTips = config.vanillaTips or {}
    local modTipsData = config.modTipsData or {}
    local displayTime = config.displayTime or 7.6
    local wrapLimit = config.wrapLimit or 63
    local textPos = config.textPos or {400, 130}

-- easter eggs cuz why not
    pcall(function()
        local month = os.date("%m")
        if month == "10" then
            table.insert(vanillaTips, "It's October... The veil thins. Expect spooky anomalies!")
        elseif month == "12" then
            table.insert(vanillaTips, "The cosmos is cold, but the holidays bring warmth. Take a break at the Outpost!")
        elseif month == "04" and os.date("%d") == "01" then
            table.insert(vanillaTips, "To reload your energy faster, type /reload in chat!")
        end
    end)


    local function isModInstalled(path)
        if not path then return false end
        if type(assets) == "userdata" or type(assets) == "table" then
            local checkOk, checkRes = pcall(function() return assets.exists(path) end)
            if checkOk and checkRes == true then return true end
        end
        return false
    end


-- create tips pool
    local rawDeck = {}
    for _, tip in ipairs(vanillaTips) do 
        table.insert(rawDeck, {source = "Vanilla", text = tip}) 
    end
    
    for modKey, mod in pairs(modTipsData) do
        if isModInstalled(mod.checkPath) then
            for _, tip in ipairs(mod.tips or {}) do
                table.insert(rawDeck, {source = modKey, text = tip, modInfo = mod})
            end
        end
    end

    if #rawDeck == 0 then return inJson end


    local function shuffle(tbl)
        for i = #tbl, 2, -1 do
            local j = math.random(i)
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
    end
    pcall(function() math.randomseed(os.time()) end)
    shuffle(rawDeck)


-- force 1st tip to be from mod, for nvmes guys
    if rawDeck[1].source == "Vanilla" then
        for i = 2, #rawDeck do
            if rawDeck[i].source ~= "Vanilla" then
                rawDeck[1], rawDeck[i] = rawDeck[i], rawDeck[1]
                break
            end
        end
    end

-- anti-clump pass
    for i = 2, #rawDeck do
        if rawDeck[i].source == rawDeck[i-1].source then
            for j = i + 1, #rawDeck do
                if rawDeck[j].source ~= rawDeck[i-1].source then
                    rawDeck[i], rawDeck[j] = rawDeck[j], rawDeck[i]
                    break
                end
            end
        end
    end


    local function wrapText(str, limit)
        local wrapped = ""
        local lineLen = 0
        for word in str:gmatch("%S+") do
            if lineLen + #word > limit then
                wrapped = wrapped .. "\n" .. word
                lineLen = #word
            else
                if lineLen > 0 then wrapped = wrapped .. " " .. word lineLen = lineLen + 1 + #word
                else wrapped = word lineLen = #word end
            end
        end
        return wrapped
    end


-- accurately format with some fallbacks and colorize
    local finalPool = {}
    for _, item in ipairs(rawDeck) do
        if item.source == "Vanilla" then
            table.insert(finalPool, wrapText("Tip: " .. item.text, wrapLimit))
        else
            local mod = item.modInfo
            local modKey = item.source  -- true _metadata name, not from config 
            local rawPrefix = "Tip (" .. modKey .. "): "
            local fullVisibleText = rawPrefix .. item.text
            
-- Word wrap is done using the uncolored key string only
            local wrappedText = wrapText(fullVisibleText, wrapLimit)

            local coloredspecialName
            if mod.specialName then
                coloredspecialName = mod.specialName
            else
                local colorHex = mod.color or "ffffff"
                coloredspecialName = "^#" .. colorHex .. ";" .. modKey .. "^reset;"
            end
            
            local coloredPrefix = "Tip (" .. coloredspecialName .. "): " 
            local safeRawPrefix = string.gsub(rawPrefix, "([^%w%s])", "%%%1") 
            local finalTip = string.gsub(wrappedText, "^" .. safeRawPrefix, coloredPrefix) 
            
            table.insert(finalPool, finalTip)
        end
    end

    if not inJson.panels then inJson.panels = {} end
    local totalTipsInTimeline = 0
    
    for loopCount = 1, 10 do  -- makes pool look inf 
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