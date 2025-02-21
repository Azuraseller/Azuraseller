-- LocalScript đặt trong StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local originalCamera = workspace.CurrentCamera

-- Tạo ra camera clone và sao chép một số thuộc tính cơ bản
local cloneCamera = Instance.new("Camera")
cloneCamera.FieldOfView = originalCamera.FieldOfView
cloneCamera.CameraType = Enum.CameraType.Scriptable  -- Cho phép điều khiển hoàn toàn qua script

-- Chuyển sang camera clone (chỉ áp dụng cho client hiện hành)
workspace.CurrentCamera = cloneCamera

-- Các biến điều khiển xoay và zoom
local rotationX = 20      -- Góc nâng/cúi ban đầu (pitch)
local rotationY = 0       -- Góc xoay ngang ban đầu (yaw)
local zoomDistance = 20   -- Khoảng cách zoom ban đầu

local MIN_ZOOM = 5
local MAX_ZOOM = 100

-- Các hệ số nhạy cho input
local mouseRotationSensitivity = 0.2
local mouseZoomSensitivity = 1.0      -- Điều chỉnh qua vòng chuột
local touchRotationSensitivity = 0.5  -- Nhạy cảm với cảm ứng
local touchZoomSensitivity = 0.05     -- Nhạy cảm với cử chỉ pinch

-----------------------------------------------------------
-- Xử lý Input từ chuột (Desktop)
-----------------------------------------------------------
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        rotationX = math.clamp(rotationX - input.Delta.Y * mouseRotationSensitivity, -80, 80)
        rotationY = rotationY - input.Delta.X * mouseRotationSensitivity
    elseif input.UserInputType == Enum.UserInputType.MouseWheel then
        zoomDistance = math.clamp(zoomDistance - input.Position.Z * mouseZoomSensitivity, MIN_ZOOM, MAX_ZOOM)
    end
end)

-----------------------------------------------------------
-- Xử lý Input từ cảm ứng (Mobile)
-----------------------------------------------------------
local activeTouches = {}      -- Lưu trữ các cảm ứng đang hoạt động theo UserInputId
local pinchStartDistance = nil  -- Khoảng cách ban đầu giữa 2 cảm ứng để tính zoom
local pinchStartZoom = zoomDistance

-- Khi cảm ứng bắt đầu
UserInputService.TouchStarted:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    activeTouches[input.UserInputId] = {
        last = input.Position,
        current = input.Position,
        delta = Vector2.new(0, 0)
    }
end)

-- Khi cảm ứng di chuyển
UserInputService.TouchMoved:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local touchData = activeTouches[input.UserInputId]
    if touchData then
        local previousPos = touchData.current
        touchData.current = input.Position
        touchData.delta = input.Position - previousPos
    end
    
    -- Đếm số cảm ứng đang hoạt động
    local touchCount = 0
    for _ in pairs(activeTouches) do
        touchCount = touchCount + 1
    end

    if touchCount == 1 then
        -- Một cảm ứng: dùng di chuyển để xoay camera
        for _, touchData in pairs(activeTouches) do
            rotationX = math.clamp(rotationX - touchData.delta.Y * touchRotationSensitivity, -80, 80)
            rotationY = rotationY - touchData.delta.X * touchRotationSensitivity
        end
    elseif touchCount >= 2 then
        -- Hai cảm ứng trở lên: dùng cử chỉ pinch để zoom, đồng thời dùng trung bình chuyển động để xoay
        local touches = {}
        for _, data in pairs(activeTouches) do
            table.insert(touches, data)
        end
        
        if #touches >= 2 then
            local pos1 = touches[1].current
            local pos2 = touches[2].current
            local currentPinchDistance = (pos1 - pos2).Magnitude
            
            if not pinchStartDistance then
                pinchStartDistance = currentPinchDistance
                pinchStartZoom = zoomDistance
            else
                local pinchDelta = currentPinchDistance - pinchStartDistance
                zoomDistance = math.clamp(pinchStartZoom - pinchDelta * touchZoomSensitivity, MIN_ZOOM, MAX_ZOOM)
            end
            
            -- Dùng trung bình chuyển động của 2 cảm ứng để xoay camera
            local avgDelta = (touches[1].delta + touches[2].delta) / 2
            rotationX = math.clamp(rotationX - avgDelta.Y * touchRotationSensitivity, -80, 80)
            rotationY = rotationY - avgDelta.X * touchRotationSensitivity
        end
    end
end)

-- Khi cảm ứng kết thúc
UserInputService.TouchEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    activeTouches[input.UserInputId] = nil
    -- Nếu số cảm ứng giảm dưới 2, reset pinch
    local touchCount = 0
    for _ in pairs(activeTouches) do
        touchCount = touchCount + 1
    end
    if touchCount < 2 then
        pinchStartDistance = nil
    end
end)

-----------------------------------------------------------
-- Cập nhật vị trí và hướng của camera clone mỗi khung hình
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = character.HumanoidRootPart.Position
        
        -- Offset nâng camera lên một chút (có thể điều chỉnh)
        local offset = Vector3.new(0, 5, zoomDistance)
        -- Tạo CFrame xoay dựa trên góc người dùng điều chỉnh
        local rotationCF = CFrame.Angles(math.rad(rotationX), math.rad(rotationY), 0)
        local cameraPosition = targetPosition + (rotationCF * offset)
        
        -- Cập nhật CFrame, đảm bảo camera luôn hướng về vị trí của nhân vật (có thể tùy chỉnh theo ý muốn)
        cloneCamera.CFrame = CFrame.new(cameraPosition, targetPosition)
    end
end)
