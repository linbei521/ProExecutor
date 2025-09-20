--[[
    ProExecutor - 主程序
    这个文件通过loader.lua加载，可以访问所有模块
]]

-- 获取模块和配置
local Theme = modules.Theme
local Storage = modules.Storage  
local Utils = modules.Utils
local Editor = modules.Editor
local OutputManager = modules.OutputManager
local ScriptManager = modules.ScriptManager
local AutoComplete = modules.AutoComplete
local CodeExecutor = modules.CodeExecutor
local UI = modules.UI

-- 应用配置
local Config = config

-- 主应用类
local ProExecutor = {}
ProExecutor.__index = ProExecutor

function ProExecutor.new()
    local self = setmetatable({}, ProExecutor)
    
    -- 初始化模块
    self.theme = Theme
    self.storage = Storage
    self.utils = Utils
    self.config = Config
    
    -- 创建管理器实例
    self.outputManager = OutputManager.new(self.theme, self.utils)
    self.editor = Editor.new(self.theme, self.utils)
    self.autoComplete = AutoComplete.new(self.theme, self.utils)
    self.codeExecutor = CodeExecutor.new(self.outputManager)
    self.ui = UI.new(self.theme, self.utils, self.config)
    
    -- 初始化应用
    self:Initialize()
    
    return self
end

function ProExecutor:Initialize()
    self:CreateUI()
    self:SetupEventHandlers()
    self:LoadInitialData()
    
    -- 显示启动信息
    self.outputManager:LogSuccess("🚀 ProExecutor GitHub版已启动")
    self.outputManager:LogInfo("📦 模块化架构加载完成")
    self.outputManager:LogInfo("🔧 配置: " .. (self.config.touchOptimized and "移动端优化" or "桌面端"))
end

-- 这里包含其他方法...
-- (由于篇幅限制，其他方法与之前的实现类似)

-- 启动应用
local app = ProExecutor.new()

-- 导出到全局（可选，用于调试）
_G.ProExecutor = app