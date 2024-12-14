local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace
Camera2.CameraType = Enum.CameraType.Scriptable

-- Cấu hình các tham số
local Prediction = 0.15
local Radius = 250 -- Bán kính tự động bật/tắt Aim
local CloseRadius = 25 -- Bán kính gần
local SmoothFactor = 0.2
local Locked = false
local CurrentTarget = nil
local AimActive = false
local AimVisible = true -- Trạng thái hiển thị Aim

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local VisibilityButton = Instance.new("TextButton") -- Nút +

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF Aim
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút + để bật/tắt hiển thị Aim
VisibilityButton.Parent = ScreenGui
VisibilityButton.Size = UDim2.new(0, 50, 0, 50)
VisibilityButton.Position = UDim2.new(0.85, 110, 0.01, 0)
VisibilityButton.Text = "+"
VisibilityButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
VisibilityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisibilityButton.Font = Enum.Font.SourceSans
VisibilityButton.TextSize = 20

-- Hiệu ứng phóng to/thu nhỏ
local function PlayScaleEffect(guiElement, isAppearing)
    local goalSize = isAppearing and UDim2.new(0, 100, 0, 50) or UDim2.new(0, 0, 0, 0)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(guiElement, tweenInfo, {Size = goalSize})
    tween:Play()
end

-- Bật/Tắt Aim thủ công
ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        Camera2.CFrame = Camera.CFrame
        workspace.CurrentCamera = Camera2
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
        workspace.CurrentCamera = Camera
    end
end)

-- Bật/Tắt hiển thị Aim
VisibilityButton.MouseButton1Click:Connect(function()
    AimVisible = not AimVisible
    if AimVisible then
        VisibilityButton.Text = "+"
        VisibilityButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
        ToggleButton.Visible = true
        PlayScaleEffect(ToggleButton, true)
    else
        VisibilityButton.Text = "-"
        VisibilityButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        PlayScaleEffect(ToggleButton, false)
        task.wait(0.3) -- Chờ hiệu ứng thu nhỏ xong
        ToggleButton.Visible = false
    end
end)

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius(radius)
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= radius then
                    table.insert(targets, Character)
                end
            end
        end
    end
    return targets
end

-- Kiểm tra mục tiêu hiện tại có hợp lệ hay không
local function IsTargetValid(target)
    if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") then
        local distance = (target.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if target.Humanoid.Health > 0 and distance <= Radius then
            return true
        end
    end
    return false
end

-- Dự đoán vị trí mục tiêu
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return humanoidRootPart.Position
end

-- Ghim chính xác vào mục tiêu
local function GetAimPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local head = target:FindFirstChild("Head")
        if head then
            return head.Position -- Ghim vào đầu
        else
            return humanoidRootPart.Position + Vector3.new(0, 1.5, 0) -- Ghim vào ngực nếu không có đầu
        end
    end
    return nil
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if not AimVisible then return end -- Tắt Aim nếu không hiển thị

    local enemiesInRange = FindEnemiesInRadius(Radius)
    if #enemiesInRange > 0 then
        AimActive = true
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        workspace.CurrentCamera = Camera2
    else
        AimActive = false
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        workspace.CurrentCamera = Camera
        Locked = false
        CurrentTarget = nil
    end

    if AimActive then
        if not IsTargetValid(CurrentTarget) then
            Locked = false
            CurrentTarget = nil
        end

        if not Locked then
            if #enemiesInRange > 0 then
                CurrentTarget = enemiesInRange[1]
                Locked = true
            end
        end

        if CurrentTarget and Locked then
            local aimPosition = GetAimPosition(CurrentTarget)
            if aimPosition then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPosition), SmoothFactor)
            end
        end
    end
end)
