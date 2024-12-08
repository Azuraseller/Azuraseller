local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local CameraSpeed = 0.25 -- Tốc độ phản hồi camera
local SmoothFactor = 0.15 -- Hệ số mượt của camera khi theo dõi
local Locked = false
local CurrentTarget = nil -- Mục tiêu hiện tại

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

-- Biến trạng thái ẩn/hiện
local lastClickTime = 0
local doubleClickThreshold = 0.5 -- Thời gian giữa hai lần nhấn để xem là nhấn đúp
local ToggleVisible = true
local AimActive = true -- Trạng thái aim (Kích hoạt hoặc tắt aim)

-- Hàm bật/tắt trạng thái CamLock từ nút
local function ToggleCamlock()
    if AimActive then
        Locked = not Locked
        if Locked then
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CamlockState = true
        else
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            CamlockState = false
        end
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleCamlock)

-- Nút X để tắt/hoạt động lại aim
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    if currentTime - lastClickTime < doubleClickThreshold then
        -- Nhấn đúp sẽ tắt aim
        AimActive = not AimActive
        if AimActive then
            -- Khi aim hoạt động lại, gán trạng thái là ON
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CamlockState = true
        else
            -- Khi aim bị tắt, gán trạng thái là OFF
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            CamlockState = false
            CurrentTarget = nil -- Ngừng ghim mục tiêu
        end
    end
    lastClickTime = currentTime
end)

-- Tìm đối thủ gần nhất trong phạm vi
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = Radius, nil
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius and Distance < ClosestDistance then
                    ClosestPlayer = Character.HumanoidRootPart
                    ClosestDistance = Distance
                end
            end
        end
    end
    return ClosestPlayer
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    local enemy = FindNearestEnemy()

    if AimActive then
        if enemy then
            local distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            -- Kiểm tra và bật Aim khi mục tiêu vào phạm vi R = 200
            if distance <= Radius then
                if CurrentTarget ~= enemy then
                    -- Nếu có mục tiêu mới, ghim mục tiêu đó
                    CurrentTarget = enemy
                    CamlockState = true
                    ToggleButton.Text = "CamLock: ON"
                    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                end

                -- Tính toán vị trí mục tiêu với dự đoán di chuyển
                local targetPosition = enemy.Position + enemy.Velocity * Prediction

                -- Cập nhật camera chính với mượt mà (Camera 1)
                local newCFrame1 = CFrame.new(Camera.CFrame.Position, targetPosition)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame1, SmoothFactor)

                -- Cập nhật camera phụ với cùng góc nhìn
                local newCFrame2 = CFrame.new(Camera2.CFrame.Position, targetPosition)
                Camera2.CFrame = Camera2.CFrame:Lerp(newCFrame2, SmoothFactor)

                -- Xử lý mục tiêu ra sau lưng
                local directionToEnemy = (enemy.Position - Camera.CFrame.Position).Unit
                local forwardDirection = Camera.CFrame.LookVector
                if forwardDirection:Dot(directionToEnemy) < 0 then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemy.Position) -- Điều chỉnh tức thì
                    Camera2.CFrame = CFrame.new(Camera2.CFrame.Position, enemy.Position) -- Camera 2 cũng phải điều chỉnh
                end
            else
                -- Nếu mục tiêu ra ngoài phạm vi, tắt khóa và reset
                if CurrentTarget then
                    CurrentTarget = nil
                    CamlockState = false
                    ToggleButton.Text = "CamLock: OFF"
                    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        else
            -- Nếu không tìm thấy mục tiêu, tắt khóa camera
            if CurrentTarget then
                CurrentTarget = nil
                CamlockState = false
                ToggleButton.Text = "CamLock: OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end)
