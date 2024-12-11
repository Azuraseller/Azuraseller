-- Khai báo các biến cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local SoundService = game:GetService("SoundService")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo một âm thanh khi cuộn
local scrollSound = Instance.new("Sound")
scrollSound.SoundId = "rbxassetid://123456789"  -- Thay thế ID này bằng ID âm thanh của bạn
scrollSound.Parent = SoundService

-- GUI: Player List
local PlayerListFrame = Instance.new("Frame")
local ScrollButtonToggle = Instance.new("ImageButton")
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

-- Nút toggle cuộn danh sách (bánh răng)
ScrollButtonToggle.Parent = ScreenGui
ScrollButtonToggle.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonToggle.Position = UDim2.new(0.6, 0, 0.06, 0) -- Di chuyển sang trái
ScrollButtonToggle.Image = "rbxassetid://6035047377" -- Biểu tượng bánh răng
ScrollButtonToggle.BackgroundTransparency = 1

-- Khung cuộn danh sách người chơi
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Biến để theo dõi player đang được view
local currentViewedPlayer = nil
local currentViewedButton = nil

-- Hiển thị danh sách người chơi
local function UpdatePlayerList()
    for _, child in ipairs(PlayerListScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local yOffset = 0
    local lastActivePlayerButton = nil -- Lưu nút của người chơi trước đó

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

            -- Nút View (ẩn mặc định)
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(0, 0, 1, 0)
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ mặc định
            ViewButton.Visible = false  -- Ẩn nút View ban đầu

            -- Nút Teleport (ẩn mặc định)
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 30, 0, 30)
            TeleportButton.Position = UDim2.new(0, 35, 1, 0) -- Đặt cạnh ViewButton
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- Tím
            TeleportButton.Visible = false -- Ẩn nút Teleport ban đầu

            -- Bật/Tắt nút View và Teleport khi click vào tên player
            PlayerButton.MouseButton1Click:Connect(function()
                if lastActivePlayerButton and lastActivePlayerButton ~= PlayerButton then
                    -- Ẩn các nút của người chơi trước đó
                    lastActivePlayerButton.ViewButton.Visible = false
                    lastActivePlayerButton.TeleportButton.Visible = false
                end

                -- Hiển thị hoặc ẩn nút của người chơi hiện tại
                ViewButton.Visible = not ViewButton.Visible
                TeleportButton.Visible = not TeleportButton.Visible

                -- Cập nhật nút đang hoạt động
                lastActivePlayerButton = PlayerButton
            end)

            -- Nút View sự kiện
            ViewButton.MouseButton1Click:Connect(function()
                if currentViewedPlayer == player then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ khi tắt
                    currentViewedPlayer = nil
                    currentViewedButton = nil
                else
                    if currentViewedButton then
                        currentViewedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
                    end
                    Camera.CameraSubject = player.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá khi đang view
                    currentViewedPlayer = player
                    currentViewedButton = ViewButton
                end
            end)

            -- Góc bo tròn cho nút View
            local ViewCorner = Instance.new("UICorner")
            ViewCorner.CornerRadius = UDim.new(1, 0)
            ViewCorner.Parent = ViewButton

            -- Nút Teleport sự kiện
            TeleportButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            -- Góc bo tròn cho nút Teleport
            local TeleportCorner = Instance.new("UICorner")
            TeleportCorner.CornerRadius = UDim.new(1, 0)
            TeleportCorner.Parent = TeleportButton

            yOffset = yOffset + 40 -- Tăng khoảng cách giữa các player
        end
    end
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()
