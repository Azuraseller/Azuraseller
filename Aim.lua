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
local SpeedMultiplier = 1
local AimOffset = Vector3.new(1.0, 1.0, 1.0)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local MenuButton = Instance.new("TextButton")
local RAdjustButton = Instance.new("TextButton")
local RAdjustInput = Instance.new("TextBox")
local AimAdjustButton = Instance.new("TextButton")
local AimAdjustGui = Instance.new("Frame")
local XInput = Instance.new("TextBox")
local YInput = Instance.new("TextBox")
local ZInput = Instance.new("TextBox")

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

-- Nút 📄 Menu
CreateRoundedButton(MenuButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.74, 0, 0.01, 0), "📄", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

-- Menu Slide-out
local MenuFrame = Instance.new("Frame")
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 150, 0, 50)
MenuFrame.Position = UDim2.new(0.74, 0, 0.01, 0)
MenuFrame.BackgroundTransparency = 0.5
MenuFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
MenuFrame.Visible = false

-- Nút chỉnh R 🌐
CreateRoundedButton(RAdjustButton, MenuFrame, UDim2.new(0, 30, 0, 30), UDim2.new(0.1, 0, 0, 0), "🌐", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

-- Nút chỉnh Aim
CreateRoundedButton(AimAdjustButton, MenuFrame, UDim2.new(0, 30, 0, 30), UDim2.new(0.5, 0, 0, 0), "🎯", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

-- Nút chỉnh Aim (Gui nhỏ)
AimAdjustGui.Parent = ScreenGui
AimAdjustGui.Size = UDim2.new(0, 150, 0, 60)
AimAdjustGui.Position = UDim2.new(0.74, 0, 0.06, 0)
AimAdjustGui.BackgroundTransparency = 0.5
AimAdjustGui.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
AimAdjustGui.Visible = false

-- Inputs for Aim X, Y, Z
XInput.Parent = AimAdjustGui
XInput.Size = UDim2.new(0, 50, 0, 20)
XInput.Position = UDim2.new(0, 0, 0, 10)
XInput.Text = "1.0"
XInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

YInput.Parent = AimAdjustGui
YInput.Size = UDim2.new(0, 50, 0, 20)
YInput.Position = UDim2.new(0.3, 0, 0, 10)
YInput.Text = "1.0"
YInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

ZInput.Parent = AimAdjustGui
ZInput.Size = UDim2.new(0, 50, 0, 20)
ZInput.Position = UDim2.new(0.6, 0, 0, 10)
ZInput.Text = "1.0"
ZInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

-- Hàm điều chỉnh vị trí mục tiêu dựa trên dự đoán
local function AdjustCameraPrediction()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetPart = CurrentTarget.HumanoidRootPart
        local targetDirection = targetPart.CFrame.LookVector
        local predictedPosition = targetPart.Position + targetDirection * 3  -- Predict 3 studs ahead
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), SmoothFactor * SpeedMultiplier)
    end
end

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
    if AimActive then
        -- Kiểm tra xem có mục tiêu nào trong phạm vi không
        UpdateTarget()

        if Locked and CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
            AdjustCameraPrediction()
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

-- Mở menu
MenuButton.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
end)

-- Chỉnh R
RAdjustButton.MouseButton1Click:Connect(function()
    RAdjustInput.Visible = not RAdjustInput.Visible
end)

-- Chỉnh Aim (X, Y, Z)
AimAdjustButton.MouseButton1Click:Connect(function()
    AimAdjustGui.Visible = not AimAdjustGui.Visible
end)

-- Cập nhật giá trị X, Y, Z
XInput.FocusLost:Connect(function()
    local newX = tonumber(XInput.Text)
    if newX and newX >= 1.0 and newX <= 5.0 then
        AimOffset = Vector3.new(newX, AimOffset.Y, AimOffset.Z)
    end
end)

YInput.FocusLost:Connect(function()
    local newY = tonumber(YInput.Text)
    if newY and newY >= 1.0 and newY <= 5.0 then
        AimOffset = Vector3.new(AimOffset.X, newY, AimOffset.Z)
    end
end)

ZInput.FocusLost:Connect(function()
    local newZ = tonumber(ZInput.Text)
    if newZ and newZ >= 1.0 and newZ <= 5.0 then
        AimOffset = Vector3.new(AimOffset.X, AimOffset.Y, newZ)
    end
end)
