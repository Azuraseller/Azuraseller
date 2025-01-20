local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Create a new ScreenGui
local GUI = Instance.new("ScreenGui")
GUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create the main frame for the keyboard
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 100)
MainFrame.Position = UDim2.new(1, -310, 0.95, -100) -- Start off-screen
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Parent = GUI

-- Round the corners of the main frame
local MainFrameCorner = Instance.new("UICorner")
MainFrameCorner.CornerRadius = UDim.new(0, 10)
MainFrameCorner.Parent = MainFrame

-- Trình tự các phím
local sequence = {"2", "C", "3", "X", "1", "Z", "2", "X", "1", "C", "X"}
local currentIndex = 1
local isHolding = false

-- Hàm thực hiện hành động
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

-- Cập nhật lại chữ trên nút
local function updateButtonText(button)
    button.Text = sequence[currentIndex]
end

-- Tạo các phím ảo
local function createButton(text, position)
    local button = Instance.new("TextButton")
    button.Parent = MainFrame
    button.Text = text
    button.Size = UDim2.new(0, 80, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 24
    button.TextButtonStyle = Enum.ButtonStyle.Rounded

    -- Bo tròn các nút
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = button

    -- Sự kiện nhấn nút
    button.MouseButton1Down:Connect(function()
        if not isHolding then
            isHolding = true
            performAction(sequence[currentIndex])
            wait(0.1)  -- Thời gian trễ giữa các lần bấm
            currentIndex = currentIndex + 1
            if currentIndex > #sequence then
                currentIndex = 1  -- Quay lại phím đầu tiên
            end
            updateButtonText(button)
            isHolding = false
        end
    end)

    return button
end

-- Tạo các phím theo trình tự
local button1 = createButton("2", UDim2.new(0, 0, 0, 0))
local button2 = createButton("C", UDim2.new(0, 90, 0, 0))
local button3 = createButton("3", UDim2.new(0, 180, 0, 0))
local button4 = createButton("X", UDim2.new(0, 270, 0, 0))
local button5 = createButton("1", UDim2.new(0, 0, 0, 60))
local button6 = createButton("Z", UDim2.new(0, 90, 0, 60))
local button7 = createButton("2", UDim2.new(0, 180, 0, 60))
local button8 = createButton("X", UDim2.new(0, 270, 0, 60))
local button9 = createButton("1", UDim2.new(0, 0, 0, 120))
local button10 = createButton("C", UDim2.new(0, 90, 0, 120))
local button11 = createButton("X", UDim2.new(0, 180, 0, 120))

-- Thêm sự kiện cho việc nhấn giữ trên thiết bị di động
for _, button in ipairs({button1, button2, button3, button4, button5, button6, button7, button8, button9, button10, button11}) do
    button.MouseButton1Hold:Connect(function()
        if not isHolding then
            isHolding = true
            performAction(sequence[currentIndex])
            wait(0.1)  -- Thời gian trễ giữa các lần bấm
            currentIndex = currentIndex + 1
            if currentIndex > #sequence then
                currentIndex = 1  -- Quay lại phím đầu tiên
            end
            updateButtonText(button)
            isHolding = false
        end
    end)
end

-- Lắng nghe sự kiện nhấn phím từ bàn phím PC
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        -- Kiểm tra phím nhấn và thực hiện hành động tương ứng
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
