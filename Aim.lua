local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Cấu hình các tham số
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local Radius = 400 -- Bán kính khóa mục tiêu
local BaseSmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.5  -- Mức độ mượt tối đa
local CameraRotationSpeed = 0.3  -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.2 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.1 -- Tốc độ chuyển mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính

-- Hàm X, Y, Z, F, XY, XF, ZY, ZF
local targetMovement = {
    X = 1,
    Y = 1,
    Z = 1,
    F = 1,
    XY = 1,
    XF = 1,
    ZY = 1,
    ZF = 1
}

-- Cập nhật các giá trị di chuyển dựa trên hướng mục tiêu
local function UpdateTargetMovement(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local previousPosition = humanoidRootPart.Position
        local currentPosition = previousPosition
        local delta = currentPosition - previousPosition

        -- Di chuyển bên phải (X)
        if delta.X > 0 then
            targetMovement.X = targetMovement.X + 1
        -- Di chuyển sang trái (Z)
        elseif delta.X < 0 then
            targetMovement.Z = targetMovement.Z + 1
        end

        -- Di chuyển lên (Y)
        if delta.Y > 0 then
            targetMovement.Y = targetMovement.Y + 1
        -- Di chuyển xuống (F)
        elseif delta.Y < 0 then
            targetMovement.F = targetMovement.F + 1
        end

        -- Di chuyển theo các đường chéo
        if delta.X > 0 and delta.Y > 0 then
            targetMovement.XY = targetMovement.XY + 1
        elseif delta.X > 0 and delta.Y < 0 then
            targetMovement.XF = targetMovement.XF + 1
        elseif delta.X < 0 and delta.Y > 0 then
            targetMovement.ZY = targetMovement.ZY + 1
        elseif delta.X < 0 and delta.Y < 0 then
            targetMovement.ZF = targetMovement.ZF + 1
        end

        -- Nếu mục tiêu đứng yên, reset giá trị di chuyển
        if delta.Magnitude == 0 then
            targetMovement.X = 1
            targetMovement.Y = 1
            targetMovement.Z = 1
            targetMovement.F = 1
            targetMovement.XY = 1
            targetMovement.XF = 1
            targetMovement.ZY = 1
            targetMovement.ZF = 1
        end
    end
end

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

-- Hàm để điều chỉnh Aim vào thân mục tiêu
local function AimAtTargetBody(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    local humanoid = target:FindFirstChild("Humanoid")
    if humanoidRootPart and humanoid then
        -- Đặt aim vào vị trí thân (HumanoidRootPart)
        return humanoidRootPart.Position
    end
    return target.HumanoidRootPart.Position
end

-- Cập nhật Camera và Aim đồng bộ
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            if Locked then
                Locked = false
                CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
            end
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                UpdateTargetMovement(targetCharacter) -- Cập nhật chuyển động của mục tiêu

                local targetPosition = AimAtTargetBody(targetCharacter)

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

                    -- Cập nhật camera và aim đồng bộ
                    Camera.CFrame = TargetPositionSmooth
                end
            end
        end
    end
end)

-- Tự động bật script khi chuyển server
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        AimActive = true
    end
end)
