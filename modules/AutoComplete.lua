--[[
    自动补全模块 - 增强版
]]

local AutoComplete = {}

function AutoComplete.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.visible = false
    self.lastWord = ""
    self.selectedIndex = 1
    self.matches = {}
    
    function self:Setup(autoCompleteFrame, autoCompleteScroll, autoCompleteLayout)
        self.frame = autoCompleteFrame
        self.scroll = autoCompleteScroll
        self.layout = autoCompleteLayout
        
        -- 设置键盘导航
        self:SetupKeyboardNavigation()
    end
    
    function self:SetupKeyboardNavigation()
        local UserInputService = game:GetService("UserInputService")
        
        UserInputService.InputBegan:Connect(function(input, processed)
            if not self.visible or processed then return end
            
            if input.KeyCode == Enum.KeyCode.Up then
                self:SelectPrevious()
            elseif input.KeyCode == Enum.KeyCode.Down then
                self:SelectNext()
            elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Tab then
                self:ConfirmSelection()
            elseif input.KeyCode == Enum.KeyCode.Escape then
                self:Hide()
            end
        end)
    end
    
    function self:Show(word, position)
        if #word <= 1 or word == self.lastWord then
            if #word <= 1 then
                self:Hide()
            end
            return
        end
        
        self.lastWord = word
        self:ClearItems()
        
        local matches = self:GetMatches(word)
        if #matches == 0 then
            self:Hide()
            return
        end
        
        self.matches = matches
        self.selectedIndex = 1
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
        self.matches = {}
        self.selectedIndex = 1
    end
    
    function self:GetMatches(word)
        local matches = {}
        local lowerWord = word:lower()
        local exactMatches = {}
        local prefixMatches = {}
        local containsMatches = {}
        
        for _, keyword in ipairs(self.utils.AutoCompleteWords) do
            local lowerKeyword = keyword:lower()
            
            if lowerKeyword == lowerWord then
                -- 跳过完全匹配的词
                continue
            elseif lowerKeyword:sub(1, #word) == lowerWord then
                -- 前缀匹配（优先级最高）
                table.insert(prefixMatches, keyword)
            elseif lowerKeyword:find(lowerWord, 1, true) then
                -- 包含匹配（优先级较低）
                table.insert(containsMatches, keyword)
            end
        end
        
        -- 合并结果，前缀匹配优先
        for _, match in ipairs(prefixMatches) do
            table.insert(matches, match)
            if #matches >= 8 then break end  -- 限制数量
        end
        
        if #matches < 8 then
            for _, match in ipairs(containsMatches) do
                table.insert(matches, match)
                if #matches >= 8 then break end
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
        
        for index, match in ipairs(matches) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 18)
            item.BackgroundColor3 = index == 1 and self.theme.Colors.Accent or self.theme.Colors.Tertiary
            item.Text = match
            item.TextColor3 = self.theme.Colors.Text
            item.TextSize = 10
            item.Font = Enum.Font.Code
            item.BorderSizePixel = 0
            item.LayoutOrder = index
            item.Parent = self.scroll
            
            -- 高亮匹配的部分
            if self.lastWord and #self.lastWord > 0 then
                item.RichText = true
                local lowerMatch = match:lower()
                local lowerWord = self.lastWord:lower()
                local startPos = lowerMatch:find(lowerWord, 1, true)
                
                if startPos then
                    local before = match:sub(1, startPos - 1)
                    local highlight = match:sub(startPos, startPos + #self.lastWord - 1)
                    local after = match:sub(startPos + #self.lastWord)
                    item.Text = before .. "<b><u>" .. highlight .. "</u></b>" .. after
                end
            end
            
            item.MouseButton1Click:Connect(function()
                self:SelectItem(index)
                self:ConfirmSelection()
            end)
            
            -- 悬停效果
            item.MouseEnter:Connect(function()
                self:SelectItem(index)
            end)
        end
    end
    
    function self:SelectItem(index)
        if not self.scroll or index < 1 or index > #self.matches then return end
        
        self.selectedIndex = index
        
        -- 更新选中状态
        for i, child in ipairs(self.scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = (child.LayoutOrder == index) and self.theme.Colors.Accent or self.theme.Colors.Tertiary
            end
        end
    end
    
    function self:SelectNext()
        local newIndex = self.selectedIndex + 1
        if newIndex > #self.matches then
            newIndex = 1
        end
        self:SelectItem(newIndex)
    end
    
    function self:SelectPrevious()
        local newIndex = self.selectedIndex - 1
        if newIndex < 1 then
            newIndex = #self.matches
        end
        self:SelectItem(newIndex)
    end
    
    function self:ConfirmSelection()
        if self.selectedIndex > 0 and self.selectedIndex <= #self.matches then
            local selected = self.matches[self.selectedIndex]
            if self.onSelect and selected then
                self.onSelect(selected, self.lastWord)
            end
        end
        self:Hide()
    end
    
    function self:UpdateSize(itemCount)
        if not self.frame then return end
        
        local height = math.min(144, itemCount * 19 + 4)  -- 最多8项
        self.frame.Size = UDim2.new(0, 180, 0, height)
        
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