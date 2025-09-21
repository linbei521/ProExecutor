--[[
    编辑器功能模块 - 无语法高亮版本
]]

local Editor = {}

function Editor.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.callbacks = {}
    self.lastText = ""
    
    function self:SetupEditor(codeInput, lineNumberText, codeScroll, lineNumberScroll, charCount)
        self.codeInput = codeInput
        self.lineNumberText = lineNumberText
        self.codeScroll = codeScroll
        self.lineNumberScroll = lineNumberScroll
        self.charCount = charCount
        
        -- 同步滚动
        self.codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            self.lineNumberScroll.CanvasPosition = Vector2.new(0, self.codeScroll.CanvasPosition.Y)
        end)
        
        -- 监听文本变化
        self.codeInput:GetPropertyChangedSignal("Text"):Connect(function()
            self:UpdateLineNumbers()
            self:TriggerAutoComplete()
        end)
        
        -- 监听光标位置变化（用于自动补全）
        self.codeInput:GetPropertyChangedSignal("CursorPosition"):Connect(function()
            self:OnCursorChanged()
        end)
        
        -- 初始化
        self:UpdateLineNumbers()
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
    
    return self
end

return Editor