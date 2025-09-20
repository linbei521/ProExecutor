--[[
    UI创建模块
]]

local UI = {}

function UI.new(theme, utils, config)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.config = config
    
    function self:CreateMainWindow()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "ProExecutor"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = game:GetService("CoreGui")
        
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, self.config.windowSize[1], 0, self.config.windowSize[2])
        mainFrame.Position = UDim2.new(0.5, -self.config.windowSize[1]/2, 0.5, -self.config.windowSize[2]/2)
        mainFrame.BackgroundColor3 = self.theme.Colors.Background
        mainFrame.BorderSizePixel = 0
        mainFrame.ClipsDescendants = true
        mainFrame.Active = true
        mainFrame.Parent = screenGui
        
        self.theme:CreateCorner(12).Parent = mainFrame
        self.theme:CreateBorder(1).Parent = mainFrame
        
        return screenGui, mainFrame
    end
    
    function self:CreateTopBar(parent)
        local topBar = Instance.new("Frame")
        topBar.Name = "TopBar"
        topBar.Size = UDim2.new(1, 0, 0, 30)
        topBar.BackgroundColor3 = self.theme.Colors.Secondary
        topBar.BorderSizePixel = 0
        topBar.Active = true
        topBar.Parent = parent
        
        self.theme:CreateCorner(12).Parent = topBar
        
        local topBarFix = Instance.new("Frame")
        topBarFix.Size = UDim2.new(1, 0, 0, 10)
        topBarFix.Position = UDim2.new(0, 0, 1, -10)
        topBarFix.BackgroundColor3 = self.theme.Colors.Secondary
        topBarFix.BorderSizePixel = 0
        topBarFix.Parent = topBar
        
        -- 标题
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.7, 0, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "ProExecutor GitHub版"
        title.TextColor3 = self.theme.Colors.Text
        title.TextSize = self.config.fontSize.title
        title.Font = Enum.Font.SourceSansSemibold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topBar
        
        -- 控制按钮
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Size = UDim2.new(0, 30, 0, 25)
        minimizeBtn.Position = UDim2.new(1, -65, 0, 2.5)
        minimizeBtn.BackgroundColor3 = self.theme.Colors.Warning
        minimizeBtn.Text = "─"
        minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.TextSize = 12
        minimizeBtn.Font = Enum.Font.SourceSansBold
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Parent = topBar
        
        self.theme:CreateCorner(6).Parent = minimizeBtn
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 25)
        closeBtn.Position = UDim2.new(1, -32, 0, 2.5)
        closeBtn.BackgroundColor3 = self.theme.Colors.Error
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 12
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.BorderSizePixel = 0
        closeBtn.Parent = topBar
        
        self.theme:CreateCorner(6).Parent = closeBtn
        
        return topBar, minimizeBtn, closeBtn
    end
    
    return self
end

return UI