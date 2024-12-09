local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.3  -- Dự đoán vị trí mục tiêu
local Radius = 250  -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi
local FastFollowFactor = 0.5  -- Tốc độ cực nhanh khi mục tiêu di chuyển ra sau
local CameraRotationSpeed = 0.7  -- Tốc độ xoay camera
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút X

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

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Ẩn/hiện nút ON/OFF theo trạng thái Aim
    if not AimActive then
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
    else
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil -- Hủy mục tiêu khi tắt CamLock
    end
end)

-- Tìm đối thủ gần nhất trong phạm vi
local function FindClosestEnemy()
    local closestEnemy = nil
    local shortestDistance = Radius
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = Character
                end
            end
        end
    end
    return closestEnemy
end

-- Điều chỉnh camera để tránh bị che khuất
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hitPart then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm đối thủ gần nhất
        local target = FindClosestEnemy()
        if target then
            if not Locked then
                Locked = true
                ToggleButton.Text = "CamLock: ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            CurrentTarget = target
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "CamLock: OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil
            end
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

                -- Kiểm tra nếu mục tiêu không hợp lệ
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    targetPosition = AdjustCameraPosition(targetPosition)

                    -- Nếu mục tiêu di chuyển nhanh hoặc ra sau, tăng tốc camera
                    local lerpFactor = (distance > Radius / 2) and FastFollowFactor or SmoothFactor
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), lerpFactor)
                    Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), lerpFactor)
                end
            end
        end
    end
end)
