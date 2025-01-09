-- Tạo GUI hiển thị FPS
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local FPSFrame = Instance.new("Frame")
FPSFrame.Size = UDim2.new(0, 200, 0, 50)
FPSFrame.Position = UDim2.new(0, 10, 0, 10)
FPSFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FPSFrame.BackgroundTransparency = 0.5
FPSFrame.Parent = ScreenGui

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, 0, 1, 0)
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.TextSize = 18
FPSLabel.Text = "FPS: 0"
FPSLabel.Parent = FPSFrame

-- Cập nhật FPS mỗi giây
local function updateFPS()
    while true do
        -- Tính FPS
        local fps = math.floor(1 / game:GetService("RunService").Heartbeat:Wait())
        FPSLabel.Text = "FPS: " .. fps
    end
end

-- Bắt đầu cập nhật FPS
coroutine.wrap(updateFPS)()

-- Mở khóa FPS và tăng chất lượng đồ họa
local UserSettings = game:GetService("UserSettings")
local GameSettings = UserSettings.GameSettings

-- Cấu hình đồ họa để tăng FPS
GameSettings.SavedQualityLevel = Enum.QualityLevel.Level10  -- Chất lượng đồ họa cao nhất
GameSettings.GraphicsQuality = Enum.GraphicsQuality.Level10  -- Cài đặt chất lượng đồ họa tối đa
GameSettings.MovementMode = Enum.MovementMode.Classic  -- Chế độ di chuyển cổ điển để giảm độ trễ

-- Gửi thông báo rằng FPS không giới hạn đã được kích hoạt
local function showUnlockMessage()
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0, 300, 0, 50)
    messageLabel.Position = UDim2.new(0, 10, 0, 70)
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    messageLabel.TextSize = 20
    messageLabel.Text = "FPS Unlock Activated!"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Parent = ScreenGui

    wait(3)
    messageLabel:Destroy()  -- Xóa thông báo sau 3 giây
end

-- Hiển thị thông báo khi mở khóa FPS
coroutine.wrap(showUnlockMessage)()
