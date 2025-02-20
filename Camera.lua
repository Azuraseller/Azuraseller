local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- Đặt camera luôn ở chế độ Scriptable
camera.CameraType = Enum.CameraType.Scriptable

-- Các thông số camera
local cameraDistance = 10      -- Khoảng cách ban đầu giữa camera và nhân vật
local minDistance = 5          -- Khoảng cách zoom gần nhất
local maxDistance = 50         -- Khoảng cách zoom xa nhất
local cameraYaw = 0            -- Góc xoay ngang (yaw)
local cameraPitch = 20         -- Góc xoay dọc (pitch)

-- Độ nhạy (sensitivity)
local desktopRotateSpeed = 0.2 -- Tốc độ xoay trên desktop
local desktopZoomSpeed = 2     -- Tốc độ zoom trên desktop

local mobileRotateSpeed = 0.5  -- Tốc độ xoay trên mobile (tăng lên cho nhanh hơn)
local mobileZoomSpeed = 0.05   -- Hệ số zoom cho pinch (đơn vị: thay đổi pixel nhân với hệ số)

local isTouchDevice = UserInputService.TouchEnabled

--------------------------------------------------
-- Xử lý nhập liệu cho Desktop (sử dụng chuột)
--------------------------------------------------
if not isTouchDevice then
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    -- Xoay camera bằng di chuyển chuột
    UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            cameraYaw = cameraYaw - input.Delta.X * desktopRotateSpeed
            cameraPitch = math.clamp(cameraPitch - input.Delta.Y * desktopRotateSpeed, -80, 80)
        end
    end)

    -- Zoom bằng cuộn chuột
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            cameraDistance = math.clamp(cameraDistance - input.Position.Z * desktopZoomSpeed, minDistance, maxDistance)
        end
    end)
end

--------------------------------------------------
-- Xử lý nhập liệu cho Mobile (sử dụng cảm ứng)
--------------------------------------------------
if isTouchDevice then
    -- Sử dụng bảng để lưu trữ thông tin của từng cảm ứng
    local activeTouches = {}
    local previousPinchDistance = nil

    -- Hàm đếm số cảm ứng đang hoạt động
    local function countActiveTouches()
        local count = 0
        for _ in pairs(activeTouches) do
            count = count + 1
        end
        return count
    end

    -- Khi cảm ứng bắt đầu: lưu cả vị trí hiện tại và vị trí trước đó
    UserInputService.TouchStarted:Connect(function(touch, processed)
        if processed then return end
        activeTouches[touch.FingerId] = { current = touch.Position, previous = touch.Position }
    end)

    -- Cập nhật vị trí của cảm ứng
    UserInputService.TouchMoved:Connect(function(touch, processed)
        if processed then return end
        if activeTouches[touch.FingerId] then
            local data = activeTouches[touch.FingerId]
            data.previous = data.current
            data.current = touch.Position
        end
    end)

    -- Khi cảm ứng kết thúc: xóa dữ liệu cảm ứng đó
    UserInputService.TouchEnded:Connect(function(touch, processed)
        if processed then return end
        activeTouches[touch.FingerId] = nil
        if countActiveTouches() < 2 then
            previousPinchDistance = nil
        end
    end)

    -- Xử lý nhập liệu mỗi frame cho mobile
    RunService.RenderStepped:Connect(function()
        local touches = {}
        for _, data in pairs(activeTouches) do
            table.insert(touches, data)
        end

        if #touches == 1 then
            -- Nếu chỉ có 1 cảm ứng: dùng để xoay camera
            local delta = touches[1].current - touches[1].previous
            cameraYaw = cameraYaw - delta.X * mobileRotateSpeed
            cameraPitch = math.clamp(cameraPitch - delta.Y * mobileRotateSpeed, -80, 80)
            -- Cập nhật lại vị trí trước cho cảm ứng đó
            touches[1].previous = touches[1].current

        elseif #touches >= 2 then
            -- Nếu có 2 cảm ứng: dùng để zoom (phát hiện pinch)
            local pos1 = touches[1].current
            local pos2 = touches[2].current
            local currentPinchDistance = (pos1 - pos2).Magnitude
            if previousPinchDistance then
                local deltaDistance = currentPinchDistance - previousPinchDistance
                cameraDistance = math.clamp(cameraDistance - deltaDistance * mobileZoomSpeed, minDistance, maxDistance)
            end
            previousPinchDistance = currentPinchDistance
        end
    end)
end

--------------------------------------------------
-- Cập nhật vị trí & góc nhìn của camera mỗi frame
--------------------------------------------------
RunService.RenderStepped:Connect(function()
    if character and hrp then
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        local pivot = hrp.Position  -- Điểm xoay của camera (vị trí nhân vật)
        -- Tính toán offset: xoay theo yaw rồi pitch, sau đó dịch về khoảng cách
        local offsetCFrame = CFrame.Angles(0, math.rad(cameraYaw), 0) *
                             CFrame.Angles(math.rad(cameraPitch), 0, 0) *
                             CFrame.new(0, 0, cameraDistance)
        local cameraPosition = pivot + offsetCFrame.Position

        -- Luôn đảm bảo camera nhìn về pivot
        camera.CFrame = CFrame.lookAt(cameraPosition, pivot)
    end
end)
