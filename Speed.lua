 -- Variabel untuk menyimpan kecepatan
local speed = 65
local speedEnabled = true
local guiVisible = true
 
-- Fungsi untuk mengatur kecepatan
local function setSpeed(newSpeed)
    speed = newSpeed
    if speedEnabled then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    end
end
 
-- GUI Elements
local screenGui = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local titleFrame = Instance.new("Frame")
local titleLabel = Instance.new("TextLabel")
local speedLabel = Instance.new("TextLabel")
local toggleButton = Instance.new("TextButton")
local increaseButton = Instance.new("TextButton")
local decreaseButton = Instance.new("TextButton")
local closeButton = Instance.new("TextButton")
local minimizeButton = Instance.new("TextButton")
 
-- Parent GUI to Player's PlayerGui
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false  -- Menetapkan ResetOnSpawn ke false
 
-- Configure Main Frame
mainFrame.Size = UDim2.new(0, 200, 0, 130)
mainFrame.Position = UDim2.new(0.5, -100, 0, 50)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
mainFrame.ClipsDescendants = true  -- Menyembunyikan elemen yang keluar dari batas bingkai
 
-- Add shadow to main frame
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.Image = "rbxassetid://1316045217"  -- ID gambar bayangan
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.BackgroundTransparency = 1
shadow.ZIndex = 0
shadow.Parent = mainFrame
 
-- Configure Title Frame
titleFrame.Size = UDim2.new(1, 0, 0, 30)
titleFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
titleFrame.BackgroundTransparency = 0.3
titleFrame.BorderSizePixel = 0
titleFrame.Parent = mainFrame
 
-- Configure Title Label
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "Speed Hack"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18  -- Mengatur ukuran teks menjadi lebih kecil
titleLabel.Parent = titleFrame
 
-- Configure Close Button
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleFrame
 
-- Configure Minimize Button
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -50, 0, 5)
minimizeButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextScaled = true
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = titleFrame
 
-- Configure Speed Label
speedLabel.Size = UDim2.new(0, 180, 0, 30)
speedLabel.Position = UDim2.new(0.5, -90, 0, 40)
speedLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
speedLabel.BackgroundTransparency = 0.3
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextScaled = true
speedLabel.Text = "Speed: " .. speed
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = mainFrame
 
-- Configure Toggle Button
toggleButton.Size = UDim2.new(0, 60, 0, 30)
toggleButton.Position = UDim2.new(0.5, -30, 0, 80)
toggleButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
toggleButton.BackgroundTransparency = 0.3
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Text = "On"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame
 
-- Configure Increase Button
increaseButton.Size = UDim2.new(0, 30, 0, 30)
increaseButton.Position = UDim2.new(0.75, -15, 0, 80)
increaseButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
increaseButton.BackgroundTransparency = 0.3
increaseButton.TextColor3 = Color3.new(1, 1, 1)
increaseButton.TextScaled = true
increaseButton.Text = ">"
increaseButton.Font = Enum.Font.GothamBold
increaseButton.Parent = mainFrame
 
-- Configure Decrease Button
decreaseButton.Size = UDim2.new(0, 30, 0, 30)
decreaseButton.Position = UDim2.new(0.25, -15, 0, 80)
decreaseButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
decreaseButton.BackgroundTransparency = 0.3
decreaseButton.TextColor3 = Color3.new(1, 1, 1)
decreaseButton.TextScaled = true
decreaseButton.Text = "<"
decreaseButton.Font = Enum.Font.GothamBold
decreaseButton.Parent = mainFrame
 
-- Function to update player's speed
local function updateSpeed()
    if speedEnabled then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
    else
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
    speedLabel.Text = "Speed: " .. speed
end
 
-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    toggleButton.Text = speedEnabled and "On" or "Off"
    updateSpeed()
end)
 
-- Increase speed functionality
increaseButton.MouseButton1Click:Connect(function()
    speed = speed + 5
    updateSpeed()
end)
 
-- Decrease speed functionality
decreaseButton.MouseButton1Click:Connect(function()
    speed = speed - 5
    updateSpeed()
end)
 
-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    setSpeed(16)  -- Mengatur kecepatan kembali ke normal (16)
    speedEnabled = true  -- Mengaktifkan kembali kecepatan
    toggleButton.Text = "On"  -- Mengatur teks tombol toggle kembali menjadi "On"
    updateSpeed()
    screenGui:Destroy()  -- Menutup GUI
end)
 
-- Minimize button functionality
minimizeButton.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    for _, element in pairs(mainFrame:GetChildren()) do
        if element ~= titleFrame then
            element.Visible = guiVisible
        end
    end
    mainFrame.Size = guiVisible and UDim2.new(0, 200, 0, 130) or UDim2.new(0, 200, 0, 30)
end)
 
-- Initial speed setup
updateSpeed()
 
-- Make the GUI draggable on mobile
local dragging = false
local dragInput
local dragStart
local startPos
 
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
 
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
 
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
 
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
 
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        update(input)
    end
end)
