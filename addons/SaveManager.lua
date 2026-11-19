-- SaveManager for Linoria-Style Left UI (콘픽 저장, 불러오기, 삭제, 오토로드)

local HttpService = game:GetService("HttpService")

local SaveManager = {
    Folder = "LinoriaLeftUI/Configs",
    Library = nil,
    AutoLoadFile = "autoload.txt",
}

local function hasFileIO()
    return (typeof(writefile) == "function")
        and (typeof(readfile) == "function")
        and (typeof(isfile) == "function")
        and (typeof(delfile) == "function")
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

function SaveManager:SetLibrary(lib)
    self.Library = lib
    ensureFolder(self.Folder)
end

function SaveManager:SetFolder(folderPath)
    self.Folder = tostring(folderPath)
    ensureFolder(self.Folder)
end

function SaveManager:SerializeFlags()
    local data = {}
    if not self.Library or not self.Library.Flags then
        return data
    end

    for flag, obj in pairs(self.Library.Flags) do
        if type(obj) == "table" and obj.Value ~= nil then
            data[flag] = obj.Value
        end
    end
    return data
end

function SaveManager:ApplyFlags(data)
    if type(data) ~= "table" or not self.Library or not self.Library.Flags then
        return false
    end

    for flag, val in pairs(data) do
        local obj = self.Library.Flags[flag]
        if obj and type(obj.SetValue) == "function" then
            pcall(function()
                obj:SetValue(val)
            end)
        end
    end
    return true
end

function SaveManager:Save(configName)
    configName = tostring(configName or "default")
    if configName == "" then
        configName = "default"
    end

    local serialized = self:SerializeFlags()
    local encoded = HttpService:JSONEncode(serialized)

    if hasFileIO() then
        ensureFolder(self.Folder)
        local path = self.Folder .. "/" .. configName .. ".json"
        local ok = pcall(writefile, path, encoded)
        if ok then
            if self.Library then
                self.Library:Notify("콘픽 저장됨: " .. configName, 2.5)
            end
            return true
        end
    end

    self._MemoryConfigs = self._MemoryConfigs or {}
    self._MemoryConfigs[configName] = encoded
    if self.Library then
        self.Library:Notify("메모리 콘픽 저장됨: " .. configName, 2.5)
    end
    return true
end

function SaveManager:Load(configName)
    configName = tostring(configName or "default")
    local raw = nil

    if hasFileIO() then
        local path = self.Folder .. "/" .. configName .. ".json"
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok then
                raw = content
            end
        end
    end

    if not raw and self._MemoryConfigs and self._MemoryConfigs[configName] then
        raw = self._MemoryConfigs[configName]
    end

    if not raw then
        if self.Library then
            self.Library:Notify("콘픽을 찾을 수 없음: " .. configName, 2.5)
        end
        return false
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if ok and type(decoded) == "table" then
        self:ApplyFlags(decoded)
        if self.Library then
            self.Library:Notify("콘픽 불러오기 완료: " .. configName, 2.5)
        end
        return true
    end

    return false
end

function SaveManager:Delete(configName)
    configName = tostring(configName or "default")

    if hasFileIO() then
        local path = self.Folder .. "/" .. configName .. ".json"
        if isfile(path) then
            pcall(delfile, path)
        end
    end

    if self._MemoryConfigs then
        self._MemoryConfigs[configName] = nil
    end

    if self.Library then
        self.Library:Notify("콘픽 삭제됨: " .. configName, 2.5)
    end
    return true
end

function SaveManager:SetAutoLoad(configName)
    configName = tostring(configName or "default")
    if hasFileIO() then
        ensureFolder(self.Folder)
        pcall(writefile, self.Folder .. "/" .. self.AutoLoadFile, configName)
    end
    self._AutoLoadName = configName
    if self.Library then
        self.Library:Notify("자동 로드 지정: " .. configName, 2.5)
    end
end

function SaveManager:LoadAutoLoad()
    local targetName = nil
    if hasFileIO() then
        local autoPath = self.Folder .. "/" .. self.AutoLoadFile
        if isfile(autoPath) then
            local ok, content = pcall(readfile, autoPath)
            if ok and content and content ~= "" then
                targetName = content
            end
        end
    end
    if not targetName and self._AutoLoadName then
        targetName = self._AutoLoadName
    end
    if targetName then
        return self:Load(targetName)
    end
    return false
end

function SaveManager:BuildConfigSection(groupBox)
    if not groupBox then
        return
    end

    groupBox:AddLabel("콘픽 저장 / 불러오기")

    local cfgInput = groupBox:AddInput("ConfigNameInput", {
        Text = "콘픽 이름",
        Placeholder = "예: main_cfg",
        Default = "main_cfg",
    })

    groupBox:AddButton({
        Text = "콘픽 저장",
        Callback = function()
            self:Save(cfgInput.Value)
        end,
    })

    groupBox:AddButton({
        Text = "콘픽 불러오기",
        Callback = function()
            self:Load(cfgInput.Value)
        end,
    })

    groupBox:AddButton({
        Text = "자동 로드 설정",
        Callback = function()
            self:SetAutoLoad(cfgInput.Value)
        end,
    })

    groupBox:AddButton({
        Text = "콘픽 삭제",
        Callback = function()
            self:Delete(cfgInput.Value)
        end,
    })
end

return SaveManager
