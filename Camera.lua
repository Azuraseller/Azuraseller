------------------------------------------------------------
-- Script Clone Camera (Roblox Lua)
-- Yêu cầu:
-- 1. Khi bật script, camera của người chơi chuyển sang cloneCamera.
-- 2. cloneCamera có các chức năng giống camera gốc.
-- 3. cloneCamera không bị ảnh hưởng bởi các tác động bên ngoài.
-- 4. Hệ thống chống can hiệp (anti-tamper).
------------------------------------------------------------

-- Dịch vụ cần dùng
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

-- Đợi nhân vật và Head load xong
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")

-- Lấy camera gốc và tạo cloneCamera
local originalCamera = workspace.CurrentCamera

-- Tạo một camera mới (clone)
local cloneCamera = Instance.new("Camera")
cloneCamera.Name = "CloneCamera"
cloneCamera.FieldOfView = originalCamera.FieldOfView
cloneCamera.CameraType = Enum.CameraType.Scriptable
-- (Bạn có thể copy thêm các thuộc tính khác nếu cần)
workspace.CurrentCamera = cloneCamera  -- Chuyển sang cloneCamera

-- Các biến điều khiển camera
local cameraRotation = Vector2.new(0, 0)   -- Góc xoay (yaw, pitch)
local cameraDistance = 10                  -- Khoảng cách mặc định từ nhân vật
local sensitivity = 0.2                    -- Độ nhạy chuột

-- Giới hạn zoom
local minDistance = 5
local maxDistance = 1000

-- HÀM: Tính toán CFrame mong muốn dựa trên Head của nhân vật, góc xoay và khoảng cách
local function getDesiredCFrame()
    -- Tạo offset: đưa camera ra phía sau theo khoảng cách
    local offset = CFrame.new(0, 0, cameraDistance)
    -- Tạo xoay: xoay quanh trục Y (yaw) và X (pitch)
    local rotationCFrame = CFrame.Angles(0, math.rad(cameraRotation.X), 0) * CFrame.Angles(math.rad(cameraRotation.Y), 0, 0)
    -- Vị trí mong muốn: căn cứ vào vị trí head của nhân vật
    local desiredCFrame = head.CFrame * rotationCFrame * offset
    return desiredCFrame
end

-- HÀM: Cập nhật cloneCamera theo CFrame mong muốn
local function updateCamera()
    local desiredCFrame = getDesiredCFrame()
    cloneCamera.CFrame = desiredCFrame
    cloneCamera.Focus = head.CFrame
    -- Có thể cập nhật thêm các thuộc tính khác (FOV, ClearType, …) nếu cần
end

-- KẾT NỐI: Theo dõi di chuyển chuột để xoay camera
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        cameraRotation = cameraRotation + Vector2.new(-input.Delta.X * sensitivity, -input.Delta.Y * sensitivity)
        updateCamera()
    end
end)

-- KẾT NỐI: Lắng nghe input của chuột (wheel) để điều chỉnh zoom
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        cameraDistance = math.clamp(cameraDistance - input.Position.Z, minDistance, maxDistance)
        updateCamera()
    end
end)

-- HỆ THỐNG CHỐNG CAN HIỆP (Anti-Tamper)
-- 1. Theo dõi sự thay đổi của workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera ~= cloneCamera then
        workspace.CurrentCamera = cloneCamera
        warn("Anti-Tamper: Reset CurrentCamera về cloneCamera")
    end
end)

-- 2. Cập nhật liên tục camera theo logic của chúng ta
RunService.RenderStepped:Connect(function(deltaTime)
    updateCamera()
    -- Nếu ai đó cố thay đổi thuộc tính quan trọng của cloneCamera, updateCamera() sẽ ghi đè
end)

------------------------------------------------------------
-- Ghi chú:
-- Đây là một mẫu cơ bản. Để “clone” hoàn toàn mọi chức năng của camera gốc,
-- bạn có thể cần tích hợp thêm các tính năng (như xử lý va chạm, mượt, …
-- hay các hiệu ứng đặc biệt) tương tự như default camera script.
------------------------------------------------------------
