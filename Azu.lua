local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo danh sách nền mờ đục
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
PlayerListFrame.Position = UDim2.new(0.75, 0, 0.06, 0)  -- Dịch sang trái một chút
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.BackgroundTransparency = 0.6
PlayerListFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
PlayerListFrame.BorderSizePixel = 2
PlayerListFrame.ClipsDescendants = true

-- Nút cuộn lên/xuống
local ScrollButtonToggle = Instance.new("TextButton")
ScrollButtonToggle.Parent = ScreenGui
ScrollButtonToggle.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonToggle.Position = UDim2.new(0.79, 0, 0.06, 0)
ScrollButtonToggle.Text = "↓"
ScrollButtonToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonToggle.Font = Enum.Font.SourceSans
ScrollButtonToggle.TextSize = 18

-- Khung cuộn danh sách người chơi
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Hiển thị danh sách người chơi
local function UpdatePlayerList()
    -- Xóa các mục cũ
    for _, child in ipairs(PlayerListScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local yOffset = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Nút tên người chơi
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListScrollingFrame
            PlayerButton.Size = UDim2.new(1, -8, 0, 30)
            PlayerButton.Position = UDim2.new(0, 4, 0, yOffset)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayerButton.Font = Enum.Font.SourceSans
            PlayerButton.TextSize = 16

            -- Nút xem camera
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 30, 1, 0)
            ViewButton.Position = UDim2.new(0.8, 0, 0, 0)  -- Dời nút View sang phải
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
            ViewButton.MouseButton1Click:Connect(function()
                -- Toggle camera view
                if Camera.CameraSubject == player.Character.Humanoid then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)  -- Revert color when view is off
                else
                    Camera.CameraSubject = player.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- Change to green when view is on
                end
            end)

            -- Nút dịch chuyển
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 30, 1, 0)
            TeleportButton.Position = UDim2.new(0.85, 0, 0, 0)
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
            TeleportButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                    end
                end
            end)

            yOffset = yOffset + 35
        end
    end

    -- Cập nhật kích thước canvas
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý cuộn lên/xuống
local isExpanded = false
ScrollButtonToggle.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
        ScrollButtonToggle.Text = "↑"
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
        ScrollButtonToggle.Text = "↓"
    end
end)
