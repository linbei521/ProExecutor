--[[
    ProExecutor - GitHub模块加载器
    仓库地址: https://github.com/YourUsername/ProExecutor
    
    使用方法:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/ProExecutor/main/loader.lua"))()
]]

local ProExecutorLoader = {}

-- 配置
local GITHUB_BASE = "https://raw.githubusercontent.com/YourUsername/ProExecutor/main"
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

-- 检测设备类型
local function detectDevice()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "mobile" or "desktop"
end

-- 模块缓存
local moduleCache = {}

-- 加载模块函数
local function loadModule(moduleName)
    if moduleCache[moduleName] then
        return moduleCache[moduleName]
    end
    
    local url = GITHUB_BASE .. "/modules/" .. moduleName .. ".lua"
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        error("无法加载模块 " .. moduleName .. ": " .. tostring(response))
    end
    
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
        return game:HttpGet(configUrl)
    end)
    
    if success then
        local configFunc = loadstring(response)
        if configFunc then
            return configFunc()
        end
    end
    
    -- 返回默认配置
    return {
        windowSize = device == "mobile" and {340, 400} or {450, 320},
        touchOptimized = device == "mobile"
    }
end

-- 显示加载进度
local function showLoadingProgress()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProExecutorLoader"
    screenGui.Parent = game:GetService("CoreGui")
    
    local loadingFrame = Instance.new("Frame")
    loadingFrame.Size = UDim2.new(0, 300, 0, 100)
    loadingFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = loadingFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 加载ProExecutor..."
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.Parent = loadingFrame
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 35)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "正在初始化..."
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    progressLabel.TextSize = 12
    progressLabel.Font = Enum.Font.SourceSans
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = loadingFrame
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 4)
    progressBar.Position = UDim2.new(0, 10, 0, 60)
    progressBar.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = loadingFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 2)
    progressCorner.Parent = progressBar
    
    return {
        gui = screenGui,
        updateProgress = function(current, total, message)
            local progress = current / total
            progressBar:TweenSize(UDim2.new(progress, -20, 0, 4), "Out", "Quad", 0.2, true)
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
        local existing = game:GetService("CoreGui"):FindFirstChild("ProExecutor")
        if existing then existing:Destroy() end
    end)
    
    local loader = showLoadingProgress()
    
    wait(0.1) -- 让加载界面显示
    
    -- 加载配置
    loader.updateProgress(1, #MODULES + 3, "🔧 加载配置...")
    local config = loadConfig()
    
    -- 加载所有模块
    local modules = {}
    for i, moduleName in ipairs(MODULES) do
        loader.updateProgress(i + 1, #MODULES + 3, "📦 加载模块: " .. moduleName)
        modules[moduleName] = loadModule(moduleName)
        wait(0.05) -- 避免请求过快
    end
    
    -- 加载主程序
    loader.updateProgress(#MODULES + 2, #MODULES + 3, "🚀 启动主程序...")
    local mainUrl = GITHUB_BASE .. "/main.lua"
    local mainCode = game:HttpGet(mainUrl)
    
    -- 创建执行环境
    local env = {
        -- 提供模块访问
        modules = modules,
        config = config,
        
        -- Roblox服务
        game = game,
        workspace = workspace,
        
        -- 标准库
        print = print,
        warn = warn,
        error = error,
        wait = wait,
        spawn = spawn,
        delay = delay,
        tick = tick,
        
        -- 实例创建
        Instance = Instance,
        
        -- 数学和字符串
        math = math,
        string = string,
        table = table,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        
        -- 其他
        typeof = typeof,
        tostring = tostring,
        tonumber = tonumber,
        pcall = pcall,
        xpcall = xpcall,
        getfenv = getfenv,
        setfenv = setfenv,
        loadstring = loadstring,
        
        -- Roblox特定
        Color3 = Color3,
        Vector3 = Vector3,
        CFrame = CFrame,
        UDim2 = UDim2,
        UDim = UDim,
        Enum = Enum
    }
    
    loader.updateProgress(#MODULES + 3, #MODULES + 3, "✅ 加载完成!")
    
    wait(0.5)
    loader.destroy()
    
    -- 执行主程序
    local mainFunc = loadstring(mainCode)
    setfenv(mainFunc, env)
    mainFunc()
end

-- 错误处理包装
local function safeLoad()
    local success, error = pcall(function()
        ProExecutorLoader:Load()
    end)
    
    if not success then
        -- 创建错误显示
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name = "ProExecutorError"
        errorGui.Parent = game:GetService("CoreGui")
        
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 400, 0, 200)
        errorFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
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
        errorText.Size = UDim2.new(1, -20, 1, -80)
        errorText.Position = UDim2.new(0, 10, 0, 45)
        errorText.BackgroundTransparency = 1
        errorText.Text = "错误信息: " .. tostring(error) .. "\n\n请检查:\n• 网络连接\n• GitHub仓库地址\n• HttpService是否启用"
        errorText.TextColor3 = Color3.fromRGB(255, 255, 255)
        errorText.TextSize = 12
        errorText.Font = Enum.Font.SourceSans
        errorText.TextXAlignment = Enum.TextXAlignment.Left
        errorText.TextYAlignment = Enum.TextYAlignment.Top
        errorText.TextWrapped = true
        errorText.Parent = errorFrame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 100, 0, 30)
        closeBtn.Position = UDim2.new(0.5, -50, 1, -35)
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
        
        -- 5秒后自动关闭
        game:GetService("Debris"):AddItem(errorGui, 10)
    end
end

-- 启动加载
safeLoad()
