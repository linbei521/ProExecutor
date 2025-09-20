--[[
    ProExecutor 主程序 - 优化版
    性能增强 + 用户体验优化
]]

-- 获取模块和配置
local Theme = modules.Theme
local Storage = modules.Storage  
local Utils = modules.Utils
local Editor = modules.Editor
local OutputManager = modules.OutputManager
local ScriptManager = modules.ScriptManager
local AutoComplete = modules.AutoComplete
local CodeExecutor = modules.CodeExecutor
local UI = modules.UI

-- 应用配置和性能统计
local Config = config
local VersionInfo = versionInfo
local PerformanceStats = performanceStats

-- 服务
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- 性能监控器
local PerformanceMonitor = {
    frameCount = 0,
    renderTime = 0,
    lastFrameTime = tick(),
    memoryUsage = {}
}

function PerformanceMonitor:Update()
    local now = tick()
    local deltaTime = now - self.lastFrameTime
    self.lastFrameTime = now
    self.frameCount = self.frameCount + 1
    self.renderTime = self.renderTime + deltaTime
    
    -- 内存监控
    if self.frameCount % 60 == 0 then -- 每60帧检查一次
        table.insert(self.memoryUsage, {
            time = now,
            memory = gcinfo()
        })
        
        -- 保留最近100个样本
        if #self.memoryUsage > 100 then
            table.remove(self.memoryUsage, 1)
        end
    end
end

function PerformanceMonitor:GetFPS()
    if self.frameCount < 60 then return 0 end
    return math.floor(60 / (self.renderTime / 60))
end

function PerformanceMonitor:GetMemoryTrend()
    if #self.memoryUsage < 2 then return 0 end
    local first = self.memoryUsage[1].memory
    local last = self.memoryUsage[#self.memoryUsage].memory
    return last - first
end

-- 防抖工具
local function Debounce(func, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

-- 主应用类
local ProExecutor = {}
ProExecutor.__index = ProExecutor

function ProExecutor.new()
    local self = setmetatable({}, ProExecutor)
    
    -- 初始化模块
    self.theme = Theme
    self.storage = Storage
    self.utils = Utils
    self.config = Config
    self.version = VersionInfo
    self.performance = PerformanceStats
    
    -- 性能优化设置
    self.animations = {
        enabled = Config.performance.enableAnimations,
        duration = Config.performance.enableAnimations and 0.3 or 0.1,
        easing = Enum.EasingStyle.Quad
    }
    
    -- 创建管理器实例
    self.outputManager = OutputManager.new(self.theme, self.utils, {
        maxLines = Config.performance.maxOutputLines,
        enableAnimations = self.animations.enabled
    })
    self.codeExecutor = CodeExecutor.new(self.outputManager)
    self.ui = UI.new(self.theme, self.utils, self.config)
    
    -- 状态变量
    self.minimized = false
    self.originalSize = nil
    self.currentScript = nil
    self.lastAutoCompleteWord = ""
    self.isDestroyed = false
    
    -- 防抖函数
    self.debouncedSave = Debounce(function() self:AutoSave() end, 2)
    self.debouncedAutoComplete = Debounce(function(word) self:HandleAutoComplete(word) end, 0.3)
    
    -- 性能监控连接
    self.performanceConnection = RunService.Heartbeat:Connect(function()
        PerformanceMonitor:Update()
    end)
    
    -- 自动保存定时器
    if Config.performance.autoSaveInterval > 0 then
        self.autoSaveConnection = RunService.Heartbeat:Connect(function()
            if tick() % Config.performance.autoSaveInterval < 0.1 then
                self.debouncedSave()
            end
        end)
    end
    
    -- 初始化应用
    self:Initialize()
    
    return self
end

function ProExecutor:Initialize()
    -- 显示启动动画
    self:ShowStartupAnimation()
    
    self:CreateUI()
    self:SetupEventHandlers()
    self:SetupKeyboardShortcuts()
    self:LoadInitialData()
    self:StartPerformanceMonitoring()
    
    -- 显示启动信息
    self.outputManager:LogSuccess("🚀 ProExecutor 优化版启动成功")
    self.outputManager:LogInfo("📊 加载统计: " .. self:FormatPerformanceStats())
    self.outputManager:LogInfo("🎨 UI优化: " .. (self.animations.enabled and "动画已启用" or "轻量模式"))
    self.outputManager:LogInfo("📋 版本: " .. (self.version.version or "unknown"))
end

function ProExecutor:FormatPerformanceStats()
    return string.format("模块:%d | 效率:%.1f%% | 用时:%.2fs", 
        self.performance.moduleCount, 
        self.performance.efficiency, 
        self.performance.totalTime)
end

function ProExecutor:ShowStartupAnimation()
    if not self.animations.enabled then return end
    
    -- 创建启动动画
    local animGui = Instance.new("ScreenGui")
    animGui.Name = "ProExecutorStartup"
    animGui.Parent = game:GetService("CoreGui")
    
    local animFrame = Instance.new("Frame")
    animFrame.Size = UDim2.new(0, 200, 0, 100)
    animFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
    animFrame.BackgroundColor3 = self.theme.Colors.Accent
    animFrame.BorderSizePixel = 0
    animFrame.Parent = animGui
    
    self.theme:CreateCorner(12).Parent = animFrame
    
    local animText = Instance.new("TextLabel")
    animText.Size = UDim2.new(1, 0, 1, 0)
    animText.BackgroundTransparency = 1
    animText.Text = "⚡ ProExecutor"
    animText.TextColor3 = Color3.fromRGB(255, 255, 255)
    animText.TextSize = 18
    animText.Font = Enum.Font.SourceSansBold
    animText.Parent = animFrame
    
    -- 动画序列
    local sequence = {
        {target = animFrame, props = {Size = UDim2.new(0, 250, 0, 120)}, duration = 0.3},
        {target = animText, props = {TextTransparency = 0.2}, duration = 0.2},
        {target = animFrame, props = {Size = UDim2.new(0, 0, 0, 0)}, duration = 0.4, delay = 1},
    }
    
    local function playSequence(index)
        if index > #sequence or self.isDestroyed then
            animGui:Destroy()
            return
        end
        
        local step = sequence[index]
        local info = TweenInfo.new(step.duration, self.animations.easing)
        
        if step.delay then
            wait(step.delay)
        end
        
        local tween = TweenService:Create(step.target, info, step.props)
        tween:Play()
        
        tween.Completed:Connect(function()
            playSequence(index + 1)
        end)
    end
    
    spawn(function()
        wait(0.1)
        playSequence(1)
    end)
end

function ProExecutor:CreateUI()
    -- 检查设备信息
    local device = self.config.device
    
    -- 创建主界面
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "ProExecutor"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = game:GetService("CoreGui")
    
    -- 响应式窗口大小
    local windowSize = self.config.windowSize
    if device.screenSize.X < 800 then -- 小屏幕适配
        windowSize = {math.min(windowSize[1], device.screenSize.X * 0.9), 
                     math.min(windowSize[2], device.screenSize.Y * 0.8)}
    end
    
    -- 主窗口
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, windowSize[1], 0, windowSize[2])
    self.mainFrame.Position = UDim2.new(0.5, -windowSize[1]/2, 0.5, -windowSize[2]/2)
    self.mainFrame.BackgroundColor3 = self.theme.Colors.Background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.ClipsDescendants = true
    self.mainFrame.Active = true
    self.mainFrame.Parent = self.screenGui
    
    self.originalSize = self.mainFrame.Size
    self.theme:CreateCorner(8).Parent = self.mainFrame
    self.theme:CreateBorder(1).Parent = self.mainFrame
    
    -- 阴影效果
    if self.animations.enabled then
        local shadow = Instance.new("ImageLabel")
        shadow.Size = UDim2.new(1, 20, 1, 20)
        shadow.Position = UDim2.new(0, -10, 0, -10)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxasset://textures/ui/Controls/DropShadow.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.7
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(12, 12, 12, 12)
        shadow.ZIndex = -1
        shadow.Parent = self.mainFrame
    end
    
    -- 创建UI组件
    self:CreateTopBar()
    self:CreateMainContainer()
    self:CreateSidePanel()
    self:CreateEditorArea()
    self:CreateAutoComplete()
    self:CreatePerformanceOverlay()
    
    -- 设置拖拽
    self:SetupDragging()
    
    -- 窗口大小适配完成动画
    if self.animations.enabled then
        self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
        local openTween = TweenService:Create(self.mainFrame, 
            TweenInfo.new(self.animations.duration, self.animations.easing),
            {Size = self.originalSize}
        )
        openTween:Play()
    end
end

function ProExecutor:CreatePerformanceOverlay()
    if not self.config.device.isMobile then -- 桌面端显示性能信息
        self.performanceOverlay = Instance.new("TextLabel")
        self.performanceOverlay.Size = UDim2.new(0, 120, 0, 40)
        self.performanceOverlay.Position = UDim2.new(1, -125, 0, 5)
        self.performanceOverlay.BackgroundColor3 = self.theme.Colors.Background
        self.performanceOverlay.BackgroundTransparency = 0.3
        self.performanceOverlay.TextColor3 = self.theme.Colors.TextDim
        self.performanceOverlay.TextSize = 8
        self.performanceOverlay.Font = Enum.Font.Code
        self.performanceOverlay.TextYAlignment = Enum.TextYAlignment.Top
        self.performanceOverlay.Text = "FPS: --\nMEM: --KB"
        self.performanceOverlay.Parent = self.screenGui
        
        self.theme:CreateCorner(4).Parent = self.performanceOverlay
    end
end

function ProExecutor:StartPerformanceMonitoring()
    if self.performanceOverlay then
        spawn(function()
            while not self.isDestroyed and self.performanceOverlay.Parent do
                wait(1) -- 每秒更新一次
                
                local fps = PerformanceMonitor:GetFPS()
                local memory = math.floor(gcinfo())
                local memoryTrend = PerformanceMonitor:GetMemoryTrend()
                
                local trendIcon = ""
                if memoryTrend > 50 then
                    trendIcon = " ↗"
                elseif memoryTrend < -50 then
                    trendIcon = " ↘"
                end
                
                self.performanceOverlay.Text = string.format("FPS: %d\nMEM: %dKB%s", 
                    fps, memory, trendIcon)
                
                -- 性能警告
                if fps < 30 then
                    self.performanceOverlay.TextColor3 = self.theme.Colors.Warning
                elseif fps < 20 then
                    self.performanceOverlay.TextColor3 = self.theme.Colors.Error
                else
                    self.performanceOverlay.TextColor3 = self.theme.Colors.TextDim
                end
            end
        end)
    end
end

-- 继续之前的UI创建方法，但添加性能优化...
function ProExecutor:CreateTopBar()
    self.topBar = Instance.new("Frame")
    self.topBar.Name = "TopBar"
    self.topBar.Size = UDim2.new(1, 0, 0, 28)
    self.topBar.BackgroundColor3 = self.theme.Colors.Secondary
    self.topBar.BorderSizePixel = 0
    self.topBar.Active = true
    self.topBar.Parent = self.mainFrame
    
    self.theme:CreateCorner(8).Parent = self.topBar
    
    local topBarFix = Instance.new("Frame")
    topBarFix.Size = UDim2.new(1, 0, 0, 10)
    topBarFix.Position = UDim2.new(0, 0, 1, -10)
    topBarFix.BackgroundColor3 = self.theme.Colors.Secondary
    topBarFix.BorderSizePixel = 0
    topBarFix.Parent = self.topBar
    
    -- 标题 + 性能指示器
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.3, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ProExecutor"
    title.TextColor3 = self.theme.Colors.Text
    title.TextSize = 13
    title.Font = Enum.Font.SourceSansSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.topBar
    
    -- 优化指示器
    local optimizationBadge = Instance.new("TextLabel")
    optimizationBadge.Size = UDim2.new(0, 40, 0, 16)
    optimizationBadge.Position = UDim2.new(0, 100, 0.5, -8)
    optimizationBadge.BackgroundColor3 = self.theme.Colors.Success
    optimizationBadge.Text = "OPT"
    optimizationBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    optimizationBadge.TextSize = 8
    optimizationBadge.Font = Enum.Font.SourceSansBold
    optimizationBadge.Parent = self.topBar
    self.theme:CreateCorner(3).Parent = optimizationBadge
    
    -- 存储状态指示器
    local storageIndicator = Instance.new("TextLabel")
    storageIndicator.Size = UDim2.new(0, 50, 0, 16)
    storageIndicator.Position = UDim2.new(0.5, -25, 0.5, -8)
    storageIndicator.BackgroundColor3 = self.storage:HasFileSupport() and self.theme.Colors.Success or self.theme.Colors.Warning
    storageIndicator.Text = self.storage:HasFileSupport() and "文件" or "内存"
    storageIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
    storageIndicator.TextSize = 10
    storageIndicator.Font = Enum.Font.SourceSans
    storageIndicator.Parent = self.topBar
    self.theme:CreateCorner(4).Parent = storageIndicator
    
    -- 控制按钮
    self:CreateControlButtons()
end

function ProExecutor:CreateControlButtons()
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 56, 1, 0)
    controlsFrame.Position = UDim2.new(1, -56, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = self.topBar
    
    self.minimizeBtn = Instance.new("TextButton")
    self.minimizeBtn.Size = UDim2.new(0, 28, 1, 0)
    self.minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
    self.minimizeBtn.BackgroundTransparency = 1
    self.minimizeBtn.Text = "_"
    self.minimizeBtn.TextColor3 = self.theme.Colors.TextDim
    self.minimizeBtn.TextSize = 14
    self.minimizeBtn.Font = Enum.Font.SourceSansBold
    self.minimizeBtn.Parent = controlsFrame
    
    self.closeBtn = Instance.new("TextButton")
    self.closeBtn.Size = UDim2.new(0, 28, 1, 0)
    self.closeBtn.Position = UDim2.new(0, 28, 0, 0)
    self.closeBtn.BackgroundTransparency = 1
    self.closeBtn.Text = "X"
    self.closeBtn.TextColor3 = self.theme.Colors.TextDim
    self.closeBtn.TextSize = 14
    self.closeBtn.Font = Enum.Font.SourceSansBold
    self.closeBtn.Parent = controlsFrame
    
    -- 悬停效果
    if self.animations.enabled then
        self.theme:AddHoverEffect(self.minimizeBtn, Color3.fromRGB(255, 193, 7))
        self.theme:AddHoverEffect(self.closeBtn, self.theme.Colors.Error)
    end
end

-- 其余方法继续沿用之前的实现，但添加性能优化...

function ProExecutor:AutoSave()
    if self.currentScript and self.editor then
        local code = self.editor:GetText()
        if code and code ~= self.currentScript.code then
            -- 静默保存到临时存储
            local tempData = self.storage:Load()
            for i, script in ipairs(tempData.Scripts) do
                if script.name == self.currentScript.name then
                    script.code = code
                    script.lastModified = tick()
                    break
                end
            end
            self.storage:Save(tempData)
        end
    end
end

function ProExecutor:HandleAutoComplete(word)
    if self.autoComplete and #word > 2 then
        local position = UDim2.new(0, self.mainFrame.Position.X.Offset + 140, 0, self.mainFrame.Position.Y.Offset + 100)
        self.autoComplete:Show(word, position)
    elseif self.autoComplete then
        self.autoComplete:Hide()
    end
end

function ProExecutor:Destroy()
    self.isDestroyed = true
    
    -- 断开连接
    if self.performanceConnection then
        self.performanceConnection:Disconnect()
    end
    if self.autoSaveConnection then
        self.autoSaveConnection:Disconnect()
    end
    
    -- 最终保存
    self:AutoSave()
    
    -- 销毁UI
    if self.animations.enabled and self.mainFrame then
        local closeTween = TweenService:Create(self.mainFrame,
            TweenInfo.new(self.animations.duration, self.animations.easing),
            {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
        )
        closeTween:Play()
        closeTween.Completed:Connect(function()
            self.screenGui:Destroy()
        end)
    else
        self.screenGui:Destroy()
    end
    
    -- 性能报告
    local memoryUsed = gcinfo()
    self.outputManager:LogInfo(string.format("📊 会话结束 | 内存使用: %.1fKB | FPS: %d", 
        memoryUsed, PerformanceMonitor:GetFPS()))
end

-- 继续实现其他方法，基本保持原有逻辑但添加性能优化...
-- [这里继续添加其他必要的方法，保持与之前版本的兼容性]

-- 启动应用
local app = ProExecutor.new()

-- 全局访问和清理
_G.ProExecutor = app
_G.ProExecutorStats = PerformanceStats

-- 清理函数
game:BindToClose(function()
    if app and not app.isDestroyed then
        app:Destroy()
    end
end)

print("ProExecutor 优化版启动完成! 🚀")