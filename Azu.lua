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

-- GUI cho nút View và Teleport (ngoài PlayerListFrame)
local viewTeleportFrame = Instance.new("Frame")
viewTeleportFrame.Parent = ScreenGui
viewTeleportFrame.BackgroundTransparency = 1
viewTeleportFrame.Size = UDim2.new(0, 0, 0, 0)

-- Hiển thị danh sách người chơi
local function UpdatePlayerList()
    -- Xóa các button cũ trong danh sách
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

            -- Khởi tạo nút View và Teleport (ẩn mặc định)
            local ViewButton = Instance.new("TextButton")
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ mặc định
            ViewButton.Visible = false -- Ẩn khi chưa bấm vào tên

            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Size = UDim2.new(0, 30, 0, 30)
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- Tím
            TeleportButton.Visible = false -- Ẩn khi chưa bấm vào tên

            -- Đặt các nút View và Teleport ra ngoài PlayerListFrame
            ViewButton.Parent = viewTeleportFrame
            TeleportButton.Parent = viewTeleportFrame
            ViewButton.Position = UDim2.new(0, -35, 0, yOffset) -- Đặt View phía sau tên player
            TeleportButton.Position = UDim2.new(0, -70, 0, yOffset) -- Đặt Teleport cách View 1 chút

            -- Bật/ Tắt nút View và Teleport khi click vào tên player
            local toggleVisibility = false
            PlayerButton.MouseButton1Click:Connect(function()
                -- Nếu bấm vào tên player đã có nút View, ẩn các nút cũ
                if currentViewedPlayer and currentViewedPlayer ~= player then
                    currentViewedButton.Visible = false
                    currentViewedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đặt lại màu đỏ
                    currentViewedButton = nil
                end
                -- Nếu nút View và Teleport chưa hiện, hiển thị chúng
                if not toggleVisibility then
                    ViewButton.Visible = true
                    TeleportButton.Visible = true
                    toggleVisibility = true
                    currentViewedPlayer = player
                    currentViewedButton = ViewButton
                else
                    -- Ẩn chúng nếu đã được hiển thị
                    ViewButton.Visible = false
                    TeleportButton.Visible = false
                    toggleVisibility = false
                    currentViewedPlayer = nil
                    currentViewedButton = nil
                end
            end)

            -- Nút View sự kiện
            ViewButton.MouseButton1Click:Connect(function()
                if currentViewedPlayer == player then
                    -- Nếu player đang được view, tắt view
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ khi tắt
                    currentViewedPlayer = nil
                    currentViewedButton = nil
                else
                    -- Tắt view player trước đó
                    if currentViewedButton then
                        currentViewedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
                    end
                    -- View player mới
                    Camera.CameraSubject = player.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá khi đang view
                    currentViewedPlayer = player
                    currentViewedButton = ViewButton
                end
            end)

            -- Nút Teleport sự kiện
            TeleportButton.MouseButton1Click:Connect(function()
                -- Dịch chuyển tới player
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            yOffset = yOffset + 40 -- Tăng khoảng cách giữa các player
        end
    end
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý toggle cuộn danh sách (với hiệu ứng xoay bánh răng)
local isExpanded = false
local rotation = 0
ScrollButtonToggle.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
    end
    -- Xoay bánh răng 60°
    rotation = rotation + 60
    ScrollButtonToggle.Rotation = rotation
end)

-- Xử lý cuộn với MouseWheel và phát âm thanh
local UserInputService = game:GetService("UserInputService")

PlayerListScrollingFrame.MouseWheelForward:Connect(function()
    rotation = rotation - 45
    ScrollButtonToggle.Rotation = rotation
    scrollSound:Play()  -- Phát âm thanh khi cuộn lên
end)

PlayerListScrollingFrame.MouseWheelBackward:Connect(function()
    rotation = rotation + 45
    ScrollButtonToggle.Rotation = rotation
    scrollSound:Play()  -- Phát âm thanh khi cuộn xuống
end)
