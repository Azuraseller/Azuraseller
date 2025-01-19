-- Tạo một bảng lưu trữ các hotkeys và hành động của chúng
local hotkeys = {
    {key = "2", action = "Action 1", button = nil},
    {key = "C", action = "Action 2", button = nil},
    {key = "3", action = "Action 3", button = nil},
    {key = "X", action = "Action 4", button = nil},
    {key = "1", action = "Action 5", button = nil},
    {key = "Z", action = "Action 6", button = nil}
}

-- Tạo các nút trên màn hình
local function createButtons()
    for i, hotkey in ipairs(hotkeys) do
        hotkey.button = display.newText(hotkey.action, display.contentCenterX, 100 + (i - 1) * 50, native.systemFont, 20)
        hotkey.button:setFillColor(1, 1, 1)
    end
end

-- Hàm xử lý hotkey
local function handleHotkey(event)
    for i, hotkey in ipairs(hotkeys) do
        if event.keyName == hotkey.key then
            print("Nhấn phím " .. hotkey.key .. ": " .. hotkey.action)
            -- Cập nhật giao diện khi phím được nhấn
            hotkey.button:setFillColor(0, 1, 0)  -- Đổi màu nút khi nhấn
        else
            hotkey.button:setFillColor(1, 1, 1)  -- Đặt lại màu khi không nhấn
        end
    end
end

-- Tạo các nút và thiết lập sự kiện bàn phím
createButtons()
Runtime:addEventListener("key", handleHotkey)
