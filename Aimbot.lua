local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CamlockState = false
local Prediction = 0.16
local Radius = 300 -- Phạm vi khóa mục tiêu
local enemy = nil
local Locked = true

getgenv().Key = "c"

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

-- Cập nhật camera để khóa mục tiêu
RunService.Heartbeat:Connect(function()
    if CamlockState and enemy then
        local camera = workspace.CurrentCamera
        camera.CFrame = CFrame.new(camera.CFrame.p, enemy.Position + enemy.Velocity * Prediction)
    end
end)

-- Phím chuyển đổi CamLock
Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            enemy = FindNearestEnemy()
            CamlockState = true
        else
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Xử lý khi đối thủ ra khỏi phạm vi
RunService.Heartbeat:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if Distance > Radius then
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Tạo giao diện người dùng
local BladLock = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TextButton = Instance.new("TextButton")

BladLock.Name = "BladLock"
BladLock.Parent = game.CoreGui

Frame.Parent = BladLock
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.Size = UDim2.new(0, 200, 0, 50)
Frame.Position = UDim2.new(0.5, -100, 0.1, 0)
Frame.Draggable = true
UICorner.Parent = Frame

TextButton.Parent = Frame
TextButton.Text = "Toggle CamLock"
TextButton.Size = UDim2.new(1, 0, 1, 0)
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

TextButton.MouseButton1Click:Connect(function()
    CamlockState = not CamlockState
    if CamlockState then
        enemy = FindNearestEnemy()
        TextButton.Text = "ON"
    else
        enemy = nil
        TextButton.Text = "OFF"
    end
end)
