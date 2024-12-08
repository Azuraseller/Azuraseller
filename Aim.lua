local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local CamlockState = false
local Prediction = 0.1  -- Giảm giá trị dự đoán để nhanh hơn
local Radius = 200  -- Bán kính khóa mục tiêu
local CameraSpeed = 0.35 -- Tăng tốc độ phản hồi camera
local CameraRotationSpeed = 0.7 -- Tốc độ xoay camera nhanh hơn khi ghim
local SmoothFactor = 0.1  -- Tăng độ mượt của camera khi theo dõi
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

-- Biến trạng thái ẩn/hiện và kích hoạt Aim
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

-- Nút X để tắt/hoạt động lại aim và ẩn/hiện nút ON/OFF
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    if currentTime - lastClickTime < doubleClickThreshold then
        -- Nhấn đúp sẽ tắt aim
        AimActive = not AimActive
        if AimActive then
            -- Khi aim hoạt động lại, gán trạng thái là ON và hiện nút ON/OFF
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CamlockState = true
            ToggleButton.Visible = true -- Hiện lại nút ON/OFF
        else
            -- Khi aim bị tắt, gán trạng thái là OFF và ẩn nút ON/OFF
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            CamlockState = false
            ToggleButton.Visible = false -- Ẩn nút ON/OFF
            CurrentTarget = nil -- Ngừng ghim mục tiêu
        end
    end
    lastClickTime = currentTime
end)

-- Tìm tất cả đối thủ trong phạm vi
function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    table.insert(targets, Character.HumanoidRootPart)
                end
            end
        end
    end
    return targets
end

-- Kiểm tra và điều chỉnh camera để không bị che khuất
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart, hitPosition = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    
    -- Nếu có vật thể chắn, điều chỉnh camera để không bị che
    if hitPart then
        local direction = (targetPosition - Camera.CFrame.Position).Unit
        local offset = direction * 5 -- Đẩy camera ra xa 5 studs để tránh vật cản
        return Camera.CFrame.Position + offset
    end
    return targetPosition
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    local enemies = FindEnemiesInRadius()

    if AimActive then
        -- Kiểm tra nếu chưa có mục tiêu hoặc mục tiêu đã chết, tìm mục tiêu mới
        if CurrentTarget == nil or CurrentTarget.Parent == nil or CurrentTarget.Humanoid.Health <= 0 then
            if #enemies > 0 then
                CurrentTarget = enemies[1] -- Chọn player đầu tiên trong phạm vi (bạn có thể chọn cách chọn khác)
                CamlockState = true
                ToggleButton.Text = "CamLock: ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
        end

        if CurrentTarget then
            local distance = (CurrentTarget.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            -- Tính toán vị trí mục tiêu với dự đoán di chuyển
            local targetPosition = CurrentTarget.Position + CurrentTarget.Velocity * Prediction

            -- Điều chỉnh lại vị trí camera để không bị che khuất
            targetPosition = AdjustCameraPosition(targetPosition)

            -- Cập nhật camera chính với mượt mà (Camera 1)
            local newCFrame1 = CFrame.new(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame1, SmoothFactor)

            -- Cập nhật camera phụ với cùng góc nhìn
            local newCFrame2 = CFrame.new(Camera2.CFrame.Position, targetPosition)
            Camera2.CFrame = Camera2.CFrame:Lerp(newCFrame2, SmoothFactor)

            -- Tăng tốc độ xoay camera khi mục tiêu di chuyển nhanh
            if CurrentTarget.Velocity.Magnitude > 50 then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), CameraRotationSpeed)
                Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), CameraRotationSpeed)
            end

            -- Xử lý mục tiêu ra sau lưng
            local directionToEnemy = (CurrentTarget.Position - Camera.CFrame.Position).Unit
            local forwardDirection = Camera.CFrame.LookVector
            if forwardDirection:Dot(directionToEnemy) < 0 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, CurrentTarget.Position) -- Điều chỉnh tức thì
                Camera2.CFrame = CFrame.new(Camera2.CFrame.Position, CurrentTarget.Position) -- Camera 2 cũng phải điều chỉnh
            end

            -- Nếu mục tiêu ra ngoài phạm vi hoặc chết, reset
            if distance > Radius or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
                CurrentTarget = nil
                CamlockState = false
                ToggleButton.Text = "CamLock: OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end)
