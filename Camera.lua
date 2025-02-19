------------------------------------------------------------
-- Upgraded Clone Camera Script (Roblox Lua)
-- Yêu cầu:
-- 1. Camera clone mô phỏng camera third-person mặc định đi theo player.
-- 2. Sửa lỗi camera “cứng”: cho phép xoay 360° và zoom mượt.
-- 3. Không bị can thiệp bởi bất cứ thứ gì, kể cả ShiftLock.
-- 4. Khi bật, camera có khả năng xoay tự do, không ghim vào head.
-- 5. Hỗ trợ xoay & zoom qua vuốt (touch) trên điện thoại.
-- 6. Hành vi giống như camera trong hầu hết game Roblox.
------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

-- Lấy nhân vật và phần cần theo dõi (HumanoidRootPart hoặc Head)
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart") or character:WaitForChild("Head")

-- Lấy camera gốc và tạo cloneCamera mới
local originalCamera = workspace.CurrentCamera

local cloneCamera = Instance.new("Camera")
cloneCamera.Name = "CloneCamera"
cloneCamera.FieldOfView = originalCamera.FieldOfView
cloneCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera = cloneCamera

------------------------------------------------------------
-- CÁC THAM SỐ ĐIỀU KHIỂN CAMERA
------------------------------------------------------------
local yaw = 0           -- Góc xoay ngang (đơn vị: độ)
local pitch = 10        -- Góc xoay dọc (đơn vị: độ), mặc định hơi nghiêng xuống
local cameraDistance = 10
local minDistance = 5
local maxDistance = 1000

-- Độ nhạy điều khiển trên PC
local rotationSensitivity = 0.3  -- xoay bằng chuột
local zoomSensitivity = 1        -- zoom bằng MouseWheel

-- Độ nhạy điều khiển trên mobile (touch)
local touchRotationSensitivity = 0.2  -- xoay bằng vuốt
local touchZoomSensitivity = 0.05       -- zoom bằng pinch

-- Hệ số smoothing (làm mượt chuyển động)
local smoothing = 0.2

------------------------------------------------------------
-- BIẾN HỖ TRỢ INPUT
------------------------------------------------------------
-- Cho PC (chuột)
local isRotating = false
local lastMousePos = nil

-- Cho mobile (touch)
local activeTouches = {}          -- Bảng lưu vị trí các ngón đang chạm (key: TouchId)
local lastTouchPositions = {}     -- Lưu vị trí trước đó cho mỗi TouchId
local lastPinchDistance = nil      -- Khoảng cách pinch trước đó

-- Hàm đếm số phần tử trong bảng (dành cho bảng dạng từ điển)
local function countTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

------------------------------------------------------------
-- HÀM XỬ LÝ VỊ TRÍ MỤC TIÊU (nhân vật)
------------------------------------------------------------
local function getTargetPosition()
    -- Cập nhật lại nhân vật nếu cần (trường hợp respawn)
    if not character or not character.Parent then
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    end
    local offset = Vector3.new(0, 2, 0)  -- Dịch chuyển nhẹ lên trên
    return rootPart.Position + offset
end

------------------------------------------------------------
-- HÀM TÍNH TOÁN CFrame MONG MUỐN CHO CAMERA
------------------------------------------------------------
local function getDesiredCFrame()
    local target = getTargetPosition()
    pitch = math.clamp(pitch, -89, 89)  -- Giới hạn pitch để tránh lộn
    local radPitch = math.rad(pitch)
    local radYaw = math.rad(yaw)
    local rotationCFrame = CFrame.Angles(radPitch, radYaw, 0)
    -- Đặt camera phía sau target: dùng dịch chuyển âm theo trục Z
    local desiredCFrame = CFrame.new(target) * rotationCFrame * CFrame.new(0, 0, -cameraDistance)
    return desiredCFrame
end

------------------------------------------------------------
-- HÀM CẬP NHẬT CAMERA VỚI SMOOTHING
------------------------------------------------------------
local currentCameraCFrame = cloneCamera.CFrame
local function updateCamera()
    local desiredCFrame = getDesiredCFrame()
    currentCameraCFrame = currentCameraCFrame:Lerp(desiredCFrame, smoothing)
    cloneCamera.CFrame = currentCameraCFrame
    cloneCamera.Focus = CFrame.new(getTargetPosition())
end

------------------------------------------------------------
-- HỆ THỐNG CHỐNG CAN HIỆP (ANTI-TAMPER)
------------------------------------------------------------
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera ~= cloneCamera then
        workspace.CurrentCamera = cloneCamera
        warn("Anti-Tamper: Reset CurrentCamera to cloneCamera")
    end
end)

------------------------------------------------------------
-- XỬ LÝ INPUT (PC & Mobile)
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Cho PC: khi nhấn chuột phải (MouseButton2)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRotating = true
        lastMousePos = input.Position
    end

    -- Cho mobile: khi chạm màn hình
    if input.UserInputType == Enum.UserInputType.Touch then
        activeTouches[input.TouchId] = input.Position
        lastTouchPositions[input.TouchId] = input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRotating = false
        lastMousePos = nil
    end

    if input.UserInputType == Enum.UserInputType.Touch then
        activeTouches[input.TouchId] = nil
        lastTouchPositions[input.TouchId] = nil
        if countTable(activeTouches) < 2 then
            lastPinchDistance = nil
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Xử lý chuột (PC)
    if input.UserInputType == Enum.UserInputType.MouseMovement and isRotating then
        if lastMousePos then
            local delta = input.Position - lastMousePos
            yaw = yaw - delta.X * rotationSensitivity
            pitch = pitch - delta.Y * rotationSensitivity
            lastMousePos = input.Position
        end
    end

    if input.UserInputType == Enum.UserInputType.MouseWheel then
        cameraDistance = math.clamp(cameraDistance - input.Position.Z * zoomSensitivity, minDistance, maxDistance)
    end

    -- Xử lý cảm ứng (Mobile)
    if input.UserInputType == Enum.UserInputType.Touch then
        local previousPos = lastTouchPositions[input.TouchId]
        lastTouchPositions[input.TouchId] = input.Position
        activeTouches[input.TouchId] = input.Position

        local touchCount = countTable(activeTouches)
        if touchCount == 1 and previousPos then
            -- Vuốt đơn: xoay camera
            local delta = input.Position - previousPos
            yaw = yaw - delta.X * touchRotationSensitivity
            pitch = pitch - delta.Y * touchRotationSensitivity
        elseif touchCount >= 2 then
            -- Pinch: zoom camera
            local touches = {}
            for _, pos in pairs(activeTouches) do
                table.insert(touches, pos)
            end
            if #touches >= 2 then
                local currentDistance = (touches[1] - touches[2]).Magnitude
                if lastPinchDistance then
                    local deltaDistance = currentDistance - lastPinchDistance
                    cameraDistance = math.clamp(cameraDistance - deltaDistance * touchZoomSensitivity, minDistance, maxDistance)
                end
                lastPinchDistance = currentDistance
            end
        end
    end
end)

------------------------------------------------------------
-- CẬP NHẬT CAMERA MỖI KHUNG Hình
------------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    updateCamera()
end)

------------------------------------------------------------
-- KẾT THÚC SCRIPT
------------------------------------------------------------
