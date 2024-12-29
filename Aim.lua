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
local AimOffset = Vector3.new(1, 1, 1) -- Tâm mặc định
local PriorityTarget = nil -- Mục tiêu ưu tiên

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local MenuButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
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

-- Nút Menu 📄
CreateRoundedButton(MenuButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.73, 0, 0.01, 0), "📄", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

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

-- Nút chỉnh Aim 🎯
CreateRoundedButton(AimAdjustButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.7, 0, 0.01, 0), "🎯", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))
AimAdjustButton.Visible = false

-- GUI chỉnh Aim
AimAdjustGui.Parent = ScreenGui
AimAdjustGui.Size = UDim2.new(0, 150, 0, 100)
AimAdjustGui.Position = UDim2.new(0.7, 0, 0.05, 0)
AimAdjustGui.BackgroundTransparency = 0.5
AimAdjustGui.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimAdjustGui.Visible = false

-- Các TextBox chỉnh Aim
local function CreateInput(input, parent, position, text, color)
    input.Parent = parent
    input.Size = UDim2.new(0, 50, 0, 20)
    input.Position = position
    input.Text = text
    input.TextColor3 = color
    input.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    input.Font = Enum.Font.SourceSansBold
    input.TextSize = 18
end

CreateInput(XInput, AimAdjustGui, UDim2.new(0.1, 0, 0.2, 0), "X: 1.0", Color3.fromRGB(255, 0, 0))
CreateInput(YInput, AimAdjustGui, UDim2.new(0.1, 0, 0.5, 0), "Y: 1.0", Color3.fromRGB(0, 0, 255))
CreateInput(ZInput, AimAdjustGui, UDim2.new(0.1, 0, 0.8, 0), "Z: 1.0", Color3.fromRGB(0, 255, 0))

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

-- Tự động điều chỉnh camera và dự đoán chuyển động của mục tiêu
RunService.RenderStepped:Connect(function()
    if AimActive and Locked then
        if not CurrentTarget or not CurrentTarget:FindFirstChild("HumanoidRootPart") then
            UpdateTarget()
        end

        if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
            local targetPart = CurrentTarget.HumanoidRootPart
            local predictedPosition = targetPart.Position + targetPart.Velocity * Prediction

            -- Dự đoán vị trí mục tiêu dựa vào hướng camera của mục tiêu
            local targetDirection = (CurrentTarget.HumanoidRootPart.Position - Camera.CFrame.Position).unit
            predictedPosition = predictedPosition + targetDirection * 3 -- Khoảng cách 3

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

-- Hiển thị/ẩn menu
MenuButton.MouseButton1Click:Connect(function()
    local isVisible = RAdjustButton.Visible
    RAdjustButton.Visible = not isVisible
    AimAdjustButton.Visible = not isVisible
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

-- Chỉnh tâm Aim
AimAdjustButton.MouseButton1Click:Connect(function()
    AimAdjustGui.Visible = not AimAdjustGui.Visible
end)

-- Chỉnh giá trị X, Y, Z cho tâm Aim
XInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newX = tonumber(XInput.Text:match("%d+%.?%d*"))
        if newX and newX >= 1.0 and newX <= 5.0 then
            AimOffset = Vector3.new(newX, AimOffset.Y, AimOffset.Z)
        end
        XInput.Text = string.format("X: %.1f", AimOffset.X)
    end
end)

YInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newY = tonumber(YInput.Text:match("%d+%.?%d*"))
        if newY and newY >= 1.0 and newY <= 5.0 then
            AimOffset = Vector3.new(AimOffset.X, newY, AimOffset.Z)
        end
        YInput.Text = string.format("Y: %.1f", AimOffset.Y)
    end
end)

ZInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newZ = tonumber(ZInput.Text:match("%d+%.?%d*"))
        if newZ and newZ >= 1.0 and newZ <= 5.0 then
            AimOffset = Vector3.new(AimOffset.X, AimOffset.Y, newZ)
        end
        ZInput.Text = string.format("Z: %.1f", AimOffset.Z)
    end
end)

-- Ưu tiên mục tiêu
local function UpdatePriorityTarget()
    if CurrentTarget and (CurrentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > Radius then
        CurrentTarget = nil
    end
end
