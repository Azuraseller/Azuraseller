local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local Radius = 200  -- Bán kính khóa mục tiêu
local SmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

-- Nút Cài đặt
local SettingsButton = Instance.new("TextButton")
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 50, 0, 50) -- Kích thước nút
SettingsButton.Position = UDim2.new(0.85, 0, 0.01, 0) -- Vị trí
SettingsButton.Text = "" -- Không hiển thị chữ
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh
SettingsButton.Visible = true -- Hiển thị nút
SettingsButton.ZIndex = 2 -- Đặt thứ tự hiển thị

-- Biểu tượng cài đặt
local SettingsIcon = Instance.new("ImageLabel")
SettingsIcon.Parent = SettingsButton
SettingsIcon.Size = UDim2.new(1, 0, 1, 0) -- Kích thước bằng nút
SettingsIcon.BackgroundTransparency = 1 -- Không có nền
SettingsIcon.Image = "rbxassetid://12345678" -- Thay bằng ID hình ảnh cài đặt

-- Nút ON/OFF
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.07, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20
ToggleButton.Visible = false -- Ẩn nút khi bắt đầu

-- Nút Trượt xuống
local DropButton = Instance.new("TextButton")
DropButton.Parent = ScreenGui
DropButton.Size = UDim2.new(0, 100, 0, 30) -- Nút nhỏ hơn nút ON/OFF
DropButton.Position = UDim2.new(0.85, 0, 0.13, 0)
DropButton.Text = "↓"
DropButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255) -- Màu xanh dương
DropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropButton.Font = Enum.Font.SourceSans
DropButton.TextSize = 20
DropButton.Visible = false -- Ẩn khi bắt đầu

-- Hiện/Ẩn nút khi nhấn nút cài đặt
SettingsButton.MouseButton1Click:Connect(function()
    if not ToggleButton.Visible then
        ToggleButton.Visible = true
        DropButton.Visible = true
        SettingsButton:TweenPosition(SettingsButton.Position + UDim2.new(0, 30, 0, 0), "Out", "Sine", 0.3, true) -- Xoay nút
    else
        ToggleButton.Visible = false
        DropButton.Visible = false
        SettingsButton:TweenPosition(SettingsButton.Position - UDim2.new(0, 30, 0, 0), "Out", "Sine", 0.3, true)
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

-- Nút trượt xuống hiển thị danh sách Player
DropButton.MouseButton1Click:Connect(function()
    -- Tạo danh sách player
    local PlayerListFrame = Instance.new("Frame")
    PlayerListFrame.Parent = ScreenGui
    PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
    PlayerListFrame.Position = DropButton.Position + UDim2.new(0, 0, 0.05, 0)
    PlayerListFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PlayerListFrame.BackgroundTransparency = 0.5

    -- Thêm danh sách player vào frame
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListFrame
            PlayerButton.Size = UDim2.new(1, 0, 0, 30)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            PlayerButton.MouseButton1Click:Connect(function()
                -- Dịch chuyển đến player
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
                end
            end)
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
    return targets
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 and not Locked then
            Locked = true
        end

        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)
            end
        end
    end
end)
