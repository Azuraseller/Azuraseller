--[[  
  Advanced Camera Gun Script - Phiên bản nâng cấp chuyên sâu (v2)
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
local LOCK_RADIUS = 600                   -- Bán kính ghim mục tiêu
local CLOSE_RADIUS = 7                    -- Nếu mục tiêu quá gần, lock theo ngang
local PRIORITY_HOLD_TIME = 3              -- Thời gian ưu tiên (giây)
local HEALTH_PRIORITY_THRESHOLD = 0.3     -- HP dưới 30% được ưu tiên
local CAMERA_ROTATION_SPEED = 0.55        -- Tốc độ xoay camera cơ bản
local FAST_ROTATION_MULTIPLIER = 2        -- Tăng tốc xoay khi mục tiêu “sau lưng”
local HEALTH_BOARD_RADIUS = 1000           -- Bán kính hiển thị Health Board
local HEIGHT_DIFFERENCE_THRESHOLD = 20    -- Ngưỡng chênh lệch theo trục Y

-- Các thông số liên quan đến chuyển động của LocalPlayer  
local MOVEMENT_THRESHOLD = 0.1            
local STATIONARY_TIMEOUT = 5              

-------------------------------  
-- Biến trạng thái toàn cục --  
-------------------------------  
local locked = false                    -- Trạng thái ghim mục tiêu (ON/OFF)
local aimActive = true                  -- Script có đang hoạt động
local currentTarget = nil               -- Mục tiêu hiện tại
local targetTimeTracker = {}            -- Thời gian mục tiêu nằm trong vùng

local lastLocalPosition = nil
local lastMovementTime = tick()

-- Bảng lưu Health Board (key = Character)
local healthBoards = {}

-------------------------------  
-- Thiết lập GUI  
-------------------------------  
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")

-- Các kích thước cơ bản  
local baseToggleSize = Vector2.new(100, 50)
local baseCloseSize = Vector2.new(30, 30)

-- Nút Toggle (On/Off)
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = screenGui
toggleButton.Size = UDim2.new(0, baseToggleSize.X, 0, baseToggleSize.Y)
-- Dời nút lên trên (vị trí đã điều chỉnh)  
toggleButton.Position = UDim2.new(0.85, 0, 0.03, 0)
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.Text = "OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 18

-- Bo tròn nút Toggle  
local toggleUICorner = Instance.new("UICorner")
toggleUICorner.CornerRadius = UDim.new(0, 10)
toggleUICorner.Parent = toggleButton

-- Viền trắng cho Toggle  
local toggleUIStroke = Instance.new("UIStroke")
toggleUIStroke.Color = Color3.fromRGB(255, 255, 255)
toggleUIStroke.Thickness = 2
toggleUIStroke.Parent = toggleButton

-- Nút Close (X)
local closeButton = Instance.new("TextButton")
closeButton.Parent = screenGui
closeButton.Size = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
closeButton.Position = UDim2.new(0.75, 0, 0.03, 0)  -- Đặt gần nút Toggle
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 18

-- Bo tròn nút Close  
local closeUICorner = Instance.new("UICorner")
closeUICorner.CornerRadius = UDim.new(0, 10)
closeUICorner.Parent = closeButton

-- Viền trắng cho nút Close  
local closeUIStroke = Instance.new("UIStroke")
closeUIStroke.Color = Color3.fromRGB(255, 255, 255)
closeUIStroke.Thickness = 2
closeUIStroke.Parent = closeButton

-------------------------------------  
-- Xử lý sự kiện cho các nút GUI --  
-------------------------------------  
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
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        currentTarget = nil
    end
end)

-------------------------------------  
-- Các hàm tiện ích và xử lý logic --  
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

local function selectTarget()
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    if #enemies == 0 then
        return nil
    end
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
                local score = 0
                if timeInRange >= PRIORITY_HOLD_TIME or healthRatio <= HEALTH_PRIORITY_THRESHOLD then
                    score = distance + (healthRatio * 1000)
                else
                    score = distance + 1000
                end
                if score < bestScore then
                    bestScore = score
                    bestTarget = enemy
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
    return distance <= LOCK_RADIUS
end

local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local basePrediction = hrp.Position + hrp.Velocity * PREDICTION_TIME
    local offset = Vector3.new(0, 0, 0)
    if tick() - lastMovementTime <= STATIONARY_TIMEOUT then
        if hrp.Velocity.Magnitude > 1 then
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
    end
    return basePrediction + offset
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
    local dotProduct = Camera.CFrame.LookVector:Dot(direction.Unit)
    local targetBehind = dotProduct < 0
    return newCFrame, targetBehind
end

-- Health Board: sử dụng kích thước của enemy.Head (không scale theo khoảng cách)
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

    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return end
    local distance = (enemy.HumanoidRootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    if distance > HEALTH_BOARD_RADIUS then
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
        return
    end

    -- Tính kích thước Health Board theo kích thước Head  
    local headSize = enemy.Head.Size
    local boardWidth = headSize.X * 100
    local boardHeight = headSize.Y * 50

    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = enemy.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, headSize.Y + 0.5, 0)
        billboard.Parent = enemy

        -- Khung nền của Health Board  
        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BorderSizePixel = 0
        bg.Parent = billboard

        local bgStroke = Instance.new("UIStroke")
        bgStroke.Color = Color3.fromRGB(255, 255, 255)
        bgStroke.Thickness = 2
        bgStroke.Parent = bg

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 10)
        bgCorner.Parent = bg

        -- Thanh fill hiển thị % máu  
        local healthFill = Instance.new("Frame")
        healthFill.Name = "HealthFill"
        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        healthFill.Size = UDim2.new(ratio, 0, 1, 0)
        healthFill.BackgroundColor3 = (ratio > 0.7 and Color3.fromRGB(0,255,0)) or (ratio > 0.25 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(255,0,0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = bg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 10)
        fillCorner.Parent = healthFill

        -- Text hiển thị máu: bên trái là máu hiện tại  
        local leftLabel = Instance.new("TextLabel")
        leftLabel.Name = "LeftHealth"
        leftLabel.Size = UDim2.new(0.5, 0, 1, 0)
        leftLabel.Position = UDim2.new(0, 0, 0, 0)
        leftLabel.BackgroundTransparency = 1
        leftLabel.Text = tostring(math.floor(humanoid.Health))
        leftLabel.TextColor3 = Color3.fromRGB(255,255,255)
        leftLabel.Font = Enum.Font.SourceSansBold
        leftLabel.TextScaled = true
        leftLabel.TextXAlignment = Enum.TextXAlignment.Left
        leftLabel.Parent = bg

        -- Bên phải hiển thị máu tối đa  
        local rightLabel = Instance.new("TextLabel")
        rightLabel.Name = "RightHealth"
        rightLabel.Size = UDim2.new(0.5, 0, 1, 0)
        rightLabel.Position = UDim2.new(0.5, 0, 0, 0)
        rightLabel.BackgroundTransparency = 1
        rightLabel.Text = tostring(math.floor(humanoid.MaxHealth))
        rightLabel.TextColor3 = Color3.fromRGB(255,255,255)
        rightLabel.Font = Enum.Font.SourceSansBold
        rightLabel.TextScaled = true
        rightLabel.TextXAlignment = Enum.TextXAlignment.Right
        rightLabel.Parent = bg

        healthBoards[enemy] = billboard
    else
        local billboard = healthBoards[enemy]
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, headSize.Y + 0.5, 0)
        local bg = billboard:FindFirstChild("Background")
        if bg then
            local healthFill = bg:FindFirstChild("HealthFill")
            local leftLabel = bg:FindFirstChild("LeftHealth")
            local rightLabel = bg:FindFirstChild("RightHealth")
            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            if healthFill then
                healthFill.Size = UDim2.new(ratio, 0, 1, 0)
                healthFill.BackgroundColor3 = (ratio > 0.7 and Color3.fromRGB(0,255,0)) or (ratio > 0.25 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(255,0,0)
            end
            if leftLabel then
                leftLabel.Text = tostring(math.floor(humanoid.Health))
            end
            if rightLabel then
                rightLabel.Text = tostring(math.floor(humanoid.MaxHealth))
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
        updateTargetTimers(deltaTime)
        
        -- Nếu currentTarget không hợp lệ, chọn lại  
        if not isValidTarget(currentTarget) then
            local selected = selectTarget()
            if selected then
                currentTarget = selected
                locked = true
                toggleButton.Text = "ON"
                toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            else
                currentTarget = nil
                locked = false
                toggleButton.Text = "OFF"
                toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
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
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        if distance <= CLOSE_RADIUS then
                            predictedPos = Vector3.new(predictedPos.X, Camera.CFrame.Position.Y, predictedPos.Z)
                        end
                        local targetCFrame, targetIsBehind = calculateCameraRotation(predictedPos)
                        local interpSpeed = targetIsBehind and CAMERA_ROTATION_SPEED * FAST_ROTATION_MULTIPLIER or CAMERA_ROTATION_SPEED
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, interpSpeed)
                    end
                end
            end
        end

        -- Hiệu ứng oscilla cho nút Toggle khi lock (thu nhỏ & phóng to)
        if locked then
            local oscillation = 0.05 * math.sin(tick() * 5)  -- dao động ±5%
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
-- Xử lý sự kiện khi người chơi thay đổi character hoặc rời server --  
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
end)
