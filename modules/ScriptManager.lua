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
    self.currentScript = nil
    self.scriptItems = {}
    
    function self:Setup(scriptListScroll, scriptListLayout, currentScriptLabel)
        self.scriptListScroll = scriptListScroll
        self.scriptListLayout = scriptListLayout
        self.currentScriptLabel = currentScriptLabel
    end
    
    function self:LoadSavedScripts()
        for _, script in ipairs(self.savedData.Scripts) do
            self:CreateScriptItem(script.name, script.code)
        end
    end
    
    function self:CreateScriptItem(name, code)
        if not self.scriptListScroll then return end
        
        local item = Instance.new("TextButton")
        item.Name = name
        item.Size = UDim2.new(1, 0, 0, 22)
        item.BackgroundColor3 = self.theme.Colors.Tertiary
        item.Text = ""
        item.BorderSizePixel = 0
        item.Parent = self.scriptListScroll
        
        self.theme:CreateCorner(4).Parent = item
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Size = UDim2.new(1, -18, 1, 0)
        itemLabel.Position = UDim2.new(0, 4, 0, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Text = name
        itemLabel.TextColor3 = self.theme.Colors.Text
        itemLabel.TextSize = 10
        itemLabel.Font = Enum.Font.SourceSans
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
        itemLabel.Parent = item
        
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Size = UDim2.new(0, 14, 0, 14)
        deleteBtn.Position = UDim2.new(1, -16, 0.5, -7)
        deleteBtn.BackgroundTransparency = 1
        deleteBtn.Text = "×"
        deleteBtn.TextColor3 = self.theme.Colors.Error
        deleteBtn.TextSize = 12
        deleteBtn.Font = Enum.Font.SourceSansBold
        deleteBtn.Parent = item
        
        item.MouseButton1Click:Connect(function()
            self:LoadScript(name, code)
            self:SetActiveItem(item)
        end)
        
        deleteBtn.MouseButton1Click:Connect(function()
            self:DeleteScript(name, item)
        end)
        
        self.scriptItems[name] = item
        self:UpdateCanvasSize()
        
        return item
    end
    
    function self:LoadScript(name, code)
        self.currentScript = {name = name, code = code}
        
        if self.currentScriptLabel then
            self.currentScriptLabel.Text = name
        end
        
        if self.onLoadScript then
            self.onLoadScript(code)
        end
        
        self.outputManager:LogSuccess("已加载: " .. name)
    end
    
    function self:SetActiveItem(activeItem)
        for _, item in pairs(self.scriptItems) do
            item.BackgroundColor3 = self.theme.Colors.Tertiary
        end
        activeItem.BackgroundColor3 = self.theme.Colors.Accent
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
        self.outputManager:LogError("已删除: " .. name)
        self:UpdateCanvasSize()
    end
    
    function self:SaveScript(name, code)
        local isValid, error = self.utils:ValidateScriptName(name)
        if not isValid then
            self.outputManager:LogError(error)
            return false
        end
        
        -- 检查重名
        for _, script in ipairs(self.savedData.Scripts) do
            if script.name == name then
                self.outputManager:LogError("名称已存在！")
                return false
            end
        end
        
        table.insert(self.savedData.Scripts, {name = name, code = code})
        self:SaveData()
        self:CreateScriptItem(name, code)
        self.currentScript = {name = name, code = code}
        
        if self.currentScriptLabel then
            self.currentScriptLabel.Text = name
        end
        
        self.outputManager:LogSuccess("已保存: " .. name)
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
            self.outputManager:LogSuccess("已导出 " .. #self.savedData.Scripts .. " 个脚本到剪贴板")
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
            self.outputManager:LogSuccess("已导入 " .. imported .. " 个脚本")
        else
            self.outputManager:LogWarning("没有新脚本导入")
        end
    end
    
    function self:NewScript()
        self.currentScript = nil
        if self.currentScriptLabel then
            self.currentScriptLabel.Text = "未命名"
        end
        
        if self.onNewScript then
            self.onNewScript()
        end
        
        self.outputManager:LogSuccess("新建脚本")
    end
    
    function self:UpdateCanvasSize()
        if self.scriptListScroll and self.scriptListLayout then
            self.scriptListScroll.CanvasSize = UDim2.new(0, 0, 0, self.scriptListLayout.AbsoluteContentSize.Y)
        end
    end
    
    function self:SetLoadCallback(callback)
        self.onLoadScript = callback
    end
    
    function self:SetNewCallback(callback)
        self.onNewScript = callback
    end
    
    return self
end

return ScriptManager