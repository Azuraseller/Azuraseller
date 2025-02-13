--[[  
  Advanced Camera Gun Script - Phiên bản nâng cấp tiên tiến (Super Advanced Upgrade)
--]]  

-------------------------------  
-- Services & Cấu hình chung --  
-------------------------------  
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Các tham số cấu hình  
local PREDICTION_TIME = 0.1               -- Thời gian dự đoán (giây)  
local LOCK_RADIUS = 500                   -- Bán kính ghim mục tiêu  
local CLOSE_RADIUS = 7                    -- Nếu mục tiêu quá gần, khóa theo ngang  
local PRIORITY_HOLD_TIME = 3              -- Thời gian (giây) để mục tiêu được ưu tiên nếu đã trong vùng  
local HEALTH_PRIORITY_THRESHOLD = 0.3     -- Nếu HP của mục tiêu dưới 30% thì được ưu tiên  
local CAMERA_ROTATION_SPEED = 1.1         -- Tốc độ xoay camera (đã tăng cho độ chính xác cao)
local FAST_ROTATION_MULTIPLIER = 2        -- Hệ số tăng tốc xoay khi mục tiêu “sau lưng”  
local HEALTH_BOARD_RADIUS = 700           -- Bán kính hiển thị Health Board

-- Các thông số liên quan đến dự đoán chuyển động của LocalPlayer  
local MOVEMENT_THRESHOLD = 0.1            -- Ngưỡng chuyển động tối thiểu  
local STATIONARY_TIMEOUT = 5              -- Thời gian cho “dự đoán” khi người chơi dừng (không quá 5 giây)  

-------------------------------  
-- Biến trạng thái toàn cục --  
-------------------------------  
local locked = false                    -- Trạng thái ghim mục tiêu (On/Off)  
local aimActive = true                  -- Script đang hoạt động hay không (điều khiển qua nút X)  
local currentTarget = nil               -- Mục tiêu hiện tại (Character)  
local targetTimeTracker = {}            -- Bảng theo dõi thời gian mục tiêu trong vùng  

-- Theo dõi vị trí và chuyển động của LocalPlayer  
local lastLocalPosition = nil  
local lastMovementTime = tick()  

-- Bảng lưu Health Board (BillboardGui) cho các mục tiêu (key = Character)  
local healthBoards = {}

-------------------------------  
-- Thiết lập GUI --  
-------------------------------  
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")

-- Nút On/Off: dời lên trên một chút (ví dụ vị trí 0.005 theo Y thay vì 0.01)  
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = screenGui
toggleButton.Size = UDim2.new(0, 100, 0, 50)
toggleButton.Position = UDim2.new(0.85, 0, 0.005, 0)
toggleButton.Text = "OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- đỏ khi tắt
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 18
toggleButton.Visible = false  -- ban đầu ẩn, chỉ hiện khi nhấn nút X

-- Bo tròn nút On/Off  
local toggleButtonCorner = Instance.new("UICorner")
toggleButtonCorner.CornerRadius = UDim.new(0, 8)
toggleButtonCorner.Parent = toggleButton

-- Viền trắng cho nút On/Off  
local toggleButtonStroke = Instance.new("UIStroke")
toggleButtonStroke.Color = Color3.fromRGB(255, 255, 255)
toggleButtonStroke.Thickness = 2
toggleButtonStroke.Parent = toggleButton

-- Nút X: vị trí (0.79, 0.005), kích thước (30,30)
local closeButton = Instance.new("TextButton")
closeButton.Parent = screenGui
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(0.79, 0, 0.005, 0)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 18

-- Bo tròn nút X  
local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 8)
closeButtonCorner.Parent = closeButton

-- Viền trắng cho nút X  
local closeButtonStroke = Instance.new("UIStroke")
closeButtonStroke.Color = Color3.fromRGB(255, 255, 255)
closeButtonStroke.Thickness = 2
closeButtonStroke.Parent = closeButton

-- Lưu lại kích thước và vị trí gốc của toggleButton dùng cho hiệu ứng pulsate  
local originalToggleButtonSize = toggleButton.Size
local originalToggleButtonPosition = toggleButton.Position

-------------------------------  
-- Hiệu ứng pulsate cho nút On/Off khi hoạt động  
-------------------------------  
local pulsateRunning = false
local function startPulsate()
    if pulsateRunning then return end
    pulsateRunning = true
    coroutine.wrap(function()
        while locked and aimActive do
            local tweenInfoShrink = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tweenInfoExpand = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            -- Tính kích thước giảm 90% so với gốc
            local newWidth = originalToggleButtonSize.X.Offset * 0.9
            local newHeight = originalToggleButtonSize.Y.Offset * 0.9
            local targetSize = UDim2.new(originalToggleButtonSize.X.Scale, newWidth, originalToggleButtonSize.Y.Scale, newHeight)
            -- Điều chỉnh vị trí để giữ giữa
            local deltaX = (originalToggleButtonSize.X.Offset - newWidth) / 2
            local deltaY = (originalToggleButtonSize.Y.Offset - newHeight) / 2
            local targetPosition = UDim2.new(originalToggleButtonPosition.X.Scale, originalToggleButtonPosition.X.Offset + deltaX,
                                             originalToggleButtonPosition.Y.Scale, originalToggleButtonPosition.Y.Offset + deltaY)
            local tweenShrink = TweenService:Create(toggleButton, tweenInfoShrink, {Size = targetSize, Position = targetPosition})
            tweenShrink:Play()
            tweenShrink.Completed:Wait()
            local tweenExpand = TweenService:Create(toggleButton, tweenInfoExpand, {Size = originalToggleButtonSize, Position = originalToggleButtonPosition})
            tweenExpand:Play()
            tweenExpand.Completed:Wait()
        end
        pulsateRunning = false
    end)()
end

-------------------------------  
-- Xử lý sự kiện cho các nút GUI --  
-------------------------------  
closeButton.MouseButton1Click:Connect(function()
    aimActive = not aimActive
    toggleButton.Visible = aimActive
    if not aimActive then
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        locked = false
        currentTarget = nil
    else
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    locked = not locked
    if locked then
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        startPulsate()
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        toggleButton.Size = originalToggleButtonSize
        toggleButton.Position = originalToggleButtonPosition
    end
end)

-------------------------------  
-- Các hàm tiện ích & xử lý logic --  
-------------------------------  

-- Cập nhật vị trí của LocalPlayer  
local function updateLocalMovement()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local currentPos = character.HumanoidRootPart.Position
        if lastLocalPosition then
            if (currentPos - lastLocalPosition).Magnitude > MOVEMENT_THRESHOLD then
                lastMovementTime = tick()
            end
        end
        lastLocalPosition = currentPos
    end
end

-- Lấy danh sách các mục tiêu (đối thủ) trong bán kính cho trước  
local function getEnemiesInRadius(radius)
    local enemies = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return enemies end
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

-- Cập nhật thời gian mà mỗi mục tiêu đã có trong vùng LOCK_RADIUS  
local function updateTargetTimers(deltaTime)
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    local newTracker = {}
    for _, enemy in ipairs(enemies) do
        if targetTimeTracker[enemy] then
            newTracker[enemy] = targetTimeTracker[enemy] + deltaTime
        else
            newTracker[enemy] = deltaTime
        end
    end
    targetTimeTracker = newTracker
end

-- Chọn mục tiêu ưu tiên dựa trên thời gian có trong vùng, khoảng cách & HP  
local function selectTarget()
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    if #enemies == 0 then return nil end

    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localPos = localCharacter.HumanoidRootPart.Position

    local bestTarget = nil
    local bestScore = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
            local enemyHumanoid = enemy.Humanoid
            if enemyHumanoid.Health > 0 then
                local timeInRange = targetTimeTracker[enemy] or 0
                local distance = (enemy.HumanoidRootPart.Position - localPos).Magnitude
                local healthRatio = enemyHumanoid.Health / enemyHumanoid.MaxHealth
                local score = (timeInRange >= PRIORITY_HOLD_TIME or healthRatio <= HEALTH_PRIORITY_THRESHOLD)
                              and (distance + (healthRatio * 1000)) or (distance + 1000)
                if score < bestScore then
                    bestScore = score
                    bestTarget = enemy
                end
            end
        end
    end

    return bestTarget
end

-- Dự đoán vị trí mục tiêu dựa trên vận tốc  
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local basePrediction = hrp.Position + hrp.Velocity * PREDICTION_TIME
    local offset = Vector3.new(0, 0, 0)

    if tick() - lastMovementTime <= STATIONARY_TIMEOUT and hrp.Velocity.Magnitude > 1 then
        local right = hrp.CFrame.RightVector
        local up = hrp.CFrame.UpVector
        local forward = hrp.CFrame.LookVector
        local threshold = 1

        local dotRight = hrp.Velocity:Dot(right)
        if math.abs(dotRight) > threshold then
            offset = offset + right * 5 * (dotRight > 0 and 1 or -1)
        end

        local dotUp = hrp.Velocity:Dot(up)
        if math.abs(dotUp) > threshold then
            offset = offset + up * 5 * (dotUp > 0 and 1 or -1)
        end

        local dotForward = hrp.Velocity:Dot(forward)
        if math.abs(dotForward) > threshold then
            offset = offset + forward * 5 * (dotForward > 0 and 1 or -1)
        end
    end

    return basePrediction + offset
end

-- Tính toán CFrame xoay camera hướng về vị trí mục tiêu  
local function calculateCameraRotation(targetPosition)
    local camPos = Camera.CFrame.Position
    local direction = targetPosition - camPos
    local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
    local newCFrame = (math.abs(targetPosition.Y - camPos.Y) > 20)
                      and CFrame.new(camPos, targetPosition)
                      or (horizontalDirection.Magnitude > 0 and CFrame.new(camPos, camPos + horizontalDirection) or Camera.CFrame)
    local targetBehind = (Camera.CFrame.LookVector:Dot(direction.Unit) < 0)
    return newCFrame, targetBehind
end

-- Cập nhật (hoặc tạo mới) Health Board cho mục tiêu  
local function updateHealthBoardForTarget(enemy)
    if not enemy or not enemy:FindFirstChild("Head") or not enemy:FindFirstChild("Humanoid") then return end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return end
    local distance = (enemy.HumanoidRootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude

    if distance > HEALTH_BOARD_RADIUS or enemy.Humanoid.Health <= 0 then
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
        return
    end

    -- Sử dụng kích thước của Head để đặt kích thước Health Board (không phụ thuộc khoảng cách)
    local head = enemy.Head
    local headSize = head.Size.X  -- giả sử X là chuẩn (thông thường head có kích thước ~2)
    local billboardWidth = headSize * 50   -- chuyển đổi sang pixel (100 pixel khi head.Size.X = 2)
    local billboardHeight = headSize * 5     -- ~10 pixel khi head.Size.X = 2
    local studsOffset = head.Size.Y

    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, billboardWidth, 0, billboardHeight)
        billboard.StudsOffset = Vector3.new(0, studsOffset, 0)
        billboard.Parent = enemy

        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BorderSizePixel = 0
        bg.Parent = billboard

        local healthFill = Instance.new("Frame")
        healthFill.Name = "HealthFill"
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = bg

        healthBoards[enemy] = billboard
    else
        local billboard = healthBoards[enemy]
        billboard.Size = UDim2.new(0, billboardWidth, 0, billboardHeight)
        billboard.StudsOffset = Vector3.new(0, studsOffset, 0)
        if billboard and billboard:FindFirstChild("Background") and billboard.Background:FindFirstChild("HealthFill") then
            local healthFill = billboard.Background.HealthFill
            local humanoid = enemy.Humanoid
            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthFill.Size = UDim2.new(ratio, 0, 1, 0)
            if ratio > 0.7 then
                healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif ratio > 0.25 then
                healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end

-- Cập nhật Health Board cho tất cả các đối thủ  
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

-------------------------------  
-- Main Loop: RenderStepped Update --  
-------------------------------  
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        updateTargetTimers(deltaTime)

        local selected = selectTarget()
        if selected then
            currentTarget = selected
            locked = true
            toggleButton.Text = "ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            startPulsate()
        else
            currentTarget = nil
            locked = false
            toggleButton.Text = "OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            toggleButton.Size = originalToggleButtonSize
            toggleButton.Position = originalToggleButtonPosition
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
                    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    toggleButton.Size = originalToggleButtonSize
                    toggleButton.Position = originalToggleButtonPosition
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        if distance <= CLOSE_RADIUS then
                            predictedPos = Vector3.new(predictedPos.X, Camera.CFrame.Position.Y, predictedPos.Z)
                        end
                        local targetCFrame, targetIsBehind = calculateCameraRotation(predictedPos)
                        local interpSpeed = (targetIsBehind and CAMERA_ROTATION_SPEED * FAST_ROTATION_MULTIPLIER or CAMERA_ROTATION_SPEED)
                        local t = interpSpeed * deltaTime
                        if t > 1 then t = 1 end
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, t)
                    end
                end
            end
        end
    end

    updateAllHealthBoards()
end)

-------------------------------  
-- Xử lý sự kiện khi người chơi thay đổi character hoặc rời server --  
-------------------------------  
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
end)
