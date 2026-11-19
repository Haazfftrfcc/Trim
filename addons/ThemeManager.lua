-- ThemeManager for Linoria-Style Left UI (연한 파란색 포인트 & 테마 프리셋 저장/불러오기)

local HttpService = game:GetService("HttpService")

local ThemeManager = {
    Folder = "LinoriaLeftUI/Themes",
    Library = nil,
    Presets = {
        ["SoftBlue"] = Color3.fromRGB(115, 185, 255), -- 연한 파란색 (기본)
        ["SkyIce"]   = Color3.fromRGB(145, 210, 255),
        ["Cobalt"]   = Color3.fromRGB(90, 155, 245),
        ["MintBlue"] = Color3.fromRGB(110, 220, 215),
    },
    CurrentThemeName = "SoftBlue",
}

local function hasFileIO()
    return (typeof(writefile) == "function")
        and (typeof(readfile) == "function")
        and (typeof(isfile) == "function")
        and (typeof(makefolder) == "function")
        and (typeof(isfolder) == "function")
end

local function ensureFolder(path)
    if not hasFileIO() then
        return false
    end
    local parts = string.split(path, "/")
    local current = ""
    for _, part in ipairs(parts) do
        if part ~= "" then
            current = current == "" and part or (current .. "/" .. part)
            if not isfolder(current) then
                pcall(makefolder, current)
            end
        end
    end
    return true
end

local function colorToTable(c)
    return {
        r = math.floor((c.R * 255) + 0.5),
        g = math.floor((c.G * 255) + 0.5),
        b = math.floor((c.B * 255) + 0.5),
    }
end

local function tableToColor(t)
    if type(t) ~= "table" then
        return Color3.fromRGB(115, 185, 255)
    end
    return Color3.fromRGB(
        math.clamp(tonumber(t.r) or 115, 0, 255),
        math.clamp(tonumber(t.g) or 185, 0, 255),
        math.clamp(tonumber(t.b) or 255, 0, 255)
    )
end

function ThemeManager:SetLibrary(lib)
    self.Library = lib
    ensureFolder(self.Folder)
end

function ThemeManager:ApplyAccent(color, themeName)
    if not self.Library then
        return
    end
    if themeName then
        self.CurrentThemeName = tostring(themeName)
    end
    self.Library:SetAccentColor(color)
end

function ThemeManager:ApplyPreset(presetName)
    local col = self.Presets[presetName]
    if col then
        self:ApplyAccent(col, presetName)
        return true
    end
    return false
end

function ThemeManager:SaveTheme(fileName)
    fileName = tostring(fileName or self.CurrentThemeName or "default")
    local accent = self.Library and self.Library.AccentColor or Color3.fromRGB(115, 185, 255)

    local payload = {
        ThemeName = self.CurrentThemeName,
        Accent = colorToTable(accent),
    }
    local encoded = HttpService:JSONEncode(payload)

    if hasFileIO() then
        ensureFolder(self.Folder)
        local path = self.Folder .. "/" .. fileName .. ".json"
        local ok = pcall(writefile, path, encoded)
        if ok then
            if self.Library then
                self.Library:Notify("테마 저장 완료: " .. fileName, 2.5)
            end
            return true
        end
    end

    self._MemoryThemes = self._MemoryThemes or {}
    self._MemoryThemes[fileName] = encoded
    if self.Library then
        self.Library:Notify("메모리 테마 저장됨: " .. fileName, 2.5)
    end
    return true
end

function ThemeManager:LoadTheme(fileName)
    fileName = tostring(fileName or self.CurrentThemeName or "default")
    local raw = nil

    if hasFileIO() then
        local path = self.Folder .. "/" .. fileName .. ".json"
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok then
                raw = content
            end
        end
    end

    if not raw and self._MemoryThemes and self._MemoryThemes[fileName] then
        raw = self._MemoryThemes[fileName]
    end

    if not raw then
        if self.Library then
            self.Library:Notify("테마 파일 없음: " .. fileName, 2.5)
        end
        return false
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if ok and type(decoded) == "table" then
        local col = tableToColor(decoded.Accent)
        self:ApplyAccent(col, decoded.ThemeName or fileName)
        if self.Library then
            self.Library:Notify("테마 적용 완료: " .. fileName, 2.5)
        end
        return true
    end

    return false
end

function ThemeManager:ApplyToGroupBox(groupBox)
    if not groupBox then
        return
    end

    groupBox:AddLabel("테마 / 연한 파란색 설정")

    groupBox:AddButton({
        Text = "연한 파란색 기본 적용",
        Callback = function()
            self:ApplyPreset("SoftBlue")
        end,
    })

    groupBox:AddButton({
        Text = "스카이 아이스 적용",
        Callback = function()
            self:ApplyPreset("SkyIce")
        end,
    })

    local nameInput = groupBox:AddInput("ThemeConfigName", {
        Text = "테마 콘픽 이름",
        Placeholder = "예: my_blue_theme",
        Default = "my_blue_theme",
    })

    groupBox:AddButton({
        Text = "테마 콘픽 저장",
        Callback = function()
            self:SaveTheme(nameInput.Value)
        end,
    })

    groupBox:AddButton({
        Text = "테마 콘픽 불러오기",
        Callback = function()
            self:LoadTheme(nameInput.Value)
        end,
    })
end

return ThemeManager
