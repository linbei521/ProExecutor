--[[
    工具函数模块
]]

local Utils = {}

Utils.CodeTemplates = {
    ["基础打印"] = "print('Hello World')",
    ["循环遍历"] = "for i = 1, 10 do\n    print(i)\nend",
    ["条件判断"] = "if condition then\n    -- 代码\nelse\n    -- 代码\nend",
    ["函数定义"] = "local function functionName(param)\n    -- 代码\n    return result\nend",
    ["玩家获取"] = "local player = game.Players.LocalPlayer\nlocal character = player.Character or player.CharacterAdded:Wait()\nlocal humanoid = character:WaitForChild('Humanoid')",
    ["远程事件"] = "local remote = game:GetService('ReplicatedStorage'):WaitForChild('RemoteName')\nremote:FireServer(args)",
    ["等待循环"] = "while wait(1) do\n    -- 每秒执行\nend",
    ["错误处理"] = "local success, result = pcall(function()\n    -- 可能出错的代码\nend)\n\nif success then\n    print('成功:', result)\nelse\n    warn('错误:', result)\nend",
    ["表遍历"] = "for key, value in pairs(table) do\n    print(key, value)\nend",
    ["服务获取"] = "local Players = game:GetService('Players')\nlocal RunService = game:GetService('RunService')\nlocal UserInputService = game:GetService('UserInputService')"
}

Utils.AutoCompleteWords = {
    "local", "function", "if", "then", "else", "elseif", "end",
    "for", "while", "do", "repeat", "until", "return", "break",
    "true", "false", "nil", "and", "or", "not", "in", "pairs", "ipairs",
    "game", "workspace", "script", "wait", "spawn", "delay",
    "Instance", "Vector3", "CFrame", "Color3", "UDim2",
    "print", "warn", "error", "typeof", "tostring", "tonumber",
    "Players", "Workspace", "ReplicatedStorage", "ServerStorage",
    "StarterGui", "StarterPack", "Lighting", "TweenService",
    "RunService", "UserInputService", "HttpService"
}

function Utils:FormatTimestamp()
    return os.date("%H:%M:%S")
end

function Utils:FormatCode(code)
    local lines = string.split(code, "\n")
    local formatted = {}
    local indent = 0
    
    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        
        if trimmed:match("^end") or trimmed:match("^else") or trimmed:match("^elseif") or trimmed:match("^until") then
            indent = math.max(0, indent - 1)
        end
        
        table.insert(formatted, string.rep("    ", indent) .. trimmed)
        
        if trimmed:match("then$") or trimmed:match("do$") or trimmed:match("function") or trimmed:match("repeat$") then
            indent = indent + 1
        end
    end
    
    return table.concat(formatted, "\n")
end

function Utils:ValidateScriptName(name)
    if not name or name:gsub("%s", "") == "" then
        return false, "脚本名不能为空"
    end
    if #name > 50 then
        return false, "脚本名过长"
    end
    return true
end

function Utils:ShowTemplateMenu(parent, theme, config, callback)
    local templateFrame = Instance.new("Frame")
    templateFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    templateFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    templateFrame.BackgroundColor3 = theme.Colors.Background
    templateFrame.BorderSizePixel = 0
    templateFrame.ZIndex = 10
    templateFrame.Parent = parent
    
    theme:CreateCorner(12).Parent = templateFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "📝 选择代码模板"
    title.TextColor3 = theme.Colors.Text
    title.TextSize = config.fontSize.title
    title.Font = Enum.Font.SourceSansBold
    title.Parent = templateFrame
    
    local templateScroll = Instance.new("ScrollingFrame")
    templateScroll.Size = UDim2.new(1, -20, 1, -100)
    templateScroll.Position = UDim2.new(0, 10, 0, 45)
    templateScroll.BackgroundTransparency = 1
    templateScroll.ScrollBarThickness = 4
    templateScroll.BorderSizePixel = 0
    templateScroll.Parent = templateFrame
    
    local templateLayout = Instance.new("UIListLayout")
    templateLayout.Padding = UDim.new(0, 5)
    templateLayout.Parent = templateScroll
    
    for name, code in pairs(self.CodeTemplates) do
        local templateItem = Instance.new("TextButton")
        templateItem.Size = UDim2.new(1, 0, 0, 40)
        templateItem.BackgroundColor3 = theme.Colors.Secondary
        templateItem.Text = name
        templateItem.TextColor3 = theme.Colors.Text
        templateItem.TextSize = config.fontSize.normal
        templateItem.Font = Enum.Font.SourceSansSemibold
        templateItem.BorderSizePixel = 0
        templateItem.Parent = templateScroll
        
        theme:CreateCorner(6).Parent = templateItem
        theme:AddHoverEffect(templateItem, theme.Colors.Secondary)
        
        templateItem.MouseButton1Click:Connect(function()
            callback(code)
            templateFrame:Destroy()
        end)
    end
    
    templateScroll.CanvasSize = UDim2.new(0, 0, 0, templateLayout.AbsoluteContentSize.Y)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -20, 0, 40)
    closeBtn.Position = UDim2.new(0, 10, 1, -50)
    closeBtn.BackgroundColor3 = theme.Colors.Error
    closeBtn.Text = "❌ 关闭"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = config.fontSize.normal
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = templateFrame
    
    theme:CreateCorner(8).Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        templateFrame:Destroy()
    end)
end

return Utils