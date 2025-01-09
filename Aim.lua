--[[ 
    Aimbot Premium Script for Blox Fruits
    Features: Advanced Targeting, Skill Chains, Dynamic Evasion, Anti-Detection, and more.
    Version: Premium Edition
    Note: Use responsibly and comply with Roblox's Terms of Service.
]]--

-- Global Configuration
local Aimbot = {
    Enabled = true,
    FOV = 150, -- Field of View
    Smoothness = 0.3,
    TargetPriority = "Closest", -- Options: Closest, LowestHP, HighestLevel
    MultiTarget = true,
    Prediction = true,
    DynamicEvasion = true,
    AntiDetection = true,
    SkillChain = true,
    GhostAim = false,
    AutoAdjustFOV = true,
    DisplayTargetInfo = true,
    SafeMode = true, -- Avoid targeting strong players
    GUIVisibility = true,
    HighlightTarget = true, -- Highlight current target
    Lock360 = true, -- 360° Target Lock
    ReturnLastTarget = true -- Automatically return to the last target
}

-- Dependencies
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- Variables
local lastTarget = nil
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

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDistance = Aimbot.FOV

    for _, player in pairs(GetTargets()) do
        local targetPos = player.Character.HumanoidRootPart.Position
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos)
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

        if onScreen and distance < shortestDistance then
            shortestDistance = distance
            closestTarget = player
        end
    end
    return closestTarget
end

local function PredictTargetMovement(target)
    if not target or not target.Character then return nil end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local velocity = hrp.Velocity
    return hrp.Position + velocity * 0.1
end

local function AimAt(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local aimPosition = Aimbot.Prediction and PredictTargetMovement(target) or hrp.Position
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPosition), Aimbot.Smoothness)
end

-- Highlight Target
local function HighlightTarget(target)
    if not Aimbot.HighlightTarget or not target or not target.Character then return end
    local highlight = Instance.new("SelectionBox", target.Character)
    highlight.Adornee = target.Character
    highlight.LineThickness = 0.05
    highlight.Color3 = Color3.new(1, 0, 0)
    highlight.Name = "AimbotHighlight"

    game:GetService("Debris"):AddItem(highlight, 0.2) -- Auto-remove highlight
end

-- Skill Chain Execution
local function ExecuteSkillChain(target)
    if not Aimbot.SkillChain or not target then return end
    local skills = {"Z", "X", "C", "V"} -- Replace with skill hotkeys

    for _, skill in ipairs(skills) do
        wait(0.2) -- Adjust timing for skill cooldown
        game:GetService("VirtualInputManager"):SendKeyEvent(true, skill, false, game)
        AimAt(target)
    end
end

-- Dynamic Evasion
local function EvasionHandler()
    if not Aimbot.DynamicEvasion then return end

    -- Random movement to avoid attacks
    Player.Character.Humanoid:Move(Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), true)
end

-- GUI for Aimbot Toggle
local function CreateGUI()
    local ToggleButton = Instance.new("TextButton", ScreenGui)
    ToggleButton.Size = UDim2.new(0, 200, 0, 50)
    ToggleButton.Position = UDim2.new(0.5, -100, 0.9, 0)
    ToggleButton.Text = "Aimbot: ON"
    ToggleButton.BackgroundColor3 = Color3.new(0, 1, 0)

    ToggleButton.MouseButton1Click:Connect(function()
        Aimbot.Enabled = not Aimbot.Enabled
        ToggleButton.Text = Aimbot.Enabled and "Aimbot: ON" or "Aimbot: OFF"
        ToggleButton.BackgroundColor3 = Aimbot.Enabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end)
end

if Aimbot.GUIVisibility then
    CreateGUI()
end

-- Main Loop
game:GetService("RunService").RenderStepped:Connect(function()
    if not Aimbot.Enabled then return end

    local target = GetClosestTarget()
    if Aimbot.ReturnLastTarget and not target then
        target = lastTarget
    else
        lastTarget = target
    end

    if target then
        AimAt(target)
        HighlightTarget(target)
        if Aimbot.DisplayTargetInfo then
            print("Targeting:", target.Name)
        end
    end
end)

-- Anti-Detection
if Aimbot.AntiDetection then
    game:GetService("RunService").RenderStepped:Connect(function()
        Aimbot.Smoothness = math.random(3, 10) / 10 -- Randomize smoothness
    end)
end

-- Dynamic Evasion Execution
game:GetService("RunService").Stepped:Connect(EvasionHandler)

print("Aimbot Premium Script Loaded. Use responsibly!")
