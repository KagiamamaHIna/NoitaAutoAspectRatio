local ffi = require("ffi")
ffi.cdef[[
int SetDllDirectoryA(const char* lpPathName);
uint32_t FindPlatformWin();

struct PlatformWin{
    void* vtable;
    //--unknown...
};

struct WizardAppConfig{
    void* vtable;
    uint32_t internal_size_w;
    uint32_t internal_size_h;
    char unknown[44];
    uint32_t backbuffer_width;
    uint32_t backbuffer_height;
    //--unknown...
};

typedef struct WizardAppConfig* __thiscall GetWizardAppConfig(void* PlatformWin);
]]
ffi.C.SetDllDirectoryA("mods/auto_aspect_ratio/module/")
local YNP = ffi.load("YNoitaPatcher")

local function GetWizardAppConfig()
    local PlatformWinPtr = YNP.FindPlatformWin()
    if PlatformWinPtr == nil then
        error("PlatformWin is nullptr")
    end
    local Vftable = ffi.cast("char**", PlatformWinPtr)[0]
    local fn = ffi.cast("GetWizardAppConfig*", ffi.cast("char**", (Vftable + 172))[0])
    return fn(ffi.cast("void*", PlatformWinPtr))
end

local config = GetWizardAppConfig()

local normalAspectRatio = 16 / 9
local currentAspectRatio = config.internal_size_w / config.internal_size_h
local MagicNumberFormat = [[
<MagicNumbers
  VIRTUAL_RESOLUTION_X="%d"
  VIRTUAL_RESOLUTION_Y="%d"
></MagicNumbers>
]]
if normalAspectRatio ~= currentAspectRatio then
    local resx = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X"))
    local resy = math.floor(resx / currentAspectRatio + 0.5) + 1
    ModTextFileSetContent("mods/auto_aspect_ratio/magic_numbers.xml", MagicNumberFormat:format(resx, resy))
    ModMagicNumbersFileAdd("mods/auto_aspect_ratio/magic_numbers.xml")

    local AspectRatio = config.backbuffer_width / config.backbuffer_height
    if AspectRatio ~= normalAspectRatio then
        config.internal_size_h = math.modf(config.internal_size_w / AspectRatio)
    end
end

local lastWidth
local lastHeight
function OnPausePreUpdate()
    if ModSettingGet("auto_aspect_ratio.rest_def_asepect_ratio") then
        config.internal_size_w = 1280
        config.internal_size_h = 720
        lastWidth = nil
        lastHeight = nil
    elseif lastWidth ~= config.backbuffer_width or lastHeight ~= config.backbuffer_height then
        lastWidth = config.backbuffer_width
        lastHeight = config.backbuffer_height

        local AspectRatio = lastWidth / lastHeight
        config.internal_size_h = math.modf(config.internal_size_w / AspectRatio)
    end
end