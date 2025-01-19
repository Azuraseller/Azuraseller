-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Button2 = Instance.new("TextButton")
local Button3 = Instance.new("TextButton")
local Button1 = Instance.new("TextButton")

-- Thuộc tính GUI
ScreenGui.Name = "CustomKeyboard"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

Frame.Name = "Frame"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.new(1, 1, 1)
Frame.Size = UDim2.new(0, 300, 0, 100)
Frame.Position = UDim2.new(0.5, -150, 0.5, -50)

-- Nút 2
Button2.Name = "Button2"
Button2.Parent = Frame
Button2.Text = "2"
Button2.Size = UDim2.new(0, 90, 0, 50)
Button2.Position = UDim2.new(0, 10, 0, 25)
Button2.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)

-- Nút 3
Button3.Name = "Button3"
Button3.Parent = Frame
Button3.Text = "3"
Button3.Size = UDim2.new(0, 90, 0, 50)
Button3.Position = UDim2.new(0, 110, 0, 25)
Button3.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)

-- Nút 1
Button1.Name = "Button1"
Button1.Parent = Frame
Button1.Text = "1"
Button1.Size = UDim2.new(0, 90, 0, 50)
Button1.Position = UDim2.new(0, 210, 0, 25)
Button1.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)

-- Chu kỳ hành động
local actions = {
    {number = "2", letters = {"c"}},
    {number = "3", letters = {"x"}},
    {number = "1", letters = {"z"}},
    {number = "2", letters = {"x"}},
    {number = "1", letters = {"x", "c"}}
}

local currentIndex = 1

-- Hàm thực hiện hành động
local function performAction(button)
    local action = actions[currentIndex]

    -- In số và chữ tương ứng
    print("Pressed:", action.number)
    for _, letter in ipairs(action.letters) do
        print("Output:", letter)
    end

    -- Ẩn nút hiện tại
    button.Visible = false

    -- Chuyển sang nút tiếp theo
    currentIndex = currentIndex + 1
    if currentIndex > #actions then
        currentIndex = 1 -- Quay lại đầu chu kỳ
    end

    -- Hiển thị nút tiếp theo
    local nextAction = actions[currentIndex]
    if nextAction.number == "2" then
        Button2.Visible = true
    elseif nextAction.number == "3" then
        Button3.Visible = true
    elseif nextAction.number == "1" then
        Button1.Visible = true
    end
end

-- Kết nối sự kiện nhấn nút
Button2.MouseButton1Click:Connect(function()
    performAction(Button2)
end)

Button3.MouseButton1Click:Connect(function()
    performAction(Button3)
end)

Button1.MouseButton1Click:Connect(function()
    performAction(Button1)
end)

-- Khởi tạo trạng thái
Button3.Visible = false
Button1.Visible = false
