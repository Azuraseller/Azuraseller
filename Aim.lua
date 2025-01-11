local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Cấu hình
local Prediction = 0.5 -- Dự đoán vị trí mục tiêu
local Radius = 350 -- Bán kính khóa mục tiêu
local FOVRadius = 100 -- Bán kính FOV hiển thị
local BaseSmoothFactor = 0.2 -- Mức độ mượt cơ bản
local MaxSmoothFactor = 0.6 -- Mức độ mượt tối đa
local TargetSwitchSpeed = 0.2 -- Tốc độ chuyển đổi mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true
local PriorityMode = "Closest" -- "Closest", "Dangerous", "LowestHealth"

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local FOVCircle = Instance.new("Frame")
local TargetLabel = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui")

-- FOV Circle
FOVCircle.Parent = ScreenGui
FOVCircle.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVCircle.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 0.8
FOVCircle.BorderSizePixel = 2
FOVCircle.BorderColor3 = Color3.fromRGB(0, 255, 0)

-- Target Label
TargetLabel.Parent = ScreenGui
TargetLabel.Size = UDim2.new(0, 300, 0, 50)
TargetLabel.Position = UDim2.new(0.5, -150, 0.85, 0)
TargetLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TargetLabel.BackgroundTransparency = 0.5
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.Font = Enum.Font.SourceSans
TargetLabel.TextSize = 18
TargetLabel.Text = "Target: None"

-- Tìm mục tiêu trong bán kính
local function FindPriorityTarget()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart and humanoid.Health > 0 then
                local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance <= Radius then
                    local dangerScore = 0
                    if PriorityMode == "Dangerous" then
                        local relativeDirection = (rootPart.Position - Camera.CFrame.Position).Unit
                        local dotProduct = relativeDirection:Dot(Camera.CFrame.LookVector)
                        dangerScore = distance * (1 - dotProduct)
                    elseif PriorityMode == "LowestHealth" then
                        dangerScore = humanoid.Health
                    end
                    table.insert(targets, {Character = character, Distance = distance, DangerScore = dangerScore})
                end
            end
        end
    end

    if PriorityMode == "Closest" then
        table.sort(targets, function(a, b)
            return a.Distance < b.Distance
        end)
    elseif PriorityMode == "Dangerous" then
        table.sort(targets, function(a, b)
            return a.DangerScore < b.DangerScore
        end)
    elseif PriorityMode == "LowestHealth" then
        table.sort(targets, function(a, b)
            return a.DangerScore < b.DangerScore
        end)
    end

    return targets[1] and targets[1].Character or nil
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local rootPart = target:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local velocity = rootPart.Velocity
        local predictedPosition = rootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return rootPart.Position
end

-- Theo dõi mục tiêu
RunService.RenderStepped:Connect(function()
    if AimActive then
        local target = FindPriorityTarget()
        if target then
            Locked = true
            CurrentTarget = target
            TargetLabel.Text = "Target: " .. target.Name

            local targetPosition = PredictTargetPosition(target)
            local smoothFactor = math.clamp(BaseSmoothFactor + (target.HumanoidRootPart.Velocity.Magnitude / 100), BaseSmoothFactor, MaxSmoothFactor)
            local smoothedCFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), smoothFactor)

            Camera.CFrame = smoothedCFrame
        else
            Locked = false
            CurrentTarget = nil
            TargetLabel.Text = "Target: None"
        end
    end
end)

-- SnapAim luôn bật
RunService.RenderStepped:Connect(function()
    if CurrentTarget and AimActive then
        local targetPosition = PredictTargetPosition(CurrentTarget)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
    end
end)
