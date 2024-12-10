-- Khai báo các biến cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- GUI: Player List
local PlayerListFrame = Instance.new("Frame")
local ScrollButtonDown = Instance.new("TextButton")
local ScrollButtonUp = Instance.new("TextButton")
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")

-- Tạo danh sách nền mờ đục
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.06, 0) -- Di chuyển sang trái
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.BackgroundTransparency = 0.6
PlayerListFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
PlayerListFrame.BorderSizePixel = 2
PlayerListFrame.ClipsDescendants = true

-- Nút cuộn xuống
ScrollButtonDown.Parent = ScreenGui
ScrollButtonDown.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonDown.Position = UDim2.new(0.6, 0, 0.06, 0) -- Di chuyển sang trái
ScrollButtonDown.Text = "↓"
ScrollButtonDown.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonDown.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonDown.Font = Enum.Font.SourceSans
ScrollButtonDown.TextSize = 18

-- Nút cuộn lên
ScrollButtonUp.Parent = PlayerListFrame
ScrollButtonUp.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonUp.Position = UDim2.new(0, 60, 0, 5)
ScrollButtonUp.Text = "↑"
ScrollButtonUp.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonUp.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonUp.Font = Enum.Font.SourceSans
ScrollButtonUp.TextSize = 18
ScrollButtonUp.Visible = false -- Mặc định ẩn

-- Khung cuộn danh sách người chơi
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Hiển thị danh sách người chơi
local function UpdatePlayerList()
    for _, child in ipairs(PlayerListScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    local yOffset = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListScrollingFrame
            PlayerButton.Size = UDim2.new(1, -8, 0, 30)
            PlayerButton.Position = UDim2.new(0, 4, 0, yOffset)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayerButton.Font = Enum.Font.SourceSans
            PlayerButton.TextSize = 16

            -- Tạo góc bo tròn
            local UICorner = Instance.new("UICorner")
            UICorner.Parent = PlayerButton

            -- Nút View
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 30, 1, 0)
            ViewButton.Position = UDim2.new(0.7, 0, 0, 0)
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
            ViewButton.MouseButton1Click:Connect(function()
                Camera.CameraSubject = player.Character.Humanoid -- Xem camera player
            end)

            -- Góc bo tròn cho nút View
            local ViewCorner = Instance.new("UICorner")
            ViewCorner.CornerRadius = UDim.new(1, 0)
            ViewCorner.Parent = ViewButton

            -- Nút Teleport
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 30, 1, 0)
            TeleportButton.Position = UDim2.new(0.85, 0, 0, 0)
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
            TeleportButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            -- Góc bo tròn cho nút Teleport
            local TeleportCorner = Instance.new("UICorner")
            TeleportCorner.CornerRadius = UDim.new(1, 0)
            TeleportCorner.Parent = TeleportButton

            yOffset = yOffset + 35
        end
    end
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý cuộn xuống và lên
local isExpanded = false
ScrollButtonDown.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
        ScrollButtonUp.Visible = true
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
        ScrollButtonUp.Visible = false
    end
end)
ScrollButtonUp.MouseButton1Click:Connect(function()
    PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
    ScrollButtonUp.Visible = false
    isExpanded = false
end)
