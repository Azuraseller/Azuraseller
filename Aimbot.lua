-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
local Button = Instance.new("TextButton")

-- Thuộc tính GUI
ScreenGui.Name = "CustomKeyboard"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

Button.Name = "ActionButton"
Button.Parent = ScreenGui
Button.Text = ""
Button.Size = UDim2.new(0, 100, 0, 50)
Button.Position = UDim2.new(1, -120, 1, -70) -- Góc phải phía dưới
Button.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
Button.Visible = true

-- Chu kỳ hành động
local actions = {
    {number = "2", letters = {"C"}, ability = function()
        print("Thực thi chiêu C")
        -- Thêm hiệu ứng hoặc hành động trong game tại đây
        -- Ví dụ: Gây sát thương, tạo hiệu ứng, hoặc di chuyển
    end},
    {number = "3", letters = {"X"}, ability = function()
        print("Thực thi chiêu X")
        -- Ví dụ: Gây sát thương diện rộng
    end},
    {number = "1", letters = {"Z"}, ability = function()
        print("Thực thi chiêu Z")
        -- Ví dụ: Tăng tốc độ hoặc nhảy cao
    end},
    {number = "2", letters = {"X"}, ability = function()
        print("Thực thi chiêu X lần nữa")
    end},
    {number = "1", letters = {"X", "C"}, ability = function()
        print("Thực thi chiêu X và C")
        -- Gọi nhiều chiêu cùng lúc
    end}
}

local currentIndex = 1

-- Hàm thực hiện hành động
local function performAction()
    local action = actions[currentIndex]

    -- Hiển thị số và chữ trên nút
    Button.Text = action.number .. " → " .. table.concat(action.letters, ", ")

    -- Thực thi chiêu thức
    action.ability()

    -- Chuyển sang nút tiếp theo
    currentIndex = currentIndex + 1
    if currentIndex > #actions then
        currentIndex = 1 -- Quay lại đầu chu kỳ
    end
end

-- Kết nối sự kiện nhấn nút
Button.MouseButton1Click:Connect(function()
    performAction()
end)

-- Khởi tạo trạng thái
performAction()
