local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Cấu hình các tham số
local Prediction = 0.15 -- Dự đoán vị trí mục tiêu
local Radius = 450 -- Bán kính khóa mục tiêu
local CloseRadius = 7 -- Bán kính gần để tự động tắt Aim
local CameraRotationSpeed = 0.65 -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.8 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.2 -- Tốc độ chuyển mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local SilentAimActive = false -- Trạng thái Silent Aim
local SilentSkillActive = false -- Trạng thái Silent Skill
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút X
local SilentAimButton = Instance.new("TextButton")
local SilentSkillButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "OFF" -- Văn bản mặc định
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Nút Silent Aim
SilentAimButton.Parent = ScreenGui
SilentAimButton.Size = UDim2.new(0, 100, 0, 50)
SilentAimButton.Position = UDim2.new(0.85, 0, 0.1, 0)
SilentAimButton.Text = "Silent Aim OFF"
SilentAimButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
SilentAimButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
SilentAimButton.Font = Enum.Font.SourceSans
SilentAimButton.TextSize = 18

-- Nút Silent Skill
SilentSkillButton.Parent = ScreenGui
SilentSkillButton.Size = UDim2.new(0, 100, 0, 50)
SilentSkillButton.Position = UDim2.new(0.85, 0, 0.2, 0)
SilentSkillButton.Text = "Silent Skill OFF"
SilentSkillButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
SilentSkillButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
SilentSkillButton.Font = Enum.Font.SourceSans
SilentSkillButton.TextSize = 18

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Ẩn/hiện nút ON/OFF theo trạng thái Aim
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút ON/OFF để bật/tắt Silent Aim
SilentAimButton.MouseButton1Click:Connect(function()
    SilentAimActive = not SilentAimActive
    if SilentAimActive then
        SilentAimButton.Text = "Silent Aim ON"
        SilentAimButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        SilentAimButton.Text = "Silent Aim OFF"
        SilentAimButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Nút ON/OFF để bật/tắt Silent Skill
SilentSkillButton.MouseButton1Click:Connect(function()
    SilentSkillActive = not SilentSkillActive
    if SilentSkillActive then
        SilentSkillButton.Text = "Silent Skill ON"
        SilentSkillButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        SilentSkillButton.Text = "Silent Skill OFF"
        SilentSkillButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    table.insert(targets, Character)
                end
            end
        end
    end
    return targets
end

-- Dự đoán vị trí mục tiêu với gia tốc và tốc độ (Cải tiến)
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local previousVelocity = humanoidRootPart:GetAttribute("PreviousVelocity") or velocity
        local acceleration = (velocity - previousVelocity) / RunService.Heartbeat:Wait()
        humanoidRootPart:SetAttribute("PreviousVelocity", velocity) -- Store the previous velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction + 0.5 * acceleration * Prediction^2
        
        -- Account for target's rotation and gravity
        local gravity = Vector3.new(0, -9.81, 0)  -- Simulate gravity effect on target
        predictedPosition = predictedPosition + gravity * (Prediction ^ 2)  -- Add gravity effect
        
        return predictedPosition
    end
    return target.HumanoidRootPart.Position
end

-- Hàm bắn tự động vào mục tiêu (Silent Aim)
local function FireAtTarget(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        local predictedPosition = PredictTargetPosition(target)
        
        -- Raycast kiểm tra xem có trúng mục tiêu không
        local ray = workspace:Raycast(Camera.CFrame.Position, (predictedPosition - Camera.CFrame.Position).Unit * 1000)
        if ray and ray.Instance and ray.Instance.Parent and ray.Instance.Parent:FindFirstChild("Humanoid") then
            -- Bắn vào mục tiêu nếu raycast trúng
            ReplicatedStorage:FireServer("FireAtPosition", predictedPosition) -- Modify this to match your game’s firing system
        end
    end
end

-- Hàm Silent Skill
local lastSkillUseTime = 0
local skillCooldown = 1  -- 1 second cooldown for skill

local function UseSilentSkill(target)
    if target and SilentSkillActive then
        local currentTime = tick()
        if currentTime - lastSkillUseTime >= skillCooldown then
            lastSkillUseTime = currentTime
            -- Perform skill at predicted position
            local predictedPosition = PredictTargetPosition(target)
            
            -- Example: Aim at weak spots (headshot targeting)
            local head = target:FindFirstChild("Head")
            if head then
                predictedPosition = head.Position
            end
            
            -- Send skill usage event to the server
            ReplicatedStorage:FireServer("UseSkillAtPosition", predictedPosition)
        end
    end
end

-- Cập nhật camera và Silent Aim
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            -- Chuyển sang mục tiêu gần nhất hoặc mục tiêu ưu tiên
            local closestTarget = nil
            local minDistance = math.huge
            for _, enemy in ipairs(enemies) do
                local distance = (enemy.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    closestTarget = enemy
                    minDistance = distance
                end
            end

            CurrentTarget = closestTarget
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
            end
        end

        -- Silent Skill: Tự động sử dụng kỹ năng vào mục tiêu
        if SilentSkillActive and CurrentTarget then
            UseSilentSkill(CurrentTarget)
        end

        -- Camera tự động "lock" vào mục tiêu
        if CurrentTarget then
            local targetPosition = PredictTargetPosition(CurrentTarget)
            local targetRotation = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(targetRotation, CameraRotationSpeed)
            
            -- Adjust FOV for better focus on the target
            local distance = (targetPosition - Camera.CFrame.Position).Magnitude
            Camera.FieldOfView = math.clamp(70 + (distance / 10), 60, 90)  -- Adjust FOV based on distance
        end
    end
end)

-- Tự động bật script khi chuyển server
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        AimActive = true
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)
