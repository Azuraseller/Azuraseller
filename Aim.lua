local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local CamlockState = false
local Prediction = 0.2 -- Tăng dự đoán để theo sát mục tiêu
local Radius = 200 -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15 -- Tăng tốc độ chuyển động camera
local CameraRotationSpeed = 0.75 -- Tốc độ xoay camera nhanh hơn
local Locked = false
local CurrentTarget = nil

-- Hàm tìm mục tiêu trong phạm vi
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

-- Hàm điều chỉnh camera khi có vật cản
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart, hitPosition = workspace:FindPartOnRay(ray, LocalPlayer.Character)

    -- Nếu có vật thể chắn, điều chỉnh camera ra xa mục tiêu
    if hitPart then
        local direction = (targetPosition - Camera.CFrame.Position).Unit
        local offset = direction * 5 -- Đẩy camera ra xa 5 studs
        return Camera.CFrame.Position + offset
    end
    return targetPosition
end

-- Cập nhật camera theo mục tiêu
RunService.RenderStepped:Connect(function()
    if CamlockState and CurrentTarget then
        local targetCharacter = CurrentTarget
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction

            -- Điều chỉnh camera để không bị che khuất
            targetPosition = AdjustCameraPosition(targetPosition)

            -- Tính toán vị trí camera chính
            local newCFrame1 = CFrame.new(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame1, SmoothFactor)

            -- Tính toán vị trí camera phụ
            local newCFrame2 = CFrame.new(Camera2.CFrame.Position, targetPosition)
            Camera2.CFrame = Camera2.CFrame:Lerp(newCFrame2, SmoothFactor)

            -- Nếu mục tiêu di chuyển nhanh, tăng tốc độ xoay camera
            if targetCharacter.HumanoidRootPart.Velocity.Magnitude > 50 then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), CameraRotationSpeed)
                Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), CameraRotationSpeed)
            end

            -- Kiểm tra mục tiêu còn hợp lệ
            local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                CurrentTarget = nil -- Hủy ghim mục tiêu nếu không hợp lệ
            end
        end
    else
        -- Tìm mục tiêu mới nếu không có mục tiêu
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            CurrentTarget = enemies[1] -- Lựa chọn mục tiêu đầu tiên
        end
    end
end)
