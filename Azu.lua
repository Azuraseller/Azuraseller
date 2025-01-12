local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local MenuButton = Instance.new("TextButton")
local MenuFrame = Instance.new("Frame")
local EspButton = Instance.new("TextButton")
local AutoAdjustButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút Menu 📜
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.79, 0, 0.06, 0)
MenuButton.Text = "📜"
MenuButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18

-- Menu Frame
MenuFrame.Parent = ScreenGui
MenuFrame.Size = UDim2.new(0, 0, 0, 100)
MenuFrame.Position = UDim2.new(0.79, 0, 0.1, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MenuFrame.Visible = false

-- Nút ESP
EspButton.Parent = MenuFrame
EspButton.Size = UDim2.new(0, 30, 0, 30)
EspButton.Position = UDim2.new(0, 0, 0, 0)
EspButton.Text = "👁️"
EspButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Off by default
EspButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EspButton.Font = Enum.Font.SourceSans
EspButton.TextSize = 18

-- Nút Auto Adjust 🎯
AutoAdjustButton.Parent = MenuFrame
AutoAdjustButton.Size = UDim2.new(0, 30, 0, 30)
AutoAdjustButton.Position = UDim2.new(0, 0, 0, 35)
AutoAdjustButton.Text = "🎯"
AutoAdjustButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Off by default
AutoAdjustButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoAdjustButton.Font = Enum.Font.SourceSans
AutoAdjustButton.TextSize = 18

-- Hiệu ứng trượt Menu
MenuButton.MouseButton1Click:Connect(function()
    MenuFrame.Visible = not MenuFrame.Visible
    local newSize = MenuFrame.Visible and UDim2.new(0, 40, 0, 100) or UDim2.new(0, 0, 0, 100)
    TweenService:Create(MenuFrame, TweenInfo.new(0.3), {Size = newSize}):Play()
end)

-- ESP Logic
local EspActive = false
EspButton.MouseButton1Click:Connect(function()
    EspActive = not EspActive
    EspButton.BackgroundColor3 = EspActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

local function DisplayEsp(target)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = target.HumanoidRootPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = target

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Text = target.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.BackgroundTransparency = 1

    local healthBar = Instance.new("Frame", billboard)
    healthBar.Size = UDim2.new(1, 0, 0.5, 0)
    healthBar.Position = UDim2.new(0, 0, 0.5, 0)
    healthBar.BackgroundColor3 = Color3.new(1, 0, 0)

    local healthFill = Instance.new("Frame", healthBar)
    healthFill.Size = UDim2.new(target.Humanoid.Health / target.Humanoid.MaxHealth, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
end

RunService.RenderStepped:Connect(function()
    if EspActive then
        local target = FindTargetInRadius(500)
        if target then
            DisplayEsp(target)
        end
    end
end)

-- Auto Adjust Logic
local AutoAdjustActive = false
local PredictionAdjustments = {North = 1, South = 1, East = 1, West = 1}
AutoAdjustButton.MouseButton1Click:Connect(function()
    AutoAdjustActive = not AutoAdjustActive
    AutoAdjustButton.BackgroundColor3 = AutoAdjustActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

RunService.RenderStepped:Connect(function()
    if AutoAdjustActive then
        local target = FindTargetInRadius(500)
        if target then
            local velocity = target.HumanoidRootPart.Velocity
            local speed = velocity.Magnitude

            -- Tự động điều chỉnh hướng
            PredictionAdjustments.North = velocity.Z > 0 and math.min(speed / 10, 5) or 1
            PredictionAdjustments.South = velocity.Z < 0 and math.min(speed / 10, 5) or 1
            PredictionAdjustments.East = velocity.X > 0 and math.min(speed / 10, 5) or 1
            PredictionAdjustments.West = velocity.X < 0 and math.min(speed / 10, 5) or 1

            -- Áp dụng điều chỉnh
            print("Adjustments:", PredictionAdjustments)
        else
            -- Reset nếu không có mục tiêu
            PredictionAdjustments = {North = 1, South = 1, East = 1, West = 1}
        end
    end
end)
