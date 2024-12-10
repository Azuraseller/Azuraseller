-- Khai báo các biến cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- GUI: Player List
local PlayerListFrame = Instance.new("Frame")
local ScrollButtonToggle = Instance.new("TextButton")
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

-- Nút toggle cuộn danh sách
ScrollButtonToggle.Parent = ScreenGui
ScrollButtonToggle.Size = UDim2.new(0, 30, 0, 30)
ScrollButtonToggle.Position = UDim2.new(0.6, 0, 0.06, 0) -- Di chuyển sang trái
ScrollButtonToggle.Text = "⇕"
ScrollButtonToggle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ScrollButtonToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ScrollButtonToggle.Font = Enum.Font.SourceSans
ScrollButtonToggle.TextSize = 18

-- Khung cuộn danh sách người chơi
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 30)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Biến để theo dõi player đang được view
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

            -- Nút View
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(0.65, 0, 0, 0) -- Sắp xếp để tránh trùng
            ViewButton.Text = ""
            ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255) -- Xanh dương mặc định
            ViewButton.MouseButton1Click:Connect(function()
                if currentViewedPlayer == player then
                    -- Nếu player đang được view, tắt view
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
                    currentViewedPlayer = nil
                else
                    -- View player mới
                    if currentViewedPlayer then
                        -- Tắt view player trước đó
                        local previousButton = PlayerListScrollingFrame:FindFirstChild(currentViewedPlayer.Name)
                        if previousButton and previousButton:FindFirstChild("ViewButton") then
                            previousButton.ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
                        end
                    end
                    Camera.CameraSubject = player.Character.Humanoid
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá khi đang view
                    currentViewedPlayer = player
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
            TeleportButton.Position = UDim2.new(0.8, 0, 0, 0) -- Sắp xếp để tránh trùng
            TeleportButton.Text = ""
            TeleportButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128) -- Tím
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

-- Xử lý toggle cuộn danh sách
local isExpanded = false
ScrollButtonToggle.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    if isExpanded then
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 200)
    else
        PlayerListFrame.Size = UDim2.new(0, 150, 0, 0)
    end
end)
