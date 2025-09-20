--[[
    主题管理模块
]]

local Theme = {}

Theme.Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Secondary = Color3.fromRGB(28, 28, 35),
    Tertiary = Color3.fromRGB(35, 35, 42),
    Accent = Color3.fromRGB(88, 101, 242),
    Success = Color3.fromRGB(87, 202, 134),
    Error = Color3.fromRGB(237, 66, 69),
    Warning = Color3.fromRGB(255, 163, 26),
    Text = Color3.fromRGB(220, 221, 222),
    TextDim = Color3.fromRGB(163, 166, 168),
    Border = Color3.fromRGB(47, 49, 54),
    LineNumber = Color3.fromRGB(90, 90, 100),
    -- 语法高亮
    Keyword = Color3.fromRGB(198, 120, 221),
    String = Color3.fromRGB(152, 195, 121),
    Comment = Color3.fromRGB(92, 99, 112),
    Number = Color3.fromRGB(209, 154, 102),
    Function = Color3.fromRGB(97, 175, 239)
}

function Theme:CreateCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    return corner
end

function Theme:CreateBorder(thickness)
    local border = Instance.new("UIStroke")
    border.Color = self.Colors.Border
    border.Thickness = thickness or 1
    return border
end

function Theme:AddHoverEffect(button, normalColor, hoverMultiplier)
    local TweenService = game:GetService("TweenService")
    hoverMultiplier = hoverMultiplier or 1.2
    
    local function getHoverColor(color)
        return Color3.new(
            math.min(color.R * hoverMultiplier, 1),
            math.min(color.G * hoverMultiplier, 1),
            math.min(color.B * hoverMultiplier, 1)
        )
    end
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = getHoverColor(normalColor)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

return Theme