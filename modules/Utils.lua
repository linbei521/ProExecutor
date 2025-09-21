--[[
    工具函数模块 - 增强版
]]

local Utils = {}

Utils.CodeTemplates = {
    ["基础打印"] = "print('Hello World')",
    ["变量定义"] = "local variable = value",
    ["循环遍历"] = "for i = 1, 10 do\n    print(i)\nend",
    ["遍历表"] = "for key, value in pairs(table) do\n    print(key, value)\nend",
    ["数值循环"] = "for i = 1, #array do\n    print(array[i])\nend",
    ["While循环"] = "while condition do\n    -- 代码\n    wait()\nend",
    ["条件判断"] = "if condition then\n    -- 代码\nelseif other_condition then\n    -- 代码\nelse\n    -- 代码\nend",
    ["函数定义"] = "local function functionName(param1, param2)\n    -- 代码\n    return result\nend",
    ["匿名函数"] = "local func = function(param)\n    -- 代码\n    return result\nend",
    ["玩家获取"] = "local Players = game:GetService('Players')\nlocal player = Players.LocalPlayer\nlocal character = player.Character or player.CharacterAdded:Wait()\nlocal humanoid = character:WaitForChild('Humanoid')",
    ["角色检测"] = "local player = game.Players.LocalPlayer\nlocal function onCharacterAdded(character)\n    local humanoid = character:WaitForChild('Humanoid')\n    -- 角色加载完成\nend\n\nif player.Character then\n    onCharacterAdded(player.Character)\nend\nplayer.CharacterAdded:Connect(onCharacterAdded)",
    ["远程事件"] = "local ReplicatedStorage = game:GetService('ReplicatedStorage')\nlocal remote = ReplicatedStorage:WaitForChild('RemoteName')\nremote:FireServer(args)",
    ["远程函数"] = "local ReplicatedStorage = game:GetService('ReplicatedStorage')\nlocal remoteFunction = ReplicatedStorage:WaitForChild('RemoteFunctionName')\nlocal result = remoteFunction:InvokeServer(args)",
    ["等待循环"] = "while wait(1) do\n    -- 每秒执行一次\nend",
    ["RunService循环"] = "local RunService = game:GetService('RunService')\nlocal connection\nconnection = RunService.Heartbeat:Connect(function()\n    -- 每帧执行\n    -- connection:Disconnect() -- 取消连接\nend)",
    ["错误处理"] = "local success, result = pcall(function()\n    -- 可能出错的代码\n    return value\nend)\n\nif success then\n    print('成功:', result)\nelse\n    warn('错误:', result)\nend",
    ["异步错误处理"] = "spawn(function()\n    local success, result = pcall(function()\n        -- 异步代码\n        return value\n    end)\n    \n    if success then\n        print('异步成功:', result)\n    else\n        warn('异步错误:', result)\n    end\nend)",
    ["表操作"] = "local myTable = {}\ntable.insert(myTable, value)  -- 添加\ntable.remove(myTable, index)  -- 删除\nprint(#myTable)  -- 长度",
    ["字符串操作"] = "local text = 'Hello World'\nlocal parts = string.split(text, ' ')  -- 分割\nlocal upper = string.upper(text)  -- 大写\nlocal find = string.find(text, 'World')  -- 查找",
    ["服务获取"] = "local Players = game:GetService('Players')\nlocal RunService = game:GetService('RunService')\nlocal UserInputService = game:GetService('UserInputService')\nlocal ReplicatedStorage = game:GetService('ReplicatedStorage')",
    ["GUI创建"] = "local screenGui = Instance.new('ScreenGui')\nscreenGui.Parent = game.Players.LocalPlayer:WaitForChild('PlayerGui')\n\nlocal frame = Instance.new('Frame')\nframe.Size = UDim2.new(0, 200, 0, 100)\nframe.Position = UDim2.new(0.5, -100, 0.5, -50)\nframe.Parent = screenGui",
    ["按钮事件"] = "local button = script.Parent -- 或者你的按钮实例\nbutton.MouseButton1Click:Connect(function()\n    print('按钮被点击了!')\nend)",
    ["Tween动画"] = "local TweenService = game:GetService('TweenService')\nlocal info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)\nlocal tween = TweenService:Create(object, info, {Property = value})\ntween:Play()",
    ["协程处理"] = "local co = coroutine.create(function()\n    while true do\n        print('协程运行中')\n        coroutine.yield()  -- 暂停\n    end\nend)\n\ncoroutine.resume(co)  -- 开始/恢复"
}

Utils.AutoCompleteWords = {
    -- Lua 基础关键字
    "local", "function", "if", "then", "else", "elseif", "end",
    "for", "while", "do", "repeat", "until", "return", "break",
    "true", "false", "nil", "and", "or", "not", "in", "pairs", "ipairs",
    
    -- 常用函数
    "print", "warn", "error", "assert", "typeof", "tostring", "tonumber",
    "next", "select", "unpack", "getmetatable", "setmetatable",
    "rawget", "rawset", "rawequal", "rawlen",
    "pcall", "xpcall", "loadstring", "getfenv", "setfenv",
    
    -- Roblox 全局对象
    "game", "workspace", "script", "wait", "spawn", "delay", "tick",
    "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim",
    "BrickColor", "Ray", "Region3", "Enum",
    
    -- Roblox 服务
    "Players", "Workspace", "ReplicatedStorage", "ServerStorage",
    "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService",
    "TweenService", "RunService", "UserInputService", "HttpService",
    "ContentProvider", "Debris", "MarketplaceService", "TeleportService",
    "DataStoreService", "MessagingService", "BadgeService",
    "GroupService", "FriendService", "ChatService",
    
    -- Instance 方法
    "FindFirstChild", "WaitForChild", "GetChildren", "GetDescendants",
    "Clone", "Destroy", "IsA", "FindFirstAncestor", "GetFullName",
    "GetService", "GetPropertyChangedSignal",
    
    -- 常用属性
    "Name", "Parent", "Size", "Position", "Rotation", "CFrame", "Color",
    "Transparency", "CanCollide", "Anchored", "Material", "Shape",
    "Text", "TextColor3", "TextSize", "Font", "BackgroundColor3",
    "BackgroundTransparency", "BorderSizePixel", "Visible",
    
    -- 事件
    "Changed", "ChildAdded", "ChildRemoved", "AncestryChanged",
    "MouseButton1Click", "MouseButton2Click", "MouseEnter", "MouseLeave",
    "KeyDown", "KeyUp", "InputBegan", "InputEnded", "InputChanged",
    "CharacterAdded", "CharacterRemoving", "PlayerAdded", "PlayerRemoving",
    "Heartbeat", "Stepped", "RenderStepped",
    
    -- 数学函数
    "math.abs", "math.acos", "math.asin", "math.atan", "math.atan2",
    "math.ceil", "math.cos", "math.deg", "math.exp", "math.floor",
    "math.fmod", "math.frexp", "math.huge", "math.ldexp", "math.log",
    "math.log10", "math.max", "math.min", "math.modf", "math.pi",
    "math.pow", "math.rad", "math.random", "math.randomseed", "math.sin",
    "math.sqrt", "math.tan", "math.clamp", "math.sign", "math.noise",
    
    -- 字符串函数
    "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len",
    "string.lower", "string.match", "string.rep", "string.reverse",
    "string.sub", "string.upper", "string.split",
    
    -- 表函数
    "table.concat", "table.insert", "table.maxn", "table.remove",
    "table.sort", "table.foreach", "table.foreachi", "table.getn",
    "table.find", "table.clear", "table.create", "table.move"
}

function Utils:FormatTimestamp()
    return os.date("%H:%M:%S")
end

function Utils:FormatCode(code)
    if not code or code == "" then return code end
    
    local lines = string.split(code, "\n")
    local formatted = {}
    local indent = 0
    local inMultiLineString = false
    local stringDelimiter = nil
    
    for lineNum, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$") or ""
        
        -- 处理空行
        if trimmed == "" then
            table.insert(formatted, "")
            continue
        end
        
        -- 检查多行字符串
        if not inMultiLineString then
            local doubleQuoteCount = 0
            local singleQuoteCount = 0
            for i = 1, #trimmed do
                local char = trimmed:sub(i, i)
                if char == '"' and (i == 1 or trimmed:sub(i-1, i-1) ~= "\\") then
                    doubleQuoteCount = doubleQuoteCount + 1
                elseif char == "'" and (i == 1 or trimmed:sub(i-1, i-1) ~= "\\") then
                    singleQuoteCount = singleQuoteCount + 1
                end
            end
            
            if doubleQuoteCount % 2 == 1 then
                inMultiLineString = true
                stringDelimiter = '"'
            elseif singleQuoteCount % 2 == 1 then
                inMultiLineString = true
                stringDelimiter = "'"
            end
        else
            -- 检查多行字符串是否结束
            local count = 0
            for i = 1, #trimmed do
                local char = trimmed:sub(i, i)
                if char == stringDelimiter and (i == 1 or trimmed:sub(i-1, i-1) ~= "\\") then
                    count = count + 1
                end
            end
            if count % 2 == 1 then
                inMultiLineString = false
                stringDelimiter = nil
            end
        end
        
        -- 如果在多行字符串中，保持原有缩进
        if inMultiLineString then
            table.insert(formatted, string.rep("    ", indent) .. trimmed)
            continue
        end
        
        -- 处理注释行，保持缩进但不影响后续缩进
        if trimmed:match("^%-%-") then
            table.insert(formatted, string.rep("    ", indent) .. trimmed)
            continue
        end
        
        -- 减少缩进的关键字
        local decreaseKeywords = {
            "^end%s*$", "^end%s*%)%s*$", "^else%s*$", "^elseif%s+", "^until%s+"
        }
        
        local shouldDecrease = false
        for _, pattern in ipairs(decreaseKeywords) do
            if trimmed:match(pattern) then
                shouldDecrease = true
                break
            end
        end
        
        if shouldDecrease then
            indent = math.max(0, indent - 1)
        end
        
        -- 添加格式化的行
        table.insert(formatted, string.rep("    ", indent) .. trimmed)
        
        -- 增加缩进的关键字
        local increaseKeywords = {
            "then%s*$", "do%s*$", "repeat%s*$", "else%s*$",
            "function%s*%(.*%)%s*$", "function%s+%w+%s*%(.*%)%s*$",
            "local%s+function%s+%w+%s*%(.*%)%s*$"
        }
        
        local shouldIncrease = false
        for _, pattern in ipairs(increaseKeywords) do
            if trimmed:match(pattern) then
                shouldIncrease = true
                break
            end
        end
        
        -- 特殊处理：if without then, for/while without do
        if trimmed:match("^if%s+") and not trimmed:match("then%s*$") then
            shouldIncrease = true
        elseif trimmed:match("^for%s+") and not trimmed:match("do%s*$") then
            shouldIncrease = true
        elseif trimmed:match("^while%s+") and not trimmed:match("do%s*$") then
            shouldIncrease = true
        end
        
        if shouldIncrease then
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
        return false, "脚本名过长 (最多50个字符)"
    end
    if name:match("[<>:\"/\\|?*]") then
        return false, "脚本名包含非法字符"
    end
    return true
end

function Utils:EscapeString(str)
    return str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\t", "\\t")
end

function Utils:UnescapeString(str)
    return str:gsub("\\\\", "\\"):gsub("\\\"", "\""):gsub("\\n", "\n"):gsub("\\t", "\t")
end

function Utils:ShowTemplateMenu(parent, theme, config, callback)
    local templateFrame = Instance.new("Frame")
    templateFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    templateFrame.Position = UDim2.new(0.05, 0, 0.075, 0)
    templateFrame.BackgroundColor3 = theme.Colors.Background
    templateFrame.BorderSizePixel = 0
    templateFrame.ZIndex = 15
    templateFrame.Parent = parent
    
    theme:CreateCorner(12).Parent = templateFrame
    theme:CreateBorder(2).Parent = templateFrame
    
    -- 半透明背景
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 10
    overlay.Parent = parent
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "📝 选择代码模板"
    title.TextColor3 = theme.Colors.Text
    title.TextSize = config.fontSize.title
    title.Font = Enum.Font.SourceSansBold
    title.Parent = templateFrame
    
    -- 搜索框
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(1, -20, 0, 30)
    searchContainer.Position = UDim2.new(0, 10, 0, 45)
    searchContainer.BackgroundColor3 = theme.Colors.Secondary
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = templateFrame
    
    theme:CreateCorner(6).Parent = searchContainer
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 1, -6)
    searchBox.Position = UDim2.new(0, 10, 0, 3)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "🔍 搜索模板..."
    searchBox.PlaceholderColor3 = theme.Colors.TextDim
    searchBox.TextColor3 = theme.Colors.Text
    searchBox.TextSize = config.fontSize.normal
    searchBox.Font = Enum.Font.SourceSans
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    
    local templateScroll = Instance.new("ScrollingFrame")
    templateScroll.Size = UDim2.new(1, -20, 1, -140)
    templateScroll.Position = UDim2.new(0, 10, 0, 80)
    templateScroll.BackgroundTransparency = 1
    templateScroll.ScrollBarThickness = 4
    templateScroll.ScrollBarImageColor3 = theme.Colors.Border
    templateScroll.BorderSizePixel = 0
    templateScroll.Parent = templateFrame
    
    local templateLayout = Instance.new("UIListLayout")
    templateLayout.Padding = UDim.new(0, 5)
    templateLayout.Parent = templateScroll
    
    local function createTemplateItems(filter)
        -- 清除现有项目
        for _, child in ipairs(templateScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        filter = filter and filter:lower() or ""
        
        for name, code in pairs(self.CodeTemplates) do
            if filter == "" or name:lower():find(filter, 1, true) or code:lower():find(filter, 1, true) then
                local templateItem = Instance.new("TextButton")
                templateItem.Size = UDim2.new(1, 0, 0, 50)
                templateItem.BackgroundColor3 = theme.Colors.Secondary
                templateItem.Text = ""
                templateItem.BorderSizePixel = 0
                templateItem.Parent = templateScroll
                
                theme:CreateCorner(8).Parent = templateItem
                theme:AddHoverEffect(templateItem, theme.Colors.Secondary)
                
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, -16, 0, 20)
                titleLabel.Position = UDim2.new(0, 8, 0, 5)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name
                titleLabel.TextColor3 = theme.Colors.Text
                titleLabel.TextSize = config.fontSize.normal
                titleLabel.Font = Enum.Font.SourceSansSemibold
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = templateItem
                
                local codePreview = Instance.new("TextLabel")
                codePreview.Size = UDim2.new(1, -16, 0, 20)
                codePreview.Position = UDim2.new(0, 8, 0, 25)
                codePreview.BackgroundTransparency = 1
                codePreview.Text = code:gsub("\n", " "):sub(1, 60) .. (code:len() > 60 and "..." or "")
                codePreview.TextColor3 = theme.Colors.TextDim
                codePreview.TextSize = config.fontSize.small
                codePreview.Font = Enum.Font.Code
                codePreview.TextXAlignment = Enum.TextXAlignment.Left
                codePreview.TextTruncate = Enum.TextTruncate.AtEnd
                codePreview.Parent = templateItem
                
                templateItem.MouseButton1Click:Connect(function()
                    callback(code)
                    templateFrame:Destroy()
                    overlay:Destroy()
                end)
            end
        end
        
        templateScroll.CanvasSize = UDim2.new(0, 0, 0, templateLayout.AbsoluteContentSize.Y + 10)
    end
    
    -- 搜索功能
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        createTemplateItems(searchBox.Text)
    end)
    
    -- 初始创建所有项目
    createTemplateItems()
    
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
        overlay:Destroy()
    end)
    
    -- 点击背景关闭
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            templateFrame:Destroy()
            overlay:Destroy()
        end
    end)
    
    -- 聚焦搜索框
    searchBox:CaptureFocus()
end

return Utils