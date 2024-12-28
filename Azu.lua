local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1
local Radius = 200
local SmoothFactor = 0.15
local Locked = false
local CurrentTarget = nil
local AimActive = true
local AimCenter = Vector3.new(1.0, 1.0, 1.0)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local MenuButton = Instance.new("TextButton")
local RAdjustButton = Instance.new("TextButton")
local RAdjustInput = Instance.new("TextBox")
local AimAdjustButton = Instance.new("TextButton")
local AimAdjustGui = Instance.new("Frame")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Nút Menu
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.74, 0, 0.01, 0)
MenuButton.Text = "📄"
MenuButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
MenuButton.TextColor3 = Color3.fromRGB(0, 0, 0)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18

-- Nút chỉnh R
RAdjustButton.Parent = ScreenGui
RAdjustButton.Size = UDim2.new(0, 30, 0, 30)
RAdjustButton.Position = UDim2.new(0.7, 0, 0.01, 0)
RAdjustButton.Text = "🌐"
RAdjustButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
RAdjustButton.TextColor3 = Color3.fromRGB(0, 0, 0)
RAdjustButton.Font = Enum.Font.SourceSans
RAdjustButton.TextSize = 18
RAdjustButton.Visible = false

RAdjustInput.Parent = ScreenGui
RAdjustInput.Size = UDim2.new(0, 100, 0, 20)
RAdjustInput.Position = UDim2.new(0.7, 0, 0.05, 0)
RAdjustInput.Text = tostring(Radius)
RAdjustInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
RAdjustInput.Visible = false

-- Nút chỉnh Aim
AimAdjustButton.Parent = ScreenGui
AimAdjustButton.Size = UDim2.new(0, 30, 0, 30)
AimAdjustButton.Position = UDim2.new(0.65, 0, 0.01, 0)
AimAdjustButton.Text = "🎯"
AimAdjustButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
AimAdjustButton.TextColor3 = Color3.fromRGB(0, 0, 0)
AimAdjustButton.Font = Enum.Font.SourceSans
AimAdjustButton.TextSize = 18
AimAdjustButton.Visible = false

AimAdjustGui.Parent = ScreenGui
AimAdjustGui.Size = UDim2.new(0, 100, 0, 50)
AimAdjustGui.Position = UDim2.new(0.65, 0, 0.05, 0)
AimAdjustGui.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
AimAdjustGui.Visible = false

-- Chức năng bật/tắt Aim
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive
    MenuButton.Visible = AimActive
    if not AimActive then
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    else
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Chức năng Menu
MenuButton.MouseButton1Click:Connect(function()
    local isVisible = not RAdjustButton.Visible
    RAdjustButton.Visible = isVisible
    AimAdjustButton.Visible = isVisible
    RAdjustInput.Visible = false
    AimAdjustGui.Visible = false
end)

-- Chỉnh R
RAdjustButton.MouseButton1Click:Connect(function()
    RAdjustInput.Visible = not RAdjustInput.Visible
end)

RAdjustInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newRadius = tonumber(RAdjustInput.Text)
        if newRadius and newRadius >= 100 and newRadius <= 1000 then
            Radius = newRadius
        else
            RAdjustInput.Text = tostring(Radius)
        end
    end
end)

-- Chỉnh Aim Center
AimAdjustButton.MouseButton1Click:Connect(function()
    AimAdjustGui.Visible = not AimAdjustGui.Visible
end)

-- Tìm mục tiêu
local function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    table.insert(targets, Character)
                end
            end
        end
    end

    if CurrentTarget and table.find(targets, CurrentTarget) then
        return {CurrentTarget}
    end
    return targets
end

-- Điều chỉnh camera
RunService.RenderStepped:Connect(function()
    if AimActive and Locked and CurrentTarget then
        local targetCharacter = CurrentTarget
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction
            local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance > Radius then
                CurrentTarget = nil
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)
            end
        end
    end
end)
