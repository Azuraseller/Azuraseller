-- Đây là script Lua giả định sử dụng Love2D để tạo giao diện.
local buttons = {
    {key = "2", label = "Phím 2", state = false},
    {key = "C", label = "Phím C", state = false},
    {key = "3", label = "Phím 3", state = false},
    {key = "X", label = "Phím X", state = false},
    {key = "1", label = "Phím 1", state = false},
    {key = "Z", label = "Phím Z", state = false}
}

local currentButton = 1  -- Nút hiện tại, bắt đầu từ phím 2

function love.load()
    love.window.setTitle("Hotkey System")
    love.window.setMode(800, 600)
end

function love.update(dt)
    -- Kiểm tra các phím được nhấn
    for i, button in ipairs(buttons) do
        if love.keyboard.isDown(button.key) then
            button.state = true
            currentButton = i
        else
            button.state = false
        end
    end
end

function love.draw()
    -- Vẽ các nút trên màn hình
    for i, button in ipairs(buttons) do
        local color = button.state and {0, 1, 0} or {1, 1, 1}  -- Màu sắc thay đổi khi nhấn
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", 100 * i, 500, 80, 40)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(button.label, 100 * i + 10, 510)
    end
end

function love.keypressed(key)
    -- Kiểm tra các phím nhấn và chuyển đổi
    if key == "escape" then
        love.event.quit()
    end
end
