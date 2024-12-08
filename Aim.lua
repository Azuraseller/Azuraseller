local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local CamlockState = false
local Prediction = 0.1  -- Điều chỉnh dự đoán di chuyển mục tiêu
local Radius = 200  -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15 -- Tăng mượt khi theo dõi (cao hơn làm chậm chuyển động)
local CameraRotationSpeed = 0.5 -- Tăng tốc độ xoay camera khi ghim
local Locked = false
local CurrentTarget = nil  -- Mục tiêu hiện tại

getgenv().Key = "c"

-- Giao diện GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút X

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0) -- Nâng lên cao hơn
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0) -- Nằm trái nút ON/OFF
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Hàm bật/tắt trạng thái CamLock
local function ToggleCamlock()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil -- Hủy ghim khi tắt
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleCamlock)

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

-- Điều chỉnh vị trí camera để tránh bị che khuất
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
    if Locked then
        if CurrentTarget then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction

                -- Kiểm tra nếu mục tiêu không hợp lệ
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil -- Hủy ghim nếu mục tiêu không hợp lệ
                end

                -- Điều chỉnh camera để không bị che khuất
                targetPosition = AdjustCameraPosition(targetPosition)

                -- Cập nhật camera chính (Camera 1)
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)

                -- Cập nhật camera phụ (Camera 2)
                Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), SmoothFactor)

                -- Nếu mục tiêu di chuyển nhanh, tăng tốc độ xoay camera
                if targetCharacter.HumanoidRootPart.Velocity.Magnitude > 50 then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), CameraRotationSpeed)
                    Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), CameraRotationSpeed)
                end
            end
        else
            -- Tìm mục tiêu mới
            local enemies = FindEnemiesInRadius()
            if #enemies > 0 then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        end
    end
end)
