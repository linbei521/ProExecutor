--[[
    ProExecutor 主程序
    由loader.lua加载，可以访问所有模块和配置
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

-- 应用配置
local Config = config
local VersionInfo = versionInfo

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
    
    -- 创建管理器实例
    self.outputManager = OutputManager.new(self.theme, self.utils)
    self.editor = Editor.new(self.theme, self.utils, self.config)
    self.codeExecutor = CodeExecutor.new(self.outputManager)
    self.ui = UI.new(self.theme, self.utils, self.config)
    
    -- 状态变量
    self.minimized = false
    self.originalSize = nil
    self.currentScript = nil
    
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
    self.outputManager:LogInfo("🔧 配置: " .. (self.config.touchOptimized and "移动端优化" or "桌面端"))
    self.outputManager:LogInfo("📋 版本: " .. (self.version.version or "unknown"))
end

function ProExecutor:CreateUI()
    -- 创建主界面
    self.screenGui, self.mainFrame = self.ui:CreateMainWindow()
    self.originalSize = self.mainFrame.Size
    
    -- 创建顶部栏
    self.topBar, self.minimizeBtn, self.closeBtn = self.ui:CreateTopBar(self.mainFrame)
    
    -- 主容器
    self.mainContainer = Instance.new("Frame")
    self.mainContainer.Size = UDim2.new(1, -8, 1, -32)
    self.mainContainer.Position = UDim2.new(0, 4, 0, 30)
    self.mainContainer.BackgroundTransparency = 1
    self.mainContainer.Parent = self.mainFrame
    
    if self.config.touchOptimized then
        self:CreateMobileUI()
    else
        self:CreateDesktopUI()
    end
    
    -- 设置拖拽
    self:SetupDragging()
end

function ProExecutor:CreateMobileUI()
    -- 移动端标签页界面
    self:CreateTabSystem()
end

function ProExecutor:CreateDesktopUI()
    -- 桌面端分栏界面
    self:CreateSidePanel()
    self:CreateEditorArea()
end

function ProExecutor:CreateTabSystem()
    -- 标签栏
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 35)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = self.mainContainer
    
    -- 标签按钮
    self.codeTab = self:CreateTabButton(tabBar, "代码", UDim2.new(0, 5, 0, 0), true)
    self.scriptsTab = self:CreateTabButton(tabBar, "脚本", UDim2.new(0, 85, 0, 0), false)
    self.outputTab = self:CreateTabButton(tabBar, "输出", UDim2.new(0, 165, 0, 0), false)
    self.settingsTab = self:CreateTabButton(tabBar, "设置", UDim2.new(0, 245, 0, 0), false)
    
    -- 内容区域
    self.contentFrame = Instance.new("Frame")
    self.contentFrame.Size = UDim2.new(1, 0, 1, -40)
    self.contentFrame.Position = UDim2.new(0, 0, 0, 40)
    self.contentFrame.BackgroundTransparency = 1
    self.contentFrame.Parent = self.mainContainer
    
    -- 创建各个标签页内容
    self:CreateCodeTab()
    self:CreateScriptsTab()
    self:CreateOutputTab()
    self:CreateSettingsTab()
    
    -- 默认显示代码标签页
    self:SwitchTab("code")
end

function ProExecutor:CreateTabButton(parent, text, position, active)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 75, 0, 30)
    button.Position = position
    button.BackgroundColor3 = active and self.theme.Colors.Accent or self.theme.Colors.Secondary
    button.Text = text
    button.TextColor3 = self.theme.Colors.Text
    button.TextSize = self.config.fontSize.normal
    button.Font = Enum.Font.SourceSansSemibold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    self.theme:CreateCorner(8).Parent = button
    
    return button
end

function ProExecutor:CreateCodeTab()
    self.codeFrame = Instance.new("Frame")
    self.codeFrame.Size = UDim2.new(1, 0, 1, 0)
    self.codeFrame.BackgroundTransparency = 1
    self.codeFrame.Parent = self.contentFrame
    
    -- 工具栏
    local toolbar = Instance.new("Frame")
    toolbar.Size = UDim2.new(1, 0, 0, 30)
    toolbar.BackgroundColor3 = self.theme.Colors.Secondary
    toolbar.BorderSizePixel = 0
    toolbar.Parent = self.codeFrame
    
    self.theme:CreateCorner(8).Parent = toolbar
    
    -- 工具按钮
    self.templateBtn = self:CreateToolButton(toolbar, "模板", UDim2.new(0, 5, 0, 3))
    self.clearBtn = self:CreateToolButton(toolbar, "清空", UDim2.new(0, 60, 0, 3))
    self.formatBtn = self:CreateToolButton(toolbar, "格式化", UDim2.new(0, 115, 0, 3))
    
    -- 字符统计
    self.charLabel = Instance.new("TextLabel")
    self.charLabel.Size = UDim2.new(0, 100, 1, 0)
    self.charLabel.Position = UDim2.new(1, -105, 0, 0)
    self.charLabel.BackgroundTransparency = 1
    self.charLabel.Text = "字符: 0"
    self.charLabel.TextColor3 = self.theme.Colors.TextDim
    self.charLabel.TextSize = self.config.fontSize.small
    self.charLabel.Font = Enum.Font.SourceSans
    self.charLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.charLabel.Parent = toolbar
    
    -- 代码编辑器
    local editorFrame = Instance.new("Frame")
    editorFrame.Size = UDim2.new(1, 0, 1, -80)
    editorFrame.Position = UDim2.new(0, 0, 0, 35)
    editorFrame.BackgroundColor3 = self.theme.Colors.Secondary
    editorFrame.BorderSizePixel = 0
    editorFrame.Parent = self.codeFrame
    
    self.theme:CreateCorner(8).Parent = editorFrame
    
    local editorScroll = Instance.new("ScrollingFrame")
    editorScroll.Size = UDim2.new(1, -10, 1, -10)
    editorScroll.Position = UDim2.new(0, 5, 0, 5)
    editorScroll.BackgroundTransparency = 1
    editorScroll.ScrollBarThickness = 4
    editorScroll.BorderSizePixel = 0
    editorScroll.Parent = editorFrame
    
    self.codeInput = Instance.new("TextBox")
    self.codeInput.Size = UDim2.new(1, 0, 1, 0)
    self.codeInput.BackgroundTransparency = 1
    self.codeInput.Text = "-- ProExecutor GitHub版\n-- 在这里编写你的代码\nprint('Hello from GitHub!')"
    self.codeInput.TextColor3 = self.theme.Colors.Text
    self.codeInput.TextSize = self.config.fontSize.normal
    self.codeInput.Font = Enum.Font.Code
    self.codeInput.TextXAlignment = Enum.TextXAlignment.Left
    self.codeInput.TextYAlignment = Enum.TextYAlignment.Top
    self.codeInput.MultiLine = true
    self.codeInput.ClearTextOnFocus = false
    self.codeInput.Parent = editorScroll
    
    -- 设置编辑器
    self.editor:SetupEditor(self.codeInput, editorScroll)
    
    -- 执行按钮
    self.executeBtn = Instance.new("TextButton")
    self.executeBtn.Size = UDim2.new(1, 0, 0, 40)
    self.executeBtn.Position = UDim2.new(0, 0, 1, -40)
    self.executeBtn.BackgroundColor3 = self.theme.Colors.Success
    self.executeBtn.Text = "▶ 执行代码"
    self.executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.executeBtn.TextSize = self.config.fontSize.title
    self.executeBtn.Font = Enum.Font.SourceSansBold
    self.executeBtn.BorderSizePixel = 0
    self.executeBtn.Parent = self.codeFrame
    
    self.theme:CreateCorner(8).Parent = self.executeBtn
end

function ProExecutor:CreateScriptsTab()
    self.scriptsFrame = Instance.new("Frame")
    self.scriptsFrame.Size = UDim2.new(1, 0, 1, 0)
    self.scriptsFrame.BackgroundTransparency = 1
    self.scriptsFrame.Visible = false
    self.scriptsFrame.Parent = self.contentFrame
    
    -- 脚本列表
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 1, -50)
    listFrame.BackgroundColor3 = self.theme.Colors.Secondary
    listFrame.BorderSizePixel = 0
    listFrame.Parent = self.scriptsFrame
    
    self.theme:CreateCorner(8).Parent = listFrame
    
    self.scriptsList = Instance.new("ScrollingFrame")
    self.scriptsList.Size = UDim2.new(1, -10, 1, -10)
    self.scriptsList.Position = UDim2.new(0, 5, 0, 5)
    self.scriptsList.BackgroundTransparency = 1
    self.scriptsList.ScrollBarThickness = 4
    self.scriptsList.BorderSizePixel = 0
    self.scriptsList.Parent = listFrame
    
    self.scriptsLayout = Instance.new("UIListLayout")
    self.scriptsLayout.Padding = UDim.new(0, 5)
    self.scriptsLayout.Parent = self.scriptsList
    
    -- 初始化脚本管理器
    self.scriptManager = ScriptManager.new(self.theme, self.storage, self.utils, self.outputManager)
    self.scriptManager:Setup(self.scriptsList, self.scriptsLayout)
    
    -- 按钮栏
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, 0, 0, 40)
    buttonFrame.Position = UDim2.new(0, 0, 1, -40)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = self.scriptsFrame
    
    self.saveBtn = self:CreateActionButton(buttonFrame, "💾", self.theme.Colors.Accent, UDim2.new(0, 0, 0, 0))
    self.exportBtn = self:CreateActionButton(buttonFrame, "📤", self.theme.Colors.Warning, UDim2.new(0, 85, 0, 0))
    self.importBtn = self:CreateActionButton(buttonFrame, "📥", self.theme.Colors.Success, UDim2.new(0, 170, 0, 0))
    self.deleteAllBtn = self:CreateActionButton(buttonFrame, "🗑️", self.theme.Colors.Error, UDim2.new(0, 255, 0, 0))
end

function ProExecutor:CreateOutputTab()
    self.outputFrame = Instance.new("Frame")
    self.outputFrame.Size = UDim2.new(1, 0, 1, 0)
    self.outputFrame.BackgroundTransparency = 1
    self.outputFrame.Visible = false
    self.outputFrame.Parent = self.contentFrame
    
    -- 输出显示区域
    local outputContainer = Instance.new("Frame")
    outputContainer.Size = UDim2.new(1, 0, 1, -50)
    outputContainer.BackgroundColor3 = self.theme.Colors.Secondary
    outputContainer.BorderSizePixel = 0
    outputContainer.Parent = self.outputFrame
    
    self.theme:CreateCorner(8).Parent = outputContainer
    
    self.outputScroll = Instance.new("ScrollingFrame")
    self.outputScroll.Size = UDim2.new(1, -10, 1, -10)
    self.outputScroll.Position = UDim2.new(0, 5, 0, 5)
    self.outputScroll.BackgroundTransparency = 1
    self.outputScroll.ScrollBarThickness = 4
    self.outputScroll.BorderSizePixel = 0
    self.outputScroll.Parent = outputContainer
    
    self.outputLayout = Instance.new("UIListLayout")
    self.outputLayout.Padding = UDim.new(0, 2)
    self.outputLayout.Parent = self.outputScroll
    
    -- 设置输出管理器
    self.outputManager:Setup(self.outputScroll, self.outputLayout)
    
    -- 清空输出按钮
    self.clearOutputBtn = Instance.new("TextButton")
    self.clearOutputBtn.Size = UDim2.new(1, 0, 0, 40)
    self.clearOutputBtn.Position = UDim2.new(0, 0, 1, -40)
    self.clearOutputBtn.BackgroundColor3 = self.theme.Colors.Warning
    self.clearOutputBtn.Text = "🗑️ 清空输出"
    self.clearOutputBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.clearOutputBtn.TextSize = self.config.fontSize.normal
    self.clearOutputBtn.Font = Enum.Font.SourceSansBold
    self.clearOutputBtn.BorderSizePixel = 0
    self.clearOutputBtn.Parent = self.outputFrame
    
    self.theme:CreateCorner(8).Parent = self.clearOutputBtn
end

function ProExecutor:CreateSettingsTab()
    self.settingsFrame = Instance.new("Frame")
    self.settingsFrame.Size = UDim2.new(1, 0, 1, 0)
    self.settingsFrame.BackgroundTransparency = 1
    self.settingsFrame.Visible = false
    self.settingsFrame.Parent = self.contentFrame
    
    local settingsContainer = Instance.new("Frame")
    settingsContainer.Size = UDim2.new(1, 0, 1, 0)
    settingsContainer.BackgroundColor3 = self.theme.Colors.Secondary
    settingsContainer.BorderSizePixel = 0
    settingsContainer.Parent = self.settingsFrame
    
    self.theme:CreateCorner(8).Parent = settingsContainer
    
    -- 设置内容
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -10)
    scrollFrame.Position = UDim2.new(0, 5, 0, 5)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Parent = settingsContainer
    
    -- 标题
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚙️ ProExecutor 设置"
    title.TextColor3 = self.theme.Colors.Text
    title.TextSize = self.config.fontSize.title + 2
    title.Font = Enum.Font.SourceSansBold
    title.Parent = scrollFrame
    
    -- 版本信息
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -20, 0, 30)
    versionLabel.Position = UDim2.new(0, 10, 0, 50)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "版本: " .. (self.version.version or "unknown") .. " (GitHub版)"
    versionLabel.TextColor3 = self.theme.Colors.TextDim
    versionLabel.TextSize = self.config.fontSize.normal
    versionLabel.Font = Enum.Font.SourceSans
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = scrollFrame
    
    -- 设备信息
    local deviceLabel = Instance.new("TextLabel")
    deviceLabel.Size = UDim2.new(1, -20, 0, 30)
    deviceLabel.Position = UDim2.new(0, 10, 0, 85)
    deviceLabel.BackgroundTransparency = 1
    deviceLabel.Text = "设备: " .. self.config.device .. " | 优化: " .. (self.config.touchOptimized and "移动端" or "桌面端")
    deviceLabel.TextColor3 = self.theme.Colors.TextDim
    deviceLabel.TextSize = self.config.fontSize.normal
    deviceLabel.Font = Enum.Font.SourceSans
    deviceLabel.TextXAlignment = Enum.TextXAlignment.Left
    deviceLabel.Parent = scrollFrame
    
    -- 存储状态
    local storageLabel = Instance.new("TextLabel")
    storageLabel.Size = UDim2.new(1, -20, 0, 30)
    storageLabel.Position = UDim2.new(0, 10, 0, 120)
    storageLabel.BackgroundTransparency = 1
    storageLabel.Text = "存储: " .. self.storage:GetStorageType()
    storageLabel.TextColor3 = self.theme.Colors.TextDim
    storageLabel.TextSize = self.config.fontSize.normal
    storageLabel.Font = Enum.Font.SourceSans
    storageLabel.TextXAlignment = Enum.TextXAlignment.Left
    storageLabel.Parent = scrollFrame
    
    -- 功能说明
    local helpText = Instance.new("TextLabel")
    helpText.Size = UDim2.new(1, -20, 0, 200)
    helpText.Position = UDim2.new(0, 10, 0, 165)
    helpText.BackgroundTransparency = 1
    helpText.Text = [[
📱 ProExecutor GitHub版说明：

🔧 模块化架构：
• 所有代码托管在GitHub
• 支持在线更新
• 模块化设计，易于维护

🚀 功能特色：
• 代码编辑和执行
• 脚本保存和管理
• 实时输出显示
• 导入导出功能
• 跨平台适配

💡 使用技巧：
• 拖拽移动窗口
• 支持多行代码编辑
• 自动保存功能
• 快捷键支持]]
    helpText.TextColor3 = self.theme.Colors.TextDim
    helpText.TextSize = self.config.fontSize.small + 1
    helpText.Font = Enum.Font.SourceSans
    helpText.TextXAlignment = Enum.TextXAlignment.Left
    helpText.TextYAlignment = Enum.TextYAlignment.Top
    helpText.TextWrapped = true
    helpText.Parent = scrollFrame
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 380)
end

function ProExecutor:CreateToolButton(parent, text, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 50, 0, 24)
    button.Position = position
    button.BackgroundColor3 = self.theme.Colors.Tertiary
    button.Text = text
    button.TextColor3 = self.theme.Colors.Text
    button.TextSize = self.config.fontSize.small
    button.Font = Enum.Font.SourceSans
    button.BorderSizePixel = 0
    button.Parent = parent
    
    self.theme:CreateCorner(4).Parent = button
    self.theme:AddHoverEffect(button, self.theme.Colors.Tertiary)
    
    return button
end

function ProExecutor:CreateActionButton(parent, text, color, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 1, 0)
    button.Position = position
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = self.config.fontSize.normal
    button.Font = Enum.Font.SourceSansBold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    self.theme:CreateCorner(6).Parent = button
    self.theme:AddHoverEffect(button, color)
    
    return button
end

function ProExecutor:SwitchTab(tabName)
    if not self.config.touchOptimized then return end
    
    -- 隐藏所有标签页
    self.codeFrame.Visible = false
    self.scriptsFrame.Visible = false
    self.outputFrame.Visible = false
    self.settingsFrame.Visible = false
    
    -- 重置按钮颜色
    self.codeTab.BackgroundColor3 = self.theme.Colors.Secondary
    self.scriptsTab.BackgroundColor3 = self.theme.Colors.Secondary
    self.outputTab.BackgroundColor3 = self.theme.Colors.Secondary
    self.settingsTab.BackgroundColor3 = self.theme.Colors.Secondary
    
    -- 显示对应标签页
    if tabName == "code" then
        self.codeFrame.Visible = true
        self.codeTab.BackgroundColor3 = self.theme.Colors.Accent
    elseif tabName == "scripts" then
        self.scriptsFrame.Visible = true
        self.scriptsTab.BackgroundColor3 = self.theme.Colors.Accent
    elseif tabName == "output" then
        self.outputFrame.Visible = true
        self.outputTab.BackgroundColor3 = self.theme.Colors.Accent
    elseif tabName == "settings" then
        self.settingsFrame.Visible = true
        self.settingsTab.BackgroundColor3 = self.theme.Colors.Accent
    end
end

function ProExecutor:SetupEventHandlers()
    if self.config.touchOptimized then
        -- 移动端事件
        self.codeTab.MouseButton1Click:Connect(function() self:SwitchTab("code") end)
        self.scriptsTab.MouseButton1Click:Connect(function() self:SwitchTab("scripts") end)
        self.outputTab.MouseButton1Click:Connect(function() self:SwitchTab("output") end)
        self.settingsTab.MouseButton1Click:Connect(function() self:SwitchTab("settings") end)
    end
    
    -- 通用事件
    self.executeBtn.MouseButton1Click:Connect(function() self:ExecuteCode() end)
    self.templateBtn.MouseButton1Click:Connect(function() self:ShowTemplates() end)
    self.clearBtn.MouseButton1Click:Connect(function() self:ClearCode() end)
    self.formatBtn.MouseButton1Click:Connect(function() self:FormatCode() end)
    
    if self.saveBtn then
        self.saveBtn.MouseButton1Click:Connect(function() self:SaveScript() end)
        self.exportBtn.MouseButton1Click:Connect(function() self.scriptManager:ExportScripts() end)
        self.importBtn.MouseButton1Click:Connect(function() self.scriptManager:ImportScripts() end)
        self.deleteAllBtn.MouseButton1Click:Connect(function() self:DeleteAllScripts() end)
    end
    
    self.clearOutputBtn.MouseButton1Click:Connect(function() self.outputManager:Clear() end)
    
    -- 窗口控制
    self.minimizeBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    self.closeBtn.MouseButton1Click:Connect(function() self.screenGui:Destroy() end)
    
    -- 编辑器事件
    self.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
        self:UpdateCharCount()
        self.editor:UpdateEditor()
    end)
    
    -- 脚本管理器回调
    if self.scriptManager then
        self.scriptManager:SetLoadCallback(function(code)
            self.codeInput.Text = code
            if self.config.touchOptimized then
                self:SwitchTab("code")
            end
        end)
    end
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
    if self.config.touchOptimized then return end -- 移动端不需要键盘快捷键
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        local isCtrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        
        if isCtrlDown then
            if input.KeyCode == Enum.KeyCode.Return then
                self:ExecuteCode()
            elseif input.KeyCode == Enum.KeyCode.S then
                self:SaveScript()
            elseif input.KeyCode == Enum.KeyCode.F then
                self:FormatCode()
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            local currentText = self.codeInput.Text
            self.codeInput.Text = currentText .. "    "
        end
    end)
end

function ProExecutor:UpdateCharCount()
    local text = self.codeInput.Text
    if self.charLabel then
        self.charLabel.Text = "字符: " .. #text
    end
end

function ProExecutor:ExecuteCode()
    local code = self.codeInput.Text
    self.codeExecutor:Execute(code)
end

function ProExecutor:ShowTemplates()
    self.utils:ShowTemplateMenu(self.screenGui, self.theme, self.config, function(template)
        self.codeInput.Text = self.codeInput.Text .. "\n" .. template
        self.outputManager:LogSuccess("📝 已插入模板")
    end)
end

function ProExecutor:ClearCode()
    self.codeInput.Text = ""
    self.outputManager:LogWarning("🗑️ 代码已清空")
end

function ProExecutor:FormatCode()
    local formatted = self.utils:FormatCode(self.codeInput.Text)
    self.codeInput.Text = formatted
    self.outputManager:LogSuccess("✨ 代码已格式化")
end

function ProExecutor:SaveScript()
    local code = self.codeInput.Text
    if code:gsub("%s", "") == "" then
        self.outputManager:LogError("❌ 代码为空，无法保存")
        return
    end
    
    local name = "脚本_" .. os.date("%H%M%S")
    if self.scriptManager then
        self.scriptManager:SaveScript(name, code)
    end
end

function ProExecutor:DeleteAllScripts()
    if self.scriptManager then
        self.scriptManager:DeleteAllScripts()
    end
end

function ProExecutor:ToggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then
        self.mainFrame:TweenSize(UDim2.new(0, 200, 0, 30), "Out", "Quad", 0.3, true)
        self.mainContainer.Visible = false
    else
        self.mainFrame:TweenSize(self.originalSize, "Out", "Quad", 0.3, true)
        wait(0.3)
        self.mainContainer.Visible = true
    end
end

function ProExecutor:LoadInitialData()
    -- 加载已保存的脚本
    if self.scriptManager then
        self.scriptManager:LoadSavedScripts()
    end
    
    self:UpdateCharCount()
end

-- 启动应用
local app = ProExecutor.new()

-- 导出到全局（用于调试）
_G.ProExecutor = app

print("ProExecutor GitHub版已成功启动！")