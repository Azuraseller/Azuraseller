local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local Radius = 230 -- Bán kính khóa mục tiêu
local BaseSmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.5  -- Mức độ mượt tối đa
local CameraRotationSpeed = 0.3  -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.2 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.1 -- Tốc độ chuyển mục tiêu
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
ToggleButton.Text = "OFF" -- Văn bản mặc định
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
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

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Ẩn/hiện nút ON/OFF theo trạng thái Aim
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
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
        CurrentTarget = nil -- Hủy mục tiêu khi tắt CamLock
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
    -- Nếu có nhiều mục tiêu, chọn mục tiêu gần nhất với LocalPlayer
    if #targets > 1 then
        table.sort(targets, function(a, b)
            return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        end)
    end
    return targets
end

-- Điều chỉnh camera tránh bị che khuất
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hitPart then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Dự đoán vị trí mục tiêu với gia tốc và tốc độ
local function PredictTargetPosition(target)
    local humanoid = target:FindFirstChild("Humanoid")
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoid and humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local direction = velocity.Unit
        local speed = velocity.Magnitude
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return target.HumanoidRootPart.Position
end

-- Tính toán SmoothFactor dựa trên tốc độ mục tiêu
local function CalculateSmoothFactor(target)
    local velocityMagnitude = target.HumanoidRootPart.Velocity.Magnitude
    local smoothFactor = BaseSmoothFactor + (velocityMagnitude / 100)
    return math.clamp(smoothFactor, BaseSmoothFactor, MaxSmoothFactor)
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
            end
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = PredictTargetPosition(targetCharacter)

                -- Kiểm tra nếu mục tiêu không hợp lệ
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    -- Điều chỉnh vị trí camera
                    targetPosition = AdjustCameraPosition(targetPosition)

                    -- Tính toán SmoothFactor
                    local SmoothFactor = CalculateSmoothFactor(targetCharacter)

                    -- Sử dụng TargetLockSpeed để điều chỉnh tốc độ ghim
                    local TargetPositionSmooth = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), TargetLockSpeed)
                    -- Cập nhật camera chính (Camera 1)
                    Camera.CFrame = TargetPositionSmooth

                    -- Cập nhật camera phụ (Camera 2)
                    Camera2.CFrame = TargetPositionSmooth
                end
            end
        end
    end
end)

-- Tự động bật script khi chuyển server
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        AimActive = true
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
   end)
