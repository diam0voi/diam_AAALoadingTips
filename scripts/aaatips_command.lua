local tipPool = nil
local activeCategories = nil
local categoryPools = nil
local aliasesMap = nil
local modAliases = nil
local tipBags = nil
local lastDrawn = nil
local balanceCategories = true
local rng = nil

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

local reservedCommands = {
	help = true,
	["?"] = true,
	aliases = true,
	reload = true,
}

local nonJsonExts = {
	png = true,
	jpg = true,
	jpeg = true,
	webm = true,
	mp3 = true,
	ogg = true,
	wav = true,
	lua = true,
	config = true,
	patch = true,
	txt = true,
	md = true,
}

local function trim(str)
	return (str:match("^%s*(.-)%s*$"))
end

local function randInt(minVal, maxVal)
	if not rng and sb and sb.makeRandomSource then
		rng = sb.makeRandomSource()
	end
	if rng then
		return minVal + (rng:randu32() % (maxVal - minVal + 1))
	end
	return math.random(minVal, maxVal)
end

local function drawFromBag(bagKey, pool)
	if not pool or #pool == 0 then
		return nil
	end
	if #pool == 1 then
		return pool[1]
	end

	local bag = tipBags[bagKey]
	if not bag or #bag == 0 then
		bag = {}
		for i = 1, #pool do
			bag[i] = pool[i]
		end
		for i = #bag, 2, -1 do
			local j = randInt(1, i)
			bag[i], bag[j] = bag[j], bag[i]
		end
		-- prevent previous tip reshuffle repeating
		if lastDrawn[bagKey] and bag[#bag] == lastDrawn[bagKey] then
			bag[1], bag[#bag] = bag[#bag], bag[1]
		end
		tipBags[bagKey] = bag
	end

	local picked = table.remove(bag)
	lastDrawn[bagKey] = picked
	return picked
end

-- only named colors, 3/4/6/8-char hex colors, ^reset w/o eatin across ';'
local function scrubOsbTags(text)
	return (
		text:gsub("%^([^;%s]+);", function(tag)
			local lTag = string.lower(tag)
			if lTag:match("^#%x+$") then
				local len = #lTag - 1
				if len == 3 or len == 4 or len == 6 or len == 8 then
					return "^" .. tag .. ";"
				end
			end
			if validTags[lTag] then
				return "^" .. tag .. ";"
			end
			return ""
		end)
	)
end

local function stripOsbTags(text)
	if sb and sb.stripEscapeCodes then
		return sb.stripEscapeCodes(text)
	end
	return (text:gsub("%^[^;%s]+;", ""))
end

local function isModInstalled(checkPath, pathCache)
	if type(checkPath) ~= "string" then
		return false
	end
	checkPath = trim(checkPath)
	if checkPath == "" then
		return false
	end
	if checkPath == "*" then
		return true
	end
	if checkPath:sub(1, 1) ~= "/" then
		checkPath = "/" .. checkPath
	end

	if pathCache and pathCache[checkPath] ~= nil then
		return pathCache[checkPath]
	end

	local found = false

	if root.assetsScan then
		local ok, list = pcall(root.assetsScan, checkPath)
		if ok and type(list) == "table" then
			local lCheck = string.lower(checkPath)
			for _, path in ipairs(list) do
				if string.lower(path) == lCheck then
					found = true
					break
				end
			end
		end
	else
		-- vanilla fallback w/o assetsScan
		local ext = checkPath:match("%.([^./]+)$")
		ext = ext and string.lower(ext) or ""

		if ext == "png" then
			local ok, res = pcall(root.imageSize, checkPath)
			found = ok and type(res) == "table" and type(res[1]) == "number" and res[1] > 0
		elseif ext ~= "" and not nonJsonExts[ext] then
			local ok, res = pcall(root.assetJson, checkPath)
			-- if it isnt an engine error container...
			found = ok and type(res) == "table" and next(res) ~= nil and not res.exception and not res.error
		end
	end

	if pathCache then
		pathCache[checkPath] = found
	end
	return found
end

local function collectPaths(field, out)
	if type(field) == "string" then
		table.insert(out, field)
	elseif type(field) == "table" then
		for _, p in ipairs(field) do
			table.insert(out, p)
		end
	end
end

local function areModChecksMet(mod, pathCache)
	if mod.alwaysActive == true then
		return true
	end

	local requiredPaths = {}
	collectPaths(mod.checkPath, requiredPaths)
	collectPaths(mod.checkPaths, requiredPaths)

	local anyPaths = {}
	collectPaths(mod.checkAnyPath, anyPaths)

	if #requiredPaths == 0 and #anyPaths == 0 then
		return false
	end

	for _, p in ipairs(requiredPaths) do
		if not isModInstalled(p, pathCache) then
			return false
		end
	end

	if #anyPaths > 0 then
		local anyFound = false
		for _, p in ipairs(anyPaths) do
			if isModInstalled(p, pathCache) then
				anyFound = true
				break
			end
		end
		if not anyFound then
			return false
		end
	end

	return true
end

local function registerAlias(rawAlias, targetKey, targetList, seenLocal)
	if type(rawAlias) ~= "string" then
		return
	end
	local lAlias = string.lower(trim(rawAlias))
	if lAlias == "" or reservedCommands[lAlias] or seenLocal[lAlias] then
		return
	end
	if aliasesMap[lAlias] then
		if aliasesMap[lAlias] ~= targetKey and sb and sb.logWarn then
			sb.logWarn(
				"[Tips] Alias '%s' for '%s' ignored (already claimed by '%s')",
				lAlias,
				targetKey,
				aliasesMap[lAlias]
			)
		end
		return
	end

	seenLocal[lAlias] = true
	aliasesMap[lAlias] = targetKey
	table.insert(targetList, lAlias)
end

local function buildTipPool()
	tipPool = {}
	activeCategories = {}
	categoryPools = {}
	aliasesMap = {}
	modAliases = {}
	tipBags = {}
	lastDrawn = {}

	local configOk, config = pcall(root.assetJson, "/splash_tips.config")
	if not configOk or type(config) ~= "table" then
		if sb and sb.logWarn then
			sb.logWarn("[Tips] Failed to load /splash_tips.config")
		end
		return
	end

	balanceCategories = (config.balanceCategories ~= false)

	-- vanilla pool
	local vanillaPool = {}
	local seenVanilla = {}
	if type(config.vanillaTips) == "table" then
		for _, tip in ipairs(config.vanillaTips) do
			if type(tip) == "string" then
				local cleaned = trim(tip)
				if cleaned ~= "" then
					local normKey = string.lower(trim(stripOsbTags(cleaned)))
					if normKey ~= "" and not seenVanilla[normKey] then
						seenVanilla[normKey] = true
						local formattedTip = scrubOsbTags("Tip: " .. cleaned)
						table.insert(tipPool, formattedTip)
						table.insert(vanillaPool, formattedTip)
					end
				end
			end
		end
	end

	if #vanillaPool > 0 then
		categoryPools["vanilla"] = vanillaPool
		table.insert(activeCategories, "vanilla")

		local vAliases = {}
		local seenVAliases = {}
		local rawVanillaAliases = (type(config.vanillaAliases) == "table") and config.vanillaAliases
			or { "vanilla", "base" }
		for _, alias in ipairs(rawVanillaAliases) do
			registerAlias(alias, "vanilla", vAliases, seenVAliases)
		end
		registerAlias("vanilla", "vanilla", vAliases, seenVAliases)
		modAliases["vanilla"] = vAliases
	end

	-- sort mod keys so alias priority is determined
	local modTipsData = (type(config.modTipsData) == "table") and config.modTipsData or {}
	local sortedModKeys = {}
	for modKey in pairs(modTipsData) do
		if type(modKey) == "string" then
			if string.lower(modKey) == "vanilla" then
				if sb and sb.logWarn then
					sb.logWarn("[Tips] Ignoring modTipsData key '%s' (reserved for base game)", modKey)
				end
			else
				table.insert(sortedModKeys, modKey)
			end
		end
	end
	table.sort(sortedModKeys)

	local pathCache = {}
	for _, modKey in ipairs(sortedModKeys) do
		local mod = modTipsData[modKey]
		if type(mod) == "table" and areModChecksMet(mod, pathCache) then
			local coloredName
			if type(mod.specialName) == "string" and trim(mod.specialName) ~= "" then
				coloredName = mod.specialName .. "^reset;"
			else
				local colorHex = type(mod.color) == "string" and trim(mod.color):gsub("^#", "") or "ffffff"
				local hexLen = #colorHex
				if not colorHex:match("^%x+$") or (hexLen ~= 3 and hexLen ~= 4 and hexLen ~= 6 and hexLen ~= 8) then
					colorHex = "ffffff"
				end
				coloredName = "^#" .. colorHex .. ";" .. modKey .. "^reset;"
			end

			local prefix = "Tip (" .. coloredName .. "): "
			local modPool = {}
			local seenMod = {}

			if type(mod.tips) == "table" then
				for _, tip in ipairs(mod.tips) do
					if type(tip) == "string" then
						local cleaned = trim(tip)
						if cleaned ~= "" then
							local normKey = string.lower(trim(stripOsbTags(cleaned)))
							if normKey ~= "" and not seenMod[normKey] then
								seenMod[normKey] = true
								table.insert(modPool, scrubOsbTags(prefix .. cleaned))
							end
						end
					end
				end
			end

			-- do not register crap
			if #modPool > 0 then
				for _, finalTip in ipairs(modPool) do
					table.insert(tipPool, finalTip)
				end
				categoryPools[modKey] = modPool
				table.insert(activeCategories, modKey)

				local currentAliases = {}
				local seenAliases = {}
				registerAlias(modKey, modKey, currentAliases, seenAliases)
				if type(mod.aliases) == "table" then
					for _, alias in ipairs(mod.aliases) do
						registerAlias(alias, modKey, currentAliases, seenAliases)
					end
				end

				if #currentAliases > 0 then
					modAliases[modKey] = currentAliases
				end
			end
		end
	end

	if sb and sb.logInfo then
		sb.logInfo("[Tips] Loaded %s tips across %s categories", #tipPool, #activeCategories)
	end
end

function init() -- hook into chat
	message.setHandler("/tip", function(_, _, ...)
		if not tipPool then
			buildTipPool()
		end

		local argParts = {}
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if type(v) == "string" then
				local t = trim(v)
				if t ~= "" then
					table.insert(argParts, t)
				end
			end
		end
		local args = table.concat(argParts, " ")
		local lowerArgs = string.lower(args)

		if lowerArgs == "reload" then
			buildTipPool()
			if #tipPool == 0 then
				return "Reloaded pool, but no tips were found!"
			end
			return string.format(
				"Reloaded ^green;%d^reset; tips across ^green;%d^reset; categories.",
				#tipPool,
				#activeCategories
			)
		end

		if #tipPool == 0 then
			return "No tips were found!"
		end

		if args == "" then
			if balanceCategories then
				local cat = drawFromBag("__categories__", activeCategories)
				return drawFromBag(cat, categoryPools[cat])
			end
			return drawFromBag("__all__", tipPool)
		end

		if lowerArgs == "help" or lowerArgs == "?" then
			local available = {}
			for _, cat in ipairs(activeCategories) do
				table.insert(available, cat)
			end
			table.sort(available, function(a, b)
				if a == "vanilla" then
					return true
				end
				if b == "vanilla" then
					return false
				end
				return string.lower(a) < string.lower(b)
			end)
			return "Available categories: ^green;"
				.. table.concat(available, "^reset;, ^green;")
				.. "^reset;\nType ^cyan;/tip <category>^reset; for a random tip, ^cyan;/tip^reset; for any,\n ^cyan;/tip aliases^reset; for aliases list or ^cyan;/tip reload^reset; for debuggie :3"
		end

		if lowerArgs == "aliases" then
			local lines = {}
			local sortedKeys = {}

			for modKey in pairs(modAliases) do
				if modKey ~= "vanilla" then
					table.insert(sortedKeys, modKey)
				end
			end
			table.sort(sortedKeys, function(a, b)
				return string.lower(a) < string.lower(b)
			end)

			if modAliases["vanilla"] then
				table.insert(lines, "^green;Vanilla^reset;: " .. table.concat(modAliases["vanilla"], ", "))
			end

			for _, modKey in ipairs(sortedKeys) do
				table.insert(lines, "^green;" .. modKey .. "^reset;: " .. table.concat(modAliases[modKey], ", "))
			end

			if #lines == 0 then
				return "No category aliases available!"
			end

			return table.concat(lines, ";\n") .. "."
		end

		local targetCategory = aliasesMap[lowerArgs]
		if targetCategory and categoryPools[targetCategory] then
			return drawFromBag(targetCategory, categoryPools[targetCategory])
		end

		local safeArgs = stripOsbTags(args):gsub("%^", "")
		return "Unknown category: ^orange;" .. safeArgs .. "^reset;! Type ^cyan;/tip help^reset; for a list."
	end)
end
