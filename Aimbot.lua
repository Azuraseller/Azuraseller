local UserInputService = game:GetService("UserInputService")
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer.PlayerGui

local button = Instance.new("TextButton")
button.Parent = screenGui
button.Text = "2"
button.Size = UDim2.new(0, 100, 0, 50)
button.Position = UDim2.new(1, -110, 0.5, -25)
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 24
button.TextButtonStyle = Enum.ButtonStyle.Rounded

local sequence = {"2", "C", "3", "X", "1", "Z", "2", "X", "1", "C", "X"}
local currentIndex = 1
local isHolding = false

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

local function updateButtonText()
    button.Text = sequence[currentIndex]
end

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

button.MouseButton1Down:Connect(onButtonPressed)
