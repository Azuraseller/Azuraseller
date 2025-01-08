-- Local Script: Intelligent Performance Optimization System
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Variables
local performanceData = { fps = 60, frameDrops = 0, memoryUsage = 0 }
local highPerformanceMode = false -- Toggle for High-Performance Mode
local effectManagementEnabled = true -- Toggle for Effect Management

-- Auto-Detect Device
local function detectDevice()
    if UserInputService.TouchEnabled then
        return "Mobile", 30, Enum.QualityLevel.Level03
    else
        return "PC", 60, Enum.QualityLevel.Level08
    end
end

-- Dynamic Asset Loading (DAL)
local function dynamicAssetLoading()
    local function manageAssets()
        for _, object in ipairs(Workspace:GetDescendants()) do
            if object:IsA("BasePart") and object:IsDescendantOf(Workspace) then
                local distance = (object.Position - camera.CFrame.Position).Magnitude
                object.Transparency = distance > 100 and 1 or 0 -- Hide objects far from the camera
                object.CastShadow = distance <= 100 -- Disable shadows for distant objects
            end
        end
    end

    RunService.Heartbeat:Connect(manageAssets)
end

-- Effect Management
local function manageEffects()
    for _, particle in ipairs(Workspace:GetDescendants()) do
        if particle:IsA("ParticleEmitter") or particle:IsA("Trail") then
            particle.Enabled = effectManagementEnabled
        end
    end
end

-- High-Performance Mode
local function toggleHighPerformanceMode(state)
    highPerformanceMode = state
    if state then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 -- Lowest quality
        camera.FieldOfView = 85 -- Increase FOV for performance
        effectManagementEnabled = false -- Disable effects
    else
        local _, _, quality = detectDevice()
        settings().Rendering.QualityLevel = quality -- Reset to device-specific quality
        camera.FieldOfView = 75 -- Reset FOV
        effectManagementEnabled = true -- Enable effects
    end
    manageEffects()
end

-- Performance Debug Tool
local function displayPerformanceDebug()
    local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    local debugFrame = Instance.new("Frame", gui)
    local fpsLabel = Instance.new("TextLabel", debugFrame)
    local memoryLabel = Instance.new("TextLabel", debugFrame)

    debugFrame.Size = UDim2.new(0.2, 0, 0.1, 0)
    debugFrame.Position = UDim2.new(0.8, 0, 0, 0)
    debugFrame.BackgroundTransparency = 0.5
    debugFrame.BackgroundColor3 = Color3.new(0, 0, 0)

    fpsLabel.Size = UDim2.new(1, 0, 0.5, 0)
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.Font = Enum.Font.SourceSansBold
    fpsLabel.TextSize = 20

    memoryLabel.Size = UDim2.new(1, 0, 0.5, 0)
    memoryLabel.Position = UDim2.new(0, 0, 0.5, 0)
    memoryLabel.TextColor3 = Color3.new(1, 1, 1)
    memoryLabel.Font = Enum.Font.SourceSansBold
    memoryLabel.TextSize = 20

    RunService.RenderStepped:Connect(function()
        fpsLabel.Text = string.format("FPS: %d", math.floor(performanceData.fps))
        memoryLabel.Text = string.format("Memory: %.2f MB", collectgarbage("count") / 1024)
    end)
end

-- Adaptive Performance Learning
local function adaptiveLearning()
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime

        local currentFPS = 1 / deltaTime
        performanceData.fps = (performanceData.fps + currentFPS) / 2 -- Smooth FPS calculation

        if currentFPS < 30 then
            performanceData.frameDrops = performanceData.frameDrops + 1
            if performanceData.frameDrops > 10 then
                toggleHighPerformanceMode(true)
            end
        else
            performanceData.frameDrops = math.max(performanceData.frameDrops - 1, 0)
            if performanceData.frameDrops == 0 then
                toggleHighPerformanceMode(false)
            end
        end
    end)
end

-- Initialization
local function initialize()
    local device, targetFPS, quality = detectDevice()
    settings().Rendering.QualityLevel = quality

    dynamicAssetLoading()
    adaptiveLearning()
    displayPerformanceDebug()

    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = string.format("Optimization Applied: Device [%s] | Target FPS: %d", device, targetFPS),
        Color = Color3.fromRGB(0, 255, 0),
        Font = Enum.Font.SourceSansBold,
        FontSize = Enum.FontSize.Size24
    })
end

initialize()
