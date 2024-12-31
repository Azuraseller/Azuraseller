local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Cấu hình các tham số
local Prediction = 0.1
local Radius = 230
local BaseSmoothFactor = 0.15
local MaxSmoothFactor = 0.5
local CameraRotationSpeed = 0.3
local TargetLockSpeed = 0.2
local TargetSwitchSpeed = 0.1
local Locked = false
local CurrentTarget = nil
local AimActive = true
local AutoAim = false
local FocusMode = false
local CameraZoom = 70
local FOVAdjustment = false
local CameraShakeEnabled = false
local FreeLookEnabled = false  -- Free Look flag
local AimbotEnabled = true  -- Aimbot flag

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local AimCircle = Instance.new("Frame")
local FocusButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "⚙️"
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Focus Mode Button (Now same size as Close button and positioned below it)
FocusButton.Parent = ScreenGui
FocusButton.Size = UDim2.new(0, 30, 0, 30)
FocusButton.Position = UDim2.new(0.79, 0, 0.07, 0)
FocusButton.Text = "Focus"
FocusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
FocusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FocusButton.Font = Enum.Font.SourceSans
FocusButton.TextSize = 18

-- Aim Circle (Centered in the screen with a circular shape)
AimCircle.Parent = ScreenGui
AimCircle.Size = UDim2.new(0, 100, 0, 100)
AimCircle.Position = UDim2.new(0.5, -50, 0.5, -50)
AimCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AimCircle.BackgroundTransparency = 0.5
AimCircle.AnchorPoint = Vector2.new(0.5, 0.5)
AimCircle.BorderRadius = UDim.new(0, 50)  -- Make it circular

-- Thêm UICorner để bo tròn các nút
local function addUICorner(button)
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = button
end

addUICorner(ToggleButton)
addUICorner(CloseButton)
addUICorner(FocusButton)

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive
    FocusButton.Visible = AimActive
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút Focus Mode
FocusButton.MouseButton1Click:Connect(function()
    FocusMode = not FocusMode
    if FocusMode then
        FocusButton.Text = "Focus ON"
        FocusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        FocusButton.Text = "Focus OFF"
        FocusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil
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

    if #targets > 1 then
        table.sort(targets, function(a, b)
            return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        end)
    end
    return targets
end

-- Cập nhật camera và aim
local function updateCameraAndAim(targetPosition)
    if not AimbotEnabled then return end

    -- Cập nhật FOV và tốc độ camera dựa trên khoảng cách đến mục tiêu
    local distance = (Camera.CFrame.Position - targetPosition).Magnitude
    local fov = math.clamp(distance / 10, 70, 120)  -- Điều chỉnh phạm vi FOV
    Camera.FieldOfView = fov
    local cameraSpeed = math.clamp(distance / 10, 5, 20)  -- Điều chỉnh tốc độ camera

    -- Hướng camera về mục tiêu
    local targetDirection = (targetPosition - Camera.CFrame.Position).unit
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)

    -- Điều chỉnh hướng nhân vật nếu không sử dụng Free Look
    if not FreeLookEnabled then
        local characterDirection = (targetPosition - LocalPlayer.Character.HumanoidRootPart.Position).unit
        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.lookAt(LocalPlayer.Character.HumanoidRootPart.Position, targetPosition))
    end
end

-- Theo dõi mục tiêu
local function trackTarget(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        updateCameraAndAim(target.HumanoidRootPart.Position)
    end
end

-- Free Look Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        FreeLookEnabled = not FreeLookEnabled
        AimbotEnabled = not FreeLookEnabled  -- Tắt Aimbot khi Free Look được bật
    end
end)

-- Cập nhật liên tục
RunService.RenderStepped:Connect(function()
    if AimActive then
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1]
            end
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil
            end
        end

        if CurrentTarget and Locked then
            trackTarget(CurrentTarget)
        end

        -- Camera Shake
        if CameraShakeEnabled then
            local shakeMagnitude = math.random(1, 5)
            Camera.CFrame = Camera.CFrame * CFrame.new(Vector3.new(math.random(-shakeMagnitude, shakeMagnitude), math.random(-shakeMagnitude, shakeMagnitude), math.random(-shakeMagnitude, shakeMagnitude)))
        end

        -- Focus Mode
        if FocusMode then
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, -5)
        end
    end
end)

-- Zoom Function
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseWheel then
        CameraZoom = math.clamp(CameraZoom + input.Position.Z, 50, 120)
        Camera.FieldOfView = CameraZoom
    end
end)
