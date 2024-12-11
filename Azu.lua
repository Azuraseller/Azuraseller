-- Khai báo các biến cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- GUI: Player List
local PlayerListFrame = Instance.new("Frame")
local ScrollButtonToggle = Instance.new("ImageButton")
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")

-- Tạo danh sách nền mờ đục
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.06, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.BackgroundTransparency = 0.6
PlayerListFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
PlayerListFrame.BorderSizePixel = 2
PlayerListFrame.ClipsDescendants = true

-- Nút toggle cuộn danh sách (bánh răng)
ScrollButtonToggle.Parent = ScreenGui
ScrollButtonToggle.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonToggle.Position = UDim2.new(0.6, 0, 0.06, 0)
ScrollButtonToggle.Image = "rbxassetid://6035047377"
ScrollButtonToggle.BackgroundTransparency = 1

-- Khung cuộn danh sách người chơi
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Biến lưu trạng thái
local currentSelectedButton = nil
local currentViewedPlayer = nil

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

            -- Các nút View và Teleport
            local ViewButton = Instance.new("ImageButton")
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(1.5 -35, 0, 0)
            ViewButton.Image = "rbxassetid://6035047380" -- Biểu tượng con mắt
            ViewButton.Visible = false
            ViewButton.BackgroundTransparency = 1
            ViewButton.Parent = PlayerButton

            local TeleportButton = Instance.new("ImageButton")
            TeleportButton.Size = UDim2.new(0, 30, 0, 30)
            TeleportButton.Position = UDim2.new(1.65, -10, 0, 0)
            TeleportButton.Image = "rbxassetid://6035047390" -- Biểu tượng dịch chuyển
            TeleportButton.Visible = false
            TeleportButton.BackgroundTransparency = 1
            TeleportButton.Parent = PlayerButton

            -- Xử lý khi bấm vào tên người chơi
            PlayerButton.MouseButton1Click:Connect(function()
                -- Ẩn nút của người chơi trước đó
                if currentSelectedButton then
                    currentSelectedButton.ViewButton.Visible = false
                    currentSelectedButton.TeleportButton.Visible = false
                end

                -- Hiển thị nút của người chơi hiện tại
                ViewButton.Visible = true
                TeleportButton.Visible = true
                currentSelectedButton = {ViewButton = ViewButton, TeleportButton = TeleportButton}
            end)

            -- Xử lý nút View
            ViewButton.MouseButton1Click:Connect(function()
                if currentViewedPlayer == player then
                    -- Tắt view
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    currentViewedPlayer = nil
                    ViewButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
                else
                    -- Chuyển view
                    Camera.CameraSubject = player.Character.Humanoid
                    currentViewedPlayer = player
                    ViewButton.ImageColor3 = Color3.fromRGB(0, 255, 0)
                end
            end)

            -- Xử lý nút Teleport
            TeleportButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            yOffset = yOffset + 40
        end
    end
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý toggle cuộn danh sách
local isExpanded = false
local rotation = 0
ScrollButtonToggle.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
    end
    rotation = rotation + 60
    ScrollButtonToggle.Rotation = rotation
end)
