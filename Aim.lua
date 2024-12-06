local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local SecondaryCamRadius = 1.2 -- Bán kính giới hạn camera phụ
local SecondaryCamHeightOffset = Vector3.new(0, 4, 0) -- Offset chiều cao camera phụ (sau và trên nhân vật)
local SecondaryCamSpeed = 0.2 -- Tốc độ di chuyển camera phụ
local enemy = nil
local Locked = true

getgenv().Key = "c"

-- Giao diện GUI (Nút On/Off)
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")  -- Nút "X" để tắt GUI

ScreenGui.Parent = game:GetService("CoreGui")
ToggleButton.Parent = ScreenGui
CloseButton.Parent = ScreenGui

-- Nút bật/tắt CamLock
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.02, 0) -- Vị trí nút nâng lên cao hơn
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút đóng GUI (dấu "X")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.89, 0, 0.02, 0)  -- Vị trí dấu "X"
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 20

-- Hàm bật/tắt trạng thái CamLock từ nút
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        enemy = FindNearestEnemy()
        CamlockState = true
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        enemy = nil
        CamlockState = false
    end
end)

-- Tìm đối thủ gần nhất trong phạm vi
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = Radius, nil
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    if Distance < ClosestDistance then
                        ClosestPlayer = Character.HumanoidRootPart
                        ClosestDistance = Distance
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

-- Camera phụ (di chuyển trong phạm vi hình cầu)
function UpdateSecondaryCameraPosition(mainCamPos, targetPos)
    local direction = (mainCamPos - targetPos).Unit -- Hướng từ mục tiêu về camera chính
    local desiredPosition = targetPos + direction * SecondaryCamRadius + SecondaryCamHeightOffset -- Camera phụ phía trên và sau mục tiêu
    return desiredPosition
end

-- Cập nhật camera mượt mà hơn
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        -- Vị trí mục tiêu và dự đoán
        local targetPosition = enemy.Position + enemy.Velocity * Prediction

        -- Cập nhật camera chính mượt mà hơn
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.1) -- Tăng tốc độ ghim mục tiêu

        -- Cập nhật camera phụ (theo trong hình cầu)
        local secondaryCamPosition = UpdateSecondaryCameraPosition(Camera.CFrame.Position, targetPosition)
        local secondaryCamCFrame = CFrame.new(secondaryCamPosition, targetPosition)
    end
end)

-- Tự động bật aimbot khi có đối thủ trong phạm vi
RunService.RenderStepped:Connect(function()
    if not CamlockState then
        local nearestEnemy = FindNearestEnemy()
        if nearestEnemy then
            CamlockState = true
            enemy = nearestEnemy
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

-- Phím bật/tắt CamLock bằng phím tắt
Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            enemy = FindNearestEnemy()
            CamlockState = true
        else
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Xử lý khi đối thủ ra khỏi phạm vi hoặc chết
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

        -- Kiểm tra nếu đối thủ chết hoặc ra ngoài phạm vi
        if Distance > Radius or enemy.Parent == nil or enemy.Parent:FindFirstChild("Humanoid") == nil or enemy.Parent.Humanoid.Health <= 0 then
            enemy = nil
            CamlockState = false
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)

-- Xử lý khi nhấn vào nút "X" để ẩn/hủy GUI
CloseButton.MouseButton1Click:Connect(function()
    if ScreenGui.Enabled then
        ScreenGui.Enabled = false
    else
        ScreenGui.Enabled = true
    end
end)
