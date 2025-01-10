local fov = 100
local aimSpeedBase = 0.1 -- Tốc độ cơ bản của Aimbot
local cameraHeightOffset = 2 -- Tăng chiều cao camera
local detectionRadius = 400 -- Phạm vi quét 360 độ
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = game.Workspace.CurrentCamera

-- FOV Circle Drawing
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128) -- Purple
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

-- Update FOV Circle
local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
    FOVring.Radius = fov
end

-- Adjust FOV size with keys
local function adjustFOV(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == Enum.KeyCode.Up then
        fov = math.clamp(fov + 5, 50, 500)
    elseif input.KeyCode == Enum.KeyCode.Down then
        fov = math.clamp(fov - 5, 50, 500)
    end
end

-- Remove FOV circle on Delete key
local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        RunService:UnbindFromRenderStep("FOVUpdate")
        FOVring:Remove()
    end
end

-- Look at target position with smooth Aimspeed
local function lookAtSmooth(target, aimSpeed)
    local lookVector = (target - Cam.CFrame.Position).unit
    local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
    Cam.CFrame = Cam.CFrame:Lerp(newCFrame, aimSpeed)
end

-- Calculate target speed
local function calculateTargetSpeed(player)
    if not player.Character then return 0 end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    return root.Velocity.Magnitude
end

-- Get closest and fastest player within FOV
local function getClosestAndFastestPlayerInFOV(targetPartName)
    local nearest = nil
    local highestSpeed = 0
    local closestDistance = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            local part = character and character:FindFirstChild(targetPartName)
            if part then
                local screenPos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - playerMousePos).Magnitude
                local speed = calculateTargetSpeed(player)

                if isVisible and distance < fov and distance < closestDistance then
                    if speed > highestSpeed then
                        highestSpeed = speed
                        nearest = player
                    end
                end
            end
        end
    end

    return nearest, highestSpeed
end

-- Get all players within detection radius (360° Aimbot)
local function getPlayersInRange()
    local playersInRange = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (character.HumanoidRootPart.Position - Cam.CFrame.Position).Magnitude
                if distance <= detectionRadius then
                    table.insert(playersInRange, player)
                end
            end
        end
    end
    return playersInRange
end

-- Main loop
local currentTarget = nil
RunService.RenderStepped:Connect(function()
    updateDrawings()
    local playersInRange = getPlayersInRange()

    if #playersInRange > 0 then
        -- Nếu có mục tiêu trong phạm vi, ưu tiên mục tiêu gần nhất và có tốc độ cao nhất
        local highestSpeed = 0
        local bestTarget = nil
        for _, player in ipairs(playersInRange) do
            local speed = calculateTargetSpeed(player)
            if speed > highestSpeed then
                highestSpeed = speed
                bestTarget = player
            end
        end

        -- Nếu có mục tiêu, ngắm vào nó
        if bestTarget and bestTarget.Character and bestTarget.Character:FindFirstChild("Head") then
            local aimSpeed = math.clamp(aimSpeedBase + (highestSpeed / 100), 0.1, 1)
            lookAtSmooth(bestTarget.Character.Head.Position + Vector3.new(0, cameraHeightOffset, 0), aimSpeed)
            currentTarget = bestTarget
        end
    else
        -- Nếu không có mục tiêu trong phạm vi, tắt Aimbot
        currentTarget = nil
    end
end)

-- Connect key inputs
UserInputService.InputBegan:Connect(adjustFOV)
UserInputService.InputBegan:Connect(onKeyDown)
