--[[
    编辑器功能模块
]]

local Editor = {}

function Editor.new(theme, utils, config)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.config = config
    
    function self:SetupEditor(codeInput, editorScroll)
        self.codeInput = codeInput
        self.editorScroll = editorScroll
        
        self:UpdateEditor()
    end
    
    function self:UpdateEditor()
        if not self.codeInput then return end
        
        local text = self.codeInput.Text
        local lines = string.split(text, "\n")
        local lineHeight = 15
        local totalHeight = math.max(#lines * lineHeight + 20, self.editorScroll.AbsoluteSize.Y)
        
        self.editorScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        self.codeInput.Size = UDim2.new(1, 0, 0, totalHeight)
    end
    
    return self
end

return Editor