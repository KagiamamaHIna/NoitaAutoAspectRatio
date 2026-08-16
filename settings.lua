local LocalText = [[auto_aspect_ratio_lang_ids,en,ru,pt-br,es-es,de,fr-fr,it,pl,zh-cn,jp,ko,,NOTES – use \n for newline,max length,,,,,,,,,,占位符，用于表示每一格对应的语言
auto_aspect_ratio_rest_def_asepect_ratio,Use the default aspect ratio,,,,,,,,使用默认分辨率比例,,,,,,,,,,,,,,,
auto_aspect_ratio_rest_def_asepect_ratio_desc,"Because the mod only loads once you're in a save file, \nyou must enter a save to change the settings, \nthen restart the game to apply them.",,,,,,,,由于模组是进入存档后才会加载的，\n因此你需要进入存档后更改设置再重启以生效,,,,,,,,,,,,,,,]]
dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.

local csv = dofile_once("mods/auto_aspect_ratio/csv.lua")

local currentLang = csv(LocalText)
local CurrentMap = {}
local gameLang = csv(ModTextFileGetContent("data/translations/common.csv"))
function LoadLang()
    CurrentMap = {}
	gameLang = csv(ModTextFileGetContent("data/translations/common.csv"))
    for v, _ in pairs(gameLang.rowHeads) do --构建一个关联表用来查询键值
        if v ~= "" then
            local tempKey = gameLang.get("current_language", v)
            CurrentMap[tempKey] = v
        end
    end
end
LoadLang()

local inGame = false

local function GetText(key) --获取文本
	if key == "" then
		return key
	end
	local GameKey
    local GameTextLangGet = GameTextGet("$current_language")
    local flag, entity = pcall(GameGetWorldStateEntity)
	if entity and entity ~= 0 and not inGame then
        LoadLang()
		inGame = true
	end
	GameKey = CurrentMap[GameTextLangGet]
	if GameKey == nil then
		GameKey = "en"
	end
	local result = currentLang.get(key, GameKey) or ""
	result = string.gsub(result, [[\n]], "\n")
    if result == nil or result == "" then
		result = currentLang.get(key, "en")
	end
	return result
end

---监听访问
---@param t table
---@param callback function
local function TableListener(t, callback)
	local function NewListener()
		local __data = {}
		local deleteList = {}
		for k, v in pairs(t) do
			__data[k] = v
			deleteList[#deleteList + 1] = k
		end
		for _, v in pairs(deleteList) do
			t[v] = nil
		end
		local result = {
			__newindex = function(table, key, value)
				local temp = callback(key, value)
				value = temp or value
				rawset(__data, key, value)
				rawset(table, key, nil)
			end,
			__index = function(table, key)
				local temp = callback(key, rawget(__data, key))
				if temp == nil then
					return rawget(__data, key)
				else
					return temp
				end
			end,
			__call = function()
				return __data
			end
		}
		return result
	end
	setmetatable(t, NewListener())
end

local function Setting(t)
	TableListener(t, function(key, value)
		if key == "ui_name" or key == "ui_description" then
			local result = GetText(value)
			return result
		end
	end)
	return t
end

local function GetTextOrKey(key)
	local result = GetText(key)
	return result or key
end

local function ValueListInit(t)
	TableListener(t, function(key, value)
		return GetTextOrKey(value)
	end)
	return t
end

local function ValueList(t)
	for k, v in pairs(t) do
		t[k] = ValueListInit(v)
	end
	return t
end


local mod_id = "auto_aspect_ratio"
local conjurer_reborn_reset_matwand_fav_confirm = false
local conjurer_reborn_reset_entwand_fav_confirm = false

mod_settings_version = 1
mod_settings =
{
	Setting({
        id = "rest_def_asepect_ratio",
        ui_name = "auto_aspect_ratio_rest_def_asepect_ratio",
		ui_description = "auto_aspect_ratio_rest_def_asepect_ratio_desc",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	})
}


function ModSettingsUpdate(init_scope)
	local old_version = mod_settings_get_version(mod_id) -- This can be used to migrate some settings between mod versions.
	mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
