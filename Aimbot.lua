local Players = game:GetService("Players")
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "CustomKeyboard"

-- Tạo nút chính
local button = Instance.new("TextButton", screenGui)
button.Size = UDim2.new(0, 100, 0, 100)
button.Position = UDim2.new(0.9, -50, 0.5, -50) -- Góc phải giữa
button.BackgroundColor3 = Color3.new(0, 0, 0) -- Nền màu đen
button.TextColor3 = Color3.new(1, 1, 1) -- Màu chữ trắng
button.Font = Enum.Font.SourceSans
button.TextScaled = true
button.Text = "2"
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.ClipsDescendants = true
button.BackgroundTransparency = 0.2

-- Danh sách phím và hành động
local sequence = {
    {number = "2", letter = "c"},
    {number = "3", letter = "x"},
    {number = "1", letter = "z"},
    {number = "2", letter = "x"},
    {number = "1", letter = "c", delay = 0.35, extra = "x"}
}

local index = 1 -- Vị trí hiện tại trong chuỗi

-- Hàm đổi phím
local function switchKey()
    local current = sequence[index]
    button.Text = current.number
    button.BackgroundColor3 = Color3.new(0, 0, 0)
    
    button.MouseButton1Down:Connect(function()
        -- Đổi sang phím chữ
        button.Text = current.letter
        task.wait(current.delay or 0)
        
        if current.extra then
            button.Text = current.extra
            task.wait(0.35)
        end
        
        -- Chuyển sang phím tiếp theo
        index = index + 1
        if index > #sequence then
            index = 1 -- Quay lại phím đầu tiên
        end
        switchKey() -- Gọi lại để cập nhật phím
    end)
end

switchKey()
