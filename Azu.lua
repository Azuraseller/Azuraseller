local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tạo GUI chính
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(0, 250, 0, 400)
playerListFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
playerListFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
playerListFrame.BackgroundTransparency = 0.5
playerListFrame.Parent = ScreenGui

-- Tạo nút cuộn xuống và cuộn lên
local scrollDownButton = Instance.new("TextButton")
scrollDownButton.Size = UDim2.new(0, 30, 0, 30)
scrollDownButton.Position = UDim2.new(0.5, -15, 1, -40)
scrollDownButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
scrollDownButton.Text = "↓"
scrollDownButton.Parent = playerListFrame

local scrollUpButton = Instance.new("TextButton")
scrollUpButton.Size = UDim2.new(0, 30, 0, 30)
scrollUpButton.Position = UDim2.new(0.5, -15, 0, 10)
scrollUpButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
scrollUpButton.Text = "↑"
scrollUpButton.Parent = playerListFrame
scrollUpButton.Visible = false

-- Danh sách người chơi
local playerList = Instance.new("UIListLayout")
playerList.SortOrder = Enum.SortOrder.LayoutOrder
playerList.Parent = playerListFrame

-- Chức năng cuộn
local isScrollingDown = false

scrollDownButton.MouseButton1Click:Connect(function()
    if not isScrollingDown then
        isScrollingDown = true
        scrollUpButton.Visible = true
        scrollDownButton.Text = "↑"
        scrollUpButton.Position = UDim2.new(0.5, -15, 0, playerListFrame.Size.Y.Offset - 30)
    else
        isScrollingDown = false
        scrollUpButton.Visible = false
        scrollDownButton.Text = "↓"
    end
end)

scrollUpButton.MouseButton1Click:Connect(function()
    scrollUpButton.Visible = false
    scrollDownButton.Text = "↓"
    isScrollingDown = false
end)

-- Tạo danh sách player
local function createPlayerEntry(player)
    local playerFrame = Instance.new("Frame")
    playerFrame.Size = UDim2.new(1, 0, 0, 50)
    playerFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    playerFrame.Parent = playerListFrame

    local playerName = Instance.new("TextLabel")
    playerName.Size = UDim2.new(0.7, 0, 1, 0)
    playerName.Text = player.Name
    playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerName.BackgroundTransparency = 1
    playerName.Parent = playerFrame

    local cameraButton = Instance.new("TextButton")
    cameraButton.Size = UDim2.new(0, 30, 0, 30)
    cameraButton.Position = UDim2.new(0.7, 5, 0.5, -15)
    cameraButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ
    cameraButton.Text = ""
    cameraButton.Shape = Enum.ButtonStyle.Rounded
    cameraButton.Parent = playerFrame

    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(0, 30, 0, 30)
    teleportButton.Position = UDim2.new(0.8, 5, 0.5, -15)
    teleportButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255) -- Màu xanh dương
    teleportButton.Text = ""
    teleportButton.Shape = Enum.ButtonStyle.Rounded
    teleportButton.Parent = playerFrame

    local isViewing = false

    -- Xử lý camera view
    cameraButton.MouseButton1Click:Connect(function()
        if isViewing then
            cameraButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ (Tắt)
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
            isViewing = false
        else
            cameraButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá (Bật)
            Camera.CameraSubject = player.Character.Humanoid
            isViewing = true
        end
    end)

    -- Xử lý dịch chuyển tới player
    teleportButton.MouseButton1Click:Connect(function()
        LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
    end)
end

-- Tạo danh sách player trong game
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createPlayerEntry(player)
    end
end

-- Cập nhật danh sách khi có player mới vào game
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createPlayerEntry(player)
    end
end)
