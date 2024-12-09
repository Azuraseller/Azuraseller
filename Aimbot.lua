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

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local SettingsButton = Instance.new("ImageButton") -- Nút cài đặt
local ToggleButton = Instance.new("TextButton") -- Nút ON/OFF
local DropdownButton = Instance.new("TextButton") -- Nút ↓
local PlayerListFrame = Instance.new("Frame") -- Khung danh sách player

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút Cài đặt
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 50, 0, 50)
SettingsButton.Position = UDim2.new(0.85, 0, 0.01, 0)
SettingsButton.Image = "rbxassetid://1234567890" -- Thay bằng assetID của hình cài đặt
SettingsButton.BackgroundTransparency = 1

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20
ToggleButton.Visible = false -- Ẩn mặc định

-- Nút ↓
DropdownButton.Parent = ScreenGui
DropdownButton.Size = UDim2.new(0, 100, 0, 25)
DropdownButton.Position = UDim2.new(0.85, 0, 0.08, 0)
DropdownButton.Text = "↓"
DropdownButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.TextColor3 = Color3.fromRGB(0, 0, 255)
DropdownButton.Font = Enum.Font.SourceSans
DropdownButton.TextSize = 20
DropdownButton.Visible = false -- Ẩn mặc định

-- Khung danh sách player
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 300)
PlayerListFrame.Position = UDim2.new(0.85, 0, 0.15, 0)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.Visible = false -- Ẩn mặc định

-- Hàm bật/tắt giao diện cài đặt
SettingsButton.MouseButton1Click:Connect(function()
    -- Xoay nút cài đặt
    SettingsButton.Rotation = (SettingsButton.Rotation + 30) % 360
    
    -- Hiển thị/ẩn nút ON/OFF và nút ↓
    ToggleButton.Visible = not ToggleButton.Visible
    DropdownButton.Visible = ToggleButton.Visible
end)

-- Bấm nút ↓ để hiển thị danh sách player
DropdownButton.MouseButton1Click:Connect(function()
    PlayerListFrame.Visible = not PlayerListFrame.Visible
end)

-- Cập nhật danh sách player
local function UpdatePlayerList()
    PlayerListFrame:ClearAllChildren()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListFrame
            PlayerButton.Size = UDim2.new(1, 0, 0, 30)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundTransparency = 0.5
            PlayerButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayerButton.Font = Enum.Font.SourceSans
            PlayerButton.TextSize = 18

            -- Di chuyển tới player khi bấm
            PlayerButton.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
                end
            end)
        end
    end
end

-- Theo dõi thay đổi danh sách player
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

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
-- Điều chỉnh camera tránh bị che khuất
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hitPart then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
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

        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "CamLock: ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "CamLock: OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
            end
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetCharacter.HumanoidRootPart.Position + targetCharacter.HumanoidRootPart.Velocity * Prediction

                -- Kiểm tra nếu mục tiêu không hợp lệ
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    -- Điều chỉnh vị trí camera
                    targetPosition = AdjustCameraPosition(targetPosition)

                    -- Cập nhật camera chính (Camera 1)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)

                    -- Cập nhật camera phụ (Camera 2)
                    Camera2.CFrame = Camera2.CFrame:Lerp(CFrame.new(Camera2.CFrame.Position, targetPosition), SmoothFactor)
                end
            end
        end
    end
end)
