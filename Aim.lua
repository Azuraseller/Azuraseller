local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình các tham số
local Prediction = 0.1
local Radius = 230
local MinRadius = 100
local MaxRadius = 1000
local BaseSmoothFactor = 0.15
local MaxSmoothFactor = 0.5
local Locked = false
local CurrentTarget = nil
local AimActive = true
local SavedState = true -- Trạng thái lưu trữ

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local SettingsButton = Instance.new("TextButton") -- Nút ⚙️
local AdjustRadiusButton = Instance.new("TextButton") -- Nút 🌐
local RadiusTextBox = Instance.new("TextBox") -- TextBox để điều chỉnh R

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = SavedState and "ON" or "OFF"
ToggleButton.BackgroundColor3 = SavedState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18
ToggleButton.BorderSizePixel = 0
ToggleButton.TextScaled = true
ToggleButton.ClipsDescendants = true
ToggleButton.UICorner = Instance.new("UICorner", ToggleButton)

-- Nút ⚙️
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 50, 0, 50)
SettingsButton.Position = UDim2.new(0.79, 0, 0.01, 0)
SettingsButton.Text = "⚙️"
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Font = Enum.Font.SourceSans
SettingsButton.TextSize = 18
SettingsButton.BorderSizePixel = 0
SettingsButton.UICorner = Instance.new("UICorner", SettingsButton)

-- Nút 🌐
AdjustRadiusButton.Parent = ScreenGui
AdjustRadiusButton.Size = UDim2.new(0, 50, 0, 50)
AdjustRadiusButton.Position = UDim2.new(0.74, 0, 0.01, 0)
AdjustRadiusButton.Text = "🌐"
AdjustRadiusButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
AdjustRadiusButton.BackgroundTransparency = 0.5
AdjustRadiusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AdjustRadiusButton.Font = Enum.Font.SourceSans
AdjustRadiusButton.TextSize = 18
AdjustRadiusButton.BorderSizePixel = 0
AdjustRadiusButton.UICorner = Instance.new("UICorner", AdjustRadiusButton)

-- TextBox để chỉnh R
RadiusTextBox.Parent = ScreenGui
RadiusTextBox.Size = UDim2.new(0, 150, 0, 50)
RadiusTextBox.Position = UDim2.new(0.64, 0, 0.01, 0)
RadiusTextBox.Text = "R: " .. Radius
RadiusTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RadiusTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusTextBox.Font = Enum.Font.SourceSans
RadiusTextBox.TextSize = 18
RadiusTextBox.BorderSizePixel = 0
RadiusTextBox.Visible = false
RadiusTextBox.UICorner = Instance.new("UICorner", RadiusTextBox)

-- Ẩn/hiện các nút khi bấm ⚙️
SettingsButton.MouseButton1Click:Connect(function()
    local visible = not AdjustRadiusButton.Visible
    AdjustRadiusButton.Visible = visible
    RadiusTextBox.Visible = false
    ToggleButton.Visible = visible
end)

-- Hiện TextBox khi bấm 🌐
AdjustRadiusButton.MouseButton1Click:Connect(function()
    RadiusTextBox.Visible = not RadiusTextBox.Visible
end)

-- Điều chỉnh R qua TextBox
RadiusTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newValue = tonumber(RadiusTextBox.Text:match("%d+"))
        if newValue then
            Radius = math.clamp(newValue, MinRadius, MaxRadius) -- Giới hạn giá trị
            RadiusTextBox.Text = "R: " .. Radius
        else
            RadiusTextBox.Text = "R: " .. Radius -- Giữ giá trị cũ nếu nhập sai
        end
    end
end)

-- Tìm tất cả đối thủ trong phạm vi
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

    if #targets > 1 then
        table.sort(targets, function(a, b)
            return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        end)
    end
    return targets
end

-- Dự đoán vị trí phía trước mục tiêu
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + velocity * Prediction
        return predictedPosition
    end
    return target.HumanoidRootPart.Position
end

-- Theo dõi mục tiêu
RunService.RenderStepped:Connect(function()
    if AimActive then
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget or not table.find(enemies, CurrentTarget) then
                CurrentTarget = enemies[1]
            end
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil
            end
        end

        -- Theo dõi và ghim phía trước mục tiêu
        if CurrentTarget and Locked then
            local targetPosition = PredictTargetPosition(CurrentTarget)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), BaseSmoothFactor)
        end
    end
end)
