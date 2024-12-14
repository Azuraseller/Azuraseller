local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Nút Menu
local MenuButton = Instance.new("ImageButton")
MenuButton.Size = UDim2.new(0, 100, 0, 50)
MenuButton.Position = UDim2.new(0.8, 0, 0.01, 0)
MenuButton.Image = "https://tr.rbxcdn.com/180DAY-487408766a264fb59c672611aefab053/150/150/Decal/Webp/noFilter"
MenuButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Parent = ScreenGui

-- Nút Server
local ServerButton = Instance.new("TextButton")
ServerButton.Size = UDim2.new(0, 100, 0, 50)
ServerButton.Position = UDim2.new(0.7, 0, 0.01, 0)
ServerButton.Text = "Server"
ServerButton.Visible = false
ServerButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
ServerButton.Parent = ScreenGui

-- Nút Player List
local PlayerListButton = Instance.new("ImageButton")
PlayerListButton.Size = UDim2.new(0, 100, 0, 50)
PlayerListButton.Position = UDim2.new(0.6, 0, 0.01, 0)
PlayerListButton.Image = "https://tr.rbxcdn.com/180DAY-1ab84aa5d75936fdc4979f5fe2552201/150/150/Decal/Webp/noFilter"
PlayerListButton.Visible = false
PlayerListButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlayerListButton.Parent = ScreenGui

-- Danh sách Player
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(0, 200, 0, 300)
PlayerListFrame.Position = UDim2.new(0.6, 0, 0.1, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlayerListFrame.Visible = false
PlayerListFrame.Parent = ScreenGui

-- Hàm cập nhật danh sách Player
local function UpdatePlayerList()
    PlayerListFrame:ClearAllChildren()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerButton = Instance.new("TextButton")
            PlayerButton.Size = UDim2.new(1, 0, 0, 30)
            PlayerButton.Text = player.Name
            PlayerButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            PlayerButton.Parent = PlayerListFrame

            -- Nút View và Tele
            local ViewButton = Instance.new("ImageButton")
            ViewButton.Size = UDim2.new(0, 30, 0, 30)
            ViewButton.Position = UDim2.new(0.8, 0, 0, 0)
            ViewButton.Image = "https://tr.rbxcdn.com/180DAY-627fcde344353147a79a01ce0c242710/150/150/Decal/Webp/noFilter"
            ViewButton.Parent = PlayerButton

            local TeleButton = Instance.new("ImageButton")
            TeleButton.Size = UDim2.new(0, 30, 0, 30)
            TeleButton.Position = UDim2.new(0.9, 0, 0, 0)
            TeleButton.Image = "https://tr.rbxcdn.com/180DAY-d8afcf12ffb0e5cce3c7fa80e5bc610c/150/150/Decal/Webp/noFilter"
            TeleButton.Parent = PlayerButton

            -- Logic cho View và Tele
            local isViewing = false
            ViewButton.MouseButton1Click:Connect(function()
                isViewing = not isViewing
                if isViewing then
                    ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
                    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                else
                    ViewButton.Image = "https://tr.rbxcdn.com/180DAY-627fcde344353147a79a01ce0c242710/150/150/Decal/Webp/noFilter"
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end)

            TeleButton.MouseButton1Click:Connect(function()
                if isViewing then
                    ViewButton.Image = "https://tr.rbxcdn.com/180DAY-627fcde344353147a79a01ce0c242710/150/150/Decal/Webp/noFilter"
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
                    isViewing = false
                end
                LocalPlayer.Character:MoveTo(player.Character.HumanoidRootPart.Position)
            end)

            -- Xóa nút nếu Player rời khỏi
            player.AncestryChanged:Connect(function()
                if not player:IsDescendantOf(game) then
                    PlayerButton:Destroy()
                end
            end)
        end
    end
end

-- Hiển thị Menu
local isMenuOpen = false
MenuButton.MouseButton1Click:Connect(function()
    isMenuOpen = not isMenuOpen
    ServerButton.Visible = isMenuOpen
    PlayerListButton.Visible = isMenuOpen
end)

-- Hiển thị danh sách Player
local isPlayerListOpen = false
PlayerListButton.MouseButton1Click:Connect(function()
    isPlayerListOpen = not isPlayerListOpen
    PlayerListFrame.Visible = isPlayerListOpen
    if isPlayerListOpen then
        UpdatePlayerList()
    end
end)

-- Chuyển Server
ServerButton.MouseButton1Click:Connect(function()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    TeleportService:Teleport(placeId)
end)
