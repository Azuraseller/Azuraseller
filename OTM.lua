-- Local Script: High-Performance Mode with 60 FPS Lock
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

-- Variables
local highPerformanceMode = false
local targetFPS = 60
local dynamicAssetLoadingEnabled = true
local effectManagementEnabled = true
local frameTime = 1 / targetFPS

-- Function: Set FPS Limit
local function setFPSLimit()
    -- Ensure FPS is capped at 60
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        local elapsedTime = tick() - lastTime
        if elapsedTime < frameTime then
            wait(frameTime - elapsedTime)  -- Wait to maintain 60 FPS
        end
        lastTime = tick()
    end)
end

-- Function: Toggle High-Performance Mode
local function toggleHighPerformanceMode(state)
    highPerformanceMode = state
    if state then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level02
        camera.FieldOfView = 85
        dynamicAssetLoadingEnabled = true
        effectManagementEnabled = false
        setFPSLimit()  -- Set FPS limit to 60 when in high-performance mode
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level08
        camera.FieldOfView = 75
        dynamicAssetLoadingEnabled = true
        effectManagementEnabled = true
    end
end

-- Function: Dynamic Asset Loading
local function dynamicAssetLoading()
    if not dynamicAssetLoadingEnabled then return end
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") and object:IsDescendantOf(Workspace) then
            local distance = (object.Position - camera.CFrame.Position).Magnitude
            object.Transparency = distance > 100 and 1 or 0
            object.CastShadow = distance <= 100
        end
    end
end

-- Function: Manage Effects
local function manageEffects()
    for _, particle in ipairs(Workspace:GetDescendants()) do
        if particle:IsA("ParticleEmitter") or particle:IsA("Trail") then
            particle.Enabled = effectManagementEnabled
        end
    end
end

-- Function: Create Movable GUI
local function createMovableGUI()
    local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0.3, 0, 0.4, 0)
    frame.Position = UDim2.new(0.35, 0, 0.3, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Active = true
    frame.Draggable = true -- Enable dragging

    -- Title
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Performance Control Panel"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20

    -- Toggle High-Performance Mode Button
    local highPerfButton = Instance.new("TextButton", frame)
    highPerfButton.Size = UDim2.new(1, 0, 0.2, 0)
    highPerfButton.Position = UDim2.new(0, 0, 0.15, 0)
    highPerfButton.Text = "Toggle High-Performance Mode"
    highPerfButton.TextColor3 = Color3.new(1, 1, 1)
    highPerfButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    highPerfButton.MouseButton1Click:Connect(function()
        toggleHighPerformanceMode(not highPerformanceMode)
        highPerfButton.Text = highPerformanceMode and "High-Performance Mode: ON" or "High-Performance Mode: OFF"
    end)

    -- Toggle Dynamic Asset Loading Button
    local dalButton = Instance.new("TextButton", frame)
    dalButton.Size = UDim2.new(1, 0, 0.2, 0)
    dalButton.Position = UDim2.new(0, 0, 0.4, 0)
    dalButton.Text = "Toggle Dynamic Asset Loading"
    dalButton.TextColor3 = Color3.new(1, 1, 1)
    dalButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    dalButton.MouseButton1Click:Connect(function()
        dynamicAssetLoadingEnabled = not dynamicAssetLoadingEnabled
        dalButton.Text = dynamicAssetLoadingEnabled and "Dynamic Asset Loading: ON" or "Dynamic Asset Loading: OFF"
    end)

    -- Toggle Effect Management Button
    local effectButton = Instance.new("TextButton", frame)
    effectButton.Size = UDim2.new(1, 0, 0.2, 0)
    effectButton.Position = UDim2.new(0, 0, 0.65, 0)
    effectButton.Text = "Toggle Effect Management"
    effectButton.TextColor3 = Color3.new(1, 1, 1)
    effectButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    effectButton.MouseButton1Click:Connect(function()
        effectManagementEnabled = not effectManagementEnabled
        effectButton.Text = effectManagementEnabled and "Effect Management: ON" or "Effect Management: OFF"
    end)
end

-- Initialization
local function initialize()
    createMovableGUI()
    toggleHighPerformanceMode(true)  -- Automatically enable high-performance mode on start
    RunService.Heartbeat:Connect(dynamicAssetLoading)
    manageEffects()
end

initialize()
