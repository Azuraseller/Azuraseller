local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Các dịch vụ và cài đặt cơ bản
local Radius = 200 -- Bán kính mặc định
local AimCenter = Vector3.new(1, 1, 1) -- Tâm Aim mặc định
local Locked = false
local CurrentTarget = nil
local AimActive = true
local MenuActive = false
local AdjustingR = false
local AdjustingAimCenter = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

-- Nút đóng (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Nút Menu (📄)
local MenuButton = Instance.new("TextButton")
MenuButton.Parent = ScreenGui
MenuButton.Size = CloseButton.Size
MenuButton.Position = CloseButton.Position + UDim2.new(0, 40, 0, 0)
MenuButton.Text = "📄"
MenuButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Nút chỉnh R (🌐)
local RButton = Instance.new("TextButton")
RButton.Parent = ScreenGui
RButton.Size = MenuButton.Size
RButton.Position = MenuButton.Position - UDim2.new(0, 40, 0, 0)
RButton.Text = "🌐"
RButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
RButton.TextColor3 = Color3.fromRGB(0, 0, 0)
RButton.Visible = false

local RAdjustBox = Instance.new("TextBox")
RAdjustBox.Parent = ScreenGui
RAdjustBox.Size = UDim2.new(0, 100, 0, 30)
RAdjustBox.Position = RButton.Position + UDim2.new(0, 0, 0, 40)
RAdjustBox.PlaceholderText = tostring(Radius)
RAdjustBox.Text = tostring(Radius)
RAdjustBox.Visible = false

-- Nút chỉnh tâm Aim
local AimButton = Instance.new("TextButton")
AimButton.Parent = ScreenGui
AimButton.Size = MenuButton.Size
AimButton.Position = RButton.Position - UDim2.new(0, 40, 0, 0)
AimButton.Text = "Tâm"
AimButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
AimButton.TextColor3 = Color3.fromRGB(0, 0, 0)
AimButton.Visible = false

local AimAdjustFrame = Instance.new("Frame")
AimAdjustFrame.Parent = ScreenGui
AimAdjustFrame.Size = UDim2.new(0, 150, 0, 100)
AimAdjustFrame.Position = AimButton.Position + UDim2.new(0, 0, 0, 40)
AimAdjustFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
AimAdjustFrame.Visible = false

local AimAdjustX = Instance.new("TextButton")
AimAdjustX.Parent = AimAdjustFrame
AimAdjustX.Size = UDim2.new(0, 50, 0, 30)
AimAdjustX.Position = UDim2.new(0, 0, 0, 0)
AimAdjustX.Text = "X: " .. AimCenter.X
AimAdjustX.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

local AimAdjustY = Instance.new("TextButton")
AimAdjustY.Parent = AimAdjustFrame
AimAdjustY.Size = UDim2.new(0, 50, 0, 30)
AimAdjustY.Position = UDim2.new(0, 50, 0, 0)
AimAdjustY.Text = "Y: " .. AimCenter.Y
AimAdjustY.BackgroundColor3 = Color3.fromRGB(0, 0, 255)

local AimAdjustZ = Instance.new("TextButton")
AimAdjustZ.Parent = AimAdjustFrame
AimAdjustZ.Size = UDim2.new(0, 50, 0, 30)
AimAdjustZ.Position = UDim2.new(0, 100, 0, 0)
AimAdjustZ.Text = "Z: " .. AimCenter.Z
AimAdjustZ.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

-- Sự kiện nút
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    Locked = false
    CurrentTarget = nil
end)

MenuButton.MouseButton1Click:Connect(function()
    MenuActive = not MenuActive
    RButton.Visible = MenuActive
    AimButton.Visible = MenuActive
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

AimAdjustX.MouseButton1Click:Connect(function()
    AimCenter = AimCenter + Vector3.new(1, 0, 0)
    AimAdjustX.Text = "X: " .. AimCenter.X
end)

AimAdjustY.MouseButton1Click:Connect(function()
    AimCenter = AimCenter + Vector3.new(0, 1, 0)
    AimAdjustY.Text = "Y: " .. AimCenter.Y
end)

AimAdjustZ.MouseButton1Click:Connect(function()
    AimCenter = AimCenter + Vector3.new(0, 0, 1)
    AimAdjustZ.Text = "Z: " .. AimCenter.Z
end)

-- Tìm mục tiêu
local function FindClosestTarget()
    local closestTarget = nil
    local closestDistance = Radius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance <= closestDistance then
                closestTarget = player.Character
                closestDistance = distance
            end
        end
    end
    return closestTarget
end

-- Cập nhật Camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        if not CurrentTarget or (CurrentTarget and (CurrentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > Radius) then
            CurrentTarget = FindClosestTarget()
        end

        if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
            local targetPosition = CurrentTarget.HumanoidRootPart.Position + AimCenter
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        end
    end
end)
