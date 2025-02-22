-- LocalScript (StarterPlayerScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- 🔹 Camera Clone
local cloneCamera = Instance.new("Camera")
cloneCamera.Name = "CloneCamera"
cloneCamera.CameraType = Enum.CameraType.Scriptable
workspace.CurrentCamera = cloneCamera

-- 🔹 Biến điều khiển Camera
local rotationX = 20      -- Góc nhìn lên/xuống
local rotationY = 0       -- Góc xoay ngang
local zoomDistance = 20   -- Khoảng cách từ nhân vật đến camera

local MIN_ZOOM = 5
local MAX_ZOOM = 50

-- 🔹 Cài đặt cảm ứng & chuột
local mouseSensitivity = 0.3
local zoomSensitivity = 2
local touchSensitivity = 0.5
local touchZoomSensitivity = 0.05

local lastTouchPositions = {}
local pinchStartDist = nil
local pinchStartZoom = zoomDistance

-----------------------------------------------------------
-- 🎮 Xử lý Input: Chuột (PC) & Cảm ứng (Mobile)
-----------------------------------------------------------

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- 🔹 Xoay camera bằng chuột
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        rotationX = math.clamp(rotationX - input.Delta.Y * mouseSensitivity, -80, 80)
        rotationY = rotationY - input.Delta.X * mouseSensitivity
    end

    -- 🔹 Zoom bằng con lăn chuột
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        zoomDistance = math.clamp(zoomDistance - input.Position.Z * zoomSensitivity, MIN_ZOOM, MAX_ZOOM)
    end
end)

-----------------------------------------------------------
-- 📱 Xử lý Input: Cảm ứng (Mobile)
-----------------------------------------------------------

UserInputService.TouchStarted:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    lastTouchPositions[input.UserInputId] = input.Position
end)

UserInputService.TouchMoved:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local touch = lastTouchPositions[input.UserInputId]
    if not touch then return end

    local delta = input.Position - touch
    lastTouchPositions[input.UserInputId] = input.Position

    -- 🔹 Nếu có 1 ngón tay: Xoay camera
    local touchCount = 0
    for _ in pairs(lastTouchPositions) do
        touchCount = touchCount + 1
    end

    if touchCount == 1 then
        rotationX = math.clamp(rotationX - delta.Y * touchSensitivity, -80, 80)
        rotationY = rotationY - delta.X * touchSensitivity
    end

    -- 🔹 Nếu có 2 ngón tay: Zoom camera
    if touchCount == 2 then
        local touches = {}
        for _, pos in pairs(lastTouchPositions) do
            table.insert(touches, pos)
        end

        if #touches == 2 then
            local dist = (touches[1] - touches[2]).Magnitude
            if not pinchStartDist then
                pinchStartDist = dist
                pinchStartZoom = zoomDistance
            else
                local zoomDelta = (dist - pinchStartDist) * touchZoomSensitivity
                zoomDistance = math.clamp(pinchStartZoom - zoomDelta, MIN_ZOOM, MAX_ZOOM)
            end
        end
    end
end)

UserInputService.TouchEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    lastTouchPositions[input.UserInputId] = nil
    if not next(lastTouchPositions) then
        pinchStartDist = nil
    end
end)

-----------------------------------------------------------
-- 🔄 Cập nhật Camera mỗi khung hình
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local targetPosition = rootPart.Position + Vector3.new(0, 3, 0) -- Nâng lên một chút để tránh che khuất
        
        -- 🔹 Tính toán vị trí Camera
        local rotationCF = CFrame.Angles(math.rad(rotationX), math.rad(rotationY), 0)
        local offset = Vector3.new(0, 0, zoomDistance)
        local cameraPosition = targetPosition + rotationCF:VectorToWorldSpace(offset)

        -- 🔹 Cập nhật Camera
        cloneCamera.CFrame = CFrame.new(cameraPosition, targetPosition)
    end
end)
