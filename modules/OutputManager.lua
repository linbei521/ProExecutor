--[[
    输出管理模块
]]

local OutputManager = {}

function OutputManager.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.outputCount = 0
    self.maxOutputs = 30
    
    function self:Setup(outputScroll, outputLayout)
        self.outputScroll = outputScroll
        self.outputLayout = outputLayout
    end
    
    function self:AddOutput(text, color, level)
        if not self.outputScroll then return end
        
        self.outputCount = self.outputCount + 1
        
        local outputItem = Instance.new("TextLabel")
        outputItem.Size = UDim2.new(1, 0, 0, 0)
        outputItem.AutomaticSize = Enum.AutomaticSize.Y
        outputItem.BackgroundTransparency = 1
        outputItem.Text = string.format("[%s] %s", self.utils:FormatTimestamp(), text)
        outputItem.TextColor3 = color or self.theme.Colors.Text
        outputItem.TextSize = 11
        outputItem.Font = Enum.Font.Code
        outputItem.TextXAlignment = Enum.TextXAlignment.Left
        outputItem.TextWrapped = true
        outputItem.LayoutOrder = self.outputCount
        outputItem.Parent = self.outputScroll
        
        self:UpdateScroll()
        self:CleanupOldOutputs()
    end
    
    function self:UpdateScroll()
        if not self.outputLayout then return end
        self.outputScroll.CanvasSize = UDim2.new(0, 0, 0, self.outputLayout.AbsoluteContentSize.Y)
        self.outputScroll.CanvasPosition = Vector2.new(0, self.outputLayout.AbsoluteContentSize.Y)
    end
    
    function self:CleanupOldOutputs()
        local children = self.outputScroll:GetChildren()
        local labels = {}
        
        for _, child in ipairs(children) do
            if child:IsA("TextLabel") then
                table.insert(labels, child)
            end
        end
        
        if #labels > self.maxOutputs then
            for i = 1, #labels - self.maxOutputs do
                labels[i]:Destroy()
            end
        end
    end
    
    function self:Clear()
        for _, child in ipairs(self.outputScroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        self.outputCount = 0
        self:LogWarning("🗑️ 输出已清空")
    end
    
    function self:LogInfo(text)
        self:AddOutput(text, self.theme.Colors.Text, "info")
    end
    
    function self:LogSuccess(text)
        self:AddOutput(text, self.theme.Colors.Success, "success")
    end
    
    function self:LogWarning(text)
        self:AddOutput(text, self.theme.Colors.Warning, "warning")
    end
    
    function self:LogError(text)
        self:AddOutput(text, self.theme.Colors.Error, "error")
    end
    
    return self
end

return OutputManager