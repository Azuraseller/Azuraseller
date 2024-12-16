local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui", CoreGui)

-- Tạo các nút Menu, Server Hop và Player List
local MenuButton = Instance.new("TextButton")
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.74, 0, 0.01, 0)
MenuButton.Text = "≡"
MenuButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18

local ServerButton = Instance.new("TextButton")
ServerButton.Parent = ScreenGui
ServerButton.Size = UDim2.new(0, 30, 0, 30)
ServerButton.Position = UDim2.new(0.69, 0, 0.01, 0)
ServerButton.Text = "Server"
ServerButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
ServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerButton.Font = Enum.Font.SourceSans
ServerButton.TextSize = 18
ServerButton.Visible = false

local PlayerListButton = Instance.new("TextButton")
PlayerListButton.Parent = ScreenGui
PlayerListButton.Size = UDim2.new(0, 30, 0, 30)
PlayerListButton.Position = UDim2.new(0.64, 0, 0.01, 0)
PlayerListButton.Text = "Players"
PlayerListButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
PlayerListButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerListButton.Font = Enum.Font.SourceSans
PlayerListButton.TextSize = 18
PlayerListButton.Visible = false

local YesButton = Instance.new("TextButton")
YesButton.Parent = ScreenGui
YesButton.Size = UDim2.new(0, 50, 0, 30)
YesButton.Position = UDim2.new(0.69, 0, 0.07, 0)
YesButton.Text = "Yes"
YesButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
YesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
YesButton.Font = Enum.Font.SourceSans
YesButton.TextSize = 18
YesButton.Visible = false

local NoButton = Instance.new("TextButton")
NoButton.Parent = ScreenGui
NoButton.Size = UDim2.new(0, 50, 0, 30)
NoButton.Position = UDim2.new(0.69, 0, 0.13, 0)
NoButton.Text = "No"
NoButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
NoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoButton.Font = Enum.Font.SourceSans
NoButton.TextSize = 18
NoButton.Visible = false

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 400)
PlayerListFrame.Position = UDim2.new(0.69, 0, 0.07, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlayerListFrame.Visible = false
PlayerListFrame.ScrollBarThickness = 10

local function ToggleMenu()
    -- Trượt các nút vào/ra
    local serverButtonPos = ServerButton.Position
    local playerListButtonPos = PlayerListButton.Position
    local menuButtonPos = MenuButton.Position

    if ServerButton.Visible then
        ServerButton.Visible = false
        PlayerListButton.Visible = false
    else
        ServerButton.Visible = true
        PlayerListButton.Visible = true
    end
end

-- Khi bấm nút Menu, hiển thị server hop và player list
MenuButton.MouseButton1Click:Connect(function()
    ToggleMenu()
end)

-- Chức năng chuyển server
ServerButton.MouseButton1Click:Connect(function()
    YesButton.Visible = true
    NoButton.Visible = true

    YesButton.MouseButton1Click:Connect(function()
        -- Chuyển server
        local server = game:GetService("TeleportService")
        server:Teleport(game.PlaceId, LocalPlayer) -- Chuyển server
    end)

    NoButton.MouseButton1Click:Connect(function()
        YesButton.Visible = false
        NoButton.Visible = false
    end)
end)

-- Hiển thị danh sách người chơi
PlayerListButton.MouseButton1Click:Connect(function()
    if PlayerListFrame.Visible then
        PlayerListFrame.Visible = false
    else
        PlayerListFrame.Visible = true
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerNameLabel = Instance.new("TextLabel")
                playerNameLabel.Text = player.Name
                playerNameLabel.Size = UDim2.new(0, 200, 0, 50)
                playerNameLabel.Parent = PlayerListFrame

                local viewButton = Instance.new("TextButton")
                viewButton.Text = "View"
                viewButton.Size = UDim2.new(0, 50, 0, 30)
                viewButton.Position = UDim2.new(0.5, 0, 0, 0)
                viewButton.Parent = playerNameLabel

                local teleButton = Instance.new("TextButton")
                teleButton.Text = "Tele"
                teleButton.Size = UDim2.new(0, 50, 0, 30)
                teleButton.Position = UDim2.new(1, -50, 0, 0)
                teleButton.Parent = playerNameLabel

                viewButton.MouseButton1Click:Connect(function()
                    -- Chức năng xem camera player
                    Camera.CameraSubject = player.Character.Humanoid
                end)

                teleButton.MouseButton1Click:Connect(function()
                    -- Dịch chuyển tới player
                    LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
                end)
            end
        end
    end
end)

-- Xử lý khi player ra khỏi game
Players.PlayerRemoving:Connect(function(player)
    for _, playerNameLabel in ipairs(PlayerListFrame:GetChildren()) do
        if playerNameLabel:IsA("TextLabel") and playerNameLabel.Text == player.Name then
            playerNameLabel:Destroy()
        end
    end
end)
