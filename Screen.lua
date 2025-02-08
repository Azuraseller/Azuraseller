local player = game.Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")

if not playerGui then return end

-- Xóa GUI cũ nếu có
local oldGui = playerGui:FindFirstChild("AntiGlareOverlay")
if oldGui then oldGui:Destroy() end

-- Tạo ScreenGui mới
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiGlareOverlay"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Tạo lớp phủ chống chói
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Màu đen nhẹ để giảm chói
overlay.BackgroundTransparency = 0.1 -- Điều chỉnh độ trong suốt (0.3 - 0.6 tùy môi trường)
overlay.Parent = screenGui

-- Cập nhật độ trong suốt theo môi trường ánh sáng
local lighting = game:GetService("Lighting")

local function adjustTransparency()
    local brightness = lighting.Brightness
    local exposure = lighting.ExposureCompensation

    -- Giảm chói khi ánh sáng quá cao
    local newTransparency = math.clamp(0.2 + (brightness + exposure) * 0.05, 0.3, 0.6)
    overlay.BackgroundTransparency = newTransparency
end

-- Lắng nghe thay đổi ánh sáng trong game
lighting:GetPropertyChangedSignal("Brightness"):Connect(adjustTransparency)
lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(adjustTransparency)

-- Chạy cập nhật lần đầu
adjustTransparency()
