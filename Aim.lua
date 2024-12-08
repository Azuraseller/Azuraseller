local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local CamlockState = false
local Prediction = 0.12 -- Dự đoán vị trí (giảm giá trị để chính xác hơn)
local Radius = 200 -- Bán kính khóa mục tiêu
local CameraSpeed = 0.35 -- Tốc độ camera ghim mục tiêu
local Locked = false
local CurrentTarget = nil -- Mục tiêu hiện tại

getgenv().Key = "c"

-- Giao diện GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0) -- Vị trí nâng cao hơn
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Bật/tắt chế độ CamLock
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
        CurrentTarget = nil
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleCamlock)

-- Tìm đối thủ gần nhất trong phạm vi
local function FindNearestEnemy()
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

-- Xử lý CamLock
RunService.RenderStepped:Connect(function()
    -- Tự động bật nếu có mục tiêu trong phạm vi
    if not Locked then
        local target = FindNearestEnemy()
        if target then
            Locked = true
            CamlockState = true
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CurrentTarget = target
        end
    end

    -- Ghim mục tiêu khi CamLock bật
    if CamlockState and CurrentTarget then
        local enemyPosition = CurrentTarget.Position + CurrentTarget.Velocity * Prediction
        local newCFrame = CFrame.new(Camera.CFrame.Position, enemyPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, CameraSpeed)
    end

    -- Xử lý mất mục tiêu hoặc mục tiêu ra ngoài phạm vi
    if CamlockState and CurrentTarget then
        local Distance = (CurrentTarget.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if Distance > Radius or not CurrentTarget.Parent then
            CurrentTarget = nil
            CamlockState = false
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)

-- Xử lý tránh giật qua lại giữa nhiều mục tiêu
local function SelectBestTarget()
    local bestTarget = FindNearestEnemy()
    if bestTarget and CurrentTarget ~= bestTarget then
        CurrentTarget = bestTarget
    end
end

RunService.Heartbeat:Connect(function()
    if CamlockState then
        SelectBestTarget()
    end
end)

-- Phím bật/tắt chế độ CamLock
Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        ToggleCamlock()
    end
end)
