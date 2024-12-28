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

-- Hàm tạo TextBox với góc bo tròn
local function CreateRoundedTextBox(textBox, parent, size, position, defaultText)
    textBox.Parent = parent
    textBox.Size = size
    textBox.Position = position
    textBox.Text = defaultText
    textBox.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 14
    textBox.BorderSizePixel = 0

    -- Góc bo tròn
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = textBox
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

CreateRoundedTextBox(RAdjustInput, ScreenGui, UDim2.new(0, 100, 0, 20), UDim2.new(0.69, 0, 0.06, 0), tostring(Radius))
RAdjustInput.Visible = false

-- Nút chỉnh Aim 🎯
CreateRoundedButton(AimAdjustButton, ScreenGui, UDim2.new(0, 30, 0, 30), UDim2.new(0.64, 0, 0.01, 0), "🎯", Color3.fromRGB(200, 200, 200), Color3.fromRGB(0, 0, 0))
AimAdjustButton.Visible = false

AimAdjustGui.Parent = ScreenGui
AimAdjustGui.Size = UDim2.new(0, 150, 0, 100)
AimAdjustGui.Position = UDim2.new(0.64, 0, 0.06, 0)
AimAdjustGui.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
AimAdjustGui.Visible = false

-- Các TextBox chỉnh x, y, z
CreateRoundedTextBox(AimXInput, AimAdjustGui, UDim2.new(0, 50, 0, 20), UDim2.new(0, 0, 0, 10), "X: 1.0")
CreateRoundedTextBox(AimYInput, AimAdjustGui, UDim2.new(0, 50, 0, 20), UDim2.new(0, 50, 0, 10), "Y: 1.0")
CreateRoundedTextBox(AimZInput, AimAdjustGui, UDim2.new(0, 50, 0, 20), UDim2.new(0, 100, 0, 10), "Z: 1.0")

-- Hàm đo tốc độ player khác
local function CalculatePlayerSpeed(target)
    local velocity = target.HumanoidRootPart.Velocity
    return velocity.Magnitude
end

-- Hàm dự đoán vị trí
local function PredictTargetPosition(target, r)
    local speed = CalculatePlayerSpeed(target)
    local direction = target.HumanoidRootPart.CFrame.LookVector
    return target.HumanoidRootPart.Position + direction * r * speed
end

-- Theo dõi mục tiêu
RunService.RenderStepped:Connect(function()
    if CurrentTarget and Locked then
        local targetCharacter = CurrentTarget
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local predictedPosition = PredictTargetPosition(targetCharacter, 3)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), SmoothFactor)
        end
    end
end)
