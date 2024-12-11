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

-- Biến để theo dõi player đang được chọn
local currentViewedPlayer = nil
local currentSelectedButton = nil

-- Hiển thị danh sách người chơi
local function UpdatePlayerList()
    -- Xóa hết các nút hiện tại
    for _, child in ipairs(PlayerListScrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
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

            -- Tạo góc bo tròn cho button
            local UICorner = Instance.new("UICorner")
            UICorner.Parent = PlayerButton

            -- Các nút View và Teleport
            local ViewButton = Instance.new("ImageButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(1, 0, 0, 0)  -- Nút View sẽ nằm ngay sau tên player
            ViewButton.Image = "rbxassetid://6035047380"  -- Biểu tượng con mắt
            ViewButton.BackgroundTransparency = 1
            ViewButton.Visible = false  -- Ẩn nút mặc định

            local TeleportButton = Instance.new("ImageButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 30, 0, 30)
            TeleportButton.Position = UDim2.new(1, 35, 0, 0)  -- Nút Teleport nằm cạnh nút View
            TeleportButton.Image = "rbxassetid://6035047390"  -- Biểu tượng dịch chuyển
            TeleportButton.BackgroundTransparency = 1
            TeleportButton.Visible = false  -- Ẩn nút mặc định

            -- Logic khi bấm vào tên người chơi
            PlayerButton.MouseButton1Click:Connect(function()
                -- Ẩn các nút trước đó
                if currentViewedPlayer then
                    currentViewedPlayer.ViewButton.Visible = false
                    currentViewedPlayer.TeleportButton.Visible = false
                end

                -- Hiển thị các nút cho người chơi hiện tại
                ViewButton.Visible = true
                TeleportButton.Visible = true

                -- Cập nhật player hiện tại đang xem
                currentViewedPlayer = {
                    player = player,
                    ViewButton = ViewButton,
                    TeleportButton = TeleportButton
                }

                -- Logic cho nút View
                local isViewing = false
                ViewButton.MouseButton1Click:Connect(function()
                    if isViewing then
                        -- Tắt view
                        Camera.CameraSubject = LocalPlayer.Character.Humanoid
                        isViewing = false
                    else
                        -- Chuyển view
                        Camera.CameraSubject = player.Character.Humanoid
                        isViewing = true
                    end
                end)

                -- Logic cho nút Teleport
                TeleportButton.MouseButton1Click:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                    end
                end)
            end)

            yOffset = yOffset + 40  -- Điều chỉnh khoảng cách giữa các player
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
    rotation = rotation + 45
    ScrollButtonToggle.Rotation = rotation
end)
