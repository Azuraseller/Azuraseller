local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Kích hoạt camera scriptable
camera.CameraType = Enum.CameraType.Scriptable

-- Thông số camera
local cameraDistance = 10     -- Khoảng cách mặc định
local minDistance = 5         -- Zoom tối thiểu
local maxDistance = 50        -- Zoom tối đa
local cameraYaw = 0           -- Góc xoay ngang
local cameraPitch = 20        -- Góc xoay dọc
local rotateSpeed = 0.2       -- Tốc độ xoay camera
local zoomSpeed = 2           -- Tốc độ zoom
local isTouchDevice = UserInputService.TouchEnabled -- Kiểm tra thiết bị

--------------------------------------------------
-- Xử lý nhập liệu cho PC (chuột)
--------------------------------------------------
if not isTouchDevice then
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Xoay camera bằng chuột
    UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            cameraYaw = cameraYaw - input.Delta.X * rotateSpeed
            cameraPitch = math.clamp(cameraPitch - input.Delta.Y * rotateSpeed, -80, 80)
        end
    end)

    -- Zoom bằng cuộn chuột
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            cameraDistance = math.clamp(cameraDistance - input.Position.Z * zoomSpeed, minDistance, maxDistance)
        end
    end)
end

--------------------------------------------------
-- Xử lý nhập liệu cho Mobile (cảm ứng)
--------------------------------------------------
if isTouchDevice then
    local touchStart = nil
    local lastPinchDistance = nil

    UserInputService.TouchStarted:Connect(function(touch)
        if not touchStart then
            touchStart = touch.Position
        end
    end)

    UserInputService.TouchMoved:Connect(function(touch)
        if not touchStart then return end

        -- Xoay camera bằng cách di chuyển một ngón tay
        local delta = touch.Position - touchStart
        cameraYaw = cameraYaw - delta.X * rotateSpeed
        cameraPitch = math.clamp(cameraPitch - delta.Y * rotateSpeed, -80, 80)
        touchStart = touch.Position
    end)

    UserInputService.TouchEnded:Connect(function(touch)
        touchStart = nil
    end)

    -- Zoom bằng cách dùng hai ngón tay
    UserInputService.TouchPinch:Connect(function(scale)
        cameraDistance = math.clamp(cameraDistance / scale, minDistance, maxDistance)
    end)
end

--------------------------------------------------
-- Cập nhật vị trí camera mỗi frame
--------------------------------------------------
RunService.RenderStepped:Connect(function()
    if character and hrp then
        -- Đặt lại camera type để đảm bảo không bị lỗi
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        -- Vị trí trung tâm của camera (không bị lệ thuộc vào hướng nhân vật)
        local pivot = hrp.Position

        -- Tính toán vị trí camera theo góc xoay và khoảng cách
        local offset = CFrame.Angles(0, math.rad(cameraYaw), 0) * CFrame.Angles(math.rad(cameraPitch), 0, 0) * CFrame.new(0, 0, cameraDistance)
        local cameraPosition = pivot + offset.Position

        -- Cập nhật CFrame của camera
        camera.CFrame = CFrame.lookAt(cameraPosition, pivot)
    end
end)
