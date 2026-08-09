local tipPool = nil
local categoryPools = nil
local aliasesMap = nil
local modAliases = nil

-- only allow default named colors, hex colors, and ^reset to avoid glitches
local function scrubOsbTags(text)
	return text:gsub("%^([^;]+);", function(tag)
		local lTag = string.lower(tag)
		if lTag:sub(1, 1) == "#" then
			return "^" .. tag .. ";"
		end

		local validTags = {
			reset = true,
			black = true,
			white = true,
			red = true,
			green = true,
			blue = true,
			yellow = true,
			cyan = true,
			magenta = true,
			orange = true,
			pink = true,
			gray = true,
			grey = true,
		}
		if validTags[lTag] then
			return "^" .. tag .. ";"
		end

		return ""
	end)
end

function init() -- hook into chat
	message.setHandler("/tip", function(_, _, args)
		if not tipPool then
			buildTipPool()
		end

		if #tipPool == 0 then
			return "No tips available."
		end

		args = (args and type(args) == "string") and args:match("^%s*(.-)%s*$") or ""

		if args == "" then -- default behavior
			return tipPool[math.random(#tipPool)]
		end

		local lowerArgs = string.lower(args)

		-- information
		if lowerArgs == "help" then
			local available = { "vanilla" }
			for modKey, pool in pairs(categoryPools) do
				if modKey ~= "vanilla" and #pool > 0 then
					table.insert(available, modKey)
				end
			end
			table.sort(available)
			return "Available categories: ^green;"
				.. table.concat(available, "^reset;, ^green;")
				.. "^reset;\nType ^cyan;/tip <category>^reset; for a random tip, ^cyan;/tip^reset; for any.\nType ^cyan;/tip aliases^reset; to see category aliases."
		end

		-- more information lmfao
		if lowerArgs == "aliases" then
			local lines = {}
			local sortedKeys = {}

			for modKey in pairs(modAliases) do
				if modKey ~= "vanilla" then
					table.insert(sortedKeys, modKey)
				end
			end
			table.sort(sortedKeys)

			-- force base game to be at the top
			if modAliases["vanilla"] then
				table.insert(lines, "^green;Vanilla^reset;: " .. table.concat(modAliases["vanilla"], ", "))
			end

			-- add the rest alphabetically
			for _, modKey in ipairs(sortedKeys) do
				table.insert(lines, "^green;" .. modKey .. "^reset;: " .. table.concat(modAliases[modKey], ", "))
			end

			return table.concat(lines, ";\n") .. "."
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
	if not checkPath then
		return false
	end

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

	-- direct pass prevents cpp exception wrapper bullshitto
	local isJson = checkPath:match("%.%w+$")
		and not (checkPath:match("%.png$") or checkPath:match("%.ogg$") or checkPath:match("%.wav$"))

	if isJson then
		local ok, res = pcall(root.assetJson, checkPath)
		if ok and type(res) == "table" and next(res) ~= nil and not res.exception and not res.error then
			return true -- ensures the return isnt an engine error container masqueradin as a valid table
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
	modAliases = {}

	local configOk, config = pcall(root.assetJson, "/splash_tips.config")
	if not configOk or type(config) ~= "table" then
		return
	end

	local vanillaAliases = config.vanillaAliases or { "vanilla", "base" }
	modAliases["vanilla"] = {}
	for _, alias in ipairs(vanillaAliases) do
		local lAlias = string.lower(alias)
		aliasesMap[lAlias] = "vanilla"
		table.insert(modAliases["vanilla"], lAlias)
	end

	for _, tip in ipairs(config.vanillaTips or {}) do
		local formattedTip = scrubOsbTags("Tip: " .. tip)
		table.insert(tipPool, formattedTip)
		table.insert(categoryPools.vanilla, formattedTip)
	end

	local modTipsData = config.modTipsData or {}

	for modKey, mod in pairs(modTipsData) do
		if isModInstalled(mod.checkPath) then
			categoryPools[modKey] = {}
			local currentAliases = {}

			-- free auto-alias for consistency
			aliasesMap[string.lower(modKey)] = modKey
			table.insert(currentAliases, string.lower(modKey))
			modAliases[modKey] = currentAliases

			-- formatting
			local coloredspecialName
			if mod.specialName then -- unified coloring logic
				coloredspecialName = mod.specialName
			else
				local colorHex = mod.color or "ffffff"
				coloredspecialName = "^#" .. colorHex .. ";" .. modKey .. "^reset;"
			end

			local prefix = "Tip (" .. coloredspecialName .. "): "

			for _, tip in ipairs(mod.tips or {}) do
				local finalTip = scrubOsbTags(prefix .. tip)
				table.insert(tipPool, finalTip)
				table.insert(categoryPools[modKey], finalTip)
			end
		end
	end
end
