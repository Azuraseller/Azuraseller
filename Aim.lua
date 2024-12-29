local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Các tham số cơ bản
local Radius = 200 -- Bán kính mặc định
local AimCenter = Vector3.new(1, 1, 1) -- Tâm Aim mặc định
local Locked = false
local CurrentTarget = nil
local AimActive = true
local AdjustingR = false
local AdjustingAimCenter = false
local SmoothFactor = 0.1 -- Độ mượt của camera
local SpeedBoost = 1 -- Tăng tốc độ camera

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

-- Nút cài đặt (⚙️)
local SettingsButton = Instance.new("TextButton")
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 40, 0, 40)
SettingsButton.Position = UDim2.new(0.79, 0, 0.01, 0)
SettingsButton.Text = "⚙️"
SettingsButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Font = Enum.Font.SourceSans
SettingsButton.TextSize = 18
SettingsButton.BackgroundTransparency = 0.2
SettingsButton.BorderSizePixel = 0
SettingsButton.UICorner = Instance.new("UICorner", SettingsButton)

-- Nút Menu (📄)
local MenuButton = Instance.new("TextButton")
MenuButton.Parent = ScreenGui
MenuButton.Size = SettingsButton.Size
MenuButton.Position = SettingsButton.Position - UDim2.new(0, 50, 0, 0)
MenuButton.Text = "📄"
MenuButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18
MenuButton.BackgroundTransparency = 0.2
MenuButton.BorderSizePixel = 0
MenuButton.UICorner = Instance.new("UICorner", MenuButton)

-- Nút chỉnh R (🌐)
local RButton = Instance.new("TextButton")
RButton.Parent = ScreenGui
RButton.Size = MenuButton.Size
RButton.Position = MenuButton.Position - UDim2.new(0, 50, 0, 0)
RButton.Text = "🌐"
RButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
RButton.TextColor3 = Color3.fromRGB(0, 0, 0)
RButton.Font = Enum.Font.SourceSans
RButton.TextSize = 18
RButton.Visible = false
RButton.UICorner = Instance.new("UICorner", RButton)

local RAdjustBox = Instance.new("TextBox")
RAdjustBox.Parent = ScreenGui
RAdjustBox.Size = UDim2.new(0, 100, 0, 30)
RAdjustBox.Position = RButton.Position + UDim2.new(0, 0, 0, 40)
RAdjustBox.PlaceholderText = tostring(Radius)
RAdjustBox.Text = tostring(Radius)
RAdjustBox.Visible = false
RAdjustBox.BackgroundTransparency = 0.2
RAdjustBox.BorderSizePixel = 0
RAdjustBox.UICorner = Instance.new("UICorner", RAdjustBox)

-- Nút chỉnh tâm Aim
local AimButton = Instance.new("TextButton")
AimButton.Parent = ScreenGui
AimButton.Size = MenuButton.Size
AimButton.Position = RButton.Position - UDim2.new(0, 50, 0, 0)
AimButton.Text = "TÂM"
AimButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
AimButton.TextColor3 = Color3.fromRGB(0, 0, 0)
AimButton.Font = Enum.Font.SourceSans
AimButton.TextSize = 18
AimButton.Visible = false
AimButton.UICorner = Instance.new("UICorner", AimButton)

local AimAdjustFrame = Instance.new("Frame")
AimAdjustFrame.Parent = ScreenGui
AimAdjustFrame.Size = UDim2.new(0, 150, 0, 100)
AimAdjustFrame.Position = AimButton.Position + UDim2.new(0, 0, 0, 40)
AimAdjustFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
AimAdjustFrame.Visible = false
AimAdjustFrame.BackgroundTransparency = 0.2
AimAdjustFrame.BorderSizePixel = 0
AimAdjustFrame.UICorner = Instance.new("UICorner", AimAdjustFrame)

local function CreateAxisAdjustButton(parent, axis, position, color)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = UDim2.new(0, 50, 0, 30)
    button.Position = position
    button.Text = axis .. ": " .. AimCenter[axis]
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.UICorner = Instance.new("UICorner", button)
    return button
end

local AimAdjustX = CreateAxisAdjustButton(AimAdjustFrame, "X", UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 0, 0))
local AimAdjustY = CreateAxisAdjustButton(AimAdjustFrame, "Y", UDim2.new(0, 50, 0, 0), Color3.fromRGB(0, 0, 255))
local AimAdjustZ = CreateAxisAdjustButton(AimAdjustFrame, "Z", UDim2.new(0, 100, 0, 0), Color3.fromRGB(0, 255, 0))

-- Tính toán tốc độ của player khác
local function GetPlayerSpeed(player)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local velocity = character.HumanoidRootPart.Velocity
        return velocity.Magnitude
    end
    return 0
end

-- Điều chỉnh độ mượt camera
local function AdjustSmoothFactor(speed)
    SmoothFactor = math.clamp(speed / 50, 0.1, 0.5)
end

-- Dự đoán vị trí chuyển động của player khác
local function PredictPlayerPosition(player)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local velocity = rootPart.Velocity
        return rootPart.Position + velocity.Unit * 3
    end
    return nil
end

-- Tự động chuyển nhanh khi player ở trên trời hoặc sau lưng
local function AutoAdjustCamera(target)
    local targetPosition = PredictPlayerPosition(target)
    if targetPosition then
        local distance = (Camera.CFrame.Position - targetPosition).Magnitude
        if distance > 10 then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        end
    end
end

-- Sự kiện nút
SettingsButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    Locked = false
    CurrentTarget = nil
end)

MenuButton.MouseButton1Click:Connect(function()
    local isMenuActive = not MenuButton.Visible
    RButton.Visible = isMenuActive
    AimButton.Visible = isMenuActive
end)

RButton.MouseButton1Click:Connect(function()
    AdjustingR = not AdjustingR
    RAdjustBox.Visible = AdjustingR
end)

AimButton.MouseButton1Click:Connect(function()
    AdjustingAimCenter = not AdjustingAimCenter
    AimAdjustFrame.Visible = AdjustingAimCenter
end)

RAdjustBox.FocusLost:Connect(function()
    local newR = tonumber(RAdjustBox.Text)
    if newR and newR >= 100 and newR <= 1000 then
        Radius = newR
    else
        RAdjustBox.Text = tostring(Radius)
    end
end)

local function AdjustAim(axis)
    if AimCenter[axis] < 5.0 then
        AimCenter = AimCenter + Vector3.new((axis == "X" and 1 or 0), (axis == "Y" and 1 or 0), (axis == "Z" and 1 or 0))
    else
        AimCenter = AimCenter - Vector3.new((axis == "X" and 4 or 0), (axis == "Y" and 4 or 0), (axis == "Z" and 4 or 0))
    end
end

AimAdjustX.MouseButton1Click:Connect(function()
    AdjustAim("X")
    AimAdjustX.Text = "X: " .. AimCenter.X
end)

AimAdjustY.MouseButton1Click:Connect(function()
    AdjustAim("Y")
    AimAdjustY.Text = "Y: " .. AimCenter.Y
end)

AimAdjustZ.MouseButton1Click:Connect(function()
    AdjustAim("Z")
    AimAdjustZ.Text = "Z: " .. AimCenter.Z
end)
