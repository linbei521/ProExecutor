--[[
    ProExecutor 主程序 - 修复版
    使用原始UI布局 + 安全配置处理
]]

-- 安全获取模块和配置
local Theme = modules and modules.Theme
local Storage = modules and modules.Storage
local Utils = modules and modules.Utils
local Editor = modules and modules.Editor
local OutputManager = modules and modules.OutputManager
local ScriptManager = modules and modules.ScriptManager
local AutoComplete = modules and modules.AutoComplete
local CodeExecutor = modules and modules.CodeExecutor
local UI = modules and modules.UI

-- 如果关键模块加载失败，显示错误
if not Theme or not Storage or not Utils then
    error("关键模块加载失败，请检查网络连接和GitHub仓库访问权限")
end

-- 安全获取配置，提供完整默认值
local Config = config or {}
local VersionInfo = versionInfo or {version = "unknown"}

-- 确保所有必要的配置项都存在
local function ensureConfig()
    -- 检测设备
    local UserInputService = game:GetService("UserInputService")
    local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    
    -- 默认配置
    Config.windowSize = Config.windowSize or (IsMobile and {340, 400} or {450, 320})
    Config.touchOptimized = Config.touchOptimized or IsMobile
    Config.device = Config.device or {
        type = IsMobile and "mobile" or "desktop",
        isMobile = IsMobile,
        screenSize = workspace.CurrentCamera.ViewportSize
    }
    
    -- 字体配置
    Config.fontSize = Config.fontSize or {
        title = 13,
        normal = 11,
        small = 9
    }
    
    -- 功能配置
    Config.features = Config.features or {
        autoComplete = not IsMobile,
        syntaxHighlight = true,
        lineNumbers = true,
        keyboardShortcuts = not IsMobile
    }
    
    -- 性能配置
    Config.performance = Config.performance or {}
    Config.performance.enableAnimations = Config.performance.enableAnimations ~= false and not IsMobile
    Config.performance.maxOutputLines = Config.performance.maxOutputLines or (IsMobile and 30 or 50)
    Config.performance.autoSaveInterval = Config.performance.autoSaveInterval or 30
    Config.performance.enableShadows = Config.performance.enableShadows ~= false and not IsMobile
    Config.performance.enablePerformanceOverlay = Config.performance.enablePerformanceOverlay ~= false and not IsMobile
end

-- 应用配置检查
ensureConfig()

-- 服务
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
    
    -- 动画配置
    self.enableAnimations = Config.performance.enableAnimations
    
    -- 创建管理器实例
    self.outputManager = OutputManager.new(self.theme, self.utils, {
        maxLines = Config.performance.maxOutputLines
    })
    self.codeExecutor = CodeExecutor.new(self.outputManager)
    
    -- 状态变量
    self.minimized = false
    self.originalSize = nil
    self.currentScript = nil
    self.lastAutoCompleteWord = ""
    
    -- 初始化应用
    self:Initialize()
    
    return self
end

function ProExecutor:Initialize()
    self:CreateUI()
    self:SetupEventHandlers()
    self:SetupKeyboardShortcuts()
    self:LoadInitialData()
    
    -- 显示启动信息
    self.outputManager:LogSuccess("🚀 ProExecutor GitHub版已启动")
    self.outputManager:LogInfo("📦 模块化架构加载完成")
    self.outputManager:LogInfo("🎨 设备类型: " .. (Config.device.type or "unknown"))
    self.outputManager:LogInfo("📋 版本: " .. self.version.version)
end

function ProExecutor:CreateUI()
    -- 检查设备信息
    local device = Config.device
    
    -- 创建主界面
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "ProExecutor"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = game:GetService("CoreGui")
    
    -- 响应式窗口大小
    local windowSize = Config.windowSize
    if device.screenSize and device.screenSize.X < 800 then
        windowSize = {
            math.min(windowSize[1], device.screenSize.X * 0.9), 
            math.min(windowSize[2], device.screenSize.Y * 0.8)
        }
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
    
    -- 创建顶部栏
    self:CreateTopBar()
    
    -- 主容器
    self.mainContainer = Instance.new("Frame")
    self.mainContainer.Size = UDim2.new(1, -8, 1, -32)
    self.mainContainer.Position = UDim2.new(0, 4, 0, 30)
    self.mainContainer.BackgroundTransparency = 1
    self.mainContainer.Parent = self.mainFrame
    
    -- 创建侧边栏和编辑器区域
    self:CreateSidePanel()
    self:CreateEditorArea()
    
    -- 创建自动补全
    self:CreateAutoComplete()
    
    -- 设置拖拽
    self:SetupDragging()
    
    -- 入场动画
    if self.enableAnimations then
        self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
        local openTween = TweenService:Create(self.mainFrame, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = self.originalSize}
        )
        openTween:Play()
    end
end

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
    
    -- 标题
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.4, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "专业脚本执行器"
    title.TextColor3 = self.theme.Colors.Text
    title.TextSize = Config.fontSize.title
    title.Font = Enum.Font.SourceSansSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.topBar
    
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
    
    -- 窗口控制按钮
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
end

function ProExecutor:CreateSidePanel()
    -- 侧边栏（脚本列表）
    local sidePanel = Instance.new("Frame")
    sidePanel.Size = UDim2.new(0, 100, 1, 0)
    sidePanel.BackgroundColor3 = self.theme.Colors.Secondary
    sidePanel.BorderSizePixel = 0
    sidePanel.Parent = self.mainContainer
    
    self.theme:CreateCorner(6).Parent = sidePanel
    
    -- 脚本列表标题
    local scriptListHeader = Instance.new("Frame")
    scriptListHeader.Size = UDim2.new(1, 0, 0, 22)
    scriptListHeader.BackgroundColor3 = self.theme.Colors.Tertiary
    scriptListHeader.BorderSizePixel = 0
    scriptListHeader.Parent = sidePanel
    
    self.theme:CreateCorner(6).Parent = scriptListHeader
    
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, 0, 1, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "脚本列表"
    headerLabel.TextColor3 = self.theme.Colors.Text
    headerLabel.TextSize = Config.fontSize.small + 1
    headerLabel.Font = Enum.Font.SourceSansSemibold
    headerLabel.Parent = scriptListHeader
    
    -- 脚本列表滚动框
    self.scriptListScroll = Instance.new("ScrollingFrame")
    self.scriptListScroll.Size = UDim2.new(1, -4, 1, -44)
    self.scriptListScroll.Position = UDim2.new(0, 2, 0, 24)
    self.scriptListScroll.BackgroundTransparency = 1
    self.scriptListScroll.ScrollBarThickness = 2
    self.scriptListScroll.ScrollBarImageColor3 = self.theme.Colors.Border
    self.scriptListScroll.BorderSizePixel = 0
    self.scriptListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.scriptListScroll.Parent = sidePanel
    
    self.scriptListLayout = Instance.new("UIListLayout")
    self.scriptListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.scriptListLayout.Padding = UDim.new(0, 2)
    self.scriptListLayout.Parent = self.scriptListScroll
    
    -- 新建脚本按钮
    self.newScriptBtn = Instance.new("TextButton")
    self.newScriptBtn.Size = UDim2.new(1, -4, 0, 18)
    self.newScriptBtn.Position = UDim2.new(0, 2, 1, -20)
    self.newScriptBtn.BackgroundColor3 = self.theme.Colors.Accent
    self.newScriptBtn.Text = "新建"
    self.newScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.newScriptBtn.TextSize = 10
    self.newScriptBtn.Font = Enum.Font.SourceSansSemibold
    self.newScriptBtn.BorderSizePixel = 0
    self.newScriptBtn.Parent = sidePanel
    
    self.theme:CreateCorner(4).Parent = self.newScriptBtn
    self.theme:AddHoverEffect(self.newScriptBtn, self.theme.Colors.Accent)
    
    -- 初始化脚本管理器
    self.scriptManager = ScriptManager.new(self.theme, self.storage, self.utils, self.outputManager)
    self.scriptManager:Setup(self.scriptListScroll, self.scriptListLayout, nil)
end

function ProExecutor:CreateEditorArea()
    -- 编辑器区域
    local editorFrame = Instance.new("Frame")
    editorFrame.Size = UDim2.new(1, -104, 1, 0)
    editorFrame.Position = UDim2.new(0, 104, 0, 0)
    editorFrame.BackgroundTransparency = 1
    editorFrame.Parent = self.mainContainer
    
    -- 代码工具栏
    self:CreateToolBar(editorFrame)
    
    -- 编辑器容器
    self:CreateEditorContainer(editorFrame)
    
    -- 输出区域
    self:CreateOutputContainer(editorFrame)
    
    -- 按钮栏
    self:CreateButtonBar(editorFrame)
end

function ProExecutor:CreateToolBar(parent)
    local toolBar = Instance.new("Frame")
    toolBar.Size = UDim2.new(1, 0, 0, 24)
    toolBar.BackgroundColor3 = self.theme.Colors.Tertiary
    toolBar.BorderSizePixel = 0
    toolBar.Parent = parent
    
    self.theme:CreateCorner(6).Parent = toolBar
    
    -- 模板按钮
    self.templateBtn = Instance.new("TextButton")
    self.templateBtn.Size = UDim2.new(0, 50, 0, 18)
    self.templateBtn.Position = UDim2.new(0, 3, 0, 3)
    self.templateBtn.BackgroundColor3 = self.theme.Colors.Secondary
    self.templateBtn.Text = "模板"
    self.templateBtn.TextColor3 = self.theme.Colors.Text
    self.templateBtn.TextSize = 10
    self.templateBtn.Font = Enum.Font.SourceSans
    self.templateBtn.BorderSizePixel = 0
    self.templateBtn.Parent = toolBar
    
    self.theme:CreateCorner(3).Parent = self.templateBtn
    
    -- 格式化按钮
    self.formatBtn = Instance.new("TextButton")
    self.formatBtn.Size = UDim2.new(0, 50, 0, 18)
    self.formatBtn.Position = UDim2.new(0, 56, 0, 3)
    self.formatBtn.BackgroundColor3 = self.theme.Colors.Secondary
    self.formatBtn.Text = "格式化"
    self.formatBtn.TextColor3 = self.theme.Colors.Text
    self.formatBtn.TextSize = 10
    self.formatBtn.Font = Enum.Font.SourceSans
    self.formatBtn.BorderSizePixel = 0
    self.formatBtn.Parent = toolBar
    
    self.theme:CreateCorner(3).Parent = self.formatBtn
    
    -- 清空按钮
    self.clearCodeBtn = Instance.new("TextButton")
    self.clearCodeBtn.Size = UDim2.new(0, 50, 0, 18)
    self.clearCodeBtn.Position = UDim2.new(0, 109, 0, 3)
    self.clearCodeBtn.BackgroundColor3 = self.theme.Colors.Secondary
    self.clearCodeBtn.Text = "清空"
    self.clearCodeBtn.TextColor3 = self.theme.Colors.Text
    self.clearCodeBtn.TextSize = 10
    self.clearCodeBtn.Font = Enum.Font.SourceSans
    self.clearCodeBtn.BorderSizePixel = 0
    self.clearCodeBtn.Parent = toolBar
    
    self.theme:CreateCorner(3).Parent = self.clearCodeBtn
    
    -- 字符计数
    self.charCount = Instance.new("TextLabel")
    self.charCount.Size = UDim2.new(0, 80, 1, 0)
    self.charCount.Position = UDim2.new(1, -80, 0, 0)
    self.charCount.BackgroundTransparency = 1
    self.charCount.Text = "行:1 字:0"
    self.charCount.TextColor3 = self.theme.Colors.TextDim
    self.charCount.TextSize = 10
    self.charCount.Font = Enum.Font.SourceSans
    self.charCount.TextXAlignment = Enum.TextXAlignment.Right
    self.charCount.Parent = toolBar
    
    -- 添加悬停效果
    self.theme:AddHoverEffect(self.templateBtn, self.theme.Colors.Secondary)
    self.theme:AddHoverEffect(self.formatBtn, self.theme.Colors.Secondary)
    self.theme:AddHoverEffect(self.clearCodeBtn, self.theme.Colors.Secondary)
end

function ProExecutor:CreateEditorContainer(parent)
    local editorContainer = Instance.new("Frame")
    editorContainer.Size = UDim2.new(1, 0, 0.56, -24)
    editorContainer.Position = UDim2.new(0, 0, 0, 24)
    editorContainer.BackgroundColor3 = self.theme.Colors.Secondary
    editorContainer.BorderSizePixel = 0
    editorContainer.Parent = parent
    
    self.theme:CreateCorner(6).Parent = editorContainer
    
    -- 行号容器
    local lineNumberFrame = Instance.new("Frame")
    lineNumberFrame.Size = UDim2.new(0, 28, 1, -8)
    lineNumberFrame.Position = UDim2.new(0, 4, 0, 4)
    lineNumberFrame.BackgroundColor3 = self.theme.Colors.Background
    lineNumberFrame.BorderSizePixel = 0
    lineNumberFrame.Parent = editorContainer
    
    self.theme:CreateCorner(4).Parent = lineNumberFrame
    
    -- 行号滚动框
    self.lineNumberScroll = Instance.new("ScrollingFrame")
    self.lineNumberScroll.Size = UDim2.new(1, 0, 1, 0)
    self.lineNumberScroll.BackgroundTransparency = 1
    self.lineNumberScroll.ScrollBarThickness = 0
    self.lineNumberScroll.BorderSizePixel = 0
    self.lineNumberScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    self.lineNumberScroll.Parent = lineNumberFrame
    
    -- 行号文本
    self.lineNumberText = Instance.new("TextLabel")
    self.lineNumberText.Size = UDim2.new(1, -3, 1, 0)
    self.lineNumberText.Position = UDim2.new(0, 0, 0, 0)
    self.lineNumberText.BackgroundTransparency = 1
    self.lineNumberText.Text = "1"
    self.lineNumberText.TextColor3 = self.theme.Colors.LineNumber
    self.lineNumberText.TextSize = Config.fontSize.small + 1
    self.lineNumberText.Font = Enum.Font.Code
    self.lineNumberText.TextXAlignment = Enum.TextXAlignment.Right
    self.lineNumberText.TextYAlignment = Enum.TextYAlignment.Top
    self.lineNumberText.Parent = self.lineNumberScroll
    
    -- 代码编辑框
    self.codeScroll = Instance.new("ScrollingFrame")
    self.codeScroll.Size = UDim2.new(1, -40, 1, -8)
    self.codeScroll.Position = UDim2.new(0, 36, 0, 4)
    self.codeScroll.BackgroundTransparency = 1
    self.codeScroll.ScrollBarThickness = 3
    self.codeScroll.ScrollBarImageColor3 = self.theme.Colors.Border
    self.codeScroll.BorderSizePixel = 0
    self.codeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.codeScroll.Parent = editorContainer
    
    self.codeInput = Instance.new("TextBox")
    self.codeInput.Size = UDim2.new(1, -8, 1, 0)
    self.codeInput.Position = UDim2.new(0, 4, 0, 0)
    self.codeInput.BackgroundTransparency = 1
    self.codeInput.Text = "-- ProExecutor GitHub版\n-- 在此编写代码\nprint('Hello from GitHub!')"
    self.codeInput.TextColor3 = self.theme.Colors.Text
    self.codeInput.TextSize = Config.fontSize.normal
    self.codeInput.Font = Enum.Font.Code
    self.codeInput.TextXAlignment = Enum.TextXAlignment.Left
    self.codeInput.TextYAlignment = Enum.TextYAlignment.Top
    self.codeInput.ClearTextOnFocus = false
    self.codeInput.MultiLine = true
    self.codeInput.Parent = self.codeScroll
    
    -- 设置编辑器
    self.editor = Editor.new(self.theme, self.utils)
    self.editor:SetupEditor(self.codeInput, self.lineNumberText, self.codeScroll, self.lineNumberScroll, self.charCount)
end

function ProExecutor:CreateOutputContainer(parent)
    local outputContainer = Instance.new("Frame")
    outputContainer.Size = UDim2.new(1, 0, 0.44, -22)
    outputContainer.Position = UDim2.new(0, 0, 0.56, 2)
    outputContainer.BackgroundColor3 = self.theme.Colors.Secondary
    outputContainer.BorderSizePixel = 0
    outputContainer.Parent = parent
    
    self.theme:CreateCorner(6).Parent = outputContainer
    
    -- 输出标题栏
    local outputHeader = Instance.new("Frame")
    outputHeader.Size = UDim2.new(1, 0, 0, 18)
    outputHeader.BackgroundColor3 = self.theme.Colors.Tertiary
    outputHeader.BorderSizePixel = 0
    outputHeader.Parent = outputContainer
    
    self.theme:CreateCorner(6).Parent = outputHeader
    
    local outputHeaderFix = Instance.new("Frame")
    outputHeaderFix.Size = UDim2.new(1, 0, 0, 10)
    outputHeaderFix.Position = UDim2.new(0, 0, 1, -10)
    outputHeaderFix.BackgroundColor3 = self.theme.Colors.Tertiary
    outputHeaderFix.BorderSizePixel = 0
    outputHeaderFix.Parent = outputHeader
    
    local outputLabel = Instance.new("TextLabel")
    outputLabel.Size = UDim2.new(0.5, 0, 1, 0)
    outputLabel.Position = UDim2.new(0, 8, 0, 0)
    outputLabel.BackgroundTransparency = 1
    outputLabel.Text = "输出"
    outputLabel.TextColor3 = self.theme.Colors.Text
    outputLabel.TextSize = 10
    outputLabel.Font = Enum.Font.SourceSansSemibold
    outputLabel.TextXAlignment = Enum.TextXAlignment.Left
    outputLabel.Parent = outputHeader
    
    self.clearOutputBtn = Instance.new("TextButton")
    self.clearOutputBtn.Size = UDim2.new(0, 35, 0, 14)
    self.clearOutputBtn.Position = UDim2.new(1, -38, 0, 2)
    self.clearOutputBtn.BackgroundColor3 = self.theme.Colors.Background
    self.clearOutputBtn.Text = "清空"
    self.clearOutputBtn.TextColor3 = self.theme.Colors.TextDim
    self.clearOutputBtn.TextSize = 9
    self.clearOutputBtn.Font = Enum.Font.SourceSans
    self.clearOutputBtn.BorderSizePixel = 0
    self.clearOutputBtn.Parent = outputHeader
    
    self.theme:CreateCorner(3).Parent = self.clearOutputBtn
    
    -- 输出滚动框
    self.outputScroll = Instance.new("ScrollingFrame")
    self.outputScroll.Size = UDim2.new(1, -8, 1, -22)
    self.outputScroll.Position = UDim2.new(0, 4, 0, 20)
    self.outputScroll.BackgroundTransparency = 1
    self.outputScroll.ScrollBarThickness = 3
    self.outputScroll.ScrollBarImageColor3 = self.theme.Colors.Border
    self.outputScroll.BorderSizePixel = 0
    self.outputScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.outputScroll.Parent = outputContainer
    
    self.outputLayout = Instance.new("UIListLayout")
    self.outputLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.outputLayout.Padding = UDim.new(0, 1)
    self.outputLayout.Parent = self.outputScroll
    
    -- 设置输出管理器
    self.outputManager:Setup(self.outputScroll, self.outputLayout)
end

function ProExecutor:CreateButtonBar(parent)
    local buttonBar = Instance.new("Frame")
    buttonBar.Size = UDim2.new(1, 0, 0, 20)
    buttonBar.Position = UDim2.new(0, 0, 1, -20)
    buttonBar.BackgroundTransparency = 1
    buttonBar.Parent = parent
    
    -- 创建按钮函数
    local function CreateButton(text, color, position)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 55, 1, 0)
        Button.Position = position
        Button.BackgroundColor3 = color
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = Config.fontSize.normal
        Button.Font = Enum.Font.SourceSansSemibold
        Button.BorderSizePixel = 0
        Button.Parent = buttonBar
        
        self.theme:CreateCorner(4).Parent = Button
        self.theme:AddHoverEffect(Button, color)
        
        return Button
    end
    
    self.executeBtn = CreateButton("执行", self.theme.Colors.Success, UDim2.new(0, 0, 0, 0))
    self.saveBtn = CreateButton("保存", self.theme.Colors.Accent, UDim2.new(0, 58, 0, 0))
    self.exportBtn = CreateButton("导出", self.theme.Colors.Warning, UDim2.new(0, 116, 0, 0))
    self.importBtn = CreateButton("导入", self.theme.Colors.Tertiary, UDim2.new(0, 174, 0, 0))
    
    -- 当前脚本标签
    self.currentScriptLabel = Instance.new("TextLabel")
    self.currentScriptLabel.Size = UDim2.new(0, 80, 1, 0)
    self.currentScriptLabel.Position = UDim2.new(1, -80, 0, 0)
    self.currentScriptLabel.BackgroundTransparency = 1
    self.currentScriptLabel.Text = "未命名"
    self.currentScriptLabel.TextColor3 = self.theme.Colors.TextDim
    self.currentScriptLabel.TextSize = 10
    self.currentScriptLabel.Font = Enum.Font.SourceSans
    self.currentScriptLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.currentScriptLabel.Parent = buttonBar
end

function ProExecutor:CreateAutoComplete()
    -- 自动补全提示框
    self.autoCompleteFrame = Instance.new("Frame")
    self.autoCompleteFrame.Size = UDim2.new(0, 150, 0, 100)
    self.autoCompleteFrame.BackgroundColor3 = self.theme.Colors.Background
    self.autoCompleteFrame.BorderSizePixel = 0
    self.autoCompleteFrame.Visible = false
    self.autoCompleteFrame.ZIndex = 10
    self.autoCompleteFrame.Parent = self.screenGui
    
    self.theme:CreateCorner(6).Parent = self.autoCompleteFrame
    self.theme:CreateBorder(1).Parent = self.autoCompleteFrame
    
    self.autoCompleteScroll = Instance.new("ScrollingFrame")
    self.autoCompleteScroll.Size = UDim2.new(1, -4, 1, -4)
    self.autoCompleteScroll.Position = UDim2.new(0, 2, 0, 2)
    self.autoCompleteScroll.BackgroundTransparency = 1
    self.autoCompleteScroll.ScrollBarThickness = 2
    self.autoCompleteScroll.ScrollBarImageColor3 = self.theme.Colors.Border
    self.autoCompleteScroll.BorderSizePixel = 0
    self.autoCompleteScroll.Parent = self.autoCompleteFrame
    
    self.autoCompleteLayout = Instance.new("UIListLayout")
    self.autoCompleteLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.autoCompleteLayout.Padding = UDim.new(0, 1)
    self.autoCompleteLayout.Parent = self.autoCompleteScroll
    
    -- 设置自动补全
    self.autoComplete = AutoComplete.new(self.theme, self.utils)
    self.autoComplete:Setup(self.autoCompleteFrame, self.autoCompleteScroll, self.autoCompleteLayout)
end

function ProExecutor:SetupEventHandlers()
    -- 脚本管理器回调
    self.scriptManager:SetLoadCallback(function(code)
        self.editor:SetText(code)
    end)
    
    self.scriptManager:SetNewCallback(function()
        self.editor:SetText("-- 新脚本\n")
    end)
    
    -- 自动补全回调
    if Config.features.autoComplete then
        self.editor:SetCallback("onAutoComplete", function(word)
            if #word > 2 then
                local position = UDim2.new(0, self.mainFrame.Position.X.Offset + 140, 0, self.mainFrame.Position.Y.Offset + 100)
                self.autoComplete:Show(word, position)
            else
                self.autoComplete:Hide()
            end
        end)
        
        self.autoComplete:SetSelectCallback(function(selected, original)
            local text = self.editor:GetText()
            local beforeCursor = text:sub(1, #text - #original)
            self.editor:SetText(beforeCursor .. selected)
        end)
    end
    
    -- 按钮事件
    self.executeBtn.MouseButton1Click:Connect(function()
        self.codeExecutor:Execute(self.editor:GetText())
    end)
    
    self.saveBtn.MouseButton1Click:Connect(function()
        self:ShowSaveDialog()
    end)
    
    self.exportBtn.MouseButton1Click:Connect(function()
        self.scriptManager:ExportScripts()
    end)
    
    self.importBtn.MouseButton1Click:Connect(function()
        self.scriptManager:ImportScripts()
    end)
    
    self.templateBtn.MouseButton1Click:Connect(function()
        self:ShowTemplateMenu()
    end)
    
    self.formatBtn.MouseButton1Click:Connect(function()
        self.editor:FormatCode()
        self.outputManager:LogSuccess("代码已格式化")
    end)
    
    self.clearCodeBtn.MouseButton1Click:Connect(function()
        self.editor:ClearCode()
        self.outputManager:LogWarning("代码已清空")
    end)
    
    self.newScriptBtn.MouseButton1Click:Connect(function()
        self.scriptManager:NewScript()
    end)
    
    self.clearOutputBtn.MouseButton1Click:Connect(function()
        self.outputManager:Clear()
    end)
    
    -- 窗口控制
    self.minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
end

function ProExecutor:SetupDragging()
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local function update(input)
        local delta = input.Position - dragStart
        self.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    self.topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    self.topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

function ProExecutor:SetupKeyboardShortcuts()
    if not Config.features.keyboardShortcuts then return end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        local isCtrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        
        if isCtrlDown then
            if input.KeyCode == Enum.KeyCode.Return then
                -- Ctrl+Enter 执行
                self.codeExecutor:Execute(self.editor:GetText())
            elseif input.KeyCode == Enum.KeyCode.S then
                -- Ctrl+S 保存
                self:ShowSaveDialog()
            elseif input.KeyCode == Enum.KeyCode.F then
                -- Ctrl+F 格式化
                self.editor:FormatCode()
                self.outputManager:LogSuccess("代码已格式化")
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            -- Tab 缩进
            local currentText = self.editor:GetText()
            self.editor:SetText(currentText .. "    ")
        end
    end)
end

function ProExecutor:ShowSaveDialog()
    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 200, 0, 90)
    dialog.Position = UDim2.new(0.5, -100, 0.5, -45)
    dialog.BackgroundColor3 = self.theme.Colors.Secondary
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 10
    dialog.Parent = self.screenGui
    
    self.theme:CreateCorner(8).Parent = dialog
    
    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Size = UDim2.new(1, 0, 0, 25)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = "保存脚本"
    dialogTitle.TextColor3 = self.theme.Colors.Text
    dialogTitle.TextSize = Config.fontSize.normal + 1
    dialogTitle.Font = Enum.Font.SourceSansSemibold
    dialogTitle.Parent = dialog
    
    local nameInput = Instance.new("TextBox")
    nameInput.Size = UDim2.new(1, -16, 0, 22)
    nameInput.Position = UDim2.new(0, 8, 0, 28)
    nameInput.BackgroundColor3 = self.theme.Colors.Background
    nameInput.Text = ""
    nameInput.PlaceholderText = "输入脚本名称..."
    nameInput.PlaceholderColor3 = self.theme.Colors.TextDim
    nameInput.TextColor3 = self.theme.Colors.Text
    nameInput.TextSize = Config.fontSize.normal
    nameInput.Font = Enum.Font.SourceSans
    nameInput.BorderSizePixel = 0
    nameInput.Parent = dialog
    
    self.theme:CreateCorner(4).Parent = nameInput
    
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 50, 0, 20)
    confirmBtn.Position = UDim2.new(0.5, -55, 1, -24)
    confirmBtn.BackgroundColor3 = self.theme.Colors.Success
    confirmBtn.Text = "保存"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.TextSize = Config.fontSize.normal
    confirmBtn.Font = Enum.Font.SourceSansSemibold
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Parent = dialog
    
    self.theme:CreateCorner(4).Parent = confirmBtn
    
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0, 50, 0, 20)
    cancelBtn.Position = UDim2.new(0.5, 5, 1, -24)
    cancelBtn.BackgroundColor3 = self.theme.Colors.Tertiary
    cancelBtn.Text = "取消"
    cancelBtn.TextColor3 = self.theme.Colors.Text
    cancelBtn.TextSize = Config.fontSize.normal
    cancelBtn.Font = Enum.Font.SourceSansSemibold
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Parent = dialog
    
    self.theme:CreateCorner(4).Parent = cancelBtn
    
    nameInput:CaptureFocus()
    
    confirmBtn.MouseButton1Click:Connect(function()
        local name = nameInput.Text ~= "" and nameInput.Text or "未命名"
        local success = self.scriptManager:SaveScript(name, self.editor:GetText())
        if success then
            dialog:Destroy()
        end
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

function ProExecutor:ShowTemplateMenu()
    self.utils:ShowTemplateMenu(self.screenGui, self.theme, Config, function(template)
        local currentText = self.editor:GetText()
        self.editor:SetText(currentText .. "\n" .. template)
        self.outputManager:LogSuccess("已插入模板")
    end)
end

function ProExecutor:ToggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then
        if self.enableAnimations then
            self.mainFrame:TweenSize(UDim2.new(0, 200, 0, 28), "Out", "Quad", 0.3, true)
        else
            self.mainFrame.Size = UDim2.new(0, 200, 0, 28)
        end
        self.mainContainer.Visible = false
    else
        if self.enableAnimations then
            self.mainFrame:TweenSize(self.originalSize, "Out", "Quad", 0.3, true)
            wait(0.3)
        else
            self.mainFrame.Size = self.originalSize
        end
        self.mainContainer.Visible = true
    end
end

function ProExecutor:Destroy()
    if self.enableAnimations then
        local closeTween = TweenService:Create(self.mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}
        )
        closeTween:Play()
        closeTween.Completed:Connect(function()
            self.screenGui:Destroy()
        end)
    else
        self.screenGui:Destroy()
    end
end

function ProExecutor:LoadInitialData()
    -- 加载已保存的脚本
    self.scriptManager:LoadSavedScripts()
    
    -- 初始化编辑器
    self.editor:UpdateLineNumbers()
    
    -- 显示启动信息
    self.outputManager:LogSuccess("脚本执行器已加载")
    self.outputManager:LogInfo("存储模式: " .. self.storage:GetStorageType())
    if Config.features.keyboardShortcuts then
        self.outputManager:LogInfo("快捷键: Ctrl+Enter执行 | Ctrl+S保存 | Ctrl+F格式化")
    end
end

-- 启动应用
local success, app = pcall(function()
    return ProExecutor.new()
end)

if success then
    _G.ProExecutor = app
    print("ProExecutor GitHub版启动成功! 🚀")
    
    -- 客户端清理函数
local function setupCleanup()
    -- 在客户端使用Players服务来检测玩家离开
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    if player then
        -- 当玩家离开游戏时清理
        player.AncestryChanged:Connect(function()
            if not player.Parent then
                if app and app.Destroy then
                    app:Destroy()
                end
            end
        end)
    end
    
    -- 检测GUI被删除时的清理
    if app and app.screenGui then
        app.screenGui.AncestryChanged:Connect(function()
            if not app.screenGui.Parent then
                if app.Destroy then
                    app:Destroy()
                end
            end
        end)
    end
end

-- 设置清理
pcall(setupCleanup)
else
    error("ProExecutor 启动失败: " .. tostring(app))
end