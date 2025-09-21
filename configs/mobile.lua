--[[
    移动端配置
]]

return {
    windowSize = {340, 400},
    touchOptimized = true,
    device = "mobile",
    buttonSize = {80, 40},
    fontSize = {
        title = 14,
        normal = 12,
        small = 10
    },
    spacing = {
        padding = 10,
        margin = 5
    },
    features = {
        autoComplete = false,
        lineNumbers = true,
        keyboardShortcuts = false
    },
    performance = {
        enableAnimations = false,
        maxOutputLines = 30,
        autoSaveInterval = 60,
        enableShadows = false,
        enablePerformanceOverlay = false
    }
}