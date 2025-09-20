--[[
    ProExecutor GitHub加载器 - 优化版
    
    使用方法:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/ProExecutor/main/loader.lua"))()
]]

local ProExecutorLoader = {}

-- 配置 - 请替换为你的GitHub用户名
local GITHUB_USER = "linbei521"  -- 改成你的GitHub用户名
local REPO_NAME = "ProExecutor"
local BRANCH = "main"
local GITHUB_BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s", GITHUB_USER, REPO_NAME, BRANCH)

-- 性能监控
local PerformanceMonitor = {
    startTime = tick(),
    loadTimes = {},
    errors = {}
}

function PerformanceMonitor:RecordLoad(moduleName, duration)
    self.loadTimes[moduleName] = duration
end

function PerformanceMonitor:RecordError(context, error)
    table.insert(self.errors, {
        context = context,
        error = tostring(error),
        time = tick()
    })
end

function PerformanceMonitor:GetStats()
    local totalTime = tick() - self.startTime
    local moduleCount = 0
    local totalModuleTime = 0
    
    for name, time in pairs(self.loadTimes) do
        moduleCount = moduleCount + 1
        totalModuleTime = totalModuleTime + time
    end
    
    return {
        totalTime = totalTime,
        moduleCount = moduleCount,
        averageModuleTime = moduleCount > 0 and totalModuleTime / moduleCount or 0,
        errorCount = #self.errors,
        efficiency = totalModuleTime / totalTime * 100
    }
end

-- 模块列表（按依赖顺序）
local MODULES = {
    {name = "Theme", priority = 1},
    {name = "Utils", priority = 1},
    {name = "Storage", priority = 2},
    {name = "OutputManager", priority = 3},
    {name = "Editor", priority = 3},
    {name = "ScriptManager", priority = 4},
    {name = "AutoComplete", priority = 4},
    {name = "CodeExecutor", priority = 4},
    {name = "UI", priority = 5}
}

-- 环境检查
local function validateEnvironment()
    local checks = {
        {name = "Game Service", test = function() return game ~= nil end},
        {name = "HttpService", test = function() return game:GetService("HttpService") ~= nil end},
        {name = "CoreGui", test = function() return game:GetService("CoreGui") ~= nil end},
        {name = "UserInputService", test = function() return game:GetService("UserInputService") ~= nil end}
    }
    
    local failures = {}
    for _, check in ipairs(checks) do
        if not pcall(check.test) then
            table.insert(failures, check.name)
        end
    end
    
    if #failures > 0 then
        error("环境检查失败: " .. table.concat(failures, ", "))
    end
end

-- 高级HTTP请求（带重试和缓存）
local HttpCache = {}
local function httpGetWithRetry(url, maxRetries)
    maxRetries = maxRetries or 3
    
    -- 检查缓存
    if HttpCache[url] then
        return HttpCache[url]
    end
    
    local lastError = nil
    
    for i = 1, maxRetries do
        local success, result = pcall(function()
            return game:HttpGet(url .. "?v=" .. tick()) -- 添加版本参数避免缓存问题
        end)
        
        if success then
            HttpCache[url] = result -- 缓存结果
            return result
        else
            lastError = result
            if i < maxRetries then
                wait(math.min(i * 0.5, 2)) -- 指数退避
            end
        end
    end
    
    PerformanceMonitor:RecordError("HTTP Request", lastError)
    error("HTTP请求失败 (重试" .. maxRetries .. "次): " .. tostring(lastError))
end

-- 设备检测增强
local function detectDevice()
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    
    local device = {
        type = "unknown",
        touchEnabled = UserInputService.TouchEnabled,
        mouseEnabled = UserInputService.MouseEnabled,
        keyboardEnabled = UserInputService.KeyboardEnabled,
        gamepadEnabled = UserInputService.GamepadEnabled,
        screenSize = workspace.CurrentCamera.ViewportSize,
        isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    }
    
    if device.isMobile then
        device.type = "mobile"
    elseif device.mouseEnabled and device.keyboardEnabled then
        device.type = "desktop"
    elseif device.gamepadEnabled then
        device.type = "console"
    end
    
    return device
end

-- 模块加载器（并行加载）
local moduleCache = {}
local loadingPromises = {}

local function loadModule(moduleInfo)
    local moduleName = moduleInfo.name
    
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    -- 检查是否已在加载中
    if loadingPromises[moduleName] then
        return loadingPromises[moduleName]
    end
    
    local startTime = tick()
    local url = GITHUB_BASE .. "/modules/" .. moduleName .. ".lua"
    
    local promise = {
        completed = false,
        result = nil,
        error = nil
    }
    loadingPromises[moduleName] = promise
    
    spawn(function()
        local success, result = pcall(function()
            local response = httpGetWithRetry(url)
            local moduleFunc, compileError = loadstring(response)
            
            if not moduleFunc then
                error("模块 " .. moduleName .. " 编译失败: " .. tostring(compileError))
            end
            
            return moduleFunc()
        end)
        
        local loadTime = tick() - startTime
        PerformanceMonitor:RecordLoad(moduleName, loadTime)
        
        if success then
            moduleCache[moduleName] = result
            promise.result = result
        else
            PerformanceMonitor:RecordError("Module Load: " .. moduleName, result)
            promise.error = result
        end
        
        promise.completed = true
    end)
    
    return promise
end

-- 配置加载器
local function loadConfig()
    local device = detectDevice()
    local configUrl = GITHUB_BASE .. "/configs/" .. device.type .. ".lua"
    
    local success, response = pcall(function()
        return httpGetWithRetry(configUrl)
    end)
    
    if success then
        local configFunc, compileError = loadstring(response)
        if configFunc then
            local config = configFunc()
            config.device = device
            return config
        end
    end
    
    -- 默认配置
    return {
        windowSize = device.isMobile and {340, 400} or {450, 320},
        touchOptimized = device.isMobile,
        device = device,
        performance = {
            enableAnimations = not device.isMobile,
            maxOutputLines = device.isMobile and 30 or 50,
            autoSaveInterval = 30
        }
    }
end

-- 版本检查增强
local function checkVersion()
    local success, response = pcall(function()
        return httpGetWithRetry(GITHUB_BASE .. "/version.lua")
    end)
    
    if success then
        local versionFunc, compileError = loadstring(response)
        if versionFunc then
            return versionFunc()
        end
    end
    
    return { 
        version = "unknown", 
        updateRequired = false,
        features = {},
        performance = "normal"
    }
end

-- 高级加载进度显示
local function showLoadingProgress()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProExecutorLoader"
    screenGui.Parent = game:GetService("CoreGui")
    
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.new(0, 350, 0, 150)
    loadingFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = screenGui
    
    -- 渐变边框效果
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(87, 202, 134))
    }
    
    local border = Instance.new("UIStroke")
    border.Thickness = 2
    border.Color = Color3.fromRGB(88, 101, 242)
    border.Parent = loadingFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = loadingFrame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 ProExecutor 正在加载..."
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = loadingFrame
    
    -- 设备信息
    local device = detectDevice()
    local deviceLabel = Instance.new("TextLabel")
    deviceLabel.Size = UDim2.new(1, 0, 0, 20)
    deviceLabel.Position = UDim2.new(0, 0, 0, 30)
    deviceLabel.BackgroundTransparency = 1
    deviceLabel.Text = string.format("设备: %s | 分辨率: %.0fx%.0f", 
        device.type:upper(), device.screenSize.X, device.screenSize.Y)
    deviceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    deviceLabel.TextSize = 11
    deviceLabel.Font = Enum.Font.SourceSans
    deviceLabel.Parent = loadingFrame
    
    -- 进度文本
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 55)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "正在初始化..."
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    progressLabel.TextSize = 12
    progressLabel.Font = Enum.Font.SourceSans
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = loadingFrame
    
    -- 进度条背景
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -20, 0, 8)
    progressBg.Position = UDim2.new(0, 10, 0, 80)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = loadingFrame
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 4)
    progressBgCorner.Parent = progressBg
    
    -- 进度条
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBar
    
    -- 渐变效果
    gradient:Clone().Parent = progressBar
    
    -- 性能指标
    local perfLabel = Instance.new("TextLabel")
    perfLabel.Size = UDim2.new(1, 0, 0, 15)
    perfLabel.Position = UDim2.new(0, 0, 0, 95)
    perfLabel.BackgroundTransparency = 1
    perfLabel.Text = "性能监控已启用"
    perfLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    perfLabel.TextSize = 10
    perfLabel.Font = Enum.Font.SourceSans
    perfLabel.Parent = loadingFrame
    
    -- 版本信息
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, 0, 0, 15)
    versionLabel.Position = UDim2.new(0, 0, 0, 115)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "GitHub版 | 模块化架构"
    versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    versionLabel.TextSize = 10
    versionLabel.Font = Enum.Font.SourceSans
    perfLabel.Parent = loadingFrame
    
    -- 动画效果
    local TweenService = game:GetService("TweenService")
    local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local pulseTween = TweenService:Create(border, pulseInfo, {Transparency = 0.5})
    pulseTween:Play()
    
    return {
        gui = screenGui,
        updateProgress = function(current, total, message, details)
            local progress = current / total
            
            -- 平滑进度条动画
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(progressBar, tweenInfo, {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
            
            progressLabel.Text = message or ("加载中... " .. current .. "/" .. total)
            
            if details then
                perfLabel.Text = details
            end
            
            -- 进度条颜色变化
            if progress > 0.8 then
                TweenService:Create(progressBar, tweenInfo, {
                    BackgroundColor3 = Color3.fromRGB(87, 202, 134)
                }):Play()
            end
        end,
        destroy = function()
            pulseTween:Cancel()
            TweenService:Create(loadingFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            
            wait(0.3)
            screenGui:Destroy()
        end
    }
end

-- 主加载流程（优化版）
function ProExecutorLoader:Load()
    local startTime = tick()
    
    -- 环境检查
    validateEnvironment()
    
    -- 清理旧版本
    pcall(function()
        local existing = game:GetService("CoreGui"):FindFirstChild("ProExecutor")
        if existing then existing:Destroy() end
    end)
    
    local loader = showLoadingProgress()
    local totalSteps = #MODULES + 5
    local currentStep = 0
    
    wait(0.2) -- 让加载界面显示
    
    -- 检查版本
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🔍 检查版本信息...", "连接GitHub服务器")
    local versionInfo = checkVersion()
    
    -- 加载配置
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🔧 加载配置文件...", "检测设备类型")
    local config = loadConfig()
    
    -- 按优先级分组加载模块
    local moduleGroups = {}
    for _, moduleInfo in ipairs(MODULES) do
        local priority = moduleInfo.priority
        if not moduleGroups[priority] then
            moduleGroups[priority] = {}
        end
        table.insert(moduleGroups[priority], moduleInfo)
    end
    
    local modules = {}
    
    -- 按优先级顺序加载
    local priorities = {}
    for priority in pairs(moduleGroups) do
        table.insert(priorities, priority)
    end
    table.sort(priorities)
    
    for _, priority in ipairs(priorities) do
        local group = moduleGroups[priority]
        local promises = {}
        
        -- 并行启动同优先级模块的加载
        for _, moduleInfo in ipairs(group) do
            promises[moduleInfo.name] = loadModule(moduleInfo)
        end
        
        -- 等待同优先级模块全部完成
        for _, moduleInfo in ipairs(group) do
            currentStep = currentStep + 1
            local moduleName = moduleInfo.name
            local promise = promises[moduleName]
            
            loader.updateProgress(currentStep, totalSteps, 
                "📦 加载模块: " .. moduleName, 
                "优先级: " .. priority)
            
            -- 等待模块加载完成
            while not promise.completed do
                wait(0.05)
            end
            
            if promise.error then
                error("模块 " .. moduleName .. " 加载失败: " .. promise.error)
            end
            
            modules[moduleName] = promise.result
            loadingPromises[moduleName] = nil -- 清理promise
        end
    end
    
    -- 加载主程序
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🚀 启动主程序...", "初始化应用")
    local mainUrl = GITHUB_BASE .. "/main.lua"
    local mainCode = httpGetWithRetry(mainUrl)
    
    -- 性能统计
    currentStep = currentStep + 1
    local stats = PerformanceMonitor:GetStats()
    loader.updateProgress(currentStep, totalSteps, "📊 性能检查完成", 
        string.format("效率: %.1f%% | 模块: %d", stats.efficiency, stats.moduleCount))
    
    -- 最终准备
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "✅ 准备就绪!", 
        string.format("总用时: %.2fs", stats.totalTime))
    
    wait(0.5)
    loader.destroy()
    
    -- 创建增强的执行环境
    local env = getfenv(1)
    env.modules = modules
    env.config = config
    env.versionInfo = versionInfo
    env.performanceStats = stats
    env._ProExecutorLoader = ProExecutorLoader -- 提供加载器访问
    
    -- 执行主程序
    local mainFunc, compileError = loadstring(mainCode)
    if not mainFunc then
        error("主程序编译失败: " .. tostring(compileError))
    end
    
    setfenv(mainFunc, env)
    
    -- 性能监控包装
    local executeStart = tick()
    mainFunc()
    
    local totalLoadTime = tick() - startTime
    print(string.format("ProExecutor 加载完成! 总用时: %.2fs | 模块效率: %.1f%%", 
        totalLoadTime, stats.efficiency))
end

-- 增强的错误处理
local function safeLoad()
    local success, errorMsg = pcall(function()
        ProExecutorLoader:Load()
    end)
    
    if not success then
        -- 性能统计
        local stats = PerformanceMonitor:GetStats()
        
        -- 详细错误报告
        local errorReport = {
            error = errorMsg,
            loadTime = tick() - PerformanceMonitor.startTime,
            moduleStats = stats,
            environment = {
                executor = identifyexecutor and identifyexecutor() or "Unknown",
                robloxVersion = version(),
                httpEnabled = pcall(function() return game:HttpGet("https://httpbin.org/get") end)
            }
        }
        
        -- 创建错误显示
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "ProExecutorError"
        errorGui.Parent = game:GetService("CoreGui")
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 450, 0, 300)
        errorFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
        errorFrame.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
        errorFrame.BorderSizePixel = 0
        errorFrame.Parent = errorGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = errorFrame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 50)
        title.BackgroundTransparency = 1
        title.Text = "❌ ProExecutor 加载失败"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Font = Enum.Font.SourceSansBold
        title.Parent = errorFrame
        
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -20, 1, -120)
        scrollFrame.Position = UDim2.new(0, 10, 0, 55)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.Parent = errorFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 6)
        scrollCorner.Parent = scrollFrame
        
        local errorText = Instance.new("TextLabel")
        errorText.Size = UDim2.new(1, -10, 0, 0)
        errorText.Position = UDim2.new(0, 5, 0, 5)
        errorText.BackgroundTransparency = 1
        errorText.Text = string.format([[
错误信息: %s

性能统计:
- 总用时: %.2fs
- 已加载模块: %d
- 错误数量: %d
- 效率: %.1f%%

环境信息:
- 执行器: %s
- HTTP支持: %s

建议检查:
• 网络连接是否正常
• GitHub仓库是否可访问
• 执行器是否支持HTTP请求
• HttpService是否启用

仓库地址: %s]], 
            tostring(errorMsg),
            errorReport.loadTime,
            errorReport.moduleStats.moduleCount,
            errorReport.moduleStats.errorCount,
            errorReport.moduleStats.efficiency,
            errorReport.environment.executor,
            errorReport.environment.httpEnabled and "✅" or "❌",
            GITHUB_BASE)
            
        errorText.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorText.TextSize = 11
        errorText.Font = Enum.Font.SourceSans
        errorText.TextXAlignment = Enum.TextXAlignment.Left
        errorText.TextYAlignment = Enum.TextYAlignment.Top
        errorText.TextWrapped = true
        errorText.AutomaticSize = Enum.AutomaticSize.Y
        errorText.Parent = scrollFrame
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, errorText.AbsoluteSize.Y + 10)
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 120, 0, 40)
        closeBtn.Position = UDim2.new(0.5, -60, 1, -50)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Text = "关闭"
        closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = errorFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            errorGui:Destroy()
        end)
        
        -- 自动关闭
        game:GetService("Debris"):AddItem(errorGui, 15)
        
        warn("ProExecutor加载失败: " .. tostring(errorMsg))
        warn("性能统计: " .. game:GetService("HttpService"):JSONEncode(errorReport.moduleStats))
    end
end

-- 启动加载
safeLoad()