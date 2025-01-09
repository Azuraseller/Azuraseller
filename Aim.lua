-- Script Aimbot với GUI tùy chỉnh
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotGUI"

-- Nút Menu chính
local menuButton = Instance.new("TextButton", screenGui)
menuButton.Size = UDim2.new(0, 50, 0, 50)
menuButton.Position = UDim2.new(0, 10, 0, 10)
menuButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
menuButton.Text = "⚙️"
menuButton.Font = Enum.Font.SourceSansBold
menuButton.TextSize = 24
menuButton.BorderSizePixel = 2

-- Khung trượt
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Size = UDim2.new(0, 200, 0, 300)
menuFrame.Position = UDim2.new(0, -200, 0, 10)
menuFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
menuFrame.Visible = false

-- Hiệu ứng trượt
local function slideMenu()
    if menuFrame.Visible then
        menuFrame.Visible = false
        menuFrame:TweenPosition(UDim2.new(0, -200, 0, 10), "Out", "Quad", 0.5, true)
    else
        menuFrame.Visible = true
        menuFrame:TweenPosition(UDim2.new(0, 10, 0, 10), "Out", "Quad", 0.5, true)
    end
end

menuButton.MouseButton1Click:Connect(slideMenu)

-- Biểu tượng ⚙️ (trong menu)
local settingsIcon = Instance.new("TextLabel", menuFrame)
settingsIcon.Size = UDim2.new(0, 50, 0, 50)
settingsIcon.Position = UDim2.new(0, 10, 0, 10)
settingsIcon.Text = "⚙️"
settingsIcon.Font = Enum.Font.SourceSansBold
settingsIcon.TextSize = 24
settingsIcon.BackgroundTransparency = 1

-- Biểu tượng i (thông tin người làm script)
local infoButton = Instance.new("TextButton", menuFrame)
infoButton.Size = UDim2.new(0, 30, 0, 30)
infoButton.Position = UDim2.new(0, 70, 0, 20)
infoButton.Text = "i"
infoButton.Font = Enum.Font.SourceSans
infoButton.TextSize = 20
infoButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

infoButton.MouseButton1Click:Connect(function()
    local infoFrame = Instance.new("Frame", screenGui)
    infoFrame.Size = UDim2.new(0, 300, 0, 100)
    infoFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    infoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    infoFrame.BorderSizePixel = 2

    local infoText = Instance.new("TextLabel", infoFrame)
    infoText.Size = UDim2.new(1, 0, 1, 0)
    infoText.Text = "Script made by [Your Name Here]"
    infoText.Font = Enum.Font.SourceSans
    infoText.TextSize = 20
    infoText.TextColor3 = Color3.fromRGB(0, 0, 0)
    infoText.BackgroundTransparency = 1

    wait(3)
    infoFrame:Destroy()
end)

-- Nút 🎯 (chỉnh tâm)
local aimButton = Instance.new("TextButton", menuFrame)
aimButton.Size = UDim2.new(0, 50, 0, 50)
aimButton.Position = UDim2.new(0, 10, 0, 70)
aimButton.Text = "🎯"
aimButton.Font = Enum.Font.SourceSansBold
aimButton.TextSize = 24
aimButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

-- Thêm các nút X, Y, Z
local function createAxisButton(axis, posY)
    local button = Instance.new("TextButton", menuFrame)
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = UDim2.new(0, 10, 0, posY)
    button.Text = axis .. ": 1"
    button.Font = Enum.Font.SourceSans
    button.TextSize = 20
    button.BackgroundColor3 = Color3.fromRGB(220, 220, 220)

    local value = 1
    button.MouseButton1Click:Connect(function()
        value = value + 1
        if value > 5 then value = 1 end
        button.Text = axis .. ": " .. value
    end)
end

createAxisButton("X", 130)
createAxisButton("Y", 170)
createAxisButton("Z", 210)

-- Script Aimbot hoàn chỉnh với GUI
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotGUI"

-- Nút Menu chính
local menuButton = Instance.new("TextButton", screenGui)
menuButton.Size = UDim2.new(0, 50, 0, 50)
menuButton.Position = UDim2.new(0, 10, 0, 10)
menuButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
menuButton.Text = "⚙️"
menuButton.Font = Enum.Font.SourceSansBold
menuButton.TextSize = 24
menuButton.BorderSizePixel = 2

-- Khung trượt
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Size = UDim2.new(0, 250, 0, 400)
menuFrame.Position = UDim2.new(0, -250, 0, 10)
menuFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
menuFrame.Visible = false

-- Hiệu ứng trượt
local function slideMenu()
    if menuFrame.Visible then
        menuFrame.Visible = false
        menuFrame:TweenPosition(UDim2.new(0, -250, 0, 10), "Out", "Quad", 0.5, true)
    else
        menuFrame.Visible = true
        menuFrame:TweenPosition(UDim2.new(0, 10, 0, 10), "Out", "Quad", 0.5, true)
    end
end

menuButton.MouseButton1Click:Connect(slideMenu)

-- Biểu tượng ⚙️ (trong menu)
local settingsIcon = Instance.new("TextLabel", menuFrame)
settingsIcon.Size = UDim2.new(0, 50, 0, 50)
settingsIcon.Position = UDim2.new(0, 10, 0, 10)
settingsIcon.Text = "⚙️"
settingsIcon.Font = Enum.Font.SourceSansBold
settingsIcon.TextSize = 24
settingsIcon.BackgroundTransparency = 1

-- Biểu tượng i (thông tin người làm script)
local infoButton = Instance.new("TextButton", menuFrame)
infoButton.Size = UDim2.new(0, 30, 0, 30)
infoButton.Position = UDim2.new(0, 70, 0, 20)
infoButton.Text = "i"
infoButton.Font = Enum.Font.SourceSans
infoButton.TextSize = 20
infoButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

infoButton.MouseButton1Click:Connect(function()
    local infoFrame = Instance.new("Frame", screenGui)
    infoFrame.Size = UDim2.new(0, 300, 0, 100)
    infoFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    infoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    infoFrame.BorderSizePixel = 2

    local infoText = Instance.new("TextLabel", infoFrame)
    infoText.Size = UDim2.new(1, 0, 1, 0)
    infoText.Text = "Script made by [Your Name Here]"
    infoText.Font = Enum.Font.SourceSans
    infoText.TextSize = 20
    infoText.TextColor3 = Color3.fromRGB(0, 0, 0)
    infoText.BackgroundTransparency = 1

    wait(3)
    infoFrame:Destroy()
end)

-- Nút 🎯 (chỉnh tâm)
local aimButton = Instance.new("TextButton", menuFrame)
aimButton.Size = UDim2.new(0, 50, 0, 50)
aimButton.Position = UDim2.new(0, 10, 0, 70)
aimButton.Text = "🎯"
aimButton.Font = Enum.Font.SourceSansBold
aimButton.TextSize = 24
aimButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

-- Chức năng chỉnh X, Y, Z
local function createAxisButton(axis, posY)
    local button = Instance.new("TextButton", menuFrame)
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = UDim2.new(0, 10, 0, posY)
    button.Text = axis .. ": 1"
    button.Font = Enum.Font.SourceSans
    button.TextSize = 20
    button.BackgroundColor3 = Color3.fromRGB(220, 220, 220)

    local value = 1
    button.MouseButton1Click:Connect(function()
        value = value + 1
        if value > 5 then value = 1 end
        button.Text = axis .. ": " .. value
    end)
end

createAxisButton("X", 130)
createAxisButton("Y", 170)
createAxisButton("Z", 210)

-- Nút chức năng khác (POV, tia sáng, Aim chỉnh)
local povButton = Instance.new("TextButton", menuFrame)
povButton.Size = UDim2.new(0, 200, 0, 30)
povButton.Position = UDim2.new(0, 10, 0, 250)
povButton.Text = "POV: OFF"
povButton.Font = Enum.Font.SourceSans
povButton.TextSize = 20
povButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

local povEnabled = false
povButton.MouseButton1Click:Connect(function()
    povEnabled = not povEnabled
    povButton.Text = "POV: " .. (povEnabled and "ON" or "OFF")
end)

-- Tính năng Auto Aim và các tự động điều chỉnh khác
-- Thêm logic tại đây...
