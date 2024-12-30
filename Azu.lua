local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local BaseRadius = 230 -- Bán kính khóa mục tiêu cơ bản
local DynamicRadius = true -- Bật/Tắt tự động điều chỉnh bán kính
local MaxRadius = 300 -- Bán kính tối đa
local MinRadius = 150 -- Bán kính tối thiểu
local BaseSmoothFactor = 0.15
local MaxSmoothFactor = 0.5
local CameraRotationSpeed = 0.3
local TargetLockSpeed = 0.2
local Locked = false
local CurrentTarget = nil
local AimActive = true
local LaserEnabled = true -- Hiển thị đường sáng
local POVEnabled = true -- Bật chế độ POV động
local AIEnabled = false -- Bật/Tắt AI
local AIDebugMode = false -- Bật/Tắt Debug AI
local AILearningEnabled = true -- Bật/Tắt tính năng AI học hỏi
local AIDistanceAdjustment = 0.5 -- Tốc độ điều chỉnh bán kính AI
local AISmoothAdjustment = 0.1 -- Tốc độ điều chỉnh smooth factor AI
local AIPredictionAdjustment = 0.1 -- Tốc độ điều chỉnh Prediction AI

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "Aim OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "Aim ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "Aim OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    end
end)

-- Hàm tìm đối thủ trong phạm vi
local function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= BaseRadius then
                    table.insert(targets, Character)
                end
            end
        end
    end
    return targets
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return target.HumanoidRootPart.Position
end

-- Tự động điều chỉnh bán kính
local function AdjustRadius(target)
    if DynamicRadius then
        local distance = (target.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        BaseRadius = math.clamp(distance / 2, MinRadius, MaxRadius)
    end
end

-- Hiển thị đường sáng
local function DrawLaser(target)
    if LaserEnabled and target then
        local start = Camera.CFrame.Position
        local finish = target.HumanoidRootPart.Position
        local beam = Instance.new("Part")
        beam.Anchored = true
        beam.CanCollide = false
        beam.Size = Vector3.new(0.2, 0.2, (finish - start).Magnitude)
        beam.CFrame = CFrame.new(start, finish) * CFrame.new(0, 0, -beam.Size.Z / 2)
        beam.BrickColor = BrickColor.new("Bright red")
        beam.Material = Enum.Material.Neon
        beam.Parent = workspace
        game:GetService("Debris"):AddItem(beam, 0.1)
    end
end

-- POV động
local function AdjustPOV(target)
    if POVEnabled and target then
        local distance = (target.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        local fov = math.clamp(70 - distance / 10, 40, 70) -- FOV giảm khi mục tiêu gần
        Camera.FieldOfView = fov
    end
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1]
            end
        else
            if Locked then
                Locked = false
                CurrentTarget = nil
            end
        end

        if CurrentTarget and Locked then
            local targetPosition = PredictTargetPosition(CurrentTarget)
            AdjustRadius(CurrentTarget)
            AdjustPOV(CurrentTarget)
            DrawLaser(CurrentTarget)

            local smoothPosition = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), TargetLockSpeed)
            Camera.CFrame = smoothPosition
        end
    end
end)

-- Tính năng AI siêu tiên tiến
local function AutoAdjustAI()
    if AIEnabled and CurrentTarget then
        -- Điều chỉnh tự động giá trị theo tình huống
        local distance = (CurrentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        local speed = LocalPlayer.Character.HumanoidRootPart.Velocity.Magnitude

        -- Điều chỉnh FOV, bán kính, và tốc độ ghim mục tiêu
        Camera.FieldOfView = math.clamp(70 + (speed / 10), 40, 90)
        BaseRadius = math.clamp(distance / 2, MinRadius, MaxRadius)
        TargetLockSpeed = math.clamp(TargetLockSpeed + (speed / 1000), 0.1, 0.5)
        Prediction = math.clamp(Prediction + (speed / 1000), 0.05, 0.2)

        -- Điều chỉnh smooth factor
        if speed > 50 then
            BaseSmoothFactor = math.clamp(BaseSmoothFactor - 0.05, 0.05, 0.15)
        else
            BaseSmoothFactor = math.clamp(BaseSmoothFactor + 0.05, 0.05, 0.15)
        end
    end
end

-- Kích hoạt AI Auto Adjust
RunService.RenderStepped:Connect(function()
    AutoAdjustAI()
end)

-- Nút bật/tắt AI
local AIButton = Instance.new("TextButton")
AIButton.Parent = ScreenGui
AIButton.Size = UDim2.new(0, 100, 0, 50)
AIButton.Position = UDim2.new(0.85, 0, 0.1, 0)
AIButton.Text = "AI OFF"
AIButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AIButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AIButton.Font = Enum.Font.SourceSans
AIButton.TextSize = 18

AIButton.MouseButton1Click:Connect(function()
    AIEnabled = not AIEnabled
    if AIEnabled then
        AIButton.Text = "AI ON"
        AIButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        AIButton.Text = "AI OFF"
        AIButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Cập nhật thông báo AI
local function UpdateAIDebug()
    if AIDebugMode and CurrentTarget then
        local targetPosition = PredictTargetPosition(CurrentTarget)
        print("AI Debug - FOV: " .. Camera.FieldOfView .. " Distance: " .. (CurrentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end
end

-- Debug AI
RunService.RenderStepped:Connect(function()
    if AIDebugMode then
        UpdateAIDebug()
    end
end)
