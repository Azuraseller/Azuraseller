--[[ 
    Aimbot Premium Script for Blox Fruits
    Features: Advanced Targeting, Skill Chains, Anti-Detection, and more.
    Version: Premium Edition
    Note: Use responsibly and comply with Roblox's Terms of Service.
]]--

-- Global Configuration
local Aimbot = {
    Enabled = true,
    FOV = 150, -- Field of View
    Smoothness = 0.05, -- Reduced smoothness for more precise aiming
    TargetPriority = "Closest", -- Options: Closest, LowestHP, HighestLevel
    Prediction = true, -- Enable Prediction
    AntiDetection = true, -- Enable AntiDetection
    SkillChain = true, -- Enable Skill Chain
    GhostAim = true, -- Enable Ghost Aim
    AutoAdjustFOV = true,
    DisplayTargetInfo = true,
    GUIVisibility = true,
    Lock360 = true, -- 360° Target Lock
    ReturnLastTarget = true, -- Automatically return to the last target
    TargetRadius = 400 -- Radius for target priority
}

-- Dependencies
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()
local lastTarget = nil
local currentTarget = nil
local ScreenGui = Instance.new("ScreenGui", Player.PlayerGui)

-- Utility Functions
local function GetTargets()
    local targets = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(targets, player)
        end
    end
    return targets
end

local function GetTargetsInRadius()
    local targets = {}
    for _, player in pairs(GetTargets()) do
        local targetPos = player.Character.HumanoidRootPart.Position
        local distance = (targetPos - Camera.CFrame.Position).Magnitude
        if distance <= Aimbot.TargetRadius then
            table.insert(targets, player)
        end
    end
    return targets
end

local function GetPriorityTarget()
    local targets = GetTargetsInRadius()
    local selectedTarget = nil

    if Aimbot.TargetPriority == "Closest" then
        local shortestDistance = Aimbot.FOV
        for _, player in pairs(targets) do
            local targetPos = player.Character.HumanoidRootPart.Position
            local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if onScreen and distance < shortestDistance then
                shortestDistance = distance
                selectedTarget = player
            end
        end
    elseif Aimbot.TargetPriority == "LowestHP" then
        local lowestHP = math.huge
        for _, player in pairs(targets) do
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health < lowestHP then
                lowestHP = humanoid.Health
                selectedTarget = player
            end
        end
    elseif Aimbot.TargetPriority == "HighestLevel" then
        local highestLevel = -math.huge
        for _, player in pairs(targets) do
            local level = player:FindFirstChild("Level") and player.Level.Value or 0
            if level > highestLevel then
                highestLevel = level
                selectedTarget = player
            end
        end
    end

    return selectedTarget
end

-- Improved Prediction Logic
local function PredictTargetMovement(target)
    if not target or not target.Character then return nil end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local velocity = hrp.Velocity
    local predictedPosition = hrp.Position + velocity * 0.1
    return predictedPosition
end

local function AimAt(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Apply prediction if enabled
    local aimPosition = Aimbot.Prediction and PredictTargetMovement(target) or hrp.Position
    local targetCFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Aimbot.Smoothness)
end

local function AdjustFOV(target)
    if not target or not target.Character then return end
    local distance = (Camera.CFrame.Position - target.Character.HumanoidRootPart.Position).Magnitude
    Aimbot.FOV = math.clamp(distance / 10, 50, 200)
end

local function CreateFOVCircle()
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.Radius = Aimbot.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Color = Color3.new(1, 0, 0)
    FOVCircle.Visible = true
    FOVCircle.Transparency = 0.5

    game:GetService("RunService").RenderStepped:Connect(function()
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Visible = Aimbot.Enabled
    end)
end

local function CreateGUI()
    local ToggleButton = Instance.new("TextButton", ScreenGui)
    ToggleButton.Size = UDim2.new(0, 150, 0, 50)
    ToggleButton.Position = UDim2.new(0.9, -160, 0.05, 0) -- Top-right corner
    ToggleButton.Text = "Aimbot: ON"
    ToggleButton.BackgroundColor3 = Color3.new(0, 1, 0)
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)

    ToggleButton.MouseButton1Click:Connect(function()
        Aimbot.Enabled = not Aimbot.Enabled
        ToggleButton.Text = Aimbot.Enabled and "Aimbot: ON" or "Aimbot: OFF"
        ToggleButton.BackgroundColor3 = Aimbot.Enabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end)
end

-- Skill Chain Execution with Improved Timing
local function ExecuteSkillChain(target)
    if not Aimbot.SkillChain or not target then return end
    local skills = {"Z", "X", "C", "V"} -- Replace with skill hotkeys

    for _, skill in ipairs(skills) do
        wait(0.5) -- Adjusted to allow more time between skills
        game:GetService("VirtualInputManager"):SendKeyEvent(true, skill, false, game)
        AimAt(target) -- Aim at the target before using each skill
    end
end

-- Anti-Detection Logic
local function AntiDetectionHandler()
    if Aimbot.AntiDetection then
        game:GetService("RunService").RenderStepped:Connect(function()
            Aimbot.Smoothness = math.random(3, 10) / 10 -- Randomize smoothness to avoid detection
        end)
    end
end

-- Ghost Aim Logic
local function GhostAimHandler()
    if Aimbot.GhostAim then
        -- Simulate aim at target even if not actually firing
        if currentTarget then
            AimAt(currentTarget)
        end
    end
end

-- Initialize
if Aimbot.GUIVisibility then
    CreateGUI()
end
CreateFOVCircle()

game:GetService("RunService").RenderStepped:Connect(function()
    if not Aimbot.Enabled then return end

    local target = GetPriorityTarget()

    if target then
        if Aimbot.AutoAdjustFOV then AdjustFOV(target) end
        AimAt(target)
        if Aimbot.DisplayTargetInfo then
            print("Targeting:", target.Name)
        end
    end

    -- Anti-Detection
    AntiDetectionHandler()

    -- Skill Chain Execution
    if Aimbot.SkillChain then
        ExecuteSkillChain(target)
    end

    -- Ghost Aim
    GhostAimHandler()

    -- Save the current target for the next loop
    if target then
        lastTarget = target
    end
end)

print("Aimbot Premium Script Loaded. Use responsibly!")
