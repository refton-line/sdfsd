--[[
	NewMainScript v25: загрузчик старой версии Vape V4 (восстановлен).

	GUI, библиотеки и картинки берутся из официальной сборки старой версии
	(7GrandDadPGN/VapeCompiled @ b4a3418, 08.07.2026). Модули universal и
	текущей игры собираются из старых исходников (VapeV4ForRoblox-main) так
	же, как это делает официальный сборщик. Один профиль на все игры,
	карантин битых профилей с бэкапом, перенос настроек из новой версии,
	автосейв.

	Настройки находятся в начале кода ниже. Копия скрипта сохраняется в
	newvape/oldvape/loader.lua, её запускают телепорт, Reinject, сброс
	профиля и смена темы GUI.
]]

local SOURCE = [==========[
-- ============================ НАСТРОЙКИ ============================
local LOADER_VERSION = 'v25'
-- официальная сборка старой версии: GUI, библиотеки, картинки
local COMPILED_REPO = '7GrandDadPGN/VapeCompiled'
local COMPILED_COMMIT = 'b4a3418336f13ae0ac8cc5b8d3a1a431977e6d71'
-- старые исходники (ваша папка VapeV4ForRoblox-main): модули игр
local SOURCE_REPO = 'oyuzuchin1-byte/VapeV4ForRoblox'
local SOURCE_COMMIT = '2897918f90181d64d48ba34e045a815bffdda6e5'
-- один профиль на все игры: newvape/profiles/<профиль>shared.txt
local SHARED_PROFILE = true
-- автосейв, секунд
local AUTOSAVE_INTERVAL = 2
-- ===================================================================

local WATERMARK = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'
local STATE = 'newvape/oldvape'
local SELF_PATH = STATE..'/loader.lua'
local TREE_PATH = STATE..'/tree.txt'
local SEEDED_PATH = STATE..'/seeded.txt'
local BUILD = LOADER_VERSION..'|'..COMPILED_COMMIT..'|'..SOURCE_REPO..'@'..SOURCE_COMMIT
-- порядок официального сборщика; Inventory он в те дни пропускал, хотя категория в GUI есть
local CATEGORIES = {'Combat', 'Blatant', 'Render', 'Utility', 'World', 'Inventory', 'Minigames', 'Legit'}
local LIBRARIES = {'drawing', 'entity', 'hash', 'prediction', 'vm'}
local THEMES = {new = true, old = true, rise = true}
local RELOAD_CALL = "loadstring(readfile('"..SELF_PATH.."'), 'NewMainScript')()"
local TELEPORT_SCRIPT = table.concat({
	'shared.vapereload = true',
	"local ok, source = pcall(readfile, '"..SELF_PATH.."')",
	"if ok and source and source ~= '' then",
	"\tloadstring(source, 'NewMainScript')()",
	'else',
	"\twarn('[vape] "..SELF_PATH.." не найден, запустите NewMainScript вручную')",
	'end'
}, '\n')

local cloneref = cloneref or function(obj)
	return obj
end
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local function stage(text)
	print('[vape] '..text)
end

local function readText(path)
	local suc, res = pcall(readfile, path)
	return suc and type(res) == 'string' and res or ''
end

local function hasContent(path)
	return readText(path) ~= ''
end

local function ensureFolder(path)
	local built
	for segment in path:gmatch('[^/]+') do
		built = built and built..'/'..segment or segment
		if not isfolder(built) then
			makefolder(built)
		end
	end
end

local function writeFile(path, content)
	local folder = path:match('^(.+)/[^/]+$')
	if folder then
		ensureFolder(folder)
	end
	writefile(path, content)
end

local function removeFile(path)
	if delfile then
		pcall(delfile, path)
	else
		pcall(writefile, path, '')
	end
end

local function decodeJson(text)
	local suc, res = pcall(function()
		return httpService:JSONDecode(text)
	end)
	return suc and type(res) == 'table' and res or nil
end

local function readJson(path)
	return decodeJson(readText(path))
end

local function writeJson(path, data)
	writeFile(path, httpService:JSONEncode(data))
end

local function listFolder(path)
	local suc, res = pcall(listfiles, path)
	return suc and type(res) == 'table' and res or {}
end

local function leafName(path)
	return path:match('([^/\\]+)$') or path
end

local function replacePlain(text, find, replacement)
	local parts, start, count = {}, 1, 0
	while true do
		local first, last = text:find(find, start, true)
		if not first then
			break
		end
		table.insert(parts, text:sub(start, first - 1))
		table.insert(parts, replacement)
		start = last + 1
		count += 1
	end
	table.insert(parts, text:sub(start))
	return table.concat(parts), count
end

-- ============================== СЕТЬ ===============================

local function httpGet(url)
	for attempt = 1, 3 do
		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		if suc and type(res) == 'string' and res ~= '' and res ~= '404: Not Found' then
			return res
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
end

local function encodePath(path)
	return (path:gsub('[^%w%-%._~/]', function(char)
		return string.format('%%%02X', char:byte())
	end))
end

-- GitHub, при сбое зеркало jsDelivr; size отсекает обрезанные ответы и страницы ошибок
local mirrorFirst = false
local function fetchRepoFile(repo, commit, path, size)
	if size == 0 then
		return ''
	end
	local encoded = encodePath(path)
	local urls = {
		{'https://raw.githubusercontent.com/'..repo..'/'..commit..'/'..encoded, false},
		{'https://cdn.jsdelivr.net/gh/'..repo..'@'..commit..'/'..encoded, true}
	}
	if mirrorFirst then
		urls[1], urls[2] = urls[2], urls[1]
	end
	for i, source in urls do
		local res = httpGet(source[1])
		if res and (size == nil or #res == size) then
			if i == 2 then
				-- первый источник не ответил: дальше начинаем с того, что сработал
				mirrorFirst = source[2]
			end
			return res
		end
	end
end

-- jobs: {repo, commit, path, size}; качает параллельно, при первой ошибке возвращает nil и путь
local function fetchAll(jobs)
	local results, failed = {}, nil
	local cursor, running = 0, 0
	for _ = 1, math.min(12, #jobs) do
		running += 1
		task.spawn(function()
			while not failed do
				cursor += 1
				local index = cursor
				local job = jobs[index]
				if not job then
					break
				end
				local suc, res = pcall(fetchRepoFile, job[1], job[2], job[3], job[4])
				if suc and res then
					results[index] = res
				else
					failed = job[3]
				end
			end
			running -= 1
		end)
	end
	local waited = 0
	while running > 0 and waited < 180 do
		waited += task.wait(0.1)
	end
	if failed or running > 0 then
		return nil, failed or 'таймаут скачивания'
	end
	return results
end

-- ========================= СБОРКА МОДУЛЕЙ ==========================

-- список файлов исходников с размерами; коммит закреплён, поэтому кэшируется навсегда
local function loadTree()
	local tree = {}
	for line in readText(TREE_PATH):gmatch('[^\n]+') do
		local size, path = line:match('^(%d+)\t(.+)$')
		if size then
			tree[path] = tonumber(size)
		end
	end
	if next(tree) then
		return tree
	end
	local api = decodeJson(httpGet('https://api.github.com/repos/'..SOURCE_REPO..'/git/trees/'..SOURCE_COMMIT..'?recursive=1') or '')
	if api and type(api.tree) == 'table' and not api.truncated then
		for _, node in api.tree do
			if node.type == 'blob' then
				tree[node.path] = node.size
			end
		end
	else
		local cdn = decodeJson(httpGet('https://data.jsdelivr.com/v1/packages/gh/'..SOURCE_REPO..'@'..SOURCE_COMMIT..'?structure=flat') or '')
		if cdn and type(cdn.files) == 'table' then
			for _, file in cdn.files do
				tree[file.name:sub(2)] = file.size
			end
		end
	end
	if not next(tree) then
		return nil
	end
	local lines = {}
	for path, size in tree do
		table.insert(lines, size..'\t'..path)
	end
	writeFile(TREE_PATH, table.concat(lines, '\n'))
	return tree
end

local function splitArgs(name)
	local args, start = {}, 1
	while true do
		local first, last = name:find(' - ', start, true)
		if not first then
			table.insert(args, name:sub(start))
			return args
		end
		table.insert(args, name:sub(start, first - 1))
		start = last + 1
	end
end

-- как index.js сборщика: имя с '-' означает игру, без '-' означает папку с играми
local function indexGames(tree)
	local games = {}
	local function add(name, path)
		local args = splitArgs(name)
		if args[3] == 'dev' or args[3] == 'dev.lua' then
			return
		end
		games[args[1]] = {Path = path, File = name:sub(-4) == '.lua'}
	end
	for path in tree do
		local rest = path:match('^src/games/(.+)$')
		if rest then
			local top, inner = rest:match('^([^/]+)/?(.*)$')
			if top:find('-', 1, true) then
				add(top, 'src/games/'..top)
			elseif inner ~= '' then
				local second = inner:match('^[^/]+')
				add(second, 'src/games/'..top..'/'..second)
			end
		end
	end
	return games
end

-- порядок String.localeCompare из сборщика: регистр не важен, знаки < цифры < буквы
local PUNCTUATION = " _-,;:!?.'\"()[]{}@*/\\&#%`^+<=>|~$"
local function collationKey(byte)
	if byte >= 65 and byte <= 90 then
		return 300 + byte + 32
	elseif byte >= 97 and byte <= 122 then
		return 300 + byte
	elseif byte >= 48 and byte <= 57 then
		return 200 + byte
	end
	return PUNCTUATION:find(string.char(byte), 1, true) or 500 + byte
end

local function localeLess(a, b)
	for i = 1, math.min(#a, #b) do
		local x, y = collationKey(a:byte(i)), collationKey(b:byte(i))
		if x ~= y then
			return x < y
		end
	end
	if #a ~= #b then
		return #a < #b
	end
	return a > b
end

local function buildGame(entry, tree)
	if entry.File then
		local text = fetchRepoFile(SOURCE_REPO, SOURCE_COMMIT, entry.Path, tree[entry.Path])
		return text, not text and entry.Path or nil
	end
	local paths = {entry.Path..'/base.lua'}
	for _, category in CATEGORIES do
		local prefix = entry.Path..'/'..category..'/'
		local names = {}
		for path in tree do
			if path:sub(1, #prefix) == prefix then
				local name = path:sub(#prefix + 1)
				if not name:find('/', 1, true) and not name:find('- dev', 1, true) then
					table.insert(names, name)
				end
			end
		end
		table.sort(names, localeLess)
		for _, name in names do
			table.insert(paths, prefix..name)
		end
	end
	local jobs = {}
	for i, path in paths do
		jobs[i] = {SOURCE_REPO, SOURCE_COMMIT, path, tree[path]}
	end
	local files, failed = fetchAll(jobs)
	if not files then
		return nil, failed
	end
	local parts = {''}
	for i = 2, #files do
		local text = files[i]
		if not text:find('run(', 1, true) then
			local indented = text:gsub('\n', '\n\t')
			text = 'run(function()\n\t'..indented..'\nend)'
		end
		table.insert(parts, text)
	end
	return files[1]..table.concat(parts, '\n\n')
end

local function gamePath(name)
	return 'newvape/games/'..name..'.lua'
end

local tree, games
local function prepareGame(name)
	if hasContent(gamePath(name)) then
		return true
	end
	if not games then
		tree = loadTree()
		if not tree then
			return false, 'нет списка файлов (GitHub API и jsDelivr недоступны)'
		end
		games = indexGames(tree)
	end
	local entry = games[name]
	if not entry then
		return false
	end
	stage('собираю games/'..name..'.lua из исходников')
	local text, failed = buildGame(entry, tree)
	if not text then
		return false, 'не скачался '..tostring(failed)
	end
	local fn, err = loadstring(text, name)
	if not fn then
		return false, 'games/'..name..'.lua не компилируется: '..tostring(err)
	end
	writeFile(gamePath(name), WATERMARK..'\n'..text)
	return true
end

-- ========================== GUI И СБОРКА ===========================

-- общий профиль: модули других игр, которых нет в этой, остаются в файле
local MERGE_SAVE = [=[local profilepath = 'newvape/profiles/'..self.Profile..self.Place..'.txt'
	if self.Place == 'shared' then
		local suc, olddata = pcall(function()
			return httpService:JSONDecode(readfile(profilepath))
		end)
		if suc and type(olddata) == 'table' then
			for _, key in {'Modules', 'Categories', 'Legit'} do
				if type(olddata[key]) == 'table' and type(savedata[key]) == 'table' then
					for name, data in olddata[key] do
						if savedata[key][name] == nil then
							savedata[key][name] = data
						end
					end
				end
			end
		end
	end
	writefile(profilepath, httpService:JSONEncode(savedata))]=]

local GUI_PATCHES = {
	-- Reinject, сброс профиля и смена темы: официальный загрузчик скачал бы новую версию
	{"loadstring(game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true))()", RELOAD_CALL},
	{"loadstring(readfile('newvape/loader.lua'), 'loader')()", RELOAD_CALL},
	-- после битого профиля сессия всё равно сохраняется (копия битого файла уже в .bad)
	{'self.Loaded = savecheck', 'self.Loaded = true'},
	{'runService:SetRobloxGuiFocused((clickgui.Visible or guiService:GetErrorType() ~= Enum.ConnectionError.OK) and self.Blur.Enabled)',
		'pcall(runService.SetRobloxGuiFocused, runService, (clickgui.Visible or guiService:GetErrorType() ~= Enum.ConnectionError.OK) and (self.Blur and self.Blur.Enabled or false) or false)'},
	{"writefile('newvape/profiles/'..self.Profile..self.Place..'.txt', httpService:JSONEncode(savedata))", MERGE_SAVE}
}

local function patchGui(text, theme)
	for _, patch in GUI_PATCHES do
		local count
		text, count = replacePlain(text, patch[1], patch[2])
		if count == 0 and theme == 'new' then
			warn('[vape] патч GUI не применился: '..patch[1]:sub(1, 60))
		end
	end
	return text
end

local function prepareCompiled(paths, theme)
	local jobs, targets = {}, {}
	for _, path in paths do
		if not hasContent('newvape/'..path) then
			table.insert(jobs, {COMPILED_REPO, COMPILED_COMMIT, path})
			table.insert(targets, path)
		end
	end
	if #jobs == 0 then
		return true
	end
	stage('скачиваю '..table.concat(targets, ', '))
	local files, failed = fetchAll(jobs)
	if not files then
		return false, failed
	end
	for i, path in targets do
		local text = files[i]
		if path:sub(1, 5) == 'guis/' then
			text = patchGui(text, theme)
		end
		local fn, err = loadstring(text, path)
		if not fn then
			return false, path..' не компилируется: '..tostring(err)
		end
		writeFile('newvape/'..path, WATERMARK..'\n'..text)
	end
	return true
end

-- кэш другой версии (новая Vape, прошлые загрузчики): удаляем только файлы с водяным знаком
local function wipeCache(folder)
	for _, file in listFolder(folder) do
		if not file:find('loader', 1, true) and isfile(file) and readText(file):sub(1, #WATERMARK) == WATERMARK then
			removeFile(file)
		end
	end
end

local function wipeAssets(folder)
	for _, file in listFolder(folder) do
		if isfile(file) then
			removeFile(file)
		end
	end
end

-- ============================ ПРОФИЛИ ==============================

local function quarantine(path)
	warn('[vape] битый файл '..path..', копия в '..path..'.bad')
	pcall(writefile, path..'.bad', readText(path))
	removeFile(path)
end

local function backupOnce(path, suffix)
	if not isfile(path..suffix) then
		pcall(writefile, path..suffix, readText(path))
	end
end

local function convertBind(bind)
	if type(bind) ~= 'table' then
		return {}
	elseif type(bind.Mobile) == 'table' then
		return {Mobile = true, X = bind.Mobile.X, Y = bind.Mobile.Y}
	elseif bind.Keys ~= nil or bind.Hold ~= nil then
		return type(bind.Keys) == 'table' and bind.Keys or {}
	end
	return bind
end

-- формат старого GUI; новая версия пишет v = 1 и бинды вида {Keys = {...}}
local function normalizeProfile(data)
	for _, key in {'Modules', 'Categories', 'Legit'} do
		if type(data[key]) ~= 'table' then
			data[key] = {}
		end
	end
	data.v = nil
	for name, module in data.Modules do
		if type(module) == 'table' then
			module.Bind = convertBind(module.Bind)
			module.Enabled = module.Enabled == true
		else
			data.Modules[name] = nil
		end
	end
	for name, module in data.Legit do
		if type(module) == 'table' then
			module.Enabled = module.Enabled == true
		else
			data.Legit[name] = nil
		end
	end
	for name, category in data.Categories do
		-- старый Load читает Position без проверки и вызывает Pin() при Pinned ~= nil у незакреплённого окна
		if type(category) ~= 'table' or type(category.Position) ~= 'table' then
			data.Categories[name] = nil
		elseif category.Pinned ~= true then
			category.Pinned = nil
		end
	end
	return data
end

local function findGuiBind(settings)
	if type(settings) ~= 'table' then
		return
	end
	for _, pane in settings do
		local bind = type(pane) == 'table' and pane['Rebind GUI']
		if type(bind) == 'table' and type(bind.Keys) == 'table' and #bind.Keys > 0 then
			return bind.Keys
		end
	end
end

-- настройки GUI из новой версии (v = 1); списки друзей и целей старый GUI хранит в профиле
local function convertGui(data, lists)
	local result = {
		Categories = {},
		Profile = type(data.Profile) == 'string' and data.Profile or 'default',
		Profiles = {},
		Keybind = {'RightShift'}
	}
	for name, category in (type(data.Categories) == 'table' and data.Categories or {}) do
		if type(category) ~= 'table' then
			continue
		elseif name == 'Profiles' then
			for _, profile in (type(category.List) == 'table' and category.List or {}) do
				if type(profile) == 'table' and type(profile.Name) == 'string' then
					table.insert(result.Profiles, {Name = profile.Name, Bind = convertBind(profile.Bind)})
				end
			end
		elseif name == 'Main' then
			result.Categories.Main = {Position = category.Position}
			result.Keybind = findGuiBind(category.Settings) or result.Keybind
		elseif category.List ~= nil then
			lists[name] = category
		else
			result.Categories[name] = category
		end
	end
	local known = {}
	for _, profile in result.Profiles do
		known[profile.Name] = true
	end
	for _, name in {'default', result.Profile} do
		if not known[name] then
			table.insert(result.Profiles, {Name = name, Bind = {}})
			known[name] = true
		end
	end
	return result
end

local function wasSeeded(profile)
	for line in readText(SEEDED_PATH):gmatch('[^\n]+') do
		if line == profile then
			return true
		end
	end
	return false
end

local function markSeeded(profile)
	if not wasSeeded(profile) then
		writeFile(SEEDED_PATH, readText(SEEDED_PATH)..profile..'\n')
	end
end

-- первый запуск общего профиля: объединяем профили отдельных игр, самый большой важнее
local function seedShared(profile)
	local pattern = '^'..profile:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0')..'%d+%.txt$'
	local candidates = {}
	for _, file in listFolder('newvape/profiles') do
		local name = leafName(file)
		if name:match(pattern) then
			local text = readText(file)
			local data = decodeJson(text)
			if data then
				table.insert(candidates, {Name = name, Size = #text, Data = normalizeProfile(data)})
			end
		end
	end
	if #candidates == 0 then
		return
	end
	table.sort(candidates, function(a, b)
		return a.Size > b.Size
	end)
	local result, names = candidates[1].Data, {}
	for _, candidate in candidates do
		table.insert(names, candidate.Name)
		for _, key in {'Modules', 'Categories', 'Legit'} do
			for name, value in candidate.Data[key] do
				if result[key][name] == nil then
					result[key][name] = value
				end
			end
		end
	end
	stage('общий профиль '..profile..' собран из: '..table.concat(names, ', '))
	return result
end

local function prepareProfiles(place)
	local guiPath = 'newvape/profiles/'..game.GameId..'.gui.txt'
	local profile, lists = 'default', {}
	if isfile(guiPath) then
		local data = readJson(guiPath)
		if not data then
			quarantine(guiPath)
		else
			if data.v == 1 then
				backupOnce(guiPath, '.v1.bak')
				data = convertGui(data, lists)
				writeJson(guiPath, data)
				stage('настройки GUI перенесены из новой версии (оригинал: '..guiPath..'.v1.bak)')
			elseif type(data.Keybind) ~= 'table' then
				data.Keybind = {'RightShift'}
				writeJson(guiPath, data)
			end
			profile = type(data.Profile) == 'string' and data.Profile or profile
		end
	end

	local path = 'newvape/profiles/'..profile..place..'.txt'
	local data
	if isfile(path) then
		local text = readText(path)
		data = decodeJson(text)
		if data then
			pcall(writefile, path..'.bak', text)
			if data.v == 1 then
				backupOnce(path, '.v1.bak')
				stage('профиль перенесён из новой версии (оригинал: '..path..'.v1.bak)')
			end
		else
			quarantine(path)
			data = readJson(path..'.bak')
			if data then
				stage('профиль восстановлен из '..path..'.bak')
			end
		end
	end
	if place == 'shared' then
		-- только один раз: иначе «Reset current profile» вернул бы старые настройки
		if not data and not wasSeeded(profile) then
			data = seedShared(profile)
		end
		markSeeded(profile)
	end
	if not data and next(lists) then
		data = {}
	end
	if data then
		normalizeProfile(data)
		for name, list in lists do
			if data.Categories[name] == nil then
				data.Categories[name] = list
			end
		end
		writeJson(path, data)
	end
end

-- ============================== ЗАПУСК =============================

local vape

local function finishLoading()
	vape.Init = nil
	if SHARED_PROFILE then
		vape.Place = 'shared'
	end
	local suc, err = pcall(prepareProfiles, vape.Place)
	if not suc then
		warn('[vape] проверка профилей: '..tostring(err))
	end
	suc, err = pcall(vape.Load, vape)
	if not suc then
		warn('[vape] профиль загрузился с ошибкой: '..tostring(err))
		vape.Loaded = true
	end
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(AUTOSAVE_INTERVAL)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = TELEPORT_SCRIPT
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			pcall(vape.Save, vape)
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

local function run()
	stage('NewMainScript '..LOADER_VERSION..': сборка '..COMPILED_COMMIT:sub(1, 7)..', исходники '..SOURCE_COMMIT:sub(1, 7))
	for _, folder in {'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis', STATE} do
		ensureFolder(folder)
	end

	if readText(STATE..'/build.txt') ~= BUILD or readText('newvape/profiles/commit.txt') ~= COMPILED_COMMIT then
		stage('другая версия в кэше: очищаю (профили не трогаю)')
		for _, folder in {'newvape', 'newvape/games', 'newvape/guis', 'newvape/libraries'} do
			wipeCache(folder)
		end
		if delfile then
			for _, theme in {'new', 'old', 'rise', 'wurst', 'liquidbounce'} do
				wipeAssets('newvape/assets/'..theme)
			end
		end
		removeFile(TREE_PATH)
		writeFile('newvape/profiles/commit.txt', COMPILED_COMMIT)
		-- официальный загрузчик при возврате на новую версию перекачает картинки
		writeFile('newvape/profiles/asset.txt', 'oldvape')
		writeFile(STATE..'/build.txt', BUILD)
	end

	local theme = readText('newvape/profiles/gui.txt')
	if not THEMES[theme] then
		theme = 'new'
		writeFile('newvape/profiles/gui.txt', theme)
	end
	local compiled = {'guis/'..theme..'.lua'}
	for _, name in LIBRARIES do
		table.insert(compiled, 'libraries/'..name..'.lua')
	end
	local suc, err = prepareCompiled(compiled, theme)
	if not suc then
		error('не скачались файлы GUI: '..tostring(err), 0)
	end

	suc, err = prepareGame('universal')
	if not suc then
		error('не собрался universal: '..tostring(err or 'нет в исходниках'), 0)
	end
	local issues = {}
	local place = tostring(game.PlaceId)
	suc, err = prepareGame(place)
	if suc then
		-- mega, micro, дуэли и т.п. только перенаправляют на модули основного места
		local target = readText(gamePath(place)):match('vape%.Place = (%d+)')
		if target then
			suc, err = prepareGame(target)
		end
	end
	if err then
		table.insert(issues, 'модули этой игры не загружены: '..err)
	end

	repeat task.wait() until game:IsLoaded()
	if shared.vape then
		pcall(shared.vape.Uninject, shared.vape)
	end
	stage('запуск')
	local guiFn, guiErr = loadstring(readText('newvape/guis/'..theme..'.lua'), 'gui')
	if not guiFn then
		error('GUI не компилируется: '..tostring(guiErr), 0)
	end
	vape = guiFn()
	shared.vape = vape

	if shared.VapeIndependent then
		vape.Init = finishLoading
		return vape
	end
	-- ошибка в модулях не мешает загрузить профиль и остальное
	for _, name in {'universal', place} do
		if hasContent(gamePath(name)) then
			local fn, runErr = loadstring(readText(gamePath(name)), name)
			local ok = false
			if fn then
				ok, runErr = pcall(fn)
			end
			if not ok then
				table.insert(issues, name..': '..tostring(runErr))
			end
		end
	end
	finishLoading()
	for _, text in issues do
		warn('[vape] '..text)
		vape:CreateNotification('Vape', text, 15, 'alert')
	end
end

local lockTime = shared.OldVapeLoading
if lockTime and os.time() - lockTime < 300 then
	warn('[vape] NewMainScript уже загружается, дождитесь окончания')
	return
end
shared.OldVapeLoading = os.time()
local ok, result = pcall(run)
shared.OldVapeLoading = nil
if not ok then
	warn('[vape] загрузка не удалась: '..tostring(result))
	if shared.vape then
		pcall(shared.vape.CreateNotification, shared.vape, 'Vape', 'Загрузка не удалась: '..tostring(result), 30, 'alert')
	end
end

-- страховочный autosave: независимый от gui внутреннего цикла, каждые 8 секунд
task.spawn(function()
	local lastOk = true
	while true do
		task.wait(8)
		local v = shared.vape
		if v and v.Loaded and v.Save then
			local ok = pcall(v.Save, v)
			if not ok and lastOk then
				warn('[vape] profile autosave failed (continuing retries)')
			end
			lastOk = ok
		end
	end
end)

return ok and result or nil
]==========]

pcall(function()
	for _, folder in {'newvape', 'newvape/oldvape'} do
		if not isfolder(folder) then
			makefolder(folder)
		end
	end
	writefile('newvape/oldvape/loader.lua', SOURCE)
end)

local run, err = loadstring(SOURCE, 'NewMainScript')
if not run then
	error('[vape] NewMainScript: '..tostring(err), 0)
end
return run(...)
