local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình các tham số
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local Radius = 200  -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi
local Locked = false
local CurrentTarget = nil
local AimActive = false -- Mặc định Aim tắt
local GUIVisible = false -- Trạng thái nút ON/OFF (ẩn hoặc hiện)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local SettingsButton = Instance.new("ImageButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20
ToggleButton.Visible = false -- Mặc định ẩn

-- Nút cài đặt
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 40, 0, 40)
SettingsButton.Position = UDim2.new(0.9, 0, 0.01, 0)
SettingsButton.BackgroundTransparency = 1
SettingsButton.Image = "rbxassetid://6035047377" -- Biểu tượng bánh răng
SettingsButton.Visible = true -- Đảm bảo nút cài đặt luôn hiển thị

-- Tạo hiệu ứng xoay nút cài đặt
local function RotateSettingsButton()
    local TweenService = game:GetService("TweenService")
    local rotationTween = TweenService:Create(SettingsButton, TweenInfo.new(0.3), {Rotation = SettingsButton.Rotation + 30})
    rotationTween:Play()
end

-- Bật/tắt Aim và hiển thị nút ON/OFF
SettingsButton.MouseButton1Click:Connect(function()
    GUIVisible = not GUIVisible
    RotateSettingsButton()
    
    if GUIVisible then
        ToggleButton.Visible = true
        AimActive = true -- Kích hoạt Aim
        -- Thêm hiệu ứng trượt nút ON/OFF
        ToggleButton:TweenPosition(UDim2.new(0.75, 0, 0.01, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
    else
        AimActive = false -- Tắt Aim
        -- Thêm hiệu ứng trượt nút ON/OFF trở về
        ToggleButton:TweenPosition(UDim2.new(0.85, 0, 0.01, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true, function()
            ToggleButton.Visible = false -- Ẩn nút sau khi trượt
        end)
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil -- Hủy mục tiêu khi tắt CamLock
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
    return targets
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive and Locked then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
        end

        -- Theo dõi mục tiêu
        if CurrentTarget then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction

                -- Cập nhật camera
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)
            end
        end
    end
end)
