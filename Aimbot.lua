--[[    
  Advanced Camera Gun Script - Pro Edition 6.5
  --------------------------------------------------
  Cải tiến:
   1. Camera được điều chỉnh bằng Lerp (sử dụng deltaTime và CAMERA_SMOOTH_FACTOR) để tránh giật, rung khi ghim vào mục tiêu.
   2. Khi Aim On và có mục tiêu hợp lệ, Aim tự động bật và luôn ghim vào head của mục tiêu (dùng head.Position nếu khoảng cách < MIN_PREDICTION_DISTANCE, nếu ≥ thì dự đoán theo vận tốc).
   3. Nếu mục tiêu ở gần (≤15 đơn vị) trong ít nhất 1 giây, người dùng có thể vuốt xuống (với đủ độ lệch theo trục Y và ít nhiễu theo trục X) để kích hoạt hành động đặc biệt (ví dụ: tiêu diệt mục tiêu).
   4. Chức năng Hitbox đã bị loại bỏ.
--]]    

-------------------------------------
-- CẤU HÌNH (có thể điều chỉnh) --
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 900       -- Bán kính hiển thị Health Board
local PREDICTION_ENABLED = true        -- Bật/tắt dự đoán mục tiêu

-- Dự đoán chỉ hoạt động nếu khoảng cách ≥ MIN_PREDICTION_DISTANCE; nếu nhỏ hơn luôn dùng head.Position
local MIN_PREDICTION_DISTANCE = 350

-- Các tham số khác
local CLOSE_RADIUS = 7                -- Khi mục tiêu gần, giữ Y của camera
local HEIGHT_DIFFERENCE_THRESHOLD = 5 -- Ngưỡng chênh độ cao giữa camera & mục tiêu
local MOVEMENT_THRESHOLD = 0.1
local STATIONARY_TIMEOUT = 5

-- Tham số cho camera smoothing (cao = mượt hơn)
local CAMERA_SMOOTH_FACTOR = 8

-- Cấu hình cho swipe down:
local NEAR_DISTANCE = 15              -- Mục tiêu cách ≤15 đơn vị
local SWIPE_WAIT_TIME = 1             -- Phải duy trì khoảng cách này ít nhất 1 giây
local SWIPE_THRESHOLD = 50            -- Ngưỡng vuốt xuống (pixel theo trục Y)
local SWIPE_HORIZONTAL_RATIO = 0.5    -- Đảm bảo swipe chủ yếu theo trục Y

-------------------------------------
-- Dịch vụ & Đối tượng --
-------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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

-- Các biến hỗ trợ swipe down
local swipeAvailable = false
local swipeAvailableStartTime = nil
local swipeStartPos = nil
local swipeStartTime = nil
local swipeCooldown = false

-- (Nếu cần hiển thị Health Board, giữ lại bảng này; nếu không thì có thể xoá)
local healthBoards = {}

-------------------------------------
-- GIAO DIỆN GUI (Phiên bản tối giản: chỉ gồm nút Toggle & Close) --
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")
screenGui.Name = "AdvancedCameraGUI"

-- Kích thước nút
local baseToggleSize = Vector2.new(100, 50)
local baseButtonSize = Vector2.new(30, 30)

-- Hàm hiệu ứng hover (scale tween)
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

-- Nút Toggle (Aim On/Off)
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
-- Sự kiện GUI cho Toggle & Close --
-------------------------------------
closeButton.MouseButton1Click:Connect(function()
    aimActive = not aimActive
    toggleButton.Visible = aimActive
    if not aimActive then
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
        locked = false
        currentTarget = nil
        swipeAvailable = false
        swipeAvailableStartTime = nil
    else
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
    end
end)

-- Khi bấm Toggle, bật Aim (locked luôn true)
toggleButton.MouseButton1Click:Connect(function()
    locked = true
    toggleButton.Text = "ON"
    toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
end)

-------------------------------------
-- Các hàm tiện ích cho Camera Gun --
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

local function getEnemiesInRadius(radius)
    local enemies = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return enemies
    end
    local localPos = character.HumanoidRootPart.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local enemyChar = player.Character
            if enemyChar and enemyChar:FindFirstChild("HumanoidRootPart") and enemyChar:FindFirstChild("Humanoid") then
                if enemyChar.Humanoid.Health > 0 then
                    local dist = (enemyChar.HumanoidRootPart.Position - localPos).Magnitude
                    if dist <= radius then
                        table.insert(enemies, enemyChar)
                    end
                end
            end
        end
    end
    return enemies
end

-- Hàm chọn mục tiêu với ưu tiên theo máu:
-- Ưu tiên mục tiêu có Health của mục tiêu ≥ 70% của máu LocalPlayer.
local function selectTarget()
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    if #enemies == 0 then return nil end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") or not localChar:FindFirstChild("Humanoid") then
        return nil
    end
    local localPos = localChar.HumanoidRootPart.Position
    local localHealth = localChar.Humanoid.Health
    local prioritized = {}
    local others = {}
    for _, enemy in ipairs(enemies) do
        local enemyHumanoid = enemy:FindFirstChild("Humanoid")
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        if enemyHumanoid and enemyHRP and enemyHumanoid.Health > 0 then
            local score = (enemyHRP.Position - localPos).Magnitude
            local dirToEnemy = (enemyHRP.Position - localPos).Unit
            local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToEnemy), -1, 1))
            score = score + angleDiff * 100
            if enemyHumanoid.Health >= localHealth * 0.7 then
                table.insert(prioritized, {enemy = enemy, score = score})
            else
                table.insert(others, {enemy = enemy, score = score})
            end
        end
    end
    local best = nil
    local bestScore = math.huge
    local function selectFrom(list)
        for _, data in ipairs(list) do
            if data.score < bestScore then
                bestScore = data.score
                best = data.enemy
            end
        end
    end
    if #prioritized > 0 then
        selectFrom(prioritized)
    else
        selectFrom(others)
    end
    return best
end

local function isValidTarget(target)
    if not target then return false end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local humanoid = target:FindFirstChild("Humanoid")
    local localChar = LocalPlayer.Character
    if not hrp or not humanoid or not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if humanoid.Health <= 0 then return false end
    local distance = (hrp.Position - localChar.HumanoidRootPart.Position).Magnitude
    return distance <= LOCK_RADIUS
end

-- Hàm dự đoán vị trí mục tiêu:
-- Nếu khoảng cách < MIN_PREDICTION_DISTANCE, dùng head.Position; nếu ≥ và Prediction bật thì dự đoán theo vận tốc.
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end
    local distance = (hrp.Position - localChar.HumanoidRootPart.Position).Magnitude
    if (not PREDICTION_ENABLED) or (distance < MIN_PREDICTION_DISTANCE) then
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

-- Health Board: hiển thị thanh máu của mục tiêu (nếu cần, không thay đổi)
local function updateHealthBoardForTarget(enemy)
    if not enemy or not enemy:FindFirstChild("Head") or not enemy:FindFirstChild("Humanoid") then
        return
    end
    local humanoid = enemy.Humanoid
    if humanoid.Health <= 0 then
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
        return
    end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return
    end
    local distance = (enemy.HumanoidRootPart.Position - localChar.HumanoidRootPart.Position).Magnitude
    if distance > HEALTH_BOARD_RADIUS then
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
        return
    end
    local headSize = enemy.Head.Size
    local boardWidth = headSize.X * 70
    local boardHeight = headSize.Y * 5
    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = enemy.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 1, 0)
        billboard.Parent = enemy

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

        healthBoards[enemy] = billboard
    else
        local billboard = healthBoards[enemy]
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
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local enemyChar = player.Character
            if enemyChar then
                updateHealthBoardForTarget(enemyChar)
            end
        end
    end
end

-------------------------------------
-- Main Loop: RenderStepped Update --
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
        end
        
        if currentTarget then
            locked = true  -- Khi có mục tiêu, Aim tự bật
            toggleButton.Text = "ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
        else
            locked = false
            toggleButton.Text = "OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
        end

        if currentTarget and locked then
            local enemyHumanoid = currentTarget:FindFirstChild("Humanoid")
            local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
            local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if enemyHumanoid and enemyHRP and localHRP then
                local distance = (enemyHRP.Position - localHRP.Position).Magnitude
                if enemyHumanoid.Health <= 0 or distance > LOCK_RADIUS then
                    currentTarget = nil
                    locked = false
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        local targetCFrame = calculateCameraRotation(predictedPos)
                        local smoothAlpha = 1 - math.exp(-CAMERA_SMOOTH_FACTOR * deltaTime)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothAlpha)
                    end
                end
            end
        end

        -- Hiệu ứng cho nút Toggle (oscillation)
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
-- Xử lý Input: Phát hiện vuốt xuống (swipe down) --
-------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        if swipeAvailable then
            swipeStartPos = input.Position
            swipeStartTime = tick()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    -- Kiểm tra xem nếu có mục tiêu ở gần, đánh dấu khả năng swipe
    if currentTarget and isValidTarget(currentTarget) then
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
        if localHRP and enemyHRP then
            local dist = (enemyHRP.Position - localHRP.Position).Magnitude
            if dist <= NEAR_DISTANCE then
                if not swipeAvailableStartTime then
                    swipeAvailableStartTime = tick()
                elseif tick() - swipeAvailableStartTime >= SWIPE_WAIT_TIME then
                    swipeAvailable = true
                end
            else
                swipeAvailableStartTime = nil
                swipeAvailable = false
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if swipeStartPos and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        local endPos = input.Position
        local deltaY = endPos.Y - swipeStartPos.Y  -- Y tăng xuống dưới
        local deltaX = endPos.X - swipeStartPos.X
        if deltaY >= SWIPE_THRESHOLD and math.abs(deltaX) < SWIPE_HORIZONTAL_RATIO * deltaY and not swipeCooldown then
            -- Vuốt xuống được xác nhận
            print("Swipe Down Detected!")
            local enemyHumanoid = currentTarget and currentTarget:FindFirstChild("Humanoid")
            if enemyHumanoid and enemyHumanoid.Health > 0 then
                enemyHumanoid.Health = 0
                print("Target eliminated by swipe down!")
            end
            swipeCooldown = true
            delay(1, function() swipeCooldown = false end)
        end
        swipeStartPos = nil
        swipeStartTime = nil
    end
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
    swipeAvailable = false
    swipeAvailableStartTime = nil
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    lastLocalPosition = hrp.Position
    lastMovementTime = tick()
    currentTarget = nil
    swipeAvailable = false
    swipeAvailableStartTime = nil
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
    Camera.CameraType = Enum.CameraType.Custom
end)
