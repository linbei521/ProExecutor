--[[
    UI创建模块 - 增强版
]]

local UI = {}

function UI.new(theme, utils, config)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.config = config or {}
    
    -- 创建可折叠侧边栏
    function self:CreateCollapsibleSidePanel(parent)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 100, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = parent
        
        -- 侧边栏主体
        local sidePanel = Instance.new("Frame")
        sidePanel.Size = UDim2.new(1, 0, 1, 0)
        sidePanel.BackgroundColor3 = self.theme.Colors.Secondary
        sidePanel.BorderSizePixel = 0
        sidePanel.Parent = container
        
        self.theme:CreateCorner(6).Parent = sidePanel
        
        -- Tab容器（包含折叠按钮）
        local tabContainer = Instance.new("Frame")
        tabContainer.Size = UDim2.new(1, 0, 0, 22)
        tabContainer.BackgroundColor3 = self.theme.Colors.Tertiary
        tabContainer.BorderSizePixel = 0
        tabContainer.Parent = sidePanel
        
        self.theme:CreateCorner(6).Parent = tabContainer
        
        -- 折叠按钮（集成在Tab栏右侧）
        local collapseBtn = Instance.new("TextButton")
        collapseBtn.Size = UDim2.new(0, 16, 1, -4)
        collapseBtn.Position = UDim2.new(1, -18, 0, 2)
        collapseBtn.BackgroundColor3 = self.theme.Colors.Background
        collapseBtn.Text = "‹"  -- 使用更好看的符号
        collapseBtn.TextColor3 = self.theme.Colors.Text
        collapseBtn.TextSize = 12
        collapseBtn.Font = Enum.Font.SourceSansBold
        collapseBtn.BorderSizePixel = 0
        collapseBtn.Parent = tabContainer
        
        self.theme:CreateCorner(3).Parent = collapseBtn
        self.theme:AddHoverEffect(collapseBtn, self.theme.Colors.Background)
        
        -- 内容容器
        local contentContainer = Instance.new("Frame")
        contentContainer.Size = UDim2.new(1, 0, 1, -22)
        contentContainer.Position = UDim2.new(0, 0, 0, 22)
        contentContainer.BackgroundTransparency = 1
        contentContainer.Parent = sidePanel
        
        return {
            container = container,
            collapseBtn = collapseBtn,
            sidePanel = sidePanel,
            tabContainer = tabContainer,
            contentContainer = contentContainer
        }
    end
    
    -- 创建Tab按钮（为折叠按钮留出空间）
    function self:CreateTabButton(parent, text, position, active)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0.5, -10, 1, -4)  -- 减少宽度为折叠按钮留空间
        tab.Position = position
        tab.BackgroundColor3 = active and self.theme.Colors.Accent or self.theme.Colors.Background
        tab.Text = text
        tab.TextColor3 = self.theme.Colors.Text
        tab.TextSize = 9
        tab.Font = Enum.Font.SourceSansSemibold
        tab.BorderSizePixel = 0
        tab.Parent = parent
        
        self.theme:CreateCorner(4).Parent = tab
        self.theme:AddHoverEffect(tab, tab.BackgroundColor3)
        
        return tab
    end
    
    -- 创建脚本列表面板
    function self:CreateScriptListPanel(parent)
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundTransparency = 1
        panel.Visible = true
        panel.Parent = parent
        
        -- 标题
        local header = self:CreatePanelHeader(panel, "脚本列表")
        
        -- 滚动框
        local scroll = self:CreateScrollingFrame(panel, UDim2.new(1, -4, 1, -42), UDim2.new(0, 2, 0, 22))
        
        -- 新建按钮
        local newBtn = Instance.new("TextButton")
        newBtn.Size = UDim2.new(1, -4, 0, 16)
        newBtn.Position = UDim2.new(0, 2, 1, -18)
        newBtn.BackgroundColor3 = self.theme.Colors.Accent
        newBtn.Text = "新建"
        newBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        newBtn.TextSize = 9
        newBtn.Font = Enum.Font.SourceSansSemibold
        newBtn.BorderSizePixel = 0
        newBtn.Parent = panel
        
        self.theme:CreateCorner(4).Parent = newBtn
        self.theme:AddHoverEffect(newBtn, self.theme.Colors.Accent)
        
        return {
            panel = panel,
            header = header,
            scroll = scroll.frame,
            layout = scroll.layout,
            newBtn = newBtn
        }
    end
    
    -- 创建HttpSpy面板
    function self:CreateHttpSpyPanel(parent)
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.BackgroundTransparency = 1
        panel.Visible = false
        panel.Parent = parent
        
        -- 标题栏
        local header = self:CreatePanelHeader(panel, "HTTP监控")
        
        -- 开关按钮
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 30, 0, 14)
        toggleBtn.Position = UDim2.new(1, -32, 0.5, -7)
        toggleBtn.BackgroundColor3 = self.theme.Colors.Success
        toggleBtn.Text = "开启"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 8
        toggleBtn.Font = Enum.Font.SourceSansSemibold
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Parent = header
        
        self.theme:CreateCorner(3).Parent = toggleBtn
        
        -- 日志滚动框
        local logScroll = self:CreateScrollingFrame(panel, UDim2.new(1, -4, 1, -42), UDim2.new(0, 2, 0, 22))
        
        -- 清除按钮
        local clearBtn = Instance.new("TextButton")
        clearBtn.Size = UDim2.new(1, -4, 0, 16)
        clearBtn.Position = UDim2.new(0, 2, 1, -18)
        clearBtn.BackgroundColor3 = self.theme.Colors.Error
        clearBtn.Text = "清除"
        clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        clearBtn.TextSize = 9
        clearBtn.Font = Enum.Font.SourceSansSemibold
        clearBtn.BorderSizePixel = 0
        clearBtn.Parent = panel
        
        self.theme:CreateCorner(4).Parent = clearBtn
        self.theme:AddHoverEffect(clearBtn, self.theme.Colors.Error)
        
        return {
            panel = panel,
            header = header,
            toggleBtn = toggleBtn,
            logScroll = logScroll.frame,
            logLayout = logScroll.layout,
            clearBtn = clearBtn
        }
    end
    
    -- 创建HttpSpy详细界面
    function self:CreateHttpSpyInterface(parent)
        local interface = Instance.new("Frame")
        interface.Size = UDim2.new(1, 0, 1, 0)
        interface.BackgroundTransparency = 1
        interface.Visible = false
        interface.Parent = parent
        
        -- 工具栏
        local toolBar = self:CreateToolBar(interface)
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(0.5, 0, 1, 0)
        title.Position = UDim2.new(0, 8, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "HTTP 请求监控"
        title.TextColor3 = self.theme.Colors.Text
        title.TextSize = 11
        title.Font = Enum.Font.SourceSansSemibold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = toolBar
        
        -- 状态标签
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(0, 80, 1, 0)
        statusLabel.Position = UDim2.new(1, -80, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "未启动"
        statusLabel.TextColor3 = self.theme.Colors.TextDim
        statusLabel.TextSize = 10
        statusLabel.Font = Enum.Font.SourceSans
        statusLabel.TextXAlignment = Enum.TextXAlignment.Right
        statusLabel.Parent = toolBar
        
        -- 详细日志容器
        local detailContainer = Instance.new("Frame")
        detailContainer.Size = UDim2.new(1, 0, 1, -24)
        detailContainer.Position = UDim2.new(0, 0, 0, 24)
        detailContainer.BackgroundColor3 = self.theme.Colors.Secondary
        detailContainer.BorderSizePixel = 0
        detailContainer.Parent = interface
        
        self.theme:CreateCorner(6).Parent = detailContainer
        
        -- 详细日志滚动框
        local detailScroll = self:CreateScrollingFrame(detailContainer, UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4))
        
        return {
            interface = interface,
            toolBar = toolBar,
            statusLabel = statusLabel,
            detailContainer = detailContainer,
            detailScroll = detailScroll.frame,
            detailLayout = detailScroll.layout
        }
    end
    
    -- 辅助方法：创建面板标题
    function self:CreatePanelHeader(parent, text)
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 18)
        header.Position = UDim2.new(0, 0, 0, 2)
        header.BackgroundColor3 = self.theme.Colors.Tertiary
        header.BorderSizePixel = 0
        header.Parent = parent
        
        self.theme:CreateCorner(4).Parent = header
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = self.theme.Colors.Text
        label.TextSize = 9
        label.Font = Enum.Font.SourceSansSemibold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = header
        
        return header
    end
    
    -- 辅助方法：创建滚动框
    function self:CreateScrollingFrame(parent, size, position)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = size
        scroll.Position = position
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = self.theme.Colors.Border
        scroll.BorderSizePixel = 0
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.Parent = parent
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 1)
        layout.Parent = scroll
        
        return {
            frame = scroll,
            layout = layout
        }
    end
    
    -- 辅助方法：创建工具栏
    function self:CreateToolBar(parent)
        local toolBar = Instance.new("Frame")
        toolBar.Size = UDim2.new(1, 0, 0, 24)
        toolBar.BackgroundColor3 = self.theme.Colors.Tertiary
        toolBar.BorderSizePixel = 0
        toolBar.Parent = parent
        
        self.theme:CreateCorner(6).Parent = toolBar
        
        return toolBar
    end
    
    -- 辅助方法：创建工具按钮
    function self:CreateToolButton(parent, text, position)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 50, 0, 18)
        button.Position = position
        button.BackgroundColor3 = self.theme.Colors.Secondary
        button.Text = text
        button.TextColor3 = self.theme.Colors.Text
        button.TextSize = 10
        button.Font = Enum.Font.SourceSans
        button.BorderSizePixel = 0
        button.Parent = parent
        
        self.theme:CreateCorner(3).Parent = button
        self.theme:AddHoverEffect(button, self.theme.Colors.Secondary)
        
        return button
    end
    
    -- 辅助方法：创建动作按钮
    function self:CreateActionButton(parent, text, color, position)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 55, 1, 0)
        button.Position = position
        button.BackgroundColor3 = color
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 11
        button.Font = Enum.Font.SourceSansSemibold
        button.BorderSizePixel = 0
        button.Parent = parent
        
        self.theme:CreateCorner(4).Parent = button
        self.theme:AddHoverEffect(button, color)
        
        return button
    end
    
    return self
end

return UI