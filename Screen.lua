------------------------------------------------------------
-- RTX Screen Overlay Protection
-- Mục đích:
-- 1. Phủ lên màn hình một lớp màu xanh dương nhạt, siêu trong suốt.
-- 2. Đo thông số độ chói (Brightness) của Lighting và tự động điều chỉnh
--    độ trong suốt của lớp overlay để bảo vệ mắt (giảm ánh sáng chói).
------------------------------------------------------------

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Tạo ScreenGui và Frame phủ toàn màn hình
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RTXScreenOverlay"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local overlayFrame = Instance.new("Frame")
overlayFrame.Name = "OverlayFrame"
overlayFrame.Size = UDim2.new(1, 0, 1, 0)
overlayFrame.Position = UDim2.new(0, 0, 0, 0)
overlayFrame.BackgroundColor3 = Color3.fromRGB(180, 210, 255)  -- màu xanh dương nhạt
overlayFrame.BackgroundTransparency = 0.9  -- ban đầu rất trong suốt
overlayFrame.BorderSizePixel = 0
overlayFrame.Parent = screenGui

------------------------------------------------------------
-- THIẾT LẬP CÁC THAM SỐ ĐIỀU CHỈNH OVERLAY
------------------------------------------------------------
local minTransparency = 0.5   -- Khi độ chói cao: overlay trở nên ít trong suốt (che ánh sáng nhiều hơn)
local maxTransparency = 0.9   -- Khi độ chói thấp: overlay giữ nguyên độ trong suốt ban đầu
local brightnessLow = 1.5     -- Giá trị Brightness thấp (môi trường tối)
local brightnessHigh = 3.0    -- Giá trị Brightness cao (môi trường sáng)

------------------------------------------------------------
-- HÀM TỰ ĐỘNG ĐIỀU CHỈNH OVERLAY
------------------------------------------------------------
local function updateOverlay()
    -- Lấy giá trị Brightness hiện tại từ Lighting
    local currentBrightness = Lighting.Brightness

    -- Tính t trong khoảng [0, 1] dựa trên Brightness (0 khi tối, 1 khi rất sáng)
    local t = math.clamp((currentBrightness - brightnessLow) / (brightnessHigh - brightnessLow), 0, 1)

    -- Nội suy (lerp) từ maxTransparency (khi Brightness thấp) đến minTransparency (khi Brightness cao)
    local newTransparency = maxTransparency - t * (maxTransparency - minTransparency)
    overlayFrame.BackgroundTransparency = newTransparency
end

------------------------------------------------------------
-- CẬP NHẬT THEO MỨC ĐỘ (với RenderStepped để mượt)
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    updateOverlay()
end)

------------------------------------------------------------
-- THÔNG BÁO
------------------------------------------------------------
print("RTX Screen Overlay đã được kích hoạt, tự động điều chỉnh độ trong suốt dựa trên độ chói của môi trường.")
