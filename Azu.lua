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
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(0.6, -35, 0, 0) -- Khoảng cách cho nút đầu tiên
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ mặc định
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

            -- Góc bo tròn cho nút View
            local ViewCorner = Instance.new("UICorner")
            ViewCorner.CornerRadius = UDim.new(1, 0)
            ViewCorner.Parent = ViewButton

            -- Nút Teleport
            local TeleportButton = Instance.new("TextButton")
            TeleportButton.Parent = PlayerButton
            TeleportButton.Size = UDim2.new(0, 30, 0, 30)
            TeleportButton.Position = UDim2.new(0.75, -10, 0, 0) -- Khoảng cách tránh bấm nhầm
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- Tím
            TeleportButton.MouseButton1Click:Connect(function()
                if currentViewedPlayer == player then
                    -- Tắt view nếu đang view player này
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    currentViewedPlayer = nil
                    currentViewedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
                    currentViewedButton = nil
                end
                -- Dịch chuyển tới player
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
