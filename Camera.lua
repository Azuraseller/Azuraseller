local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Khởi tạo custom camera
local customCameraEnabled = true
camera.CameraType = Enum.CameraType.Scriptable

-- Các thông số camera
local cameraDistance = 10         -- Khoảng cách giữa camera và nhân vật (zoom)
local cameraYaw = 0               -- Góc xoay ngang (yaw)
local cameraPitch = 20            -- Góc xoay dọc (pitch)
local rotateSpeed = 0.2           -- Tốc độ xoay camera
local zoomSpeed = 0.1             -- Tốc độ zoom
local minDistance = 5             -- Khoảng cách zoom tối thiểu
local maxDistance = 50            -- Khoảng cách zoom tối đa

local isTouchDevice = UserInputService.TouchEnabled

--------------------------------------------------
-- Xử lý nhập liệu cho Desktop (sử dụng chuột)
--------------------------------------------------
if not isTouchDevice then
    -- Nếu gặp lỗi với việc khóa chuột, bạn có thể tạm thời bỏ qua 2 dòng dưới đây.
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Xoay camera bằng chuột
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if customCameraEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Delta
            cameraYaw = cameraYaw - delta.X * rotateSpeed
            cameraPitch = cameraPitch - delta.Y * rotateSpeed
            cameraPitch = math.clamp(cameraPitch, -80, 80)
        end
    end)

    -- Zoom bằng chuột cuộn và các phím chức năng
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if customCameraEnabled then
                cameraDistance = math.clamp(cameraDistance - input.Position.Z * zoomSpeed, minDistance, maxDistance)
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.V then
                -- Chuyển đổi giữa custom camera và camera mặc định
                customCameraEnabled = not customCameraEnabled
                if customCameraEnabled then
                    camera.CameraType = Enum.CameraType.Scriptable
                else
                    camera.CameraType = Enum.CameraType.Custom
                end
            elseif input.KeyCode == Enum.KeyCode.R then
                -- Reset góc quay và khoảng cách zoom về mặc định
                cameraYaw = 0
                cameraPitch = 20
                cameraDistance = 10
            end
        end
    end)
end

--------------------------------------------------
-- Xử lý nhập liệu cho Mobile (sử dụng cảm ứng)
--------------------------------------------------
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
                cameraPitch = math.clamp(cameraPitch, -80, 80)
                data.delta = Vector2.new(0,0)
            end
        elseif touchCount >= 2 and customCameraEnabled then
            -- Với 2 ngón: pinch để zoom
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

--------------------------------------------------
-- Cập nhật vị trí & góc nhìn của camera mỗi frame
--------------------------------------------------
RunService.RenderStepped:Connect(function()
    if customCameraEnabled and character and hrp then
        -- Đảm bảo camera đang ở chế độ Scriptable
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        local pivot = hrp.Position

        -- Tính toán offset bằng cách nhân các CFrame để xoay theo pitch và yaw
        local cameraOffset = CFrame.new(0, 0, cameraDistance) *
                             CFrame.Angles(math.rad(cameraPitch), 0, 0) *
                             CFrame.Angles(0, math.rad(cameraYaw), 0)
        local cameraPosition = pivot + cameraOffset.Position

        -- Dùng CFrame.lookAt để đảm bảo camera luôn hướng về nhân vật
        camera.CFrame = CFrame.lookAt(cameraPosition, pivot)
    end
end)
