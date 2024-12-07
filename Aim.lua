local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local CamlockState = false
local Prediction = 0.16
local Radius = 250 -- Bán kính khóa mục tiêu
local SecondaryCamRadius = 1.5 -- Bán kính giới hạn camera phụ
local SecondaryCamSpeed = 0.3 -- Tốc độ di chuyển camera phụ
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

-- Camera phụ (di chuyển trong phạm vi hình tròn)
function UpdateSecondaryCameraPosition(mainCamPos, targetPos)
    local direction = (targetPos - mainCamPos).Unit -- Hướng di chuyển
    local distance = math.min((targetPos - mainCamPos).Magnitude, SecondaryCamRadius) -- Giới hạn trong hình tròn
    local offset = direction * distance
    return mainCamPos + offset
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        -- Vị trí mục tiêu và dự đoán
        local targetPosition = enemy.Position + enemy.Velocity * Prediction
        
        -- Cập nhật camera chính
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.3) -- Tăng tốc phản hồi camera chính

        -- Cập nhật camera phụ (theo trong hình tròn)
        local secondaryCamPosition = UpdateSecondaryCameraPosition(Camera.CFrame.Position, targetPosition)
        local secondaryCamCFrame = CFrame.new(secondaryCamPosition, targetPosition)
        
        -- Hiển thị hoặc sử dụng camera phụ (tùy chỉnh theo logic game)
        -- Ví dụ: di chuyển góc nhìn giả lập từ camera phụ (không thay thế camera chính)
    end
end)

-- Phím bật/tắt CamLock
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
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if Distance > Radius then
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Tự động tìm đối thủ mới khi không có mục tiêu
RunService.RenderStepped:Connect(function()
    if CamlockState and not enemy then
        enemy = FindNearestEnemy()
    end
end)
