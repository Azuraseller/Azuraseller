local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Biến điều khiển chế độ camera custom
local customCameraEnabled = true
camera.CameraType = Enum.CameraType.Scriptable

-- Các thông số camera
local cameraDistance = 10         -- Khoảng cách giữa camera và nhân vật (zoom)
local cameraYaw = 0               -- Góc xoay ngang (yaw)
local cameraPitch = 20            -- Góc xoay dọc (pitch)
local rotateSpeed = 0.2           -- Tốc độ xoay camera
local zoomSpeed = 0.1             -- Tốc độ zoom (điều chỉnh phù hợp)
local minDistance = 5             -- Zoom tối thiểu
local maxDistance = 50            -- Zoom tối đa

local isTouchDevice = UserInputService.TouchEnabled

---------------------------
-- Xử lý nhập liệu Desktop
---------------------------
if not isTouchDevice then
    -- Khóa chuột để nhận input chính xác
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Xoay camera bằng di chuyển chuột
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if customCameraEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Delta
            cameraYaw = cameraYaw - delta.X * rotateSpeed
            cameraPitch = cameraPitch - delta.Y * rotateSpeed
            cameraPitch = math.clamp(cameraPitch, -89, 89)
        end
    end)

    -- Nhận các phím và sự kiện cuộn chuột
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if customCameraEnabled then
                cameraDistance = math.clamp(cameraDistance - input.Position.Z * zoomSpeed, minDistance, maxDistance)
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.V then
                -- Toggle chuyển đổi giữa custom camera và camera mặc định
                customCameraEnabled = not customCameraEnabled
                if customCameraEnabled then
                    camera.CameraType = Enum.CameraType.Scriptable
                else
                    camera.CameraType = Enum.CameraType.Custom
                end
            elseif input.KeyCode == Enum.KeyCode.R then
                -- Reset góc quay và zoom về mặc định
                cameraYaw = 0
                cameraPitch = 20
                cameraDistance = 10
            end
        end
    end)
end

---------------------------
-- Xử lý nhập liệu Mobile
---------------------------
if isTouchDevice then
    local activeTouches = {}   -- Lưu trữ các cảm ứng đang hoạt động
    local lastTouchDistance = nil

    UserInputService.TouchStarted:Connect(function(touch, processed)
        if processed then return end
        activeTouches[touch.FingerId] = {position = touch.Position, delta = Vector2.new(0,0)}
    end)

    UserInputService.TouchMoved:Connect(function(touch, processed)
        if processed then return end
        local data = activeTouches[touch.FingerId]
        if data then
            local newPos = touch.Position
            data.delta = newPos - data.position
            data.position = newPos
        end
    end)

    UserInputService.TouchEnded:Connect(function(touch, processed)
        if processed then return end
        activeTouches[touch.FingerId] = nil
        if next(activeTouches) == nil then
            lastTouchDistance = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
        local touchCount = 0
        for _, _ in pairs(activeTouches) do
            touchCount = touchCount + 1
        end

        if touchCount == 1 and customCameraEnabled then
            -- Với 1 ngón: xoay camera
            for _, data in pairs(activeTouches) do
                cameraYaw = cameraYaw - data.delta.X * rotateSpeed
                cameraPitch = cameraPitch - data.delta.Y * rotateSpeed
                cameraPitch = math.clamp(cameraPitch, -89, 89)
                data.delta = Vector2.new(0,0)
            end
        elseif touchCount >= 2 and customCameraEnabled then
            -- Với 2 ngón: pinch zoom
            local touchesList = {}
            for _, data in pairs(activeTouches) do
                table.insert(touchesList, data)
            end
            if #touchesList >= 2 then
                local pos1 = touchesList[1].position
                local pos2 = touchesList[2].position
                local currentDistance = (pos1 - pos2).Magnitude
                if lastTouchDistance then
                    local deltaDistance = currentDistance - lastTouchDistance
                    cameraDistance = math.clamp(cameraDistance - deltaDistance * zoomSpeed, minDistance, maxDistance)
                end
                lastTouchDistance = currentDistance
            end
        end
    end)
end

-----------------------------------
-- Cập nhật vị trí & góc nhìn camera
-----------------------------------
RunService.RenderStepped:Connect(function()
    if customCameraEnabled and character and hrp then
        local pivot = hrp.Position  -- Điểm xoay của camera là vị trí của HumanoidRootPart
        local offset = Vector3.new(0, 0, cameraDistance)
        local rotation = CFrame.Angles(math.rad(cameraPitch), math.rad(cameraYaw), 0)
        local cameraOffset = rotation * offset
        local cameraPosition = pivot + cameraOffset
        -- Đặt camera sao cho luôn nhìn về pivot (nhân vật)
        camera.CFrame = CFrame.new(cameraPosition, pivot)
    end
end)
