--[[    
  Advanced Camera Gun Script - Pro Edition 6.2 (Nâng cấp)
--]]    

-------------------------------------
-- CẤU HÌNH (có thể điều chỉnh) --
-------------------------------------
local LOCK_RADIUS = 700               -- Bán kính ghim mục tiêu (Auto Lock)
local HEALTH_BOARD_RADIUS = 100       -- Bán kính hiển thị Health Board
local PREDICTION_ENABLED = true       -- Bật/tắt dự đoán mục tiêu
local UNLOCK_RADIUS = 1200            -- Bán kính hủy lock
local CAMERA_SMOOTH_FACTOR = 1      -- Hệ số làm mượt camera (0.1 = mượt, 1 = tức thì)

-- Các tham số khác
local CLOSE_RADIUS = 7                -- Khi mục tiêu gần, giữ Y của camera
local HEIGHT_DIFFERENCE_THRESHOLD = 3 -- Ngưỡng chênh lệch độ cao giữa camera & mục tiêu
local MOVEMENT_THRESHOLD = 0.1

-------------------------------------
-- Dịch vụ & Đối tượng --
-------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-------------------------------------
-- Biến trạng thái toàn cục --
-------------------------------------
local aimActive = true          -- Script hoạt động
local locked = false            -- Aim lock On/Off
local currentTarget = nil       -- Mục tiêu hiện tại
local lastLocalPosition = nil  
local lastMovementTime = tick()

-- Bảng lưu Health Board (key = Character)
local healthBoards = {}

-------------------------------------
-- GIAO DIỆN GUI (Phiên bản tối giản) --
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")
screenGui.Name = "AdvancedCameraGUI"

-- Kích thước cơ bản cho các nút
local baseToggleSize = Vector2.new(100, 50)
local baseButtonSize = Vector2.new(30, 30)

-- Hàm thêm hiệu ứng hover cho nút
local function addHoverEffect(button, baseSize)
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, baseSize.X * 1.1, 0, baseSize.Y * 1.1)})
        tween:Play()
    end)
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, baseSize.X, 0, baseSize.Y)})
        tween:Play()
    end)
end

-- Nút Toggle (On/Off Aim)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Parent = screenGui
toggleButton.Size = UDim2.new(0, baseToggleSize.X, 0, baseToggleSize.Y)
toggleButton.Position = UDim2.new(0.85, 0, 0.03, 0)
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.Text = "OFF"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
toggleButton.TextColor3 = Color3.new(1,1,1)
local toggleUICorner = Instance.new("UICorner", toggleButton)
toggleUICorner.CornerRadius = UDim.new(0, 10)
local toggleUIStroke = Instance.new("UIStroke", toggleButton)
toggleUIStroke.Color = Color3.new(1,1,1)
toggleUIStroke.Thickness = 2
addHoverEffect(toggleButton, baseToggleSize)

-- Nút Close (X)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Parent = screenGui
closeButton.Size = UDim2.new(0, baseButtonSize.X, 0, baseButtonSize.Y)
closeButton.Position = UDim2.new(0.75, 0, 0.03, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
closeButton.TextColor3 = Color3.new(1,1,1)
local closeUICorner = Instance.new("UICorner", closeButton)
closeUICorner.CornerRadius = UDim.new(0, 10)
local closeUIStroke = Instance.new("UIStroke", closeButton)
closeUIStroke.Color = Color3.new(1,1,1)
closeUIStroke.Thickness = 2
addHoverEffect(closeButton, baseButtonSize)

-------------------------------------
-- Sự kiện GUI --
-------------------------------------
closeButton.MouseButton1Click:Connect(function()
    aimActive = not aimActive
    toggleButton.Visible = aimActive
    if not aimActive then
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
        locked = false
        currentTarget = nil
    else
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    locked = not locked
    if locked then
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
        currentTarget = nil
    end
end)

-------------------------------------
-- Các hàm tiện ích --
-------------------------------------
local function updateLocalMovement()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local currentPos = character.HumanoidRootPart.Position
        if lastLocalPosition and (currentPos - lastLocalPosition).Magnitude > MOVEMENT_THRESHOLD then
            lastMovementTime = tick()
        end
        lastLocalPosition = currentPos
    end
end

local function getTargetsInRadius(radius)
    local targets = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return targets
    end
    local localPos = character.HumanoidRootPart.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("Humanoid") then
                if targetChar.Humanoid.Health > 0 then
                    local dist = (targetChar.HumanoidRootPart.Position - localPos).Magnitude
                    if dist <= radius then
                        table.insert(targets, targetChar)
                    end
                end
            end
        end
    end
    return targets
end

local function selectTarget()
    local targets = getTargetsInRadius(LOCK_RADIUS)
    if #targets == 0 then return nil end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local localPos = localCharacter.HumanoidRootPart.Position
    local bestTarget, bestScore = nil, math.huge
    for _, target in ipairs(targets) do
        if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") then
            local humanoid = target.Humanoid
            if humanoid.Health > 0 then
                local distance = (target.HumanoidRootPart.Position - localPos).Magnitude
                local dirToTarget = (target.HumanoidRootPart.Position - localPos).Unit
                local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToTarget), -1, 1))
                local score = distance + angleDiff * 100
                if distance < 100 then
                    score = score * (distance / 100)
                end
                if score < bestScore then
                    bestScore = score
                    bestTarget = target
                end
            end
        end
    end
    return bestTarget
end

local function isValidTarget(target)
    if not target then return false end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local humanoid = target:FindFirstChild("Humanoid")
    local localCharacter = LocalPlayer.Character
    if not hrp or not humanoid or not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if humanoid.Health <= 0 then return false end
    local distance = (hrp.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    return distance <= UNLOCK_RADIUS
end

local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local distance = (hrp.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    if (not PREDICTION_ENABLED) or (distance < 350) then
        return head.Position
    end
    local predictedTime = distance / 50
    predictedTime = math.clamp(predictedTime, 1, 2)
    return hrp.Position + hrp.Velocity * predictedTime
end

local function calculateCameraRotation(targetPosition)
    local camPos = Camera.CFrame.Position
    local direction = targetPosition - camPos
    local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
    local newCFrame
    if math.abs(targetPosition.Y - camPos.Y) > HEIGHT_DIFFERENCE_THRESHOLD then
        newCFrame = CFrame.new(camPos, targetPosition)
    else
        if horizontalDirection.Magnitude > 0 then
            newCFrame = CFrame.new(camPos, camPos + horizontalDirection)
        else
            newCFrame = Camera.CFrame
        end
    end
    return newCFrame
end

local function updateHealthBoardForTarget(target)
    if not target or not target:FindFirstChild("Head") or not target:FindFirstChild("Humanoid") then
        return
    end
    local humanoid = target.Humanoid
    if humanoid.Health <= 0 then
        if healthBoards[target] then
            healthBoards[target]:Destroy()
            healthBoards[target] = nil
        end
        return
    end

    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
    local distance = (target.HumanoidRootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    if distance > HEALTH_BOARD_RADIUS then
        if healthBoards[target] then
            healthBoards[target]:Destroy()
            healthBoards[target] = nil
        end
        return
    end

    local headSize = target.Head.Size
    local boardWidth = headSize.X * 45
    local boardHeight = headSize.Y * 3
    if not healthBoards[target] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = target.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 100, 0)
        billboard.Parent = target

        local bg = Instance.new("Frame", billboard)
        bg.Name = "Background"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BorderSizePixel = 0

        local bgStroke = Instance.new("UIStroke", bg)
        bgStroke.Color = Color3.fromRGB(255,255,255)
        bgStroke.Thickness = 2

        local bgCorner = Instance.new("UICorner", bg)
        bgCorner.CornerRadius = UDim.new(0, 10)

        local healthFill = Instance.new("Frame", bg)
        healthFill.Name = "HealthFill"
        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        healthFill.Size = UDim2.new(ratio, 0, 1, 0)
        healthFill.BackgroundColor3 = (ratio > 0.7 and Color3.fromRGB(0,255,0)) or (ratio > 0.25 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(255,0,0)
        healthFill.BorderSizePixel = 0

        local fillCorner = Instance.new("UICorner", healthFill)
        fillCorner.CornerRadius = UDim.new(0, 10)

        healthBoards[target] = billboard
    else
        local billboard = healthBoards[target]
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 1, 0)
        local bg = billboard:FindFirstChild("Background")
        if bg then
            local healthFill = bg:FindFirstChild("HealthFill")
            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            if healthFill then
                healthFill.Size = UDim2.new(ratio, 0, 1, 0)
                healthFill.BackgroundColor3 = (ratio > 0.7 and Color3.fromRGB(0,255,0)) or (ratio > 0.25 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(255,0,0)
            end
        end
    end
end

local function updateAllHealthBoards()
    local targets = getTargetsInRadius(HEALTH_BOARD_RADIUS)
    for _, target in ipairs(targets) do
        updateHealthBoardForTarget(target)
    end
end

-------------------------------------
-- Main Loop: RenderStepped Update --
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        -- Auto Lock Logic
        if not locked then
            local potentialTargets = getTargetsInRadius(LOCK_RADIUS)
            if #potentialTargets > 0 then
                currentTarget = selectTarget()
                if currentTarget then
                    locked = true
                    toggleButton.Text = "ON"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
                end
            end
        else
            if currentTarget then
                local distance = (currentTarget.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance > UNLOCK_RADIUS then
                    locked = false
                    currentTarget = nil
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
                end
            end
        end

        if locked and currentTarget then
            local predictedPos = predictTargetPosition(currentTarget)
            if predictedPos then
                local newCFrame = calculateCameraRotation(predictedPos)
                -- Làm mượt camera
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, CAMERA_SMOOTH_FACTOR)
            end
        end

        -- Hiệu ứng cho nút Toggle
        if locked then
            local oscillation = 0.05 * math.sin(tick() * 5)
            local newWidth = baseToggleSize.X * (1 + oscillation)
            local newHeight = baseToggleSize.Y * (1 + oscillation)
            toggleButton.Size = UDim2.new(0, newWidth, 0, newHeight)
        else
            toggleButton.Size = UDim2.new(0, baseToggleSize.X, 0, baseToggleSize.Y)
        end
    end

    updateAllHealthBoards()
end)

-------------------------------------
-- Xử lý khi Player/Character rời server --
-------------------------------------
Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer and player.Character and healthBoards[player.Character] then
        healthBoards[player.Character]:Destroy()
        healthBoards[player.Character] = nil
    end
end)

LocalPlayer.CharacterRemoving:Connect(function(character)
    currentTarget = nil
    locked = false
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    lastLocalPosition = hrp.Position
    lastMovementTime = tick()
    currentTarget = nil
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
    Camera.CameraType = Enum.CameraType.Custom
end)
