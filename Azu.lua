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
local AimXInput = Instance.new("TextBox")
local AimYInput = Instance.new("TextBox")
local AimZInput = Instance.new("TextBox")

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

-- Nút Menu 📄
CreateRoundedButton(MenuButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.74, 0, 0.01, 0), "📄", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))

-- Nút chỉnh R 🌐
CreateRoundedButton(RAdjustButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.69, 0, 0.01, 0), "🌐", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))
RAdjustButton.Visible = false

RAdjustInput.Parent = ScreenGui
RAdjustInput.Size = UDim2.new(0, 100, 0, 20)
RAdjustInput.Position = UDim2.new(0.69, 0, 0.05, 0)
RAdjustInput.Text = tostring(Radius)
RAdjustInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
RAdjustInput.Visible = false

-- Nút chỉnh Aim 🎯
CreateRoundedButton(AimAdjustButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.64, 0, 0.01, 0), "🎯", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))
AimAdjustButton.Visible = false

AimAdjustGui.Parent = ScreenGui
AimAdjustGui.Size = UDim2.new(0, 150, 0, 100)
AimAdjustGui.Position = UDim2.new(0.64, 0, 0.05, 0)
AimAdjustGui.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
AimAdjustGui.Visible = false

-- Các TextBox chỉnh x, y, z
local function CreateAimInput(input, parent, position, defaultText)
    input.Parent = parent
    input.Size = UDim2.new(0, 50, 0, 20)
    input.Position = position
    input.Text = defaultText
    input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.SourceSans
    input.TextSize = 14
end

CreateAimInput(AimXInput, AimAdjustGui, UDim2.new(0, 0, 0, 10), "X: 1.0")
CreateAimInput(AimYInput, AimAdjustGui, UDim2.new(0, 50, 0, 10), "Y: 1.0")
CreateAimInput(AimZInput, AimAdjustGui, UDim2.new(0, 100, 0, 10), "Z: 1.0")

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

AimXInput.FocusLost:Connect(function()
    local newValue = tonumber(AimXInput.Text:match("X: (%d+%.?%d*)"))
    if newValue then AimCenter = Vector3.new(newValue, AimCenter.Y, AimCenter.Z) end
end)

AimYInput.FocusLost:Connect(function()
    local newValue = tonumber(AimYInput.Text:match("Y: (%d+%.?%d*)"))
    if newValue then AimCenter = Vector3.new(AimCenter.X, newValue, AimCenter.Z) end
end)

AimZInput.FocusLost:Connect(function()
    local newValue = tonumber(AimZInput.Text:match("Z: (%d+%.?%d*)"))
    if newValue then AimCenter = Vector3.new(AimCenter.X, AimCenter.Y, newValue) end
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
