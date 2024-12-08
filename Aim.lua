local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình các tham số
local Radius = 200  -- Bán kính khóa mục tiêu
local Prediction = 0.15  -- Dự đoán vị trí di chuyển của mục tiêu
local SmoothFactor = 0.2  -- Độ mượt khi theo dõi mục tiêu (giảm để nhanh hơn)
local CameraRotationSpeed = 0.8  -- Tăng tốc độ xoay của Camera
local CurrentTarget = nil  -- Mục tiêu hiện tại

getgenv().Key = "c"

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius()
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

-- Chuyển đổi góc nhìn camera mượt mà
local function SmoothAim(targetPosition)
    local direction = (targetPosition - Camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, SmoothFactor)
end

-- Cập nhật camera theo mục tiêu
RunService.RenderStepped:Connect(function()
    if CurrentTarget then
        local targetPart = CurrentTarget
        if targetPart and targetPart.Parent and targetPart.Parent:FindFirstChild("Humanoid") then
            local targetPosition = targetPart.Position + (targetPart.Velocity * Prediction)

            -- Kiểm tra khoảng cách và mục tiêu có còn hợp lệ
            local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance > Radius or targetPart.Parent.Humanoid.Health <= 0 then
                CurrentTarget = nil -- Hủy ghim nếu mục tiêu không còn hợp lệ
                return
            end

            -- Chỉnh Camera chính xác vào mục tiêu
            SmoothAim(targetPosition)
        else
            CurrentTarget = nil -- Hủy ghim nếu mục tiêu không còn tồn tại
        end
    else
        -- Tìm mục tiêu mới trong phạm vi
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            CurrentTarget = enemies[1] -- Lựa chọn mục tiêu đầu tiên
        end
    end
end)
