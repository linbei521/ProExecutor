--[[
    编辑器功能模块 - 增强版
]]

local Editor = {}

function Editor.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.callbacks = {}
    self.syntaxHighlight = true
    self.lastText = ""
    self.highlightUpdateDebounce = false
    
    -- 语法高亮规则
    self.syntaxRules = {
        {pattern = "%-%-.-\n", color = theme.Colors.Comment, type = "comment"},
        {pattern = "\".-\"", color = theme.Colors.String, type = "string"},
        {pattern = "'.-'", color = theme.Colors.String, type = "string"},
        {pattern = "%d+%.?%d*", color = theme.Colors.Number, type = "number"},
        {pattern = "function%s+([%w_]+)", color = theme.Colors.Function, type = "function"},
        {pattern = "local%s+function%s+([%w_]+)", color = theme.Colors.Function, type = "function"},
    }
    
    -- Lua关键字
    self.keywords = {
        "local", "function", "end", "if", "then", "else", "elseif",
        "while", "for", "do", "repeat", "until", "break", "return",
        "and", "or", "not", "true", "false", "nil", "in", "pairs", "ipairs"
    }
    
    function self:SetupEditor(codeInput, lineNumberText, codeScroll, lineNumberScroll, charCount)
        self.codeInput = codeInput
        self.lineNumberText = lineNumberText
        self.codeScroll = codeScroll
        self.lineNumberScroll = lineNumberScroll
        self.charCount = charCount
        
        -- 创建语法高亮容器
        self.highlightFrame = Instance.new("Frame")
        self.highlightFrame.Size = UDim2.new(1, -8, 1, 0)
        self.highlightFrame.Position = UDim2.new(0, 4, 0, 0)
        self.highlightFrame.BackgroundTransparency = 1
        self.highlightFrame.ZIndex = self.codeInput.ZIndex - 1
        self.highlightFrame.Parent = self.codeScroll
        
        -- 使codeInput背景透明以显示语法高亮
        self.codeInput.BackgroundTransparency = 1
        self.codeInput.TextTransparency = 0.3  -- 让原文本半透明作为输入提示
        
        -- 同步滚动
        self.codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            self.lineNumberScroll.CanvasPosition = Vector2.new(0, self.codeScroll.CanvasPosition.Y)
        end)
        
        -- 监听文本变化
        self.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
            self:UpdateLineNumbers()
            self:UpdateSyntaxHighlight()
            self:TriggerAutoComplete()
        end)
        
        -- 监听光标位置变化（用于自动补全）
        self.codeInput:GetPropertyChangedSignal("CursorPosition"):Connect(function()
            self:OnCursorChanged()
        end)
        
        -- 初始化
        self:UpdateLineNumbers()
        self:UpdateSyntaxHighlight()
    end
    
    function self:UpdateSyntaxHighlight()
        if not self.syntaxHighlight or not self.highlightFrame then return end
        
        -- 防抖处理
        if self.highlightUpdateDebounce then return end
        self.highlightUpdateDebounce = true
        
        spawn(function()
            wait(0.1)  -- 短暂延迟避免频繁更新
            self:PerformSyntaxHighlight()
            self.highlightUpdateDebounce = false
        end)
    end
    
    function self:PerformSyntaxHighlight()
        if not self.highlightFrame then return end
        
        -- 清除旧的高亮
        for _, child in ipairs(self.highlightFrame:GetChildren()) do
            child:Destroy()
        end
        
        local text = self.codeInput.Text
        if text == self.lastText then return end
        self.lastText = text
        
        local lines = string.split(text, "\n")
        local yOffset = 0
        local lineHeight = 13
        
        for lineIndex, line in ipairs(lines) do
            self:HighlightLine(line, yOffset, lineIndex)
            yOffset = yOffset + lineHeight
        end
    end
    
    function self:HighlightLine(line, yOffset, lineIndex)
        local highlightedSegments = {}
        local currentPos = 1
        
        -- 处理注释（优先级最高）
        local commentStart = line:find("%-%-")
        if commentStart then
            -- 注释前的部分
            if commentStart > 1 then
                local beforeComment = line:sub(1, commentStart - 1)
                self:ProcessNormalText(beforeComment, highlightedSegments, currentPos)
            end
            -- 注释部分
            local comment = line:sub(commentStart)
            table.insert(highlightedSegments, {
                text = comment,
                color = self.theme.Colors.Comment,
                startPos = commentStart
            })
            self:CreateHighlightLabel(line, yOffset, highlightedSegments)
            return
        end
        
        -- 处理字符串
        line = self:ProcessStrings(line, highlightedSegments)
        
        -- 处理数字
        line = self:ProcessNumbers(line, highlightedSegments)
        
        -- 处理关键字
        line = self:ProcessKeywords(line, highlightedSegments)
        
        -- 创建高亮标签
        self:CreateHighlightLabel(line, yOffset, highlightedSegments)
    end
    
    function self:ProcessStrings(line, segments)
        -- 处理双引号字符串
        local processed = line:gsub("\"(.-)\"", function(content)
            table.insert(segments, {
                text = "\"" .. content .. "\"",
                color = self.theme.Colors.String
            })
            return string.rep("█", #content + 2)  -- 用特殊字符占位
        end)
        
        -- 处理单引号字符串
        processed = processed:gsub("'(.-)'", function(content)
            table.insert(segments, {
                text = "'" .. content .. "'",
                color = self.theme.Colors.String
            })
            return string.rep("█", #content + 2)
        end)
        
        return processed
    end
    
    function self:ProcessNumbers(line, segments)
        return line:gsub("%d+%.?%d*", function(number)
            table.insert(segments, {
                text = number,
                color = self.theme.Colors.Number
            })
            return string.rep("█", #number)
        end)
    end
    
    function self:ProcessKeywords(line, segments)
        local processed = line
        for _, keyword in ipairs(self.keywords) do
            processed = processed:gsub("%f[%a]" .. keyword .. "%f[%A]", function(match)
                table.insert(segments, {
                    text = match,
                    color = self.theme.Colors.Keyword
                })
                return string.rep("█", #match)
            end)
        end
        return processed
    end
    
    function self:CreateHighlightLabel(originalLine, yOffset, segments)
        if #segments == 0 then
            -- 没有特殊高亮，创建普通文本
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 13)
            label.Position = UDim2.new(0, 0, 0, yOffset)
            label.BackgroundTransparency = 1
            label.Text = originalLine
            label.TextColor3 = self.theme.Colors.Text
            label.TextSize = 11
            label.Font = Enum.Font.Code
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.Parent = self.highlightFrame
            return
        end
        
        -- 有高亮内容，需要分段处理
        local baseLabel = Instance.new("TextLabel")
        baseLabel.Size = UDim2.new(1, 0, 0, 13)
        baseLabel.Position = UDim2.new(0, 0, 0, yOffset)
        baseLabel.BackgroundTransparency = 1
        baseLabel.Text = originalLine
        baseLabel.TextColor3 = self.theme.Colors.Text
        baseLabel.TextSize = 11
        baseLabel.Font = Enum.Font.Code
        baseLabel.TextXAlignment = Enum.TextXAlignment.Left
        baseLabel.TextYAlignment = Enum.TextYAlignment.Top
        baseLabel.TextTransparency = 1  -- 隐藏基础文本
        baseLabel.Parent = self.highlightFrame
        
        -- 创建高亮片段
        for _, segment in ipairs(segments) do
            local segmentLabel = baseLabel:Clone()
            segmentLabel.Text = segment.text
            segmentLabel.TextColor3 = segment.color
            segmentLabel.TextTransparency = 0
            segmentLabel.Parent = self.highlightFrame
        end
    end
    
    function self:UpdateLineNumbers()
        if not self.codeInput then return end
        
        local text = self.codeInput.Text
        local lines = string.split(text, "\n")
        local lineNums = {}
        
        for i = 1, #lines do
            table.insert(lineNums, tostring(i))
        end
        
        self.lineNumberText.Text = table.concat(lineNums, "\n")
        
        local lineHeight = 13
        local totalHeight = #lines * lineHeight + 20
        
        self.codeScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        self.lineNumberScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        
        self.codeInput.Size = UDim2.new(1, -8, 0, math.max(self.codeScroll.AbsoluteSize.Y, totalHeight))
        self.lineNumberText.Size = UDim2.new(1, -3, 0, totalHeight)
        
        -- 更新高亮框架大小
        if self.highlightFrame then
            self.highlightFrame.Size = UDim2.new(1, -8, 0, math.max(self.codeScroll.AbsoluteSize.Y, totalHeight))
        end
        
        -- 更新字符计数
        if self.charCount then
            self.charCount.Text = string.format("行:%d 字:%d", #lines, #text)
        end
    end
    
    function self:OnCursorChanged()
        -- 延迟触发自动补全，避免频繁调用
        if self.autoCompleteTimer then
            self.autoCompleteTimer:Disconnect()
        end
        
        self.autoCompleteTimer = spawn(function()
            wait(0.3)  -- 300ms延迟
            self:TriggerAutoComplete()
        end)
    end
    
    function self:TriggerAutoComplete()
        if self.callbacks.onAutoComplete then
            local text = self.codeInput.Text
            local cursorPos = self.codeInput.CursorPosition
            
            -- 获取光标前的文本
            local beforeCursor = text:sub(1, cursorPos - 1)
            
            -- 查找当前词汇
            local currentWord = beforeCursor:match("([%w_]+)$") or ""
            
            if #currentWord >= 2 then  -- 至少2个字符才触发
                self.callbacks.onAutoComplete(currentWord)
            else
                -- 隐藏自动补全
                if self.callbacks.onHideAutoComplete then
                    self.callbacks.onHideAutoComplete()
                end
            end
        end
    end
    
    function self:SetText(text)
        if self.codeInput then
            self.codeInput.Text = text or ""
            self:UpdateLineNumbers()
            self:UpdateSyntaxHighlight()
        end
    end
    
    function self:GetText()
        return self.codeInput and self.codeInput.Text or ""
    end
    
    function self:FormatCode()
        local formatted = self.utils:FormatCode(self:GetText())
        self:SetText(formatted)
    end
    
    function self:ClearCode()
        self:SetText("-- 新脚本\n")
    end
    
    function self:SetCallback(event, callback)
        self.callbacks[event] = callback
    end
    
    function self:SetSyntaxHighlight(enabled)
        self.syntaxHighlight = enabled
        if enabled then
            self:UpdateSyntaxHighlight()
        else
            -- 清除高亮
            if self.highlightFrame then
                for _, child in ipairs(self.highlightFrame:GetChildren()) do
                    child:Destroy()
                end
            end
        end
    end
    
    return self
end

return Editor