--[[
    编辑器功能模块 - 增强版
]]

local Editor = {}

function Editor.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.callbacks = {}
    
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
    
    function self:TriggerAutoComplete()
        if self.callbacks.onAutoComplete then
            local text = self.codeInput.Text
            local words = string.split(text, " ")
            local lastWord = words[#words] or ""
            if #lastWord > 0 then
                self.callbacks.onAutoComplete(lastWord)
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
        self:SetText("")
    end
    
    function self:SetCallback(event, callback)
        self.callbacks[event] = callback
    end
    
    return self
end

return Editor