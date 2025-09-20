--[[
    UI创建模块 - 简化版
]]

local UI = {}

function UI.new(theme, utils, config)
    local self = {}
    self.theme = theme
    self.utils = utils
    self.config = config or {}
    
    -- 这个模块主要用于扩展，当前版本在main.lua中直接创建UI
    
    return self
end

return UI