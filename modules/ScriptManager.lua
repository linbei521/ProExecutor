--[[
    脚本管理模块
]]

local ScriptManager = {}

function ScriptManager.new(theme, storage, utils, outputManager)
    local self = {}
    self.theme = theme
    self.storage = storage
    self.utils = utils
    self.outputManager = outputManager
    self.savedData = storage:Load()
    self.scriptItems = {}
    
    function self:Setup(scriptsList, scriptsLayout)
        self.scriptsList = scriptsList
        self.scriptsLayout = scriptsLayout
        self:LoadSavedScripts()
    end
    
    function self:LoadSavedScripts()
        for _, script in ipairs(self.savedData.Scripts) do
            self:CreateScriptItem(script.name, script.code)
        end
    end
    
    function self:CreateScriptItem(name, code)
        if not self.scriptsList then return end
        
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 40)
        item.BackgroundColor3 = self.theme.Colors.Tertiary
        item.Text = ""
        item.BorderSizePixel = 0
        item.Parent = self.scriptsList
        
        self.theme:CreateCorner(6).Parent = item
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -60, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = self.theme.Colors.Text
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.SourceSansSemibold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = item
        
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0, 25, 0, 25)
        loadBtn.Position = UDim2.new(1, -50, 0.5, -12.5)
        loadBtn.BackgroundColor3 = self.theme.Colors.Success
        loadBtn.Text = "📂"
        loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadBtn.TextSize = 12
        loadBtn.Font = Enum.Font.SourceSansBold
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = item
        
        self.theme:CreateCorner(4).Parent = loadBtn
        
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Size = UDim2.new(0, 25, 0, 25)
        deleteBtn.Position = UDim2.new(1, -20, 0.5, -12.5)
        deleteBtn.BackgroundColor3 = self.theme.Colors.Error
        deleteBtn.Text = "🗑️"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.TextSize = 12
        deleteBtn.Font = Enum.Font.SourceSansBold
        deleteBtn.BorderSizePixel = 0
        deleteBtn.Parent = item
        
        self.theme:CreateCorner(4).Parent = deleteBtn
        
        loadBtn.MouseButton1Click:Connect(function()
            if self.onLoadScript then
                self.onLoadScript(code)
            end
            self.outputManager:LogSuccess("📂 已加载: " .. name)
        end)
        
        deleteBtn.MouseButton1Click:Connect(function()
            self:DeleteScript(name, item)
        end)
        
        self.scriptItems[name] = item
        self:UpdateCanvasSize()
    end
    
    function self:DeleteScript(name, item)
        for i, script in ipairs(self.savedData.Scripts) do
            if script.name == name then
                table.remove(self.savedData.Scripts, i)
                self:SaveData()
                break
            end
        end
        
        self.scriptItems[name] = nil
        item:Destroy()
        self.outputManager:LogError("🗑️ 已删除: " .. name)
        self:UpdateCanvasSize()
    end
    
    function self:SaveScript(name, code)
        local isValid, error = self.utils:ValidateScriptName(name)
        if not isValid then
            self.outputManager:LogError(error)
            return false
        end
        
        for _, script in ipairs(self.savedData.Scripts) do
            if script.name == name then
                self.outputManager:LogError("名称已存在！")
                return false
            end
        end
        
        table.insert(self.savedData.Scripts, {name = name, code = code})
        self:SaveData()
        self:CreateScriptItem(name, code)
        self.outputManager:LogSuccess("💾 已保存: " .. name)
        return true
    end
    
    function self:SaveData()
        local success, err = self.storage:Save(self.savedData)
        if not success then
            self.outputManager:LogWarning("保存失败: " .. (err or "未知错误"))
        end
    end
    
    function self:ExportScripts()
        if #self.savedData.Scripts == 0 then
            self.outputManager:LogWarning("没有脚本可导出")
            return
        end
        
        local success, err = self.storage:ExportToClipboard(self.savedData.Scripts)
        if success then
            self.outputManager:LogSuccess("📤 已导出 " .. #self.savedData.Scripts .. " 个脚本")
        else
            self.outputManager:LogError("导出失败: " .. (err or "剪贴板不支持"))
        end
    end
    
    function self:ImportScripts()
        local success, scripts = self.storage:ImportFromClipboard()
        if not success then
            self.outputManager:LogError("导入失败: " .. (scripts or "剪贴板不支持"))
            return
        end
        
        local imported = 0
        for _, script in ipairs(scripts) do
            if script.name and script.code then
                local exists = false
                for _, existing in ipairs(self.savedData.Scripts) do
                    if existing.name == script.name then
                        exists = true
                        break
                    end
                end
                
                if not exists then
                    table.insert(self.savedData.Scripts, script)
                    self:CreateScriptItem(script.name, script.code)
                    imported = imported + 1
                end
            end
        end
        
        if imported > 0 then
            self:SaveData()
            self.outputManager:LogSuccess("📥 已导入 " .. imported .. " 个脚本")
        else
            self.outputManager:LogWarning("没有新脚本导入")
        end
    end
    
    function self:DeleteAllScripts()
        if #self.savedData.Scripts == 0 then
            self.outputManager:LogWarning("没有脚本可删除")
            return
        end
        
        local count = #self.savedData.Scripts
        self.savedData.Scripts = {}
        self:SaveData()
        
        for _, item in pairs(self.scriptItems) do
            item:Destroy()
        end
        self.scriptItems = {}
        
        self.outputManager:LogError("🗑️ 已删除 " .. count .. " 个脚本")
        self:UpdateCanvasSize()
    end
    
    function self:UpdateCanvasSize()
        if self.scriptsLayout then
            self.scriptsList.CanvasSize = UDim2.new(0, 0, 0, self.scriptsLayout.AbsoluteContentSize.Y)
        end
    end
    
    function self:SetLoadCallback(callback)
        self.onLoadScript = callback
    end
    
    return self
end

return ScriptManager