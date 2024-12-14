local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace
Camera2.CameraType = Enum.CameraType.Scriptable

-- Cấu hình các tham số
local Prediction = 0.15
local Radius = 200
local CloseRadius = 25 -- Bán kính gần
local SmoothFactor = 0.2
local SpeedThreshold = 20 -- Ngưỡng tốc độ để tăng tốc độ Aim
local SpeedMultiplier = 2 -- Hệ số tăng tốc khi mục tiêu di chuyển nhanh
local Locked = false
local CurrentTarget = nil
local AimActive = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút ON/OFF để bật/tắt Aim thủ công
ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        -- Chuyển sang Camera phụ
        Camera2.CFrame = Camera.CFrame
        workspace.CurrentCamera = Camera2
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
        -- Chuyển về Camera chính
        workspace.CurrentCamera = Camera
    end
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
    return targets
end

-- Kiểm tra mục tiêu hiện tại có hợp lệ hay không
local function IsTargetValid(target)
    if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") then
        local distance = (target.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if target.Humanoid.Health > 0 and distance <= Radius then
            return true
        end
    end
    return false
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return humanoidRootPart.Position
end

-- Ghim chính xác vào vị trí trên cơ thể
local function GetAimPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local head = target:FindFirstChild("Head")
        if head then
            return head.Position -- Ghim vào đầu
        else
            return humanoidRootPart.Position + Vector3.new(0, 1.5, 0) -- Ghim vào ngực nếu không có đầu
        end
    end
    return nil
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Camera 2 theo dõi người chơi
        Camera2.CFrame = Camera.CFrame

        -- Kiểm tra nếu mục tiêu hiện tại không hợp lệ
        if not IsTargetValid(CurrentTarget) then
            Locked = false
            CurrentTarget = nil
        end

        -- Tìm mục tiêu mới nếu không có mục tiêu hiện tại
        if not Locked then
            local enemies = FindEnemiesInRadius()
            if #enemies > 0 then
                CurrentTarget = enemies[1] -- Ưu tiên mục tiêu gần nhất
                Locked = true
            end
        end

        -- Theo dõi mục tiêu hiện tại
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local aimPosition = GetAimPosition(targetCharacter)
                if aimPosition then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPosition), SmoothFactor)
                end
            end
        end
    end
end)
