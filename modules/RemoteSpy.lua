--[[
    远程调用监控模块
]]

local RemoteSpy = {}

function RemoteSpy.new(theme, utils, outputManager)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.outputManager = outputManager
    self.active = false
    self.logs = {}
    self.hooks = {}
    self.panels = {}
    self.blacklist = {}
    self.blocklist = {}
    self.selected = nil
    
    -- SimpleSpy核心功能
    self.originalNamecall = nil
    self.originalFireServer = nil
    self.originalInvokeServer = nil
    
    function self:Setup(panels)
        self.panels = panels or {}
        self.toggleBtn = panels.toggleBtn
        self.statusLabel = panels.statusLabel
        self.logScroll = panels.logScroll
        self.logLayout = panels.logLayout
        self.detailScroll = panels.detailScroll
        self.detailLayout = panels.detailLayout
        self.clearBtn = panels.clearBtn
        self.codeBox = panels.codeBox
        self.copyBtn = panels.copyBtn
        self.runBtn = panels.runBtn
        self.blockBtn = panels.blockBtn
        self.excludeBtn = panels.excludeBtn
    end
    
    function self:Start()
        if self.active then return end
        
        self.active = true
        self:UpdateUI()
        
        -- Hook远程调用
        self:HookRemotes()
        
        self.outputManager:LogSuccess("RemoteSpy已启动")
    end
    
    function self:Stop()
        if not self.active then return end
        
        self.active = false
        self:UpdateUI()
        
        -- 恢复原始函数
        self:UnhookRemotes()
        
        self.outputManager:LogWarning("RemoteSpy已停止")
    end
    
    function self:Toggle()
        if self.active then
            self:Stop()
        else
            self:Start()
        end
    end
    
    function self:UpdateUI()
        if self.toggleBtn then
            self.toggleBtn.Text = self.active and "关闭" or "开启"
            self.toggleBtn.BackgroundColor3 = self.active and self.theme.Colors.Error or self.theme.Colors.Success
        end
        
        if self.statusLabel then
            self.statusLabel.Text = self.active and "监控中" or "已停止"
            self.statusLabel.TextColor3 = self.active and self.theme.Colors.Success or self.theme.Colors.TextDim
        end
    end
    
    function self:HookRemotes()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        -- 保存原始函数
        self.originalNamecall = oldNamecall
        self.originalFireServer = Instance.new("RemoteEvent").FireServer
        self.originalInvokeServer = Instance.new("RemoteFunction").InvokeServer
        
        -- Hook namecall
        mt.__namecall = newcclosure(function(...)
            local method = getnamecallmethod()
            local args = {...}
            local remote = args[1]
            
            if method == "FireServer" or method == "InvokeServer" then
                if typeof(remote) == "Instance" and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                    -- 检查黑名单
                    if not self.blacklist[remote] and not self.blacklist[remote.Name] then
                        -- 记录调用
                        self:LogRemote(method, remote, {select(2, ...)})
                        
                        -- 检查阻止列表
                        if self.blocklist[remote] or self.blocklist[remote.Name] then
                            return nil -- 阻止调用
                        end
                    end
                end
            end
            
            return oldNamecall(...)
        end)
        
        setreadonly(mt, true)
        
        -- Hook RemoteEvent.FireServer
        if hookfunction then
            hookfunction(self.originalFireServer, function(remote, ...)
                if not self.blacklist[remote] and not self.blacklist[remote.Name] then
                    self:LogRemote("FireServer", remote, {...})
                    
                    if self.blocklist[remote] or self.blocklist[remote.Name] then
                        return nil
                    end
                end
                return self.originalFireServer(remote, ...)
            end)
            
            -- Hook RemoteFunction.InvokeServer
            hookfunction(self.originalInvokeServer, function(remote, ...)
                if not self.blacklist[remote] and not self.blacklist[remote.Name] then
                    self:LogRemote("InvokeServer", remote, {...})
                    
                    if self.blocklist[remote] or self.blocklist[remote.Name] then
                        return nil
                    end
                end
                return self.originalInvokeServer(remote, ...)
            end)
        end
    end
    
    function self:UnhookRemotes()
        if self.originalNamecall then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = self.originalNamecall
            setreadonly(mt, true)
        end
        
        -- 恢复hook的函数
        if hookfunction and self.originalFireServer then
            pcall(function()
                hookfunction(Instance.new("RemoteEvent").FireServer, self.originalFireServer)
            end)
        end
        
        if hookfunction and self.originalInvokeServer then
            pcall(function()
                hookfunction(Instance.new("RemoteFunction").InvokeServer, self.originalInvokeServer)
            end)
        end
    end
    
    function self:LogRemote(method, remote, args)
        local timestamp = self.utils:FormatTimestamp()
        local log = {
            method = method,
            remote = remote,
            remoteName = remote.Name,
            remotePath = remote:GetFullName(),
            args = args,
            timestamp = timestamp,
            time = os.time(),
            script = self:GenerateScript(method, remote, args)
        }
        
        table.insert(self.logs, log)
        
        -- 添加到侧边栏简要日志
        if self.logScroll then
            local entry = Instance.new("TextButton")
            entry.Size = UDim2.new(1, 0, 0, 20)
            entry.BackgroundColor3 = self.theme.Colors.Background
            entry.BorderSizePixel = 0
            entry.LayoutOrder = #self.logs
            entry.Parent = self.logScroll
            
            local methodLabel = Instance.new("TextLabel")
            methodLabel.Size = UDim2.new(0, 40, 1, 0)
            methodLabel.BackgroundTransparency = 1
            methodLabel.Text = method == "FireServer" and "Fire" or "Invoke"
            methodLabel.TextColor3 = method == "FireServer" and self.theme.Colors.Warning or self.theme.Colors.Accent
            methodLabel.TextSize = 8
            methodLabel.Font = Enum.Font.Code
            methodLabel.TextXAlignment = Enum.TextXAlignment.Left
            methodLabel.Parent = entry
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -40, 1, 0)
            nameLabel.Position = UDim2.new(0, 40, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = remote.Name
            nameLabel.TextColor3 = self.theme.Colors.Text
            nameLabel.TextSize = 8
            nameLabel.Font = Enum.Font.Code
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = entry
            
            -- 悬停效果
            entry.MouseEnter:Connect(function()
                entry.BackgroundColor3 = self.theme.Colors.Tertiary
            end)
            
            entry.MouseLeave:Connect(function()
                entry.BackgroundColor3 = self.selected == log and self.theme.Colors.Accent or self.theme.Colors.Background
            end)
            
            -- 点击选择
            entry.MouseButton1Click:Connect(function()
                self:SelectLog(log, entry)
            end)
            
            log.entry = entry
        end
        
        self:UpdateScrolls()
    end
    
    function self:SelectLog(log, entry)
        -- 取消之前的选择
        if self.selected and self.selected.entry then
            self.selected.entry.BackgroundColor3 = self.theme.Colors.Background
        end
        
        self.selected = log
        entry.BackgroundColor3 = self.theme.Colors.Accent
        
        -- 显示详细信息
        self:ShowLogDetail(log)
    end
    
    function self:ShowLogDetail(log)
        -- 清除详细日志
        if self.detailScroll then
            for _, child in ipairs(self.detailScroll:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        -- 更新代码框
        if self.codeBox then
            self.codeBox.Text = log.script
        end
        
        -- 添加详细信息
        if self.detailScroll then
            self:AddDetailEntry("时间", log.timestamp)
            self:AddDetailEntry("方法", log.method)
            self:AddDetailEntry("远程", log.remoteName)
            self:AddDetailEntry("路径", log.remotePath)
            
            -- 显示参数
            if #log.args > 0 then
                self:AddDetailEntry("参数", "")
                for i, arg in ipairs(log.args) do
                    local argStr = self:ValueToString(arg)
                    self:AddDetailEntry("  [" .. i .. "]", argStr)
                end
            else
                self:AddDetailEntry("参数", "无")
            end
        end
        
        self:UpdateScrolls()
    end
    
    function self:AddDetailEntry(label, value)
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, 0, 0, 16)
        entry.BackgroundTransparency = 1
        entry.Parent = self.detailScroll
        
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0, 60, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label .. ":"
        labelText.TextColor3 = self.theme.Colors.TextDim
        labelText.TextSize = 9
        labelText.Font = Enum.Font.Code
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = entry
        
        local valueText = Instance.new("TextLabel")
        valueText.Size = UDim2.new(1, -65, 1, 0)
        valueText.Position = UDim2.new(0, 65, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = tostring(value)
        valueText.TextColor3 = self.theme.Colors.Text
        valueText.TextSize = 9
        valueText.Font = Enum.Font.Code
        valueText.TextXAlignment = Enum.TextXAlignment.Left
        valueText.TextTruncate = Enum.TextTruncate.AtEnd
        valueText.Parent = entry
    end
    
    function self:GenerateScript(method, remote, args)
        local script = "-- Generated by RemoteSpy\n"
        local remotePath = self:GetRemotePath(remote)
        
        if #args > 0 then
            script = script .. "local args = {\n"
            for i, arg in ipairs(args) do
                script = script .. "    " .. self:ValueToString(arg, 1) .. ",\n"
            end
            script = script .. "}\n\n"
            
            if method == "FireServer" then
                script = script .. remotePath .. ":FireServer(unpack(args))"
            else
                script = script .. remotePath .. ":InvokeServer(unpack(args))"
            end
        else
            if method == "FireServer" then
                script = script .. remotePath .. ":FireServer()"
            else
                script = script .. remotePath .. ":InvokeServer()"
            end
        end
        
        return script
    end
    
    function self:GetRemotePath(remote)
        local path = ""
        local current = remote
        
        while current and current.Parent do
            if current.Parent == game then
                if current.ClassName == "Workspace" then
                    path = "workspace" .. path
                else
                    path = 'game:GetService("' .. current.ClassName .. '")' .. path
                end
                break
            else
                if current.Name:match("^[%a_][%w_]*$") then
                    path = "." .. current.Name .. path
                else
                    path = '["' .. current.Name .. '"]' .. path
                end
            end
            current = current.Parent
        end
        
        return path
    end
    
    function self:ValueToString(value, indent)
        indent = indent or 0
        local valueType = typeof(value)
        local indentStr = string.rep("    ", indent)
        
        if valueType == "string" then
            return '"' .. value:gsub('"', '\\"') .. '"'
        elseif valueType == "number" or valueType == "boolean" then
            return tostring(value)
        elseif valueType == "table" then
            local str = "{\n"
            for k, v in pairs(value) do
                str = str .. indentStr .. "    [" .. self:ValueToString(k) .. "] = " .. self:ValueToString(v, indent + 1) .. ",\n"
            end
            return str .. indentStr .. "}"
        elseif valueType == "Instance" then
            return self:GetRemotePath(value)
        elseif valueType == "Vector3" then
            return "Vector3.new(" .. value.X .. ", " .. value.Y .. ", " .. value.Z .. ")"
        elseif valueType == "CFrame" then
            return "CFrame.new(" .. tostring(value) .. ")"
        elseif valueType == "Color3" then
            return "Color3.new(" .. value.R .. ", " .. value.G .. ", " .. value.B .. ")"
        else
            return "nil --[[" .. valueType .. "]]"
        end
    end
    
    function self:CopyCode()
        if self.selected and self.selected.script then
            setclipboard(self.selected.script)
            self.outputManager:LogSuccess("代码已复制到剪贴板")
        end
    end
    
    function self:RunCode()
        if self.selected then
            local success, result = pcall(function()
                loadstring(self.selected.script)()
            end)
            
            if success then
                self.outputManager:LogSuccess("代码执行成功")
            else
                self.outputManager:LogError("执行失败: " .. tostring(result))
            end
        end
    end
    
    function self:ExcludeRemote()
        if self.selected then
            self.blacklist[self.selected.remote] = true
            self.outputManager:LogWarning("已排除: " .. self.selected.remoteName)
        end
    end
    
    function self:BlockRemote()
        if self.selected then
            self.blocklist[self.selected.remote] = true
            self.outputManager:LogError("已阻止: " .. self.selected.remoteName)
        end
    end
    
    function self:UpdateScrolls()
        if self.logScroll and self.logLayout then
            self.logScroll.CanvasSize = UDim2.new(0, 0, 0, self.logLayout.AbsoluteContentSize.Y)
            self.logScroll.CanvasPosition = Vector2.new(0, self.logLayout.AbsoluteContentSize.Y)
        end
        
        if self.detailScroll and self.detailLayout then
            self.detailScroll.CanvasSize = UDim2.new(0, 0, 0, self.detailLayout.AbsoluteContentSize.Y)
        end
    end
    
    function self:Clear()
        -- 清除UI
        if self.logScroll then
            for _, child in ipairs(self.logScroll:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        if self.detailScroll then
            for _, child in ipairs(self.detailScroll:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        if self.codeBox then
            self.codeBox.Text = "-- 选择一个远程调用查看代码"
        end
        
        -- 清除数据
        self.logs = {}
        self.selected = nil
        
        -- 重置滚动
        if self.logScroll then
            self.logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        end
        if self.detailScroll then
            self.detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        end
        
        self.outputManager:LogWarning("远程日志已清除")
    end
    
    function self:ClearBlacklist()
        self.blacklist = {}
        self.outputManager:LogSuccess("排除列表已清除")
    end
    
    function self:ClearBlocklist()
        self.blocklist = {}
        self.outputManager:LogSuccess("阻止列表已清除")
    end
    
    function self:Destroy()
        if self.active then
            self:Stop()
        end
        self.logs = {}
        self.panels = {}
        self.blacklist = {}
        self.blocklist = {}
    end
    
    return self
end

return RemoteSpy