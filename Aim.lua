local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1
local Radius = 200
local SmoothFactor = 0.15
local CameraRotationSpeed = 0.5
local Locked = false
local CurrentTarget = nil
local AimActive = true
local SuperAim = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("ImageButton")
local CloseButton = Instance.new("TextButton")
local DropdownButton = Instance.new("TextButton")
local RadiusButton = Instance.new("TextButton")
local RadiusBox = Instance.new("TextBox")
local SuperAimButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Image = "rbxassetid://133602550183849"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Visible = true -- Đảm bảo nút ON/OFF luôn hiển thị

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Nút cuộn
DropdownButton.Parent = ScreenGui
DropdownButton.Size = UDim2.new(0, 100, 0, 25)
DropdownButton.Position = UDim2.new(0.85, 0, 0.07, 0)
DropdownButton.Text = "↓"
DropdownButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.Visible = true

-- Nút điều chỉnh bán kính
RadiusButton.Parent = ScreenGui
RadiusButton.Size = UDim2.new(0, 100, 0, 25)
RadiusButton.Position = UDim2.new(0.85, 0, 0.12, 0)
RadiusButton.Text = "R: " .. Radius
RadiusButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RadiusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusButton.Visible = false

-- Hộp nhập bán kính
RadiusBox.Parent = ScreenGui
RadiusBox.Size = UDim2.new(0, 100, 0, 25)
RadiusBox.Position = UDim2.new(0.85, 0, 0.17, 0)
RadiusBox.PlaceholderText = "Nhập R"
RadiusBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RadiusBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusBox.Visible = false

-- Nút siêu tốc Aim
SuperAimButton.Parent = ScreenGui
SuperAimButton.Size = UDim2.new(0, 100, 0, 25)
SuperAimButton.Position = UDim2.new(0.85, 0, 0.22, 0)
SuperAimButton.Text = "Siêu Aim"
SuperAimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SuperAimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SuperAimButton.Visible = false

-- Hàm bật/tắt dropdown
local DropdownOpen = false
DropdownButton.MouseButton1Click:Connect(function()
    DropdownOpen = not DropdownOpen
    RadiusButton.Visible = DropdownOpen
    RadiusBox.Visible = DropdownOpen
    SuperAimButton.Visible = DropdownOpen
    DropdownButton.Text = DropdownOpen and "↑" or "↓"
end)

-- Điều chỉnh bán kính
RadiusBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newRadius = tonumber(RadiusBox.Text)
        if newRadius and newRadius >= 150 and newRadius <= 500 then
            Radius = newRadius
            RadiusButton.Text = "R: " .. Radius
        else
            RadiusBox.Text = ""
            RadiusBox.PlaceholderText = "150-500"
        end
    end
end)

-- Bật/tắt siêu tốc Aim
SuperAimButton.MouseButton1Click:Connect(function()
    SuperAim = not SuperAim
    SuperAimButton.BackgroundColor3 = SuperAim and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
end)

-- Bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Đảm bảo nút ON/OFF luôn hiển thị
    if not AimActive then
        ToggleButton.Image = "rbxassetid://133602550183849"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil
    else
        ToggleButton.Image = "rbxassetid://133602550183849"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil
    end
end)

-- Tìm kẻ thù gần nhất
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
    return targets
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive and Locked then
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            CurrentTarget = CurrentTarget or enemies[1]
        else
            CurrentTarget = nil
            Locked = false
        end

        if CurrentTarget then
            local targetPosition = CurrentTarget.HumanoidRootPart.Position
            local factor = SuperAim and 1 or SmoothFactor
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), factor)
        end
    end
end)
