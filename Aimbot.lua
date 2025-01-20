-- Get the required services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Create a new ScreenGui
local GUI = Instance.new("ScreenGui")
GUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create the main frame for the keyboard
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 60)
MainFrame.Position = UDim2.new(1, -210, 0.5, -30) -- Start off-screen
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Parent = GUI

-- Round the corners of the main frame
local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 10)
MainFrameCorner.Parent = MainFrame

-- Create the notification frame
local NotificationFrame = Instance.new("Frame")
NotificationFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
NotificationFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
NotificationFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Darker gray
NotificationFrame.Parent = MainFrame

-- Round the corners of the notification frame
local NotificationFrameCorner = Instance.new("UICorner")
NotificationFrameCorner.CornerRadius = UDim.new(0, 10)
NotificationFrameCorner.Parent = NotificationFrame

-- Create the text label
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0.9, 0, 0.7, 0)
TextLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
TextLabel.TextScaled = true
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Text = "Cracked By Ata"
TextLabel.Parent = NotificationFrame

-- Create the progress bar
local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0.9, 0, 0.1, 0)
ProgressBar.Position = UDim2.new(0.05, 0, 0.85, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
ProgressBar.Parent = NotificationFrame

-- Create the progress bar fill
local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(1, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange
ProgressBarFill.Parent = ProgressBar

-- Function to show the notification
local function ShowNotification()
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local endPosition = UDim2.new(0.01, 0, 0.95, -60)
    local tween = TweenService:Create(MainFrame, tweenInfo, { Position = endPosition })
    tween:Play()

    -- Start the progress bar countdown
    local countdownTime = 6 -- Countdown time in seconds
    local startTime = tick()

    while tick() - startTime < countdownTime do
        local elapsedTime = tick() - startTime
        local progress = 1 - (elapsedTime / countdownTime)
        ProgressBarFill:TweenSize(UDim2.new(progress, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.1, true)
        task.wait()
    end

    -- Hide the notification
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local startPosition = UDim2.new(0.01, 0, 0.95, -60)
    local endPosition = UDim2.new(-1, 0, 0.95, -60)
    local tween = TweenService:Create(MainFrame, tweenInfo, { Position = endPosition })
    tween:Play()
end

-- Trigger the notification
ShowNotification()

-- Create the virtual keyboard button sequence
local sequence = {"2", "C", "3", "X", "1", "Z", "2", "X", "1", "C", "X"}
local currentIndex = 1
local isHolding = false

-- Create the button frame
local button = Instance.new("TextButton")
button.Parent = GUI
button.Text = "2"
button.Size = UDim2.new(0, 100, 0, 50)
button.Position = UDim2.new(1, -110, 0.5, -25)  -- Đặt nút ở góc phải giữa
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 24
button.TextButtonStyle = Enum.ButtonStyle.Rounded

-- Update button text based on the sequence
local function updateButtonText()
    button.Text = sequence[currentIndex]
end

-- Function to perform action when button is pressed
local function performAction(key)
    if key == "1" then
        -- Chỉ thực hiện phím C sau 0.35 giây, rồi thực hiện phím X
        print("C pressed")
        wait(0.35)
        print("X pressed")
    elseif key == "2" then
        print("2 pressed")
    elseif key == "3" then
        print("3 pressed")
    elseif key == "C" then
        print("C pressed")
    elseif key == "X" then
        print("X pressed")
    elseif key == "Z" then
        print("Z pressed")
    end
end

-- Handle button press
local function onButtonPressed()
    if not isHolding then
        isHolding = true
        performAction(sequence[currentIndex])
        wait(0.1)  -- Thời gian trễ giữa các lần bấm
        currentIndex = currentIndex + 1
        if currentIndex > #sequence then
            currentIndex = 1  -- Quay lại phím đầu tiên
        end
        updateButtonText()
        isHolding = false
    end
end

-- Event for button press
button.MouseButton1Down:Connect(onButtonPressed)

-- Event for button hold on mobile devices
button.MouseButton1Hold:Connect(function()
    if not isHolding then
        isHolding = true
        performAction(sequence[currentIndex])
        wait(0.1)  -- Thời gian trễ giữa các lần bấm
        currentIndex = currentIndex + 1
        if currentIndex > #sequence then
            currentIndex = 1  -- Quay lại phím đầu tiên
        end
        updateButtonText()
        isHolding = false
    end
end)

-- Listen for keyboard input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- Check key press and perform corresponding action
        if input.KeyCode == Enum.KeyCode.One then
            performAction("1")
            wait(0.35)
            performAction("X")
        elseif input.KeyCode == Enum.KeyCode.Two then
            performAction("2")
        elseif input.KeyCode == Enum.KeyCode.Three then
            performAction("3")
        elseif input.KeyCode == Enum.KeyCode.C then
            performAction("C")
        elseif input.KeyCode == Enum.KeyCode.X then
            performAction("X")
        elseif input.KeyCode == Enum.KeyCode.Z then
            performAction("Z")
        end
    end
end)
