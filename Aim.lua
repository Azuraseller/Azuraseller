local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1 -- Dự đoán vị trí mục tiêu
local Radius = 200 -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15 -- Mức độ mượt khi camera theo dõi
local CameraRotationSpeed = 0.5 -- Tốc độ xoay camera khi ghim mục tiêu
local AimCorrectionSpeed = 0.2 -- Tốc độ điều chỉnh khi lệch mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái Aim
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("ImageButton")
local CloseButton = Instance.new("TextButton") -- Nút X

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Image = "rbxassetid://133602550183849" -- Thay đổi biểu tượng
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.ImageTransparency = 0

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
    if AimActive then
        ToggleButton.Visible = true -- Hiển thị nút ON/OFF
        ToggleButton.Image = "rbxassetid://133602550183849"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Visible = false -- Ẩn nút ON/OFF
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
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
    return targets
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local velocity = target.HumanoidRootPart.Velocity
    local prediction = velocity * Prediction
    return target.HumanoidRootPart.Position + prediction
end

-- Điều chỉnh camera để ghim chính xác mục tiêu
local function AdjustCameraToTarget(targetPosition)
    local currentCameraDirection = (Camera.CFrame.LookVector).Unit
    local desiredDirection = (targetPosition - Camera.CFrame.Position).Unit
    local adjustment = desiredDirection - currentCameraDirection

    -- Điều chỉnh camera theo hướng mục tiêu với tốc độ giới hạn
    if adjustment.Magnitude > 0.01 then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), AimCorrectionSpeed)
    end
end

-- Hạn chế giật khi theo dõi mục tiêu
local function LimitCameraJitter(targetPosition)
    local maxAngleDeviation = math.rad(5) -- Giới hạn lệch góc tối đa (5 độ)
    local cameraDirection = (Camera.CFrame.LookVector).Unit
    local targetDirection = (targetPosition - Camera.CFrame.Position).Unit
    local angle = math.acos(cameraDirection:Dot(targetDirection))

    if angle > maxAngleDeviation then
        local correctedDirection = cameraDirection:Lerp(targetDirection, maxAngleDeviation / angle)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + correctedDirection)
    end
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            if Locked then
                Locked = false
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
                    -- Điều chỉnh vị trí camera để ghim chính xác
                    AdjustCameraToTarget(targetPosition)
                    LimitCameraJitter(targetPosition)
                end
            end
        end
    end
end)
