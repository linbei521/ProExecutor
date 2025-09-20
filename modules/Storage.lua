--[[
    数据存储模块
]]

local Storage = {}
local HttpService = game:GetService("HttpService")

local STORAGE_FILE = "ProExecutor_Scripts.json"

function Storage:Save(data)
    local success, err = pcall(function()
        if writefile then
            writefile(STORAGE_FILE, HttpService:JSONEncode(data))
            return true
        else
            _G.ProExecutorData = data
            return false, "writefile not supported"
        end
    end)
    return success, err
end

function Storage:Load()
    local success, result = pcall(function()
        if readfile and isfile and isfile(STORAGE_FILE) then
            return HttpService:JSONDecode(readfile(STORAGE_FILE))
        end
        return _G.ProExecutorData or {Scripts = {}}
    end)
    
    if success then
        return result
    else
        warn("Failed to load storage:", result)
        return {Scripts = {}}
    end
end

function Storage:HasFileSupport()
    return writefile ~= nil
end

function Storage:GetStorageType()
    return self:HasFileSupport() and "文件存储" or "内存存储"
end

function Storage:ExportToClipboard(scripts)
    local success, err = pcall(function()
        if not setclipboard then
            error("setclipboard not supported")
        end
        local exportData = HttpService:JSONEncode(scripts)
        setclipboard(exportData)
    end)
    return success, err
end

function Storage:ImportFromClipboard()
    local success, result = pcall(function()
        if not getclipboard then
            error("getclipboard not supported")
        end
        local clipboardData = getclipboard()
        if clipboardData == "" then
            error("clipboard is empty")
        end
        return HttpService:JSONDecode(clipboardData)
    end)
    return success, result
end

return Storage