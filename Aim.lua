local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local enemy = nil
local Locked = true
local SecondaryCamEnabled = true -- Kích hoạt camera thứ hai
local SecondaryCamRadius = 1.2 -- Bán kính giới hạn camera phụ
local SecondaryCamHeightOffset = Vector3.new(0, 4, 0) -- Offset chiều cao camera phụ
local SecondaryCamSpeed = 0.2 -- Tốc độ di chuyển camera phụ

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

-- Cập nhật vị trí camera chính
function UpdateMainCamera(targetPosition)
    -- Sử dụng Lerp để mượt mà
    local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.3) -- Tăng tốc độ Lerp để xử lý di chuyển nhanh
end

-- Cập nhật vị trí camera thứ hai
function UpdateSecondaryCamera(mainCamPos, targetPos)
    -- Hướng từ camera chính tới mục tiêu
    local direction = (mainCamPos - targetPos).Unit
    -- Tính toán vị trí camera phụ mượt mà, tránh hiện tượng trượt
    local desiredPosition = targetPos + direction * SecondaryCamRadius + SecondaryCamHeightOffset
    local currentPos = Camera.CFrame.Position
    local smoothPosition = currentPos:Lerp(desiredPosition, SecondaryCamSpeed) -- Lerp để mượt mà hơn
    return CFrame.new(smoothPosition, targetPos)
end

-- Camera xử lý và theo dõi mượt mà
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        -- Tính toán vị trí dự đoán của mục tiêu
        local targetPosition = enemy.Position + enemy.Velocity * Prediction

        -- Cập nhật camera chính
        UpdateMainCamera(targetPosition)

        -- Cập nhật camera thứ hai nếu được bật
        if SecondaryCamEnabled then
            local secondaryCFrame = UpdateSecondaryCamera(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = secondaryCFrame
        end
    end
end)

-- Bật/tắt CamLock bằng phím tắt
Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            enemy = FindNearestEnemy()
            if enemy then
                CamlockState = true
            end
        else
            CamlockState = false
            enemy = nil
        end
    end
end)

-- Kiểm tra nếu mục tiêu ra khỏi phạm vi hoặc chết
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

        if Distance > Radius or not enemy.Parent or not enemy.Parent:FindFirstChild("Humanoid") or enemy.Parent.Humanoid.Health <= 0 then
            enemy = nil
            CamlockState = false
        end
    end
end)
