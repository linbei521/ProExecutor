--[[
    自动补全模块 - 完整实现
]]

local AutoComplete = {}

function AutoComplete.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.visible = false
    self.lastWord = ""
    
    function self:Setup(autoCompleteFrame, autoCompleteScroll, autoCompleteLayout)
        self.frame = autoCompleteFrame
        self.scroll = autoCompleteScroll
        self.layout = autoCompleteLayout
    end
    
    function self:Show(word, position)
        if #word <= 2 or word == self.lastWord then
            self:Hide()
            return
        end
        
        self.lastWord = word
        self:ClearItems()
        
        local matches = self:GetMatches(word)
        if #matches == 0 then
            self:Hide()
            return
        end
        
        self:CreateItems(matches)
        self:UpdateSize(#matches)
        self:UpdatePosition(position)
        self.frame.Visible = true
        self.visible = true
    end
    
    function self:Hide()
        if self.frame then
            self.frame.Visible = false
        end
        self.visible = false
        self.lastWord = ""
    end
    
    function self:GetMatches(word)
        local matches = {}
        local lowerWord = word:lower()
        
        for _, keyword in ipairs(self.utils.AutoCompleteWords) do
            if keyword:lower():sub(1, #word) == lowerWord and keyword ~= word then
                table.insert(matches, keyword)
                if #matches >= 10 then break end
            end
        end
        
        return matches
    end
    
    function self:ClearItems()
        if not self.scroll then return end
        
        for _, child in ipairs(self.scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
    
    function self:CreateItems(matches)
        if not self.scroll then return end
        
        for _, match in ipairs(matches) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 18)
            item.BackgroundColor3 = self.theme.Colors.Tertiary
            item.Text = match
            item.TextColor3 = self.theme.Colors.Text
            item.TextSize = 10
            item.Font = Enum.Font.Code
            item.BorderSizePixel = 0
            item.Parent = self.scroll
            
            item.MouseButton1Click:Connect(function()
                if self.onSelect then
                    self.onSelect(match, self.lastWord)
                end
                self:Hide()
            end)
            
            -- 悬停效果
            self.theme:AddHoverEffect(item, self.theme.Colors.Tertiary, 1.1)
        end
    end
    
    function self:UpdateSize(itemCount)
        if not self.frame then return end
        
        local height = math.min(100, itemCount * 19 + 4)
        self.frame.Size = UDim2.new(0, 150, 0, height)
        
        if self.scroll then
            self.scroll.CanvasSize = UDim2.new(0, 0, 0, itemCount * 19)
        end
    end
    
    function self:UpdatePosition(position)
        if position and self.frame then
            self.frame.Position = position
        end
    end
    
    function self:SetSelectCallback(callback)
        self.onSelect = callback
    end
    
    return self
end

return AutoComplete