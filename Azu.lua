local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui

-- Nút Menu
local MenuButton = Instance.new("ImageButton")
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.75, 0, 0.01, 0)
MenuButton.Image = "https://tr.rbxcdn.com/180DAY-487408766a264fb59c672611aefab053/150/150/Decal/Webp/noFilter"
MenuButton.BackgroundTransparency = 1

-- Nút Server
local ServerButton = Instance.new("TextButton")
ServerButton.Parent = ScreenGui
ServerButton.Size = UDim2.new(0, 100, 0, 50)
ServerButton.Position = UDim2.new(0.75, 0, 0.07, 0)
ServerButton.Text = "Server"
ServerButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerButton.Font = Enum.Font.SourceSans
ServerButton.TextSize = 20
ServerButton.Visible = false

-- Nút Player List
local PlayerListButton = Instance.new("ImageButton")
PlayerListButton.Parent = ScreenGui
PlayerListButton.Size = UDim2.new(0, 30, 0, 30)
PlayerListButton.Position = UDim2.new(0.75, 0, 0.14, 0)
PlayerListButton.Image = "https://tr.rbxcdn.com/180DAY-1ab84aa5d75936fdc4979f5fe2552201/150/150/Decal/Webp/noFilter"
PlayerListButton.BackgroundTransparency = 1
PlayerListButton.Visible = false

-- Danh sách người chơi (hiện/ẩn khi bấm Player List)
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 200)
PlayerListFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.Visible = false

local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Parent = PlayerListFrame
PlayerListScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 500)
PlayerListScroll.ScrollBarThickness = 10

-- Nút View và Tele
local ViewButton = Instance.new("ImageButton")
ViewButton.Parent = ScreenGui
ViewButton.Size = UDim2.new(0, 30, 0, 30)
ViewButton.Position = UDim2.new(0.75, 0, 0.2, 0)
ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
ViewButton.BackgroundTransparency = 1
ViewButton.Visible = false

local TeleButton = Instance.new("ImageButton")
TeleButton.Parent = ScreenGui
TeleButton.Size = UDim2.new(0, 30, 0, 30)
TeleButton.Position = UDim2.new(0.75, 0, 0.26, 0)
TeleButton.Image = "https://tr.rbxcdn.com/180DAY-d8afcf12ffb0e5cce3c7fa80e5bc610c/150/150/Decal/Webp/noFilter"
TeleButton.BackgroundTransparency = 1
TeleButton.Visible = false

-- Biến lưu trữ player đã chọn
local SelectedPlayer = nil
local PlayerButtons = {}  -- Lưu trữ các nút player

-- Cập nhật danh sách người chơi
local function UpdatePlayerList()
    -- Xóa tất cả các nút player cũ
    for _, child in ipairs(PlayerListScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Tạo nút cho mỗi player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerButton = Instance.new("TextButton")
            playerButton.Parent = PlayerListScroll
            playerButton.Size = UDim2.new(1, 0, 0, 30)
            playerButton.Text = player.Name
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            playerButton.TextSize = 18
            playerButton.MouseButton1Click:Connect(function()
                if SelectedPlayer then
                    -- Ẩn các nút View và Tele trước đó
                    ViewButton.Visible = false
                    TeleButton.Visible = false
                end
                SelectedPlayer = player
                -- Hiển thị nút View và Tele cho player đã chọn
                ViewButton.Visible = true
                TeleButton.Visible = true
                -- Cập nhật nút View
                ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
            end)

            -- Lưu trữ nút player
            PlayerButtons[player.UserId] = playerButton
        end
    end
end

-- Xử lý khi player thoát
Players.PlayerRemoving:Connect(function(player)
    -- Xóa nút của player ra khỏi danh sách
    local playerButton = PlayerButtons[player.UserId]
    if playerButton then
        playerButton:Destroy()
        PlayerButtons[player.UserId] = nil
    end

    -- Nếu player bị chọn, ẩn các nút View và Tele
    if SelectedPlayer == player then
        ViewButton.Visible = false
        TeleButton.Visible = false
        SelectedPlayer = nil
    end
end)

-- Nút View: Xem camera của player
ViewButton.MouseButton1Click:Connect(function()
    if ViewButton.Image == "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter" then
        -- Chuyển sang chế độ xem camera của player
        Camera.CameraSubject = SelectedPlayer.Character.Humanoid
        ViewButton.Image = "https://tr.rbxcdn.com/180DAY-627fcde344353147a79a01ce0c242710/150/150/Decal/Webp/noFilter"
    else
        -- Quay lại camera của người chơi
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
        ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
    end
end)

-- Nút Tele: Teleport đến player
TeleButton.MouseButton1Click:Connect(function()
    if SelectedPlayer and SelectedPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(SelectedPlayer.Character.HumanoidRootPart.CFrame)
        -- Ẩn các nút sau khi teleport
        ViewButton.Visible = false
        TeleButton.Visible = false
    end
end)

-- Nút Player List: Khi nhấn sẽ hiển thị/ẩn danh sách người chơi
PlayerListButton.MouseButton1Click:Connect(function()
    if PlayerListFrame.Visible then
        PlayerListFrame.Visible = false
    else
        PlayerListFrame.Visible = true
        UpdatePlayerList()
    end
end)

-- Nút Menu: Khi nhấn sẽ hiện/ẩn menu
MenuButton.MouseButton1Click:Connect(function()
    if ServerButton.Visible then
        ServerButton.Visible = false
        PlayerListButton.Visible = false
    else
        ServerButton.Visible = true
        PlayerListButton.Visible = true
    end
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = CoreGui

-- Nút Menu
local MenuButton = Instance.new("ImageButton")
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.75, 0, 0.01, 0)
MenuButton.Image = "https://tr.rbxcdn.com/180DAY-487408766a264fb59c672611aefab053/150/150/Decal/Webp/noFilter"
MenuButton.BackgroundTransparency = 1

-- Nút Server
local ServerButton = Instance.new("TextButton")
ServerButton.Parent = ScreenGui
ServerButton.Size = UDim2.new(0, 100, 0, 50)
ServerButton.Position = UDim2.new(0.75, 0, 0.07, 0)
ServerButton.Text = "Server"
ServerButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerButton.Font = Enum.Font.SourceSans
ServerButton.TextSize = 20
ServerButton.Visible = false

-- Nút Player List
local PlayerListButton = Instance.new("ImageButton")
PlayerListButton.Parent = ScreenGui
PlayerListButton.Size = UDim2.new(0, 30, 0, 30)
PlayerListButton.Position = UDim2.new(0.75, 0, 0.14, 0)
PlayerListButton.Image = "https://tr.rbxcdn.com/180DAY-1ab84aa5d75936fdc4979f5fe2552201/150/150/Decal/Webp/noFilter"
PlayerListButton.BackgroundTransparency = 1
PlayerListButton.Visible = false

-- Danh sách người chơi (hiện/ẩn khi bấm Player List)
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Parent = ScreenGui
PlayerListFrame.Size = UDim2.new(0, 200, 0, 200)
PlayerListFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PlayerListFrame.Visible = false

local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Parent = PlayerListFrame
PlayerListScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 500)
PlayerListScroll.ScrollBarThickness = 10

-- Nút View và Tele
local ViewButton = Instance.new("ImageButton")
ViewButton.Parent = ScreenGui
ViewButton.Size = UDim2.new(0, 30, 0, 30)
ViewButton.Position = UDim2.new(0.75, 0, 0.2, 0)
ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
ViewButton.BackgroundTransparency = 1
ViewButton.Visible = false

local TeleButton = Instance.new("ImageButton")
TeleButton.Parent = ScreenGui
TeleButton.Size = UDim2.new(0, 30, 0, 30)
TeleButton.Position = UDim2.new(0.75, 0, 0.26, 0)
TeleButton.Image = "https://tr.rbxcdn.com/180DAY-d8afcf12ffb0e5cce3c7fa80e5bc610c/150/150/Decal/Webp/noFilter"
TeleButton.BackgroundTransparency = 1
TeleButton.Visible = false

-- Biến lưu trữ player đã chọn
local SelectedPlayer = nil
local PlayerButtons = {}  -- Lưu trữ các nút player

-- Cập nhật danh sách người chơi
local function UpdatePlayerList()
    -- Xóa tất cả các nút player cũ
    for _, child in ipairs(PlayerListScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Tạo nút cho mỗi player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerButton = Instance.new("TextButton")
            playerButton.Parent = PlayerListScroll
            playerButton.Size = UDim2.new(1, 0, 0, 30)
            playerButton.Text = player.Name
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            playerButton.TextSize = 18
            playerButton.MouseButton1Click:Connect(function()
                if SelectedPlayer then
                    -- Ẩn các nút View và Tele trước đó
                    ViewButton.Visible = false
                    TeleButton.Visible = false
                end
                SelectedPlayer = player
                -- Hiển thị nút View và Tele cho player đã chọn
                ViewButton.Visible = true
                TeleButton.Visible = true
                -- Cập nhật nút View
                ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
            end)

            -- Lưu trữ nút player
            PlayerButtons[player.UserId] = playerButton
        end
    end
end

-- Xử lý khi player thoát
Players.PlayerRemoving:Connect(function(player)
    -- Xóa nút của player ra khỏi danh sách
    local playerButton = PlayerButtons[player.UserId]
    if playerButton then
        playerButton:Destroy()
        PlayerButtons[player.UserId] = nil
    end

    -- Nếu player bị chọn, ẩn các nút View và Tele
    if SelectedPlayer == player then
        ViewButton.Visible = false
        TeleButton.Visible = false
        SelectedPlayer = nil
    end
end)

-- Nút View: Xem camera của player
ViewButton.MouseButton1Click:Connect(function()
    if ViewButton.Image == "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter" then
        -- Chuyển sang chế độ xem camera của player
        Camera.CameraSubject = SelectedPlayer.Character.Humanoid
        ViewButton.Image = "https://tr.rbxcdn.com/180DAY-627fcde344353147a79a01ce0c242710/150/150/Decal/Webp/noFilter"
    else
        -- Quay lại camera của người chơi
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
        ViewButton.Image = "https://tr.rbxcdn.com/180DAY-a47bbc253b252ca21d536740448961ff/150/150/Decal/Webp/noFilter"
    end
end)

-- Nút Tele: Teleport đến player
TeleButton.MouseButton1Click:Connect(function()
    if SelectedPlayer and SelectedPlayer.Character then
        LocalPlayer.Character:SetPrimaryPartCFrame(SelectedPlayer.Character.HumanoidRootPart.CFrame)
        -- Ẩn các nút sau khi teleport
        ViewButton.Visible = false
        TeleButton.Visible = false
    end
end)

-- Nút Player List: Khi nhấn sẽ hiển thị/ẩn danh sách người chơi
PlayerListButton.MouseButton1Click:Connect(function()
    if PlayerListFrame.Visible then
        PlayerListFrame.Visible = false
    else
        PlayerListFrame.Visible = true
        UpdatePlayerList()
    end
end)

-- Nút Menu: Khi nhấn sẽ hiện/ẩn menu
MenuButton.MouseButton1Click:Connect(function()
    if ServerButton.Visible then
        ServerButton.Visible = false
        PlayerListButton.Visible = false
    else
        ServerButton.Visible = true
        PlayerListButton.Visible = true
    end
end)

