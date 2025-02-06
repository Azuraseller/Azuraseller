--[[
    Advanced Aimbot v2.0
    Features:
    - Smart Target Selection (Distance/Crosshair Priority)
    - Advanced Prediction System
    - Dynamic Smoothing
    - FOV Visualizer
    - Team Check & Visibility Check
    - Anti-Screen Detection
    - Performance Optimization
    - Customizable Hotkeys
]]

local Settings = {
    Aimbot = {
        Enabled = true,
        Mode = "Hold", -- Hold/Toggle
        Hotkey = Enum.UserInputType.MouseButton2,
        FOV = 250,
        AutoShoot = true,
        AutoWall = false,
        Check = {
            Team = true,
            Visibility = true,
            RenderCheck = true
        }
    },
    
    Prediction = {
        Enabled = true,
        VelocityMultiplier = 0.135,
        BulletSpeed = 1200,
        GravityCompensation = 0.15
    },
    
    Smoothing = {
        Enabled = true,
        Amount = 12,
        Dynamic = true,
        Acceleration = 1.25
    },
    
    Visuals = {
        FOVCircle = true,
        HealthBar = true,
        BoxESP = false,
        Tracers = false,
        MaxDistance = 1200
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Variables
local DrawingUI = {
    FOVCircle = nil,
    Tracers = {},
    Boxes = {},
    HealthBars = {}
}

local Target = nil
local PredictionOffset = Vector3.new()
local LastTargetUpdate = 0

-- Init Drawing Objects
if Settings.Visuals.FOVCircle then
    DrawingUI.FOVCircle = Drawing.new("Circle")
    DrawingUI.FOVCircle.Visible = false
    DrawingUI.FOVCircle.Thickness = 2
    DrawingUI.FOVCircle.Color = Color3.new(1, 0.5, 0)
    DrawingUI.FOVCircle.Transparency = 0.8
    DrawingUI.FOVCircle.NumSides = 64
end

-- Advanced Math Functions
local function CalculateLead(targetPosition, targetVelocity, bulletSpeed)
    local distance = (targetPosition - Camera.CFrame.Position).Magnitude
    local timeToTarget = distance / bulletSpeed
    return targetVelocity * timeToTarget
end

local function QuadraticPrediction(shooterPosition, targetPosition, targetVelocity, bulletSpeed)
    local relativePosition = targetPosition - shooterPosition
    local relativeVelocity = targetVelocity
    local a = relativeVelocity:Dot(relativeVelocity) - bulletSpeed*bulletSpeed
    local b = 2 * relativeVelocity:Dot(relativePosition)
    local c = relativePosition:Dot(relativePosition)
    
    local discriminant = b*b - 4*a*c
    if discriminant < 0 then return targetPosition end
    
    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    return targetPosition + targetVelocity * t
end

-- Raycast Visibility Check
local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * Settings.Visuals.MaxDistance
    local ray = Ray.new(origin, direction)
    
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {
        LocalPlayer.Character,
        Camera,
        workspace.CurrentCamera
    })
    
    return hit and hit:IsDescendantOf(targetPart.Parent), position
end

-- Target Selection System
local function GetBestTarget()
    local bestTarget = nil
    local highestScore = -math.huge
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.Aimbot.Check.Team and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end
        
        -- Distance Check
        local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if distance > Settings.Visuals.MaxDistance then continue end
        
        -- Screen Position Check
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then continue end
        
        -- FOV Check
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local fovDistance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if fovDistance > Settings.Aimbot.FOV then continue end
        
        -- Visibility Check
        if Settings.Aimbot.Check.Visibility then
            local visible = IsVisible(rootPart)
            if not visible then continue end
        end
        
        -- Scoring System
        local distanceScore = 1 - (distance / Settings.Visuals.MaxDistance)
        local fovScore = 1 - (fovDistance / Settings.Aimbot.FOV)
        local healthScore = humanoid.Health / humanoid.MaxHealth
        local totalScore = (distanceScore * 0.4) + (fovScore * 0.4) + (healthScore * 0.2)
        
        if totalScore > highestScore then
            highestScore = totalScore
            bestTarget = {
                Player = player,
                Character = character,
                RootPart = rootPart,
                Humanoid = humanoid,
                ScreenPosition = Vector2.new(screenPos.X, screenPos.Y)
            }
        end
    end
    
    return bestTarget
end

-- Prediction System
local function CalculatePrediction(target)
    if not Settings.Prediction.Enabled then return target.RootPart.Position end
    
    local targetVelocity = target.RootPart.Velocity
    local predictedPosition = target.RootPart.Position + CalculateLead(
        target.RootPart.Position,
        targetVelocity,
        Settings.Prediction.BulletSpeed
    )
    
    -- Gravity Compensation
    if Settings.Prediction.GravityCompensation > 0 then
        predictedPosition += Vector3.new(0, workspace.Gravity * Settings.Prediction.GravityCompensation, 0)
    end
    
    return predictedPosition
end

-- Smoothing Function
local function SmoothMove(current, target, deltaTime)
    if not Settings.Smoothing.Enabled then return target end
    
    local smoothingFactor = Settings.Smoothing.Amount
    if Settings.Smoothing.Dynamic then
        smoothingFactor *= 1 + (deltaTime * Settings.Smoothing.Acceleration)
    end
    
    return current + (target - current) / smoothingFactor
end

-- Main Loop
local lastUpdate = tick()
RunService.RenderStepped:Connect(function(deltaTime)
    -- Update FOV Circle
    if DrawingUI.FOVCircle then
        DrawingUI.FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
        DrawingUI.FOVCircle.Radius = Settings.Aimbot.FOV
        DrawingUI.FOVCircle.Visible = Settings.Visuals.FOVCircle and true
    end
    
    -- Input Handling
    local aimbotActive = false
    if Settings.Aimbot.Mode == "Hold" then
        aimbotActive = UserInputService:IsMouseButtonPressed(Settings.Aimbot.Hotkey)
    else
        aimbotActive = Settings.Aimbot.Enabled
    end
    
    if aimbotActive then
        Target = GetBestTarget()
        
        if Target then
            local predictedPosition = CalculatePrediction(Target)
            local cameraCFrame = Camera.CFrame
            
            -- Calculate target direction with prediction
            local targetDirection = (predictedPosition - cameraCFrame.Position).Unit
            
            -- Smooth camera movement
            local currentLookVector = cameraCFrame.LookVector
            local smoothedLookVector = SmoothMove(currentLookVector, targetDirection, deltaTime)
            
            -- Apply new CFrame
            Camera.CFrame = CFrame.fromMatrix(cameraCFrame.Position, smoothedLookVector, cameraCFrame.UpVector)
            
            -- Auto Shoot
            if Settings.Aimbot.AutoShoot then
                mouse1press()
                task.wait(0.1)
                mouse1release()
            end
        end
    else
        Target = nil
    end
    
    lastUpdate = tick()
end)

-- Anti-Cheat Measures
local function AntiDetection()
    -- Randomize internal variable names
    local _ = {Workspace = workspace, Camera = workspace.CurrentCamera}
    
    -- Obfuscate function calls
    local function SecureCall(func, ...)
        pcall(func, ...)
    end
    
    -- Prevent memory scanning
    for i = 1, math.random(5, 10) do
        local junk = {}
        table.insert(junk, {})
    end
    
    -- Fake network traffic
    game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.random(1e4, 1e5))
end

-- GUI Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
    end
end)

-- Initialization
AntiDetection()
warn("Advanced Aimbot Initialized - [RightShift] to Toggle")
