local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cài đặt Camera và Aim Lock
local Radius = 200 -- Bán kính khóa mục tiêu
local BasePrediction = 0.2 -- Dự đoán vị trí mục tiêu
local SmoothFactor = 0.1 -- Mức độ mượt cơ bản
local HighSpeedMultiplier = 3 -- Nhân tốc độ khi mục tiêu di chuyển nhanh
local AngleSpeedMultiplier = 5 -- Nhân tốc độ khi mục tiêu ở phía sau
local SpeedThreshold = 50 -- Ngưỡng vận tốc để tăng tốc camera
local Locked = false
local CurrentTarget = nil
local AimActive = true
local SettingsVisible = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local SettingsButton = Instance.new("TextButton")
local ToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nhãn trạng thái
StatusLabel.Parent = ScreenGui
StatusLabel.Size = UDim2.new(0, 300, 0, 50)
StatusLabel.Position = UDim2.new(0.85, 0, 0.01, 0)
StatusLabel.Text = "CamLock: OFF"
StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 20
StatusLabel.BackgroundTransparency = 0.5

-- Nút Cài đặt
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 50, 0, 50)
SettingsButton.Position = UDim2.new(0.85, 0, 0.01, 0)
SettingsButton.Text = "Settings"
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Font = Enum.Font.SourceSans
SettingsButton.TextSize = 20
SettingsButton.Visible = true

-- Nút Bật/Tắt Aim
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 150, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.1, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20
ToggleButton.Visible = false

-- Hàm hiển thị/ẩn nút Toggle
SettingsButton.MouseButton1Click:Connect(function()
    SettingsVisible = not SettingsVisible
    ToggleButton.Visible = SettingsVisible
end)

-- Hàm tính góc giữa camera và mục tiêu
local function GetAngleToTarget(targetPos)
    local cameraDirection = Camera.CFrame.LookVector
    local targetDirection = (targetPos - Camera.CFrame.Position).Unit
    return math.deg(math.acos(cameraDirection:Dot(targetDirection)))
end

-- Hàm tìm mục tiêu trong phạm vi
local function GetClosestTarget()
    local closest = nil
    local closestDistance = Radius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance then
                closest = player
                closestDistance = distance
            end
        end
    end

    return closest
end

-- Cập nhật mục tiêu
local function UpdateTarget()
    local target = GetClosestTarget()

    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        CurrentTarget = target
        Locked = true
        StatusLabel.Text = "CamLock: ON (" .. target.Name .. ")"
        StatusLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        CurrentTarget = nil
        Locked = false
        StatusLabel.Text = "CamLock: OFF"
        StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end

-- Hàm Camera theo dõi mục tiêu
RunService.RenderStepped:Connect(function()
    UpdateTarget()

    if Locked and CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetPart = CurrentTarget.Character.HumanoidRootPart
        local targetPos = targetPart.Position
        local targetVelocity = targetPart.Velocity
        local targetSpeed = targetVelocity.Magnitude

        -- Tăng tốc khi mục tiêu di chuyển nhanh
        local dynamicSmoothFactor = SmoothFactor
        local prediction = BasePrediction

        if targetSpeed > SpeedThreshold then
            dynamicSmoothFactor = SmoothFactor / HighSpeedMultiplier
            prediction = BasePrediction * HighSpeedMultiplier
        end

        -- Tăng tốc khi mục tiêu ở phía sau
        local angle = GetAngleToTarget(targetPos)
        if angle > 90 then
            dynamicSmoothFactor = dynamicSmoothFactor / AngleSpeedMultiplier
        end

        -- Dự đoán vị trí mục tiêu
        local predictedPos = targetPos + (targetVelocity * prediction)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)

        -- Chuyển động camera mượt mà và nhanh khi cần
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, dynamicSmoothFactor)
    end
end)

-- Toggle Aim
ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    end
end)
