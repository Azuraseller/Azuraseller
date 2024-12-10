-- Khai báo các dịch vụ cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- GUI: Player List Frame
local PlayerListFrame = Instance.new("Frame")
local ScrollButtonToggle = Instance.new("ImageButton")
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")

-- Thiết kế danh sách người chơi (Player List Frame)
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 150, 0, 0) -- Ban đầu đóng
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.06, 0) -- Vị trí danh sách
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Màu nền đen
PlayerListFrame.BackgroundTransparency = 0.6 -- Làm mờ nền
PlayerListFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Viền màu đỏ
PlayerListFrame.BorderSizePixel = 2 -- Độ dày viền
PlayerListFrame.ClipsDescendants = true -- Cắt nội dung vượt khung

-- Nút cuộn (Scroll Button Toggle)
ScrollButtonToggle.Parent = ScreenGui
ScrollButtonToggle.Size = UDim2.new(0, 40, 0, 40) -- Kích thước hình vuông để bo tròn
ScrollButtonToggle.Position = UDim2.new(0.6, 0, 0.06, -50) -- Nằm trên danh sách
ScrollButtonToggle.Image = "rbxassetid://6035047377" -- Biểu tượng bánh răng
ScrollButtonToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Nền xám
ScrollButtonToggle.BackgroundTransparency = 0 -- Nền không trong suốt

-- Bo tròn nút cuộn
local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(1, 0) -- Tạo hình tròn
ScrollCorner.Parent = ScrollButtonToggle

-- Khung cuộn danh sách người chơi
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30) -- Khung cuộn vừa trong danh sách
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Hiệu ứng mở/đóng danh sách và xoay bánh răng
local isExpanded = false
local rotation = 0 -- Biến lưu trạng thái xoay
ScrollButtonToggle.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded -- Đổi trạng thái mở/đóng
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200) -- Mở danh sách
        rotation = rotation + 45 -- Xoay theo chiều kim đồng hồ
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0) -- Đóng danh sách
        rotation = rotation - 45 -- Xoay ngược chiều kim đồng hồ
    end
    -- Cập nhật trạng thái xoay
    ScrollButtonToggle.Rotation = rotation
end)

-- Hàm cập nhật danh sách người chơi
local function UpdatePlayerList()
    for _, child in ipairs(PlayerListScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy() -- Xóa các nút cũ để làm mới danh sách
        end
    end
    local yOffset = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Tạo nút tên người chơi
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListScrollingFrame
            PlayerButton.Size = UDim2.new(1, -8, 0, 30)
            PlayerButton.Position = UDim2.new(0, 4, 0, yOffset)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Nền xám
            PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ trắng
            PlayerButton.Font = Enum.Font.SourceSans
            PlayerButton.TextSize = 16
            PlayerButton.ClipsDescendants = false -- Cho phép nút con tràn

            -- Nút View (hình tròn trước tên)
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 20, 0, 20)
            ViewButton.Position = UDim2.new(-0.15, 0, 0.5, -10)
            ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
            ViewButton.Text = ""
            local ViewCorner = Instance.new("UICorner")
            ViewCorner.CornerRadius = UDim.new(1, 0) -- Bo tròn
            ViewCorner.Parent = ViewButton

            -- Nút Teleport (hình tròn sau tên)
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 20, 0, 20)
            TeleportButton.Position = UDim2.new(1.1, 0, 0.5, -10)
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- Tím
            TeleportButton.Text = ""
            local TeleportCorner = Instance.new("UICorner")
            TeleportCorner.CornerRadius = UDim.new(1, 0) -- Bo tròn
            TeleportCorner.Parent = TeleportButton

            -- Sự kiện khi bấm View
            ViewButton.MouseButton1Click:Connect(function()
                for _, button in ipairs(PlayerListScrollingFrame:GetChildren()) do
                    if button:IsA("TextButton") and button:FindFirstChild("TextButton") then
                        button:FindFirstChild("TextButton").BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Reset nút khác về đỏ
                    end
                end
                ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Chuyển sang xanh
            end)

            -- Sự kiện khi bấm Teleport
            TeleportButton.MouseButton1Click:Connect(function()
                ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Tắt View
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)

            yOffset = yOffset + 35 -- Cập nhật khoảng cách cho nút tiếp theo
        end
    end
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset) -- Điều chỉnh kích thước canvas
end

-- Lắng nghe sự kiện thêm/xóa người chơi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList() -- Lần đầu hiển thị danh sách
