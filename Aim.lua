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
local Radius = 200  -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi
local CameraRotationSpeed = 0.5  -- Tốc độ xoay camera khi ghim mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
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
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền
ToggleButton.BackgroundTransparency = 1 -- Không có nền
ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Màu của biểu tượng
ToggleButton.ImageTransparency = 0 -- Độ trong suốt của biểu tượng

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
        ToggleButton.Image = "rbxassetid://133602550183849" -- Biểu tượng khi tắt
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
    else
        ToggleButton.Image = "rbxassetid://133602550183849" -- Biểu tượng khi bật
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
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

-- Điều chỉnh camera tránh bị che khuất
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hitPart then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local velocity = target.HumanoidRootPart.Velocity
    local prediction = velocity * Prediction
    return target.HumanoidRootPart.Position + prediction
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
                    -- Điều chỉnh vị trí camera
                    targetPosition = AdjustCameraPosition(targetPosition)

                    -- Cập nhật camera chính (Camera 1)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)

                    -- Cập nhật camera phụ (Camera 2)
                    Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), SmoothFactor)
                end
            end
        end
    end
end)
-- Thêm hiệu ứng cho nút Aim
local function ButtonEffect()
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local goal = {Size = UDim2.new(0, 150, 0, 75), Transparency = 1}
    local tween = TweenService:Create(ToggleButton, tweenInfo, goal)
    tween:Play()
    tween.Completed:Connect(function()
        -- Sau khi hiệu ứng hoàn tất, thực hiện thay đổi lại
        ToggleButton.Size = UDim2.new(0, 100, 0, 50)
        ToggleButton.Transparency = 0
    end)
end
-- Gọi hiệu ứng khi bấm nút
ToggleButton.MouseButton1Click:Connect(function()
    ButtonEffect()
end)
0 commit comments
Comments
0
 (0)
Comment
You're receiving notifications because you're subscribed to this thread.
