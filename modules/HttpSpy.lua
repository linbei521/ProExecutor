--[[
    HTTP请求监控模块
]]

local HttpSpy = {}

function HttpSpy.new(theme, utils, outputManager)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.outputManager = outputManager
    self.active = false
    self.logs = {}
    self.hooks = {}
    self.panels = {}
    
    function self:Setup(panels)
        self.panels = panels or {}
        self.toggleBtn = panels.toggleBtn
        self.statusLabel = panels.statusLabel
        self.logScroll = panels.logScroll
        self.logLayout = panels.logLayout
        self.detailScroll = panels.detailScroll
        self.detailLayout = panels.detailLayout
        self.clearBtn = panels.clearBtn
    end
    
    function self:Start()
        if self.active then return end
        
        self.active = true
        self:UpdateUI()
        
        -- Hook HttpGet
        if not self.hooks.httpGet then
            self.hooks.httpGet = hookfunction(game.HttpGet, function(instance, url, ...)
                self:LogRequest("GET", url)
                return self.hooks.httpGet(instance, url, ...)
            end)
        end
        
        -- Hook HttpGetAsync
        if not self.hooks.httpGetAsync then
            self.hooks.httpGetAsync = hookfunction(game.HttpGetAsync, function(instance, url, ...)
                self:LogRequest("GET ASYNC", url)
                return self.hooks.httpGetAsync(instance, url, ...)
            end)
        end
        
        self.outputManager:LogSuccess("HttpSpy已启动")
    end
    
    function self:Stop()
        if not self.active then return end
        
        self.active = false
        self:UpdateUI()
        
        -- 尝试恢复原始函数
        pcall(function()
            if self.hooks.httpGet then
                hookfunction(game.HttpGet, self.hooks.httpGet)
            end
            if self.hooks.httpGetAsync then
                hookfunction(game.HttpGetAsync, self.hooks.httpGetAsync)
            end
        end)
        
        self.outputManager:LogWarning("HttpSpy已停止")
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
    
    function self:LogRequest(method, url)
        local timestamp = self.utils:FormatTimestamp()
        local log = {
            method = method,
            url = url,
            timestamp = timestamp,
            time = os.time()
        }
        
        table.insert(self.logs, log)
        
        -- 添加到简要日志
        if self.logScroll then
            local entry = Instance.new("TextButton")
            entry.Size = UDim2.new(1, 0, 0, 16)
            entry.BackgroundTransparency = 1
            entry.Text = method
            entry.TextColor3 = self.theme.Colors.Success
            entry.TextSize = 8
            entry.Font = Enum.Font.Code
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.TextTruncate = Enum.TextTruncate.AtEnd
            entry.LayoutOrder = #self.logs
            entry.BorderSizePixel = 0
            entry.Parent = self.logScroll
            
            -- 悬停效果
            entry.MouseEnter:Connect(function()
                entry.BackgroundTransparency = 0.9
                entry.BackgroundColor3 = self.theme.Colors.Tertiary
            end)
            
            entry.MouseLeave:Connect(function()
                entry.BackgroundTransparency = 1
            end)
            
            -- 点击显示详情
            entry.MouseButton1Click:Connect(function()
                self:ShowLogDetail(log)
            end)
        end
        
        -- 添加到详细日志
        if self.detailScroll then
            local detailEntry = Instance.new("TextLabel")
            detailEntry.Size = UDim2.new(1, 0, 0, 0)
            detailEntry.AutomaticSize = Enum.AutomaticSize.Y
            detailEntry.BackgroundTransparency = 1
            detailEntry.Text = string.format("[%s] %s: %s", timestamp, method, tostring(url))
            detailEntry.TextColor3 = self.theme.Colors.Text
            detailEntry.TextSize = 10
            detailEntry.Font = Enum.Font.Code
            detailEntry.TextXAlignment = Enum.TextXAlignment.Left
            detailEntry.TextWrapped = true
            detailEntry.LayoutOrder = #self.logs
            detailEntry.Parent = self.detailScroll
        end
        
        self:UpdateScrolls()
    end
    
    function self:ShowLogDetail(log)
        -- 在输出面板显示详细信息
        self.outputManager:LogInfo(string.format("[%s] %s\n%s", log.timestamp, log.method, log.url))
    end
    
    function self:UpdateScrolls()
        if self.logScroll and self.logLayout then
            self.logScroll.CanvasSize = UDim2.new(0, 0, 0, self.logLayout.AbsoluteContentSize.Y)
            self.logScroll.CanvasPosition = Vector2.new(0, self.logLayout.AbsoluteContentSize.Y)
        end
        
        if self.detailScroll and self.detailLayout then
            self.detailScroll.CanvasSize = UDim2.new(0, 0, 0, self.detailLayout.AbsoluteContentSize.Y)
            self.detailScroll.CanvasPosition = Vector2.new(0, self.detailLayout.AbsoluteContentSize.Y)
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
        
        -- 清除数据
        self.logs = {}
        
        -- 重置滚动
        if self.logScroll then
            self.logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        end
        if self.detailScroll then
            self.detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        end
        
        self.outputManager:LogWarning("HTTP日志已清除")
    end
    
    function self:Destroy()
        if self.active then
            self:Stop()
        end
        self.logs = {}
        self.panels = {}
    end
    
    return self
end

return HttpSpy