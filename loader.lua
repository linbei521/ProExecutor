--[[
    ProExecutor GitHub加载器
    
    使用方法:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/linbei521/ProExecutor/main/loader.lua"))()
    
    替换YourUsername为你的GitHub用户名
]]

local ProExecutorLoader = {}

-- 配置 - 请替换为你的GitHub用户名
local GITHUB_USER = "linbei521"  -- 改成你的GitHub用户名
local REPO_NAME = "ProExecutor"
local BRANCH = "main"
local GITHUB_BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s", GITHUB_USER, REPO_NAME, BRANCH)

-- 模块列表
local MODULES = {
    "Theme",
    "Storage", 
    "Utils",
    "Editor",
    "OutputManager",
    "ScriptManager",
    "AutoComplete",
    "CodeExecutor",
    "UI"
}

-- 检查执行环境
if not game or not game:GetService("HttpService") then
    error("此脚本需要在支持HttpService的Roblox环境中运行")
end

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- 检测设备类型
local function detectDevice()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "mobile" or "desktop"
end

-- 模块缓存
local moduleCache = {}

-- HTTP请求重试机制
local function httpGetWithRetry(url, maxRetries)
    maxRetries = maxRetries or 3
    local lastError = nil
    
    for i = 1, maxRetries do
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success then
            return result
        else
            lastError = result
            if i < maxRetries then
                wait(1) -- 等待1秒后重试
            end
        end
    end
    
    error("HTTP请求失败 (重试" .. maxRetries .. "次): " .. tostring(lastError))
end

-- 加载模块函数
local function loadModule(moduleName)
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    local url = GITHUB_BASE .. "/modules/" .. moduleName .. ".lua"
    
    local response = httpGetWithRetry(url)
    
    local moduleFunc, compileError = loadstring(response)
    if not moduleFunc then
        error("模块 " .. moduleName .. " 编译失败: " .. tostring(compileError))
    end
    
    local module = moduleFunc()
    moduleCache[moduleName] = module
    
    return module
end

-- 加载配置
local function loadConfig()
    local device = detectDevice()
    local configUrl = GITHUB_BASE .. "/configs/" .. device .. ".lua"
    
    local success, response = pcall(function()
        return httpGetWithRetry(configUrl)
    end)
    
    if success then
        local configFunc, compileError = loadstring(response)
        if configFunc then
            return configFunc()
        end
    end
    
    -- 返回默认配置
    return {
        windowSize = device == "mobile" and {340, 400} or {450, 320},
        touchOptimized = device == "mobile",
        device = device
    }
end

-- 检查版本
local function checkVersion()
    local success, response = pcall(function()
        return httpGetWithRetry(GITHUB_BASE .. "/version.lua")
    end)
    
    if success then
        local versionFunc = loadstring(response)
        if versionFunc then
            return versionFunc()
        end
    end
    
    return { version = "unknown", updateRequired = false }
end

-- 显示加载进度
local function showLoadingProgress()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProExecutorLoader"
    screenGui.Parent = CoreGui
    
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.new(0, 300, 0, 120)
    loadingFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = loadingFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 ProExecutor 加载中..."
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = loadingFrame
    
    local deviceLabel = Instance.new("TextLabel")
    deviceLabel.Size = UDim2.new(1, 0, 0, 20)
    deviceLabel.Position = UDim2.new(0, 0, 0, 25)
    deviceLabel.BackgroundTransparency = 1
    deviceLabel.Text = "设备: " .. detectDevice() .. " | 来源: GitHub"
    deviceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    deviceLabel.TextSize = 10
    deviceLabel.Font = Enum.Font.SourceSans
    deviceLabel.Parent = loadingFrame
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 50)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "正在初始化..."
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    progressLabel.TextSize = 12
    progressLabel.Font = Enum.Font.SourceSans
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = loadingFrame
    
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -20, 0, 6)
    progressBg.Position = UDim2.new(0, 10, 0, 75)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = loadingFrame
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 3)
    progressBgCorner.Parent = progressBg
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 3)
    progressCorner.Parent = progressBar
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 15)
    statusLabel.Position = UDim2.new(0, 0, 0, 85)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "v" .. (checkVersion().version or "unknown")
    statusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    statusLabel.TextSize = 9
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.Parent = loadingFrame
    
    return {
        gui = screenGui,
        updateProgress = function(current, total, message)
            local progress = current / total
            progressBar:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Quad", 0.2, true)
            progressLabel.Text = message or ("加载中... " .. current .. "/" .. total)
        end,
        destroy = function()
            screenGui:Destroy()
        end
    }
end

-- 主加载流程
function ProExecutorLoader:Load()
    -- 清理旧版本
    pcall(function()
        local existing = CoreGui:FindFirstChild("ProExecutor")
        if existing then existing:Destroy() end
    end)
    
    local loader = showLoadingProgress()
    local totalSteps = #MODULES + 4
    local currentStep = 0
    
    wait(0.1) -- 让加载界面显示
    
    -- 检查版本
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🔍 检查版本...")
    local versionInfo = checkVersion()
    
    -- 加载配置
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🔧 加载配置...")
    local config = loadConfig()
    
    -- 加载所有模块
    local modules = {}
    for i, moduleName in ipairs(MODULES) do
        currentStep = currentStep + 1
        loader.updateProgress(currentStep, totalSteps, "📦 加载: " .. moduleName)
        modules[moduleName] = loadModule(moduleName)
        wait(0.05) -- 避免请求过快
    end
    
    -- 加载主程序
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "🚀 启动程序...")
    local mainUrl = GITHUB_BASE .. "/main.lua"
    local mainCode = httpGetWithRetry(mainUrl)
    
    -- 最终准备
    currentStep = currentStep + 1
    loader.updateProgress(currentStep, totalSteps, "✅ 准备完成!")
    
    wait(0.5)
    loader.destroy()
    
    -- 创建执行环境
    local env = getfenv(1)
    env.modules = modules
    env.config = config
    env.versionInfo = versionInfo
    
    -- 执行主程序
    local mainFunc, compileError = loadstring(mainCode)
    if not mainFunc then
        error("主程序编译失败: " .. tostring(compileError))
    end
    
    setfenv(mainFunc, env)
    mainFunc()
end

-- 错误处理包装
local function safeLoad()
    local success, errorMsg = pcall(function()
        ProExecutorLoader:Load()
    end)
    
    if not success then
        -- 创建错误显示
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "ProExecutorError"
        errorGui.Parent = CoreGui
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 400, 0, 250)
        errorFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
        errorFrame.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
        errorFrame.BorderSizePixel = 0
        errorFrame.Parent = errorGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = errorFrame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "❌ ProExecutor 加载失败"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Font = Enum.Font.SourceSansBold
        title.Parent = errorFrame
        
        local errorText = Instance.new("TextLabel")
        errorText.Size = UDim2.new(1, -20, 1, -120)
        errorText.Position = UDim2.new(0, 10, 0, 45)
        errorText.BackgroundTransparency = 1
        errorText.Text = "错误信息:\n" .. tostring(errorMsg) .. "\n\n请检查:\n• 网络连接是否正常\n• GitHub仓库是否可访问\n• HttpService是否启用\n• 执行器是否支持HTTP请求"
        errorText.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorText.TextSize = 11
        errorText.Font = Enum.Font.SourceSans
        errorText.TextXAlignment = Enum.TextXAlignment.Left
        errorText.TextYAlignment = Enum.TextYAlignment.Top
        errorText.TextWrapped = true
        errorText.Parent = errorFrame
        
        local repoLink = Instance.new("TextLabel")
        repoLink.Size = UDim2.new(1, -20, 0, 20)
        repoLink.Position = UDim2.new(0, 10, 1, -70)
        repoLink.BackgroundTransparency = 1
        repoLink.Text = "GitHub: " .. GITHUB_BASE
        repoLink.TextColor3 = Color3.fromRGB(200, 200, 200)
        repoLink.TextSize = 9
        repoLink.Font = Enum.Font.SourceSans
        repoLink.TextXAlignment = Enum.TextXAlignment.Left
        repoLink.Parent = errorFrame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 100, 0, 35)
        closeBtn.Position = UDim2.new(0.5, -50, 1, -45)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Text = "关闭"
        closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        closeBtn.TextSize = 12
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = errorFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            errorGui:Destroy()
        end)
        
        -- 10秒后自动关闭
        game:GetService("Debris"):AddItem(errorGui, 10)
        
        warn("ProExecutor加载失败: " .. tostring(errorMsg))
    end
end

-- 启动加载
safeLoad()