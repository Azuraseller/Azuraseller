local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tham số cấu hình
local Prediction = 0.2 -- Dự đoán vị trí mục tiêu (tăng độ chính xác)
local Radius = 350 -- Bán kính khóa mục tiêu (tăng phạm vi)
local BaseSmoothFactor = 0.2 -- Độ mượt cơ bản (cao hơn để nhanh hơn)
local MaxSmoothFactor = 0.7 -- Độ mượt tối đa
local TargetLockSpeed = 0.3 -- Tốc độ ghim mục tiêu
local SnapAimEnabled = true -- Bật/tắt Snap Aim
local AutoLockEnabled = true -- Bật/tắt Auto Lock
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái Aim

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local SnapAimLabel = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Nhãn Snap Aim
SnapAimLabel.Parent = ScreenGui
SnapAimLabel.Size = UDim2.new(0, 100, 0, 30)
SnapAimLabel.Position = UDim2.new(0.85, 0, 0.07, 0)
SnapAimLabel.Text = "Snap Aim: OFF"
SnapAimLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SnapAimLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SnapAimLabel.Font = Enum.Font.SourceSans
SnapAimLabel.TextSize = 18

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil
    end
end)

-- Bật/tắt Snap Aim
SnapAimLabel.MouseButton1Click:Connect(function()
    SnapAimEnabled = not SnapAimEnabled
    SnapAimLabel.Text = "Snap Aim: " .. (SnapAimEnabled and "ON" or "OFF")
    SnapAimLabel.BackgroundColor3 = SnapAimEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    table.insert(targets, Character)
                end
            end
        end
    end

    -- Sắp xếp mục tiêu theo khoảng cách gần nhất
    table.sort(targets, function(a, b)
        return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    end)
    return targets
end

-- Dự đoán vị trí mục tiêu (nâng cao)
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return target.HumanoidRootPart.Position
end

-- Tính toán SmoothFactor
local function CalculateSmoothFactor(target)
    local velocityMagnitude = target.HumanoidRootPart.Velocity.Magnitude
    local smoothFactor = BaseSmoothFactor + (velocityMagnitude / 50) -- Mượt hơn ở tốc độ cao
    return math.clamp(smoothFactor, BaseSmoothFactor, MaxSmoothFactor)
end

-- Theo dõi mục tiêu
RunService.Heartbeat:Connect(function()
    if AimActive then
        local enemies = FindEnemiesInRadius()
        if AutoLockEnabled and not Locked and #enemies > 0 then
            Locked = true
            CurrentTarget = enemies[1]
            ToggleButton.Text = "ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end

        if Locked and CurrentTarget then
            local target = CurrentTarget
            if target and target:FindFirstChild("HumanoidRootPart") then
                local targetPosition = PredictTargetPosition(target)
                local distance = (target.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

                if target.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    if SnapAimEnabled then
                        -- Ghim tức thì vào mục tiêu
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
                    else
                        -- Ghim mượt dần
                        local SmoothFactor = CalculateSmoothFactor(target)
                        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)
                    end
                end
            end
        end
    end
end)
