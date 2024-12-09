local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo danh sách Player List
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 0)
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.2, 0) -- Chuyển sang khung màu xanh dương
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

-- Khung cuộn danh sách người chơi
local PlayerListScrollingFrame = Instance.new("ScrollingFrame")
PlayerListScrollingFrame.Parent = PlayerListFrame
PlayerListScrollingFrame.Size = UDim2.new(1, 0, 1, -30)
PlayerListScrollingFrame.Position = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListScrollingFrame.BackgroundTransparency = 1
PlayerListScrollingFrame.ScrollBarThickness = 8

-- Biến để lưu trạng thái View hiện tại
local currentViewingPlayer = nil

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

            -- Nút View
            local ViewButton = Instance.new("TextButton")
            ViewButton.Parent = PlayerButton
            ViewButton.Size = UDim2.new(0, 50, 1, 0)
            ViewButton.Position = UDim2.new(0.65, 0, 0, 0) -- Sang bên phải một chút
            ViewButton.Text = "View"
            ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
            ViewButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ViewButton.Font = Enum.Font.SourceSans
            ViewButton.TextSize = 14

            -- Xử lý nút View
            ViewButton.MouseButton1Click:Connect(function()
                if currentViewingPlayer == player then
                    -- Nếu đã đang xem player, tắt chế độ xem
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                    currentViewingPlayer = nil
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
                else
                    -- Nếu đang xem người khác, cập nhật
                    if currentViewingPlayer then
                        -- Đổi nút View trước đó thành màu đỏ
                        local previousButton = PlayerListScrollingFrame:FindFirstChild(currentViewingPlayer.Name)
                        if previousButton then
                            previousButton.ViewButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        end
                    end
                    -- Xem người chơi hiện tại
                    Camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                    currentViewingPlayer = player
                    ViewButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh lá
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
        end
    end

    -- Cập nhật kích thước canvas
    PlayerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Cập nhật danh sách khi có thay đổi
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)
UpdatePlayerList()

-- Xử lý cuộn lên
ScrollButtonUp.MouseButton1Click:Connect(function()
    PlayerListFrame.Size = UDim2.new(0, 200, 0, 0)
    ScrollButtonUp.Visible = false
end)
