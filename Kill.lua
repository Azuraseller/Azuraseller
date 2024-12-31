local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

-- Cài đặt cơ bản
local fov = 100
local maxDistance = 1000
local aimSensitivity = 0.1
local targetPart = "Head"
local aimMode = false
local autoAimEnabled = true
local dynamicFOV = true
local zoomEnabled = true
local skillMode = false
local lockOnEnabled = false
local smartAimEnabled = false
local lastUpdate = tick()
local updateInterval = 0.05 -- Cập nhật mỗi 50ms trên thiết bị di động
local maxUpdateInterval = 0.02 -- Cập nhật mỗi 20ms trên PC

-- Các đối tượng vẽ
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Filled = false
FOVring.Position = Cam.ViewportSize / 2
FOVring.Color = Color3.fromRGB(0, 255, 0)

local Reticle = Drawing.new("Circle")
Reticle.Visible = false
Reticle.Thickness = 2
Reticle.Color = Color3.fromRGB(255, 0, 0)
Reticle.Filled = true
Reticle.Radius = 10

-- Các hàm phụ trợ
local function predictTargetPosition(targetPart)
    if targetPart and targetPart.Parent then
        local target = targetPart.Parent
        local velocity = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Velocity or Vector3.zero
        local prediction = targetPart.Position + velocity * 0.25 -- Dự đoán vị trí sau 0.25 giây
        return prediction
    end
    return targetPart.Position
end

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

local function aimAtTarget(target)
    if aimMode and target and target.Character and target.Character:FindFirstChild(targetPart) then
        local part = target.Character:FindFirstChild(targetPart)
        local targetPosition = predictTargetPosition(part)
        local currentCFrame = Cam.CFrame
        local targetCFrame = CFrame.new(Cam.CFrame.Position, targetPosition)
        Cam.CFrame = currentCFrame:Lerp(targetCFrame, aimSensitivity)

        -- Zoom động
        if zoomEnabled then
            local distance = (Cam.CFrame.Position - targetPosition).Magnitude
            local zoomLevel = math.clamp(distance / maxDistance, 0.5, 1.5)
            Cam.FieldOfView = 70 / zoomLevel
        end
    else
        Cam.FieldOfView = 70
    end
end

local function updateFOVRing()
    if dynamicFOV then
        local closest = getClosestPlayer()
        if closest and closest.Character and closest.Character:FindFirstChild(targetPart) then
            local part = closest.Character:FindFirstChild(targetPart)
            local distance = (Cam.CFrame.Position - part.Position).Magnitude
            -- Thay đổi kích thước vòng tròn POV dựa trên khoảng cách
            FOVring.Radius = math.clamp(fov * (1 - (distance / maxDistance)), 20, fov)
        else
            FOVring.Radius = fov
        end
    end
end

local function rotateCharacterTowardsTarget(target)
    if target and target.Character and target.Character:FindFirstChild(targetPart) then
        local part = target.Character:FindFirstChild(targetPart)
        local targetPosition = predictTargetPosition(part)
        local direction = (targetPosition - Cam.CFrame.Position).unit
        local humanoid = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(targetPosition)
            humanoid:LookAt(targetPosition)
        end
    end
end

local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.F then
        aimMode = not aimMode
    elseif input.KeyCode == Enum.KeyCode.G then
        autoAimEnabled = not autoAimEnabled
    elseif input.KeyCode == Enum.KeyCode.P then
        skillMode = not skillMode
    elseif input.KeyCode == Enum.KeyCode.L then
        lockOnEnabled = not lockOnEnabled
    elseif input.KeyCode == Enum.KeyCode.S then
        smartAimEnabled = not smartAimEnabled
    end
end

UIS.InputBegan:Connect(onKeyDown)

-- Tối ưu hóa hiệu suất cho thiết bị di động
local lastUpdate = tick()

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    local deltaTime = currentTime - lastUpdate

    -- Điều chỉnh tần suất cập nhật dựa trên thiết bị
    if deltaTime >= (UIS.TouchEnabled and updateInterval or maxUpdateInterval) then
        lastUpdate = currentTime

        local closest = getClosestPlayer()
        if closest then
            aimAtTarget(closest)
            updateFOVRing()

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

            -- Hướng nhân vật về mục tiêu
            if lockOnEnabled then
                rotateCharacterTowardsTarget(closest)
            end
        else
            Reticle.Visible = false
        end
    end
end)
