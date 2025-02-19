------------------------------------------------------------
-- Script Clone Camera 360° (Roblox Lua)
-- Yêu cầu:
-- 1. Khi bật script, camera của người chơi chuyển sang cloneCamera.
-- 2. cloneCamera di chuyển theo vị trí của nhân vật nhưng không bị ràng buộc bởi hướng của head.
-- 3. Cho phép xoay 360° tự do (góc nhìn độc lập với hướng của nhân vật).
-- 4. Hệ thống chống can hiệp (anti-tamper) tích hợp.
------------------------------------------------------------

-- Dịch vụ cần dùng
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

-- Đợi nhân vật load xong
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")
local rootPart = character:FindFirstChild("HumanoidRootPart") or head

-- Lấy camera gốc và tạo cloneCamera
local originalCamera = workspace.CurrentCamera

local cloneCamera = Instance.new("Camera")
cloneCamera.Name = "CloneCamera"
cloneCamera.FieldOfView = originalCamera.FieldOfView
cloneCamera.CameraType = Enum.CameraType.Scriptable

-- Chuyển sang cloneCamera
workspace.CurrentCamera = cloneCamera

-- Các biến điều khiển camera
local cameraRotation = Vector2.new(0, 0)   -- Góc xoay tự do (x: yaw, y: pitch)
local cameraDistance = 10                  -- Khoảng cách mặc định từ nhân vật
local sensitivity = 0.2                    -- Độ nhạy chuột

local minDistance = 1
local maxDistance = 1000

-- HÀM: Tính toán CFrame mong muốn cho camera clone dựa trên vị trí của nhân vật và góc xoay tự do
local function getDesiredCFrame()
    -- Luôn cập nhật rootPart (trường hợp respawn)
    rootPart = character:FindFirstChild("HumanoidRootPart") or head
    local basePosition = rootPart.Position
    -- Tạo offset theo khoảng cách mong muốn (trục Z dương theo không gian của CFrame xoay)
    local offset = CFrame.new(0, 0, cameraDistance)
    -- Tạo CFrame xoay tự do: lưu ý thứ tự các góc để đảm bảo xoay đúng
    local rotationCFrame = CFrame.Angles(math.rad(cameraRotation.Y), math.rad(cameraRotation.X), 0)
    -- Dùng vị trí của nhân vật làm gốc, áp dụng góc xoay tự do và dịch chuyển theo offset
    local desiredCFrame = CFrame.new(basePosition) * rotationCFrame * offset
    return desiredCFrame
end

-- HÀM: Cập nhật cloneCamera
local function updateCamera()
    local desiredCFrame = getDesiredCFrame()
    cloneCamera.CFrame = desiredCFrame
    -- Đặt Focus vào vị trí của nhân vật
    cloneCamera.Focus = CFrame.new(rootPart.Position)
end

-- Lắng nghe sự thay đổi của chuột để xoay camera 360°
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- Cộng dồn delta để xoay camera theo chuột (cho phép xem 360°)
        cameraRotation = cameraRotation + Vector2.new(-input.Delta.X * sensitivity, -input.Delta.Y * sensitivity)
        updateCamera()
    elseif input.UserInputType == Enum.UserInputType.MouseWheel then
        -- Điều chỉnh zoom
        cameraDistance = math.clamp(cameraDistance - input.Position.Z, minDistance, maxDistance)
        updateCamera()
    end
end)

-- HỆ THỐNG CHỐNG CAN HIỆP (Anti-Tamper):
-- Nếu có ai đó thay đổi workspace.CurrentCamera, tự động reset về cloneCamera.
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera ~= cloneCamera then
        workspace.CurrentCamera = cloneCamera
        warn("Anti-Tamper: Reset CurrentCamera về cloneCamera")
    end
end)

-- Cập nhật camera liên tục để theo dõi vị trí của nhân vật
RunService.RenderStepped:Connect(function(deltaTime)
    updateCamera()
end)

------------------------------------------------------------
-- Ghi chú:
-- Script này đảm bảo camera clone:
-- 1. Luôn theo dõi vị trí của nhân vật (dựa trên HumanoidRootPart hoặc Head).
-- 2. Cho phép xoay 360° tự do, không phụ thuộc vào hướng của nhân vật.
-- 3. Không bị ảnh hưởng bởi các script khác.
------------------------------------------------------------
