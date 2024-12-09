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
local AimActive = true
local SettingsVisible = false -- Trạng thái cài đặt

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local SettingsButton = Instance.new("TextButton")
local ToggleButton = Instance.new("TextButton")
local PlayerListButton = Instance.new("TextButton")
local PlayerListFrame = Instance.new("Frame")
local PlayerListContainer = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local PlayerButtonTemplate = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút cài đặt
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 1, 0, 1)
SettingsButton.Position = UDim2.new(0.85, 0, 0.01, 0)
SettingsButton.Text = ""
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SettingsButton.BackgroundTransparency = 0.5
SettingsButton.Visible = true

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20
ToggleButton.Visible = false

-- Nút Player List
PlayerListButton.Parent = ScreenGui
PlayerListButton.Size = UDim2.new(0, 1, 0, 1)
PlayerListButton.Position = UDim2.new(0.05, 0, 0.01, 0)
PlayerListButton.Text = "Player List"
PlayerListButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
PlayerListButton.TextColor3 = Color3.fromRGB(0, 150, 255)
PlayerListButton.Font = Enum.Font.SourceSans
PlayerListButton.TextSize = 20
PlayerListButton.BackgroundTransparency = 0.5
PlayerListButton.Visible = false

-- Khung Player List
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 0)
PlayerListFrame.Position = UDim2.new(0.05, 0, 0.06, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlayerListFrame.BackgroundTransparency = 0.7
PlayerListFrame.Visible = false

-- Container chứa danh sách
PlayerListContainer.Parent = PlayerListFrame
PlayerListContainer.Size = UDim2.new(1, 0, 1, 0)
PlayerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.ScrollBarThickness = 4
PlayerListContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)

-- Layout cho danh sách
UIListLayout.Parent = PlayerListContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Nút mẫu cho người chơi
PlayerButtonTemplate.Text = "Player"
PlayerButtonTemplate.Size = UDim2.new(1, -10, 0, 30)
PlayerButtonTemplate.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
PlayerButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerButtonTemplate.Font = Enum.Font.SourceSans
PlayerButtonTemplate.TextSize = 20
PlayerButtonTemplate.BackgroundTransparency = 0.5
PlayerButtonTemplate.BorderSizePixel = 0
PlayerButtonTemplate.Visible = false

-- Hàm hiệu ứng bật/tắt nút cài đặt
local function AnimateSettingsButton(visible)
    if visible then
        SettingsButton.Size = UDim2.new(0, 1, 0, 1)
        SettingsButton:TweenSize(
            UDim2.new(0, 50, 0, 50),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    else
        SettingsButton:TweenSize(
            UDim2.new(0, 1, 0, 1),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end
end

-- Hàm hiệu ứng ON/OFF và Player List
local function AnimateToggleButton(visible)
    ToggleButton.Visible = visible
    PlayerListButton.Visible = visible
    if visible then
        ToggleButton.Size = UDim2.new(0, 1, 0, 1)
        ToggleButton:TweenSize(
            UDim2.new(0, 100, 0, 50),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
        PlayerListButton:TweenSize(
            UDim2.new(0, 100, 0, 50),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    else
        ToggleButton:TweenSize(
            UDim2.new(0, 1, 0, 1),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.3,
            true,
            function()
                ToggleButton.Visible = false
            end
        )
        PlayerListButton:TweenSize(
            UDim2.new(0, 1, 0, 1),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.3,
            true,
            function()
                PlayerListButton.Visible = false
            end
        )
    end
end

-- Cập nhật danh sách người chơi
local function UpdatePlayerList()
    for _, child in ipairs(PlayerListContainer:GetChildren()) do
        if child:IsA("TextButton") and child ~= PlayerButtonTemplate then
            child:Destroy()
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerButton = PlayerButtonTemplate:Clone()
            PlayerButton.Text = player.Name
            PlayerButton.Visible = true
            PlayerButton.Parent = PlayerListContainer

            PlayerButton.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0))
                end
            end)
        end
    end

    PlayerListContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end

-- Kết hợp nút cài đặt
SettingsButton.MouseButton1Click:Connect(function()
    SettingsVisible = not SettingsVisible
    AnimateSettingsButton(SettingsVisible)
    AnimateToggleButton(SettingsVisible)
    AimActive = SettingsVisible

    if SettingsVisible then
        PlayerListFrame.Visible = true
        UpdatePlayerList()
    else
        PlayerListFrame.Visible = false
    end
end)

-- Toggle ON/OFF
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil
    end
end)

-- Hiệu ứng trượt Player List
local isPlayerListOpen = false
PlayerListButton.MouseButton1Click:Connect(function()
    if isPlayerListOpen then
        PlayerListFrame:TweenSize(
            UDim2.new(0, 200, 0, 0),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
        PlayerListButton.Text = "Player List"
    else
        PlayerListFrame:TweenSize(
            UDim2.new(0, 200, 0, 200),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
        PlayerListButton.Text = "Close List"
    end
    isPlayerListOpen = not isPlayerListOpen
end)
