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

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local MenuButton = Instance.new("TextButton")
local RAdjustButton = Instance.new("TextButton")
local RAdjustInput = Instance.new("TextBox")

ScreenGui.Parent = game:GetService("CoreGui")

-- Hàm tạo nút với góc bo tròn
local function CreateRoundedButton(button, parent, size, position, text, bgColor, textColor)
    button.Parent = parent
    button.Size = size
    button.Position = position
    button.Text = text
    button.BackgroundColor3 = bgColor
    button.TextColor3 = textColor
    button.Font = Enum.Font.SourceSans
    button.TextSize = 18
    button.BorderSizePixel = 0

    -- Góc bo tròn
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
end

-- Nút ON/OFF
CreateRoundedButton(ToggleButton, ScreenGui, UDim2.new(0, 100, 0, 50), UDim2.new(0.85, 0, 0.01, 0), "CamLock: OFF", Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255))

-- Nút ⚙️
CreateRoundedButton(CloseButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.79, 0, 0.01, 0), "⚙️", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

-- Nút chỉnh R 🌐
CreateRoundedButton(RAdjustButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.74, 0, 0.01, 0), "🌐", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))
RAdjustButton.Visible = false

RAdjustInput.Parent = ScreenGui
RAdjustInput.Size = UDim2.new(0, 100, 0, 20)
RAdjustInput.Position = UDim2.new(0.74, 0, 0.05, 0)
RAdjustInput.Text = tostring(Radius)
RAdjustInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
RAdjustInput.Visible = false

-- Tìm mục tiêu gần nhất
local function UpdateTarget()
    local closestTarget = nil
    local closestDistance = Radius
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = Player.Character.HumanoidRootPart.Position
            local distance = (targetPosition - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance <= Radius and distance < closestDistance then
                closestTarget = Player.Character
                closestDistance = distance
            end
        end
    end
    CurrentTarget = closestTarget
end

-- Điều chỉnh camera với dự đoán chuyển động
RunService.RenderStepped:Connect(function()
    if AimActive and Locked then
        if not CurrentTarget or not CurrentTarget:FindFirstChild("HumanoidRootPart") then
            UpdateTarget()
        end

        if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
            local targetPart = CurrentTarget.HumanoidRootPart
            local predictedPosition = targetPart.Position + targetPart.Velocity * Prediction
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), SmoothFactor)
        end
    end
end)

-- Bật/tắt Aim
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil
    end
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
