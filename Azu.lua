-- Blox Fruits Aimbot & Camera 2 - Phiên bản Nâng Cấp Cao Cấp (Cải tiến)

-- Khai báo các biến toàn cục
local Camera = game.Workspace.CurrentCamera
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local target = nil
local predictionEnabled = true
local predictionFactor = 0.5  -- Hệ số dự đoán
local fovRadius = 50  -- Bán kính FOV
local smoothness = 0.1  -- Độ mượt của chuyển động Camera
local maxTargetDistance = 100  -- Khoảng cách tối đa để nhắm mục tiêu
local predictionMode = "kalman"  -- Chế độ dự đoán: "basic", "advanced", hoặc "kalman"
local cameraMode = "dynamic"  -- Chế độ Camera: "first-person", "third-person", hoặc "dynamic"

-- Tạo Camera 2
local Camera2 = Instance.new("Camera")
Camera2.Parent = game.Workspace
Camera2.FieldOfView = 70
Camera2.CFrame = Camera.CFrame

-- Dữ liệu Kalman Filter
local kalmanData = {
    position = Vector3.new(),
    velocity = Vector3.new(),
    acceleration = Vector3.new(),
    lastUpdate = tick()
}

-- Hàm Kalman Filter để dự đoán vị trí
local function kalmanFilter(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return nil end
    local currentTime = tick()
    local deltaTime = currentTime - kalmanData.lastUpdate
    kalmanData.lastUpdate = currentTime

    local currentPos = target.HumanoidRootPart.Position
    local currentVel = target.HumanoidRootPart.Velocity
    local currentAcc = currentVel - kalmanData.velocity

    -- Cập nhật dữ liệu Kalman
    kalmanData.position = kalmanData.position + kalmanData.velocity * deltaTime + 0.5 * kalmanData.acceleration * deltaTime ^ 2
    kalmanData.velocity = currentVel
    kalmanData.acceleration = currentAcc

    return kalmanData.position
end

-- Dự đoán vị trí mục tiêu
local function predictTargetPosition(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return nil end

    if predictionMode == "basic" then
        -- Dự đoán cơ bản
        return target.HumanoidRootPart.Position + target.HumanoidRootPart.Velocity * predictionFactor
    elseif predictionMode == "advanced" then
        -- Dự đoán nâng cao
        local targetPosition = target.HumanoidRootPart.Position
        local targetVelocity = target.HumanoidRootPart.Velocity
        local targetAcceleration = targetVelocity - target.HumanoidRootPart.Velocity
        return targetPosition + targetVelocity * predictionFactor + targetAcceleration * predictionFactor / 2
    elseif predictionMode == "kalman" then
        -- Dự đoán với Kalman Filter
        return kalmanFilter(target)
    end
end

-- Tính toán góc nhắm và dự đoán mục tiêu
local function aimAtTarget(target)
    if not target then return end
    local predictedPosition = predictTargetPosition(target)
    if not predictedPosition then return end
    local targetDirection = (predictedPosition - Camera.CFrame.Position).unit
    local lookAtCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
    Camera.CFrame = Camera.CFrame:Lerp(lookAtCFrame, smoothness)
end

-- Cập nhật Camera 2 thông minh
local function updateCamera2()
    local closestTarget = getClosestTarget()
    if closestTarget then
        local targetPosition = closestTarget.HumanoidRootPart.Position

        if cameraMode == "third-person" then
            -- Camera theo dõi từ góc nhìn thứ ba
            Camera2.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, -15), targetPosition)
        elseif cameraMode == "first-person" then
            -- Camera theo dõi từ góc nhìn thứ nhất
            Camera2.CFrame = CFrame.new(targetPosition + Vector3.new(0, 5, 0), targetPosition)
        elseif cameraMode == "dynamic" then
            -- Camera động, tự động chọn góc tối ưu
            local distance = (player.Character.HumanoidRootPart.Position - targetPosition).Magnitude
            if distance > 50 then
                -- Chuyển sang góc nhìn thứ ba khi mục tiêu xa
                Camera2.CFrame = CFrame.new(targetPosition + Vector3.new(0, 15, -20), targetPosition)
            else
                -- Chuyển sang góc nhìn thứ nhất khi mục tiêu gần
                Camera2.CFrame = CFrame.new(targetPosition + Vector3.new(0, 5, 0), targetPosition)
            end
        end
    else
        Camera2.CFrame = Camera.CFrame
    end
end

-- Kiểm tra vật thể cản trở
local function isObstructed(target)
    local ray = Ray.new(Camera2.CFrame.Position, target.HumanoidRootPart.Position - Camera2.CFrame.Position)
    local hitPart, hitPosition = game.Workspace:FindPartOnRay(ray, player.Character, false, true)
    return hitPart ~= nil
end

-- Tìm mục tiêu gần nhất trong phạm vi FOV
local function getClosestTarget()
    local closestTarget = nil
    local closestDistance = maxTargetDistance
    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (Camera.CFrame.Position - obj.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance and (Camera.CFrame.Position - obj.HumanoidRootPart.Position).Unit:Dot(Camera.CFrame.LookVector) > 0 then
                    closestTarget = obj
                    closestDistance = distance
                end
            end
        end
    end
    return closestTarget
end

-- Cập nhật mỗi frame (mỗi khi trò chơi chạy)
game:GetService("RunService").Heartbeat:Connect(function()
    -- Cập nhật Camera 2 để theo dõi mục tiêu
    updateCamera2()
    
    -- Kiểm tra và tấn công mục tiêu nếu có
    if predictionEnabled then
        local closestTarget = getClosestTarget()
        if closestTarget then
            aimAtTarget(closestTarget)
        end
    end
end)

-- Điều khiển nâng cao
local userInputService = game:GetService("UserInputService")
userInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.C then
        -- Chuyển chế độ Camera
        if cameraMode == "third-person" then
            cameraMode = "first-person"
        elseif cameraMode == "first-person" then
            cameraMode = "dynamic"
        else
            cameraMode = "third-person"
        end
        print("Chế độ Camera: " .. cameraMode)
    elseif input.KeyCode == Enum.KeyCode.M then
        -- Chuyển chế độ dự đoán
        if predictionMode == "basic" then
            predictionMode = "advanced"
        elseif predictionMode == "advanced" then
            predictionMode = "kalman"
        else
            predictionMode = "basic"
        end
        print("Chế độ Dự Đoán: " .. predictionMode)
    end
end)
