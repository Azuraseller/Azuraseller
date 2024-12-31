local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera

-- Cài đặt
local fov = 100
local maxDistance = 500
local aimSensitivity = 0.15
local targetPart = "Head"
local aimMode = false
local autoAimEnabled = true
local predictionEnabled = true
local dynamicLockOn = true
local zoomEnabled = true
local zoomFactor = 1.2

-- Vòng FOV
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Filled = false
FOVring.Position = Cam.ViewportSize / 2
FOVring.Color = Color3.fromRGB(128, 0, 128)

-- Tâm hướng
local Reticle = Drawing.new("Circle")
Reticle.Visible = false
Reticle.Thickness = 2
Reticle.Color = Color3.fromRGB(255, 255, 0)
Reticle.Filled = true
Reticle.Radius = 10

-- Dự đoán chuyển động mục tiêu
local function predictTargetPosition(targetPart)
    if targetPart and targetPart.Parent then
        local target = targetPart.Parent
        local velocity = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Velocity or Vector3.zero
        local prediction = targetPart.Position + velocity * 0.2 -- Dự đoán vị trí sau 0.2 giây
        return prediction
    end
    return targetPart.Position
end

-- Tìm mục tiêu gần nhất
local function getClosestPlayer()
    local nearest = nil
    local lastDistance = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) then
            local part = player.Character:FindFirstChild(targetPart)
            local screenPos, isVisible = Cam:WorldToViewportPoint(part.Position)
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - playerMousePos).Magnitude

            if distance < lastDistance and isVisible and distance < fov then
                lastDistance = distance
                nearest = player
            end
        end
    end

    return nearest
end

-- Nhắm mục tiêu
local function aimAtTarget(target)
    if aimMode and target and target.Character and target.Character:FindFirstChild(targetPart) then
        local part = target.Character:FindFirstChild(targetPart)
        local targetPosition = predictionEnabled and predictTargetPosition(part) or part.Position
        local currentCFrame = Cam.CFrame
        local targetCFrame = CFrame.new(Cam.CFrame.Position, targetPosition)
        Cam.CFrame = currentCFrame:Lerp(targetCFrame, aimSensitivity)

        -- Zoom động
        if zoomEnabled then
            local distance = (Cam.CFrame.Position - targetPosition).Magnitude
            local zoomLevel = math.clamp(distance / maxDistance, 0.5, 1.5) * zoomFactor
            Cam.FieldOfView = 70 / zoomLevel
        end
    else
        Cam.FieldOfView = 70 -- Reset zoom nếu không Aim
    end
end

-- Hiển thị thông tin mục tiêu
local function displayTargetInfo(target)
    if target and target.Character then
        local distance = (Cam.CFrame.Position - target.Character[targetPart].Position).Magnitude
        print("Mục tiêu:", target.Name, "Khoảng cách:", math.floor(distance))
    end
end

-- Phím tắt
local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.F then
        aimMode = not aimMode
    elseif input.KeyCode == Enum.KeyCode.G then
        autoAimEnabled = not autoAimEnabled
    elseif input.KeyCode == Enum.KeyCode.P then
        predictionEnabled = not predictionEnabled
    elseif input.KeyCode == Enum.KeyCode.L then
        dynamicLockOn = not dynamicLockOn
    end
end

UserInputService.InputBegan:Connect(onKeyDown)

-- Vòng lặp chính
RunService.RenderStepped:Connect(function()
    local closest = getClosestPlayer()
    if closest then
        aimAtTarget(closest)
        displayTargetInfo(closest)

        -- Cập nhật Reticle
        local part = closest.Character:FindFirstChild(targetPart)
        if part then
            local screenPos, isVisible = Cam:WorldToViewportPoint(part.Position)
            if isVisible then
                Reticle.Visible = true
                Reticle.Position = Vector2.new(screenPos.X, screenPos.Y)
            else
                Reticle.Visible = false
            end
        end
    else
        Reticle.Visible = false
    end
end)
