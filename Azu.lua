local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo danh sách Player List
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 180, 0, 0) -- Giảm chiều rộng
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.15, 0) -- Nâng lên trên
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.BackgroundTransparency = 0.6
PlayerListFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
PlayerListFrame.BorderSizePixel = 2
PlayerListFrame.ClipsDescendants = true

-- Nút cuộn lên (bên dưới)
local ScrollButtonUp = Instance.new("TextButton")
ScrollButtonUp.Parent = PlayerListFrame
ScrollButtonUp.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonUp.Position = UDim2.new(0.5, -15, 1, 10) -- Đặt dưới danh sách
ScrollButtonUp.Text = "↑"
ScrollButtonUp.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonUp.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonUp.Font = Enum.Font.SourceSans
ScrollButtonUp.TextSize = 18
ScrollButtonUp.Visible = false

-- Nút cuộn xuống (bên trên)
local ScrollButtonDown = Instance.new("TextButton")
ScrollButtonDown.Parent = PlayerListFrame
ScrollButtonDown.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonDown.Position = UDim2.new(0.5, -15, 0, 0)
ScrollButtonDown.Text = "↓"
ScrollButtonDown.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonDown.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonDown.Font = Enum.Font.SourceSans
ScrollButtonDown.TextSize = 18
ScrollButtonDown.Visible = false

-- Khung cuộn danh sách người chơi
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -60) -- Thêm khoảng trống cho các nút cuộn
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 0)
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
    local showScrollUp = false
    local showScrollDown = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Tạo nút hiển thị tên player
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Parent = PlayerListScrollingFrame
            PlayerButton.Size = UDim2.new(1, -8, 0, 30)
            PlayerButton.Position = UDim2.new(0, 4, 0, yOffset)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayerButton.Font = Enum.Font.SourceSans
            PlayerButton.TextSize = 16

            -- Thêm hình ảnh avatar player
            local PlayerImage = Instance.new("ImageLabel")
            PlayerImage.Parent = PlayerButton
            PlayerImage.Size = UDim2.new(0, 30, 0, 30)
            PlayerImage.Position = UDim2.new(0, 0, 0, 0)
            PlayerImage.Image = "https://www.roblox.com/bust-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            PlayerImage.BackgroundTransparency = 1

            -- Nút View
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 50, 1, 0)
            ViewButton.Position = UDim2.new(0.65, 0, 0, 0)
            ViewButton.Text = "View"
            ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
            ViewButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ViewButton.Font = Enum.Font.SourceSans
            ViewButton.TextSize = 14

            -- Xử lý nút View
            ViewButton.MouseButton1Click:Connect(function()
                if Camera.CameraSubject == player.Character:FindFirstChild("Humanoid") then
                    -- Tắt chế độ xem nếu đã đang xem
                    Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
                else
                    -- Chuyển sang xem player mới
                    Camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                end
            end)

            -- Nút Dịch Chuyển (Teleport)
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 50, 1, 0)
            TeleportButton.Position = UDim2.new(0.85, 0, 0, 0)
            TeleportButton.Text = "TP"
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
            TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TeleportButton.Font = Enum.Font.SourceSans
            TeleportButton.TextSize = 14

            -- Xử lý dịch chuyển
            TeleportButton.MouseButton1Click:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                    end
                end
            end)

            yOffset = yOffset + 35

            -- Kiểm tra xem có phải cần nút cuộn lên hoặc cuộn xuống
            if yOffset > 30 then
                showScrollUp = true
            end
            if yOffset > 200 then
                showScrollDown = true
            end
        end
    end

    -- Cập nhật kích thước canvas
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- Hiển thị các nút cuộn lên và cuộn xuống nếu cần
    ScrollButtonUp.Visible = showScrollUp
    ScrollButtonDown.Visible = showScrollDown
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý cuộn lên
ScrollButtonUp.MouseButton1Click:Connect(function()
    PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, -50)
end)

-- Xử lý cuộn xuống
ScrollButtonDown.MouseButton1Click:Connect(function()
    PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 50)
end)
