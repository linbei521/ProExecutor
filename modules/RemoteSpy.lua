--[[
    远程调用监控模块 - 基于SimpleSpy v3
]]

local RemoteSpy = {}

function RemoteSpy.new(theme, utils, outputManager)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.outputManager = outputManager
    self.active = false
    self.logs = {}
    self.panels = {}
    self.blacklist = {}
    self.blocklist = {}
    self.selected = nil
    
    -- SimpleSpy核心变量
    self.originalNamecall = nil
    self.originalFireServer = nil
    self.originalInvokeServer = nil
    self.originalUnreliableFireServer = nil
    self.connections = {}
    self.remoteLogs = {}
    self.layoutOrderNum = 999999999
    self.maxRemotes = 300
    self.funcEnabled = true
    self.logCheckCaller = false
    self.autoBlock = false
    self.advancedInfo = false
    
    -- autoblock variables
    self.history = {}
    self.excluding = {}
    
    -- 服务
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    
    -- 核心函数
    local function cloneRef(obj)
        return cloneref and cloneref(obj) or obj
    end
    
    local function safeGetService(service)
        return cloneRef(game:GetService(service))
    end
    
    local function getDebugId(obj)
        return game.GetDebugId(game, obj)
    end
    
    local function isLClosure(func)
        return islclosure and islclosure(func) or false
    end
    
    local function getCallingScript()
        return getcallingscript and getcallingscript() or nil
    end
    
    local function checkCaller()
        return checkcaller and checkcaller() or false
    end
    
    -- 深拷贝函数
    local function deepClone(original, copies)
        copies = copies or {}
        local copy
        if type(original) == 'table' then
            if copies[original] then
                copy = copies[original]
            else
                copy = {}
                copies[original] = copy
                for key, value in next, original do
                    copy[deepClone(key, copies)] = deepClone(value, copies)
                end
            end
        elseif typeof(original) == "Instance" then
            copy = cloneRef(original)
        else
            copy = original
        end
        return copy
    end
    
    -- 检查循环表
    local function isCyclicTable(tbl)
        local checkedTables = {}
        local function searchTable(t)
            table.insert(checkedTables, t)
            for i, v in next, t do
                if type(v) == "table" then
                    return table.find(checkedTables, v) and true or searchTable(v)
                end
            end
        end
        return searchTable(tbl)
    end
    
    -- 值转字符串
    local function valueToString(value, indent)
        indent = indent or 0
        local valueType = typeof(value)
        local indentStr = string.rep("    ", indent)
        
        if valueType == "string" then
            return '"' .. value:gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\t', '\\t') .. '"'
        elseif valueType == "number" or valueType == "boolean" then
            return tostring(value)
        elseif valueType == "table" then
            if indent > 5 then return "{...}" end -- 防止过深嵌套
            local str = "{\n"
            local count = 0
            for k, v in pairs(value) do
                count = count + 1
                if count > 50 then
                    str = str .. indentStr .. "    -- ... (truncated)\n"
                    break
                end
                local keyStr = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or ("[" .. valueToString(k) .. "]")
                str = str .. indentStr .. "    " .. keyStr .. " = " .. valueToString(v, indent + 1) .. ",\n"
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
        elseif valueType == "UDim2" then
            return "UDim2.new(" .. value.X.Scale .. ", " .. value.X.Offset .. ", " .. value.Y.Scale .. ", " .. value.Y.Offset .. ")"
        else
            return "nil --[[" .. valueType .. "]]"
        end
    end
    
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
        self:HookRemotes()
        
        self.outputManager:LogSuccess("SimpleSpy已启动")
    end
    
    function self:Stop()
        if not self.active then return end
        
        self.active = false
        self:UpdateUI()
        self:UnhookRemotes()
        
        self.outputManager:LogWarning("SimpleSpy已停止")
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
        -- 获取原始函数
        local mt = getrawmetatable(game)
        self.originalNamecall = mt.__namecall
        
        -- 创建新的namecall hook
        local newNamecall = newcclosure(function(...)
            local method = getnamecallmethod()
            local args = {...}
            local remote = args[1]
            
            if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
                if typeof(remote) == 'Instance' and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent")) then
                    if not self.logCheckCaller and checkCaller() then
                        return self.originalNamecall(...)
                    end
                    
                    local id = getDebugId(remote)
                    local isBlocked = self:CheckTable(self.blocklist, remote, id)
                    local callArgs = {select(2, ...)}
                    
                    if not self:CheckTable(self.blacklist, remote, id) and not isCyclicTable(callArgs) then
                        local data = {
                            method = method,
                            remote = remote,
                            args = deepClone(callArgs),
                            callingScript = getCallingScript(),
                            metamethod = "__namecall",
                            blocked = isBlocked,
                            id = id,
                            timestamp = os.time()
                        }
                        
                        if self.funcEnabled then
                            data.functionInfo = debug.info(2, "f")
                        end
                        
                        self:LogRemote(method, data)
                    end
                    
                    if isBlocked then return end
                end
            end
            
            return self.originalNamecall(...)
        end)
        
        -- Hook namecall
        if hookmetamethod then
            hookmetamethod(game, "__namecall", newNamecall)
        else
            setreadonly(mt, false)
            mt.__namecall = newNamecall
            setreadonly(mt, true)
        end
        
        -- Hook 各种RemoteEvent方法
        if hookfunction then
            self.originalFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(remote, ...)
                return self:HandleRemoteCall("FireServer", remote, ...)
            end)
            
            self.originalInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(remote, ...)
                return self:HandleRemoteCall("InvokeServer", remote, ...)
            end)
            
            self.originalUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, function(remote, ...)
                return self:HandleRemoteCall("FireServer", remote, ...)
            end)
        end
    end
    
    function self:HandleRemoteCall(method, remote, ...)
        if not self.logCheckCaller and checkCaller() then
            if method == "FireServer" then
                return self.originalFireServer(remote, ...)
            elseif method == "InvokeServer" then
                return self.originalInvokeServer(remote, ...)
            end
        end
        
        local id = getDebugId(remote)
        local isBlocked = self:CheckTable(self.blocklist, remote, id)
        local args = {...}
        
        if not self:CheckTable(self.blacklist, remote, id) and not isCyclicTable(args) then
            local data = {
                method = method,
                remote = remote,
                args = deepClone(args),
                callingScript = getCallingScript(),
                metamethod = "hookfunction",
                blocked = isBlocked,
                id = id,
                timestamp = os.time()
            }
            
            if self.funcEnabled then
                data.functionInfo = debug.info(2, "f")
            end
            
            self:LogRemote(method, data)
        end
        
        if isBlocked then return end
        
        if method == "FireServer" then
            return self.originalFireServer(remote, ...)
        elseif method == "InvokeServer" then
            return self.originalInvokeServer(remote, ...)
        end
    end
    
    function self:CheckTable(tbl, remote, id)
        return tbl[id] or tbl[remote] or tbl[remote.Name]
    end
    
    function self:UnhookRemotes()
        if self.originalNamecall then
            local mt = getrawmetatable(game)
            if hookmetamethod then
                hookmetamethod(game, "__namecall", self.originalNamecall)
            else
                setreadonly(mt, false)
                mt.__namecall = self.originalNamecall
                setreadonly(mt, true)
            end
        end
        
        if hookfunction then
            if self.originalFireServer then
                hookfunction(Instance.new("RemoteEvent").FireServer, self.originalFireServer)
            end
            if self.originalInvokeServer then
                hookfunction(Instance.new("RemoteFunction").InvokeServer, self.originalInvokeServer)
            end
            if self.originalUnreliableFireServer then
                hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, self.originalUnreliableFireServer)
            end
        end
    end
    
    function self:LogRemote(method, data)
        -- Auto-block check
        if self.autoBlock then
            local id = data.id
            if self.excluding[id] then return end
            
            if not self.history[id] then
                self.history[id] = {badOccurances = 0, lastCall = tick()}
            end
            
            if tick() - self.history[id].lastCall < 1 then
                self.history[id].badOccurances = self.history[id].badOccurances + 1
                if self.history[id].badOccurances > 3 then
                    self.excluding[id] = true
                    return
                end
            else
                self.history[id].badOccurances = 0
            end
            self.history[id].lastCall = tick()
        end
        
        local timestamp = self.utils:FormatTimestamp()
        local remote = data.remote
        
        local log = {
            method = method,
            remote = remote,
            remoteName = remote.Name,
            remotePath = remote:GetFullName(),
            args = data.args,
            timestamp = timestamp,
            time = data.timestamp,
            callingScript = data.callingScript,
            functionInfo = data.functionInfo,
            metamethod = data.metamethod,
            blocked = data.blocked,
            id = data.id,
            script = "-- 生成中，请稍候..."
        }
        
        table.insert(self.logs, log)
        
        -- 生成脚本
        spawn(function()
            log.script = self:GenerateScript(method, remote, data.args)
            if data.blocked then
                log.script = "-- 此远程调用已被SimpleSpy阻止\n\n" .. log.script
            end
        end)
        
        -- 添加到侧边栏
        if self.logScroll then
            local entry = Instance.new("TextButton")
            entry.Size = UDim2.new(1, 0, 0, 20)
            entry.BackgroundColor3 = self.theme.Colors.Background
            entry.BorderSizePixel = 0
            entry.LayoutOrder = self.layoutOrderNum
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
            self.layoutOrderNum = self.layoutOrderNum - 1
        end
        
        -- 清理旧日志
        self:CleanOldLogs()
        self:UpdateScrolls()
    end
    
    function self:CleanOldLogs()
        if #self.remoteLogs > self.maxRemotes then
            for i = 100, #self.remoteLogs do
                local log = self.remoteLogs[i]
                if log.entry then
                    log.entry:Destroy()
                end
            end
            local newLogs = {}
            for i = 1, 100 do
                table.insert(newLogs, self.remoteLogs[i])
            end
            self.remoteLogs = newLogs
        end
    end
    
    function self:SelectLog(log, entry)
        -- 取消之前的选择
        if self.selected and self.selected.entry then
            self.selected.entry.BackgroundColor3 = self.theme.Colors.Background
        end
        
        self.selected = log
        entry.BackgroundColor3 = self.theme.Colors.Accent
        
        -- 显示详细信息和代码
        self:ShowLogDetail(log)
    end
    
    function self:ShowLogDetail(log)
        -- 更新代码框
        if self.codeBox then
            self.codeBox.Text = log.script
        end
        
        -- 清除详细信息
        if self.detailScroll then
            for _, child in ipairs(self.detailScroll:GetChildren()) do
                if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        -- 添加详细信息
        if self.detailScroll then
            self:AddDetailEntry("时间", log.timestamp)
            self:AddDetailEntry("方法", log.method)
            self:AddDetailEntry("远程", log.remoteName)
            self:AddDetailEntry("路径", log.remotePath)
            self:AddDetailEntry("Hook方式", log.metamethod or "unknown")
            
            if log.callingScript then
                self:AddDetailEntry("调用脚本", log.callingScript.Name or "unknown")
            end
            
            -- 显示参数
            if #log.args > 0 then
                self:AddDetailEntry("参数", "")
                for i, arg in ipairs(log.args) do
                    local argStr = valueToString(arg)
                    if #argStr > 100 then
                        argStr = argStr:sub(1, 97) .. "..."
                    end
                    self:AddDetailEntry("  [" .. i .. "]", argStr)
                end
            else
                self:AddDetailEntry("参数", "无")
            end
            
            -- 高级信息
            if self.advancedInfo then
                if log.functionInfo then
                    self:AddDetailEntry("函数信息", "可用")
                end
                self:AddDetailEntry("调试ID", log.id or "unknown")
                self:AddDetailEntry("是否阻止", log.blocked and "是" or "否")
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
        local script = "-- 由SimpleSpy生成\n"
        local remotePath = self:GetRemotePath(remote)
        
        if #args > 0 then
            script = script .. "local args = {\n"
            for i, arg in ipairs(args) do
                script = script .. "    " .. valueToString(arg, 1) .. ",\n"
                if i >= 20 then -- 限制参数数量防止过长
                    script = script .. "    -- ... (还有" .. (#args - 20) .. "个参数)\n"
                    break
                end
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
    
    function self:CopyCode()
        if self.selected and self.selected.script then
            setclipboard(self.selected.script)
            self.outputManager:LogSuccess("代码已复制到剪贴板")
        else
            self.outputManager:LogError("没有选中的远程调用")
        end
    end
    
    function self:RunCode()
        if self.selected then
            local success, result = pcall(function()
                local func = loadstring(self.selected.script)
                if func then
                    return func()
                else
                    error("脚本编译失败")
                end
            end)
            
            if success then
                self.outputManager:LogSuccess("代码执行成功")
                if result ~= nil then
                    self.outputManager:LogInfo("返回值: " .. tostring(result))
                end
            else
                self.outputManager:LogError("执行失败: " .. tostring(result))
            end
        else
            self.outputManager:LogError("没有选中的远程调用")
        end
    end
    
    function self:ExcludeRemote()
        if self.selected then
            self.blacklist[self.selected.id] = true
            self.outputManager:LogWarning("已排除: " .. self.selected.remoteName .. " (ID)")
        else
            self.outputManager:LogError("没有选中的远程调用")
        end
    end
    
    function self:BlockRemote()
        if self.selected then
            self.blocklist[self.selected.id] = true
            self.outputManager:LogError("已阻止: " .. self.selected.remoteName .. " (ID)")
        else
            self.outputManager:LogError("没有选中的远程调用")
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
        self.remoteLogs = {}
        self.selected = nil
        self.history = {}
        self.excluding = {}
        
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
    
    function self:ToggleFuncInfo()
        self.funcEnabled = not self.funcEnabled
        self.outputManager:LogInfo("函数信息: " .. (self.funcEnabled and "已启用" or "已禁用"))
    end
    
    function self:ToggleCheckCaller()
        self.logCheckCaller = not self.logCheckCaller
        self.outputManager:LogInfo("检查调用者: " .. (self.logCheckCaller and "已启用" or "已禁用"))
    end
    
    function self:ToggleAutoBlock()
        self.autoBlock = not self.autoBlock
        self.history = {}
        self.excluding = {}
        self.outputManager:LogInfo("自动阻止: " .. (self.autoBlock and "已启用" or "已禁用"))
    end
    
    function self:ToggleAdvancedInfo()
        self.advancedInfo = not self.advancedInfo
        self.outputManager:LogInfo("高级信息: " .. (self.advancedInfo and "已启用" or "已禁用"))
    end
    
    function self:Destroy()
        if self.active then
            self:Stop()
        end
        
        -- 清理所有连接
        for _, connection in pairs(self.connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        
        self.logs = {}
        self.remoteLogs = {}
        self.panels = {}
        self.blacklist = {}
        self.blocklist = {}
        self.history = {}
        self.excluding = {}
    end
    
    return self
end

return RemoteSpy