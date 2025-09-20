--[[
    自动补全模块（占位）
]]

local AutoComplete = {}

function AutoComplete.new(theme, utils)
    local self = {}
    self.theme = theme
    self.utils = utils
    
    -- 目前为占位实现
    -- 在桌面版中可以扩展更复杂的自动补全功能
    
    return self
end

return AutoComplete