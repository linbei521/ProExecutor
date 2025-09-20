--[[
    代码执行模块
]]

local CodeExecutor = {}

function CodeExecutor.new(outputManager)
    local self = {}
    self.outputManager = outputManager
    
    function self:Execute(code)
        if not code or code:gsub("%s", "") == "" then
            self.outputManager:LogWarning("❌ 代码为空")
            return false
        end
        
        self.outputManager:LogInfo("🚀 开始执行...")
        
        local success, result = pcall(function()
            local func, compileError = loadstring(code)
            if not func then
                error("语法错误: " .. (compileError or "未知错误"))
            end
            
            local env = getfenv(func)
            local originalPrint = env.print
            
            env.print = function(...)
                local args = {...}
                local output = {}
                for i, arg in ipairs(args) do
                    table.insert(output, tostring(arg))
                end
                self.outputManager:LogSuccess("📄 " .. table.concat(output, " "))
            end
            
            env.warn = function(...)
                local args = {...}
                local output = {}
                for i, arg in ipairs(args) do
                    table.insert(output, tostring(arg))
                end
                self.outputManager:LogWarning("⚠️ " .. table.concat(output, " "))
            end
            
            local execSuccess, execResult = pcall(func)
            env.print = originalPrint
            
            if not execSuccess then
                error(execResult)
            end
            
            return execResult
        end)
        
        if success then
            self.outputManager:LogSuccess("✅ 执行成功")
            if result ~= nil then
                self.outputManager:LogInfo("📤 返回: " .. tostring(result))
            end
            return true
        else
            local errorMsg = tostring(result):gsub("^%[string \".*\"%]:%d+: ", "")
            self.outputManager:LogError("❌ 错误: " .. errorMsg)
            return false
        end
    end
    
    return self
end

return CodeExecutor