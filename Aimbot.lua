local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình các tham số
local Prediction = 0.2 -- Dự đoán vị trí mục tiêu
local Radius = 200 -- Bán kính khóa mục tiêu
local CloseRadius = 25 -- Bán kính để tắt Aimbot khi mục tiêu quá gần
local SmoothFactor = 0.3 -- Tăng mức độ mượt khi camera theo dõi
local Locked = false
local CurrentTarget = nil
local AimActive = true

-- Tìm kẻ thù gần nhất trong bán kính
local function FindClosestEnemy()
    local closestEnemy = nil
    local closestDistance = Radius

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance < closestDistance then
                    closestEnemy = Character
                    closestDistance = Distance
                end
            end
        end
    end

    return closestEnemy, closestDistance
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        local closestEnemy, closestDistance = FindClosestEnemy()

        if closestEnemy then
            if closestDistance <= CloseRadius then
                Locked = false -- Tắt Aimbot khi mục tiêu quá gần
                CurrentTarget = nil
            else
                if not Locked then
                    Locked = true
                end
                CurrentTarget = closestEnemy
            end
        else
            Locked = false
            CurrentTarget = nil
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction

                -- Kiểm tra nếu mục tiêu không hợp lệ
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    -- Cập nhật camera chính
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)
                end
            end
        end
    end
end)
