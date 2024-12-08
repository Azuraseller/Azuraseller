local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local CameraSpeed = 0.22 -- Tốc độ phản hồi camera
local SmoothFactor = 0.12 -- Hệ số mượt của camera khi theo dõi
local Locked = false
local CurrentTarget = nil -- Mục tiêu hiện tại
local MaxRotationSpeed = 30 -- Tốc độ quay tối đa khi mục tiêu dịch chuyển nhanh

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

-- Hàm bật/tắt trạng thái CamLock từ nút
local function ToggleCamlock()
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

ToggleButton.MouseButton1Click:Connect(ToggleCamlock)

-- Nút X để ẩn/hiện nút ON/OFF
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    if currentTime - lastClickTime < doubleClickThreshold then
        ToggleVisible = not ToggleVisible
        ToggleButton.Visible = ToggleVisible
        if not ToggleVisible then
            CamlockState = false -- Vô hiệu hóa Camlock
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
    if CamlockState then
        local enemy = FindNearestEnemy()

        if enemy then
            local distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            -- Kiểm tra nếu mục tiêu nằm trong phạm vi khóa
            if distance <= Radius then
                if CurrentTarget ~= enemy then
                    -- Nếu có mục tiêu mới, ghim mục tiêu đó
                    CurrentTarget = enemy
                end

                -- Tính toán vị trí mục tiêu với dự đoán di chuyển
                local targetPosition = enemy.Position + enemy.Velocity * Prediction

                -- Cập nhật camera chính với mượt mà
                local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, SmoothFactor)

                -- Đảm bảo tốc độ aim cao hơn khi mục tiêu di chuyển nhanh
                if distance > Radius * 0.8 then
                    -- Tăng tốc độ quay camera khi mục tiêu di chuyển nhanh
                    SmoothFactor = 0.3
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), MaxRotationSpeed * 0.2) -- Quay nhanh
                else
                    SmoothFactor = 0.15 -- Trở lại mượt mà khi gần
                end

                -- Xử lý mục tiêu ra sau lưng
                local directionToEnemy = (enemy.Position - Camera.CFrame.Position).Unit
                local forwardDirection = Camera.CFrame.LookVector
                if forwardDirection:Dot(directionToEnemy) < 0 then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemy.Position) -- Điều chỉnh tức thì
                end
            else
                -- Nếu mục tiêu ra ngoài phạm vi, tắt khóa và reset
                CamlockState = false
                CurrentTarget = nil
                ToggleButton.Text = "CamLock: OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        else
            -- Nếu không tìm thấy mục tiêu, tắt khóa camera
            CamlockState = false
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)
