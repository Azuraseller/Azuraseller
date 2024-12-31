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
local FreeLookMode = false  -- Thêm biến này để theo dõi chế độ Free Look
local POVMode = false       -- Thêm biến này để theo dõi chế độ POV

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local AimCircle = Instance.new("Frame")
local FocusButton = Instance.new("TextButton")
local FreeLookButton = Instance.new("TextButton") -- Nút Free Look

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

-- Focus Mode Button
FocusButton.Parent = ScreenGui
FocusButton.Size = UDim2.new(0, 100, 0, 50)
FocusButton.Position = UDim2.new(0.85, 0, 0.07, 0)
FocusButton.Text = "Focus"
FocusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
FocusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FocusButton.Font = Enum.Font.SourceSans
FocusButton.TextSize = 18

-- Free Look Button
FreeLookButton.Parent = ScreenGui
FreeLookButton.Size = UDim2.new(0, 100, 0, 50)
FreeLookButton.Position = UDim2.new(0.85, 0, 0.13, 0)
FreeLookButton.Text = "Free Look"
FreeLookButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
FreeLookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FreeLookButton.Font = Enum.Font.SourceSans
FreeLookButton.TextSize = 18

-- Aim Circle
AimCircle.Parent = ScreenGui
AimCircle.Size = UDim2.new(0, 100, 0, 100)
AimCircle.Position = UDim2.new(0.5, -50, 0.5, -50)
AimCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AimCircle.BackgroundTransparency = 0.5
AimCircle.AnchorPoint = Vector2.new(0.5, 0.5)

-- Thêm UICorner để bo tròn các nút
local function addUICorner(button)
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = button
end

addUICorner(ToggleButton)
addUICorner(CloseButton)
addUICorner(FocusButton)
addUICorner(FreeLookButton)

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive
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

-- Nút Free Look
FreeLookButton.MouseButton1Click:Connect(function()
    FreeLookMode = not FreeLookMode
    if FreeLookMode then
        FreeLookButton.Text = "Free Look ON"
        FreeLookButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    else
        FreeLookButton.Text = "Free Look OFF"
        FreeLookButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
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

-- Điều chỉnh camera tránh bị che khuất
local function AdjustCameraPosition(targetPosition)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return targetPosition end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position, raycastParams)
    
    if raycastResult then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Cập nhật camera
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
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position

                -- Điều chỉnh camera nếu Free Look không bật
                if not FreeLookMode then
                    targetPosition = AdjustCameraPosition(targetPosition)
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
                end

                -- Thay đổi FOV
                if FOVAdjustment then
                    Camera.FieldOfView = 70 + (targetPosition - Camera.CFrame.Position).Magnitude / Radius * 20
                end
            end
        end

-- Camera Shake
        if CameraShakeEnabled then
            local shakeMagnitude = math.random(1, 5)
            Camera.CFrame = Camera.CFrame * CFrame.new(Vector3.new(math.random(-shakeMagnitude, shakeMagnitude), math.random(-shakeMagnitude, shakeMagnitude), math.random(-shakeMagnitude, shakeMagnitude)))
        end
    end

    -- Free Look mode: Cập nhật camera để di chuyển tự do khi Free Look được bật
    if FreeLookMode then
        local mouseDelta = UserInputService:GetMouseDelta()
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, -mouseDelta.X * CameraRotationSpeed, 0)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(mouseDelta.Y * CameraRotationSpeed, 0, 0)
    end

    -- Điều chỉnh FOV khi POV mode được bật
    if POVMode then
        Camera.FieldOfView = CameraZoom
    end
end)
