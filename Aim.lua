--[[    
  Advanced Camera Gun Script - Siêu Nâng Cấp 3.1
  --------------------------------------------------
  Các cải tiến:
   1. Dự đoán mục tiêu dựa theo khoảng cách & tốc độ skill (1-2 giây dự đoán).
   2. Target lock cực nhanh, siêu chính xác, ưu tiên mục tiêu gần (không dùng yếu tố máu).
   3. Health Board chỉnh sửa: chiều ngang kéo dài, chiều dọc thu nhỏ, cách head 1 stud.
   4. Hitbox nâng cấp: Khi ghim, hitbox của mục tiêu tăng thêm (80,80,80) xung quanh HRP, có màu xanh đậm với transparency cao, flash đỏ khi nhận sát thương.
   5. Shiftlock cải tiến với BodyGyro ổn định.
   6. GUI Settings “siêu chất”: panel settings ban đầu nhỏ (giống nút X) sẽ phóng to ra khi nhấn ⚙️, vị trí panel được dịch sang trái 1 chút.
   7. Skill Speed: Các Tool có "Cooldown" sẽ được điều chỉnh giảm xuống (0.3 giây).
--]]    

-------------------------------------
-- Các biến cấu hình “điều chỉnh” --
-------------------------------------
local SKILL_SPEED = 50            -- Tốc độ của skill (units/sec)
local LOCK_RADIUS = 600           -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 900   -- Bán kính hiển thị Health Board
local HITBOX_OFFSET = 80          -- Giá trị mở rộng hitbox (80,80,80)
local PREDICTION_ENABLED = true   -- Bật/tắt dự đoán mục tiêu

-- Các tham số khác
local CLOSE_RADIUS = 7
local CAMERA_ROTATION_SPEED = 0.55
local FAST_ROTATION_MULTIPLIER = 2
local HEIGHT_DIFFERENCE_THRESHOLD = 3
local MOVEMENT_THRESHOLD = 0.1              
local STATIONARY_TIMEOUT = 5                

-------------------------------------
-- Dịch vụ và đối tượng --
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
local locked = false           -- Aim lock On/Off
local aimActive = true         -- Script (và Shiftlock) bật
local currentTarget = nil      -- Mục tiêu hiện tại
local lastLocalPosition = nil  
local lastMovementTime = tick()

-- Bảng lưu Health Board (key = Character)
local healthBoards = {}

-- Biến lưu hitbox (khi Aim lock)
local currentHitbox = nil

-------------------------------------
-- GUI: Tạo ScreenGui và các nút --
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")

-- Kích thước cơ bản cho các nút
local baseToggleSize = Vector2.new(100, 50)
local baseCloseSize = Vector2.new(30, 30)

-- Hàm tạo hiệu ứng hover cho nút (scale tween)
local function addHoverEffect(button)
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, button.Size.X.Offset * 1.1, 0, button.Size.Y.Offset * 1.1)})
        tween:Play()
    end)
    button.MouseLeave:Connect(function()
        if button.Name == "ToggleButton" then
            local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, baseToggleSize.X, 0, baseToggleSize.Y)})
            tween:Play()
        else
            local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)})
            tween:Play()
        end
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
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 18
local toggleUICorner = Instance.new("UICorner")
toggleUICorner.CornerRadius = UDim.new(0, 10)
toggleUICorner.Parent = toggleButton
local toggleUIStroke = Instance.new("UIStroke")
toggleUIStroke.Color = Color3.fromRGB(255, 255, 255)
toggleUIStroke.Thickness = 2
toggleUIStroke.Parent = toggleButton
addHoverEffect(toggleButton)

-- Nút Close (X)
local closeButton = Instance.new("TextButton")
closeButton.Parent = screenGui
closeButton.Size = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
closeButton.Position = UDim2.new(0.75, 0, 0.03, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Text = "✖️"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 18
local closeUICorner = Instance.new("UICorner")
closeUICorner.CornerRadius = UDim.new(0, 10)
closeUICorner.Parent = closeButton
local closeUIStroke = Instance.new("UIStroke")
closeUIStroke.Color = Color3.fromRGB(255, 255, 255)
closeUIStroke.Thickness = 2
closeUIStroke.Parent = closeButton
addHoverEffect(closeButton)

-- Nút Settings (⚙️) – đặt bên trái nút X
local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Parent = screenGui
settingsButton.Size = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
settingsButton.Position = UDim2.new(0.65, 0, 0.03, 0)
settingsButton.AnchorPoint = Vector2.new(0.5, 0.5)
settingsButton.Text = "⚙️"
settingsButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.Font = Enum.Font.SourceSans
settingsButton.TextSize = 18
local settingsUICorner = Instance.new("UICorner")
settingsUICorner.CornerRadius = UDim.new(0, 10)
settingsUICorner.Parent = settingsButton
local settingsUIStroke = Instance.new("UIStroke")
settingsUIStroke.Color = Color3.fromRGB(255, 255, 255)
settingsUIStroke.Thickness = 2
settingsUIStroke.Parent = settingsButton
addHoverEffect(settingsButton)

-- Panel Settings: Ban đầu ẩn đi với kích thước nhỏ (giống nút X)
local settingsClosedSize = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
local settingsOpenSize = UDim2.new(0, 250, 0, 200)
-- CHỈNH VỊ: Dịch panel sang trái 1 chút (offset X = -25)
local settingsClosedPosition = UDim2.new(0.65, -25, 0.03, 0)
local settingsOpenPosition = UDim2.new(0.65, -25, 0.12, 0)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Parent = screenGui
settingsFrame.Size = settingsClosedSize
settingsFrame.Position = settingsClosedPosition
settingsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
settingsFrame.BackgroundTransparency = 0.2
local settingsFrameUICorner = Instance.new("UICorner")
settingsFrameUICorner.CornerRadius = UDim.new(0, 10)
settingsFrameUICorner.Parent = settingsFrame

local settingsOpen = false
local tweenInfoSettings = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Hàm tạo dòng cài đặt (label + TextBox hoặc Toggle)
local function createSettingRow(parent, yPos, labelText, defaultValue, isToggle)
    local rowFrame = Instance.new("Frame")
    rowFrame.Parent = parent
    rowFrame.Size = UDim2.new(1, -10, 0, 30)
    rowFrame.Position = UDim2.new(0, 5, 0, yPos)
    rowFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = rowFrame
    label.Size = UDim2.new(0.5, -5, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ":"
    label.Font = Enum.Font.SourceSans
    label.TextSize = 18
    label.TextColor3 = Color3.new(1,1,1)

    if isToggle then
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Parent = rowFrame
        toggleBtn.Size = UDim2.new(0.5, -5, 1, 0)
        toggleBtn.Position = UDim2.new(0.5, 5, 0, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
        toggleBtn.TextColor3 = Color3.new(0,0,0)
        toggleBtn.Font = Enum.Font.SourceSans
        toggleBtn.TextSize = 18
        toggleBtn.Text = defaultValue and "On" or "Off"
        toggleBtn.AutoButtonColor = true
        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 10)
        uicorner.Parent = toggleBtn
        local uistroke = Instance.new("UIStroke")
        uistroke.Color = Color3.new(1,1,1)
        uistroke.Thickness = 2
        uistroke.Parent = toggleBtn

        toggleBtn.MouseButton1Click:Connect(function()
            defaultValue = not defaultValue
            toggleBtn.Text = defaultValue and "On" or "Off"
            if labelText == "Prediction" then
                PREDICTION_ENABLED = defaultValue
            end
        end)
    else
        local textBox = Instance.new("TextBox")
        textBox.Parent = rowFrame
        textBox.Size = UDim2.new(0.5, -5, 1, 0)
        textBox.Position = UDim2.new(0.5, 5, 0, 0)
        textBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
        textBox.TextColor3 = Color3.new(0,0,0)
        textBox.Font = Enum.Font.SourceSans
        textBox.TextSize = 18
        textBox.Text = tostring(defaultValue)
        textBox.ClearTextOnFocus = true
        textBox.PlaceholderText = tostring(defaultValue)
        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 10)
        uicorner.Parent = textBox
        local uistroke = Instance.new("UIStroke")
        uistroke.Color = Color3.new(1,1,1)
        uistroke.Thickness = 2
        uistroke.Parent = textBox

        textBox.FocusLost:Connect(function(enterPressed)
            if textBox.Text == "" then
                textBox.Text = tostring(defaultValue)
            else
                local num = tonumber(textBox.Text)
                if num then
                    if labelText == "Skill Speed" then
                        SKILL_SPEED = num
                    elseif labelText == "Lock Radius" then
                        LOCK_RADIUS = num
                    elseif labelText == "Health Board Radius" then
                        HEALTH_BOARD_RADIUS = num
                    elseif labelText == "Hitbox Offset" then
                        HITBOX_OFFSET = num
                    end
                    defaultValue = num
                else
                    textBox.Text = tostring(defaultValue)
                end
            end
        end)
    end
end

-- Tạo các dòng cài đặt
createSettingRow(settingsFrame, 10, "Skill Speed", SKILL_SPEED, false)
createSettingRow(settingsFrame, 50, "Lock Radius", LOCK_RADIUS, false)
createSettingRow(settingsFrame, 90, "Health Board Radius", HEALTH_BOARD_RADIUS, false)
createSettingRow(settingsFrame, 130, "Hitbox Offset", HITBOX_OFFSET, false)
createSettingRow(settingsFrame, 170, "Prediction", PREDICTION_ENABLED, true)

-- Toggle Settings Frame bằng nút ⚙️: Tween cả vị trí và kích thước
settingsButton.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    local goal = {}
    if settingsOpen then
        goal.Position = settingsOpenPosition
        goal.Size = settingsOpenSize
    else
        goal.Position = settingsClosedPosition
        goal.Size = settingsClosedSize
    end
    local tween = TweenService:Create(settingsFrame, tweenInfoSettings, goal)
    tween:Play()
end)

-------------------------------------
-- Sự kiện GUI cho Toggle & Close --
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

-- Hàm chọn mục tiêu: dùng khoảng cách và góc lệch; nếu mục tiêu gần (<100) thì score giảm theo tỷ lệ.
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
                local distance = (enemy.HumanoidRootPart.Position - localPos).Magnitude
                local dirToEnemy = (enemy.HumanoidRootPart.Position - localPos).Unit
                local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToEnemy), -1, 1))
                local angleScore = angleDiff * 100
                local score = distance + angleScore
                if distance < 100 then
                    score = score * (distance / 100)
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

-- Hàm dự đoán vị trí mục tiêu dựa theo “skill travel time”
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local distance = (hrp.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    if not PREDICTION_ENABLED then
        return head.Position
    end
    local predictedTime = distance / SKILL_SPEED
    predictedTime = math.clamp(predictedTime, 1, 2)
    local predictedPos = hrp.Position + hrp.Velocity * predictedTime
    return predictedPos
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

-- Health Board: chỉnh sửa kích thước (rộng hơn, cao thấp lại) và StudsOffset = (0,1,0)
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

    local headSize = enemy.Head.Size
    local boardWidth = headSize.X * 70   -- kéo dài theo bề ngang
    local boardHeight = headSize.Y * 5    -- thu nhỏ theo chiều dọc
    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = enemy.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 50, 0)  -- cách head 1 stud
        billboard.Parent = enemy

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
-- Main Loop: RenderStepped Update cho Camera Gun --
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        -- Target lock liên tục: nếu mục tiêu không hợp lệ, chọn lại
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
                        local targetCFrame = calculateCameraRotation(predictedPos)
                        local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot((predictedPos - Camera.CFrame.Position).Unit), -1, 1))
                        local dynamicSpeed = CAMERA_ROTATION_SPEED + (angleDiff / math.pi) * (FAST_ROTATION_MULTIPLIER - CAMERA_ROTATION_SPEED)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, dynamicSpeed)
                    end
                end
            end
        end

        -- ========== PHẦN HITBOX ==========
        if locked and currentTarget then
            local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = currentTarget:FindFirstChild("Humanoid")
            if enemyHRP and enemyHumanoid then
                if not currentHitbox then
                    currentHitbox = Instance.new("Part")
                    currentHitbox.Name = "ExpandedHitbox"
                    currentHitbox.Transparency = 0.9  -- siêu trong suốt
                    currentHitbox.CanCollide = false
                    currentHitbox.Anchored = false
                    currentHitbox.Color = Color3.new(0, 0, 0.5)  -- xanh dương đậm
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(HITBOX_OFFSET, HITBOX_OFFSET, HITBOX_OFFSET)
                    currentHitbox.Parent = currentTarget
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = enemyHRP
                    weld.Part1 = currentHitbox
                    weld.Parent = currentHitbox
                    currentHitbox:SetAttribute("LastHealth", enemyHumanoid.Health)
                else
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(HITBOX_OFFSET, HITBOX_OFFSET, HITBOX_OFFSET)
                    local lastHealth = currentHitbox:GetAttribute("LastHealth") or enemyHumanoid.Health
                    if enemyHumanoid.Health < lastHealth then
                        local originalColor = currentHitbox.Color
                        currentHitbox.Color = Color3.new(1, 0, 0)  -- flash đỏ
                        task.delay(0.1, function()
                            if currentHitbox then
                                currentHitbox.Color = originalColor
                            end
                        end)
                    end
                    currentHitbox:SetAttribute("LastHealth", enemyHumanoid.Health)
                end
            end
        else
            if currentHitbox then
                currentHitbox:Destroy()
                currentHitbox = nil
            end
        end
        -- ========== END HITBOX ==========

        -- Hiệu ứng oscilla cho nút Toggle khi lock
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
-- Xử lý sự kiện khi Character/Player rời server --
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
    if currentHitbox then
        currentHitbox:Destroy()
        currentHitbox = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    lastLocalPosition = hrp.Position
    lastMovementTime = tick()
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
    Camera.CameraType = Enum.CameraType.Custom
end)

-------------------------------------
-- CHỨC NĂNG SKILL SPEED: GIẢM COOLDOWN TOOL --
-------------------------------------
local function adjustToolCooldown(tool)
    local cooldownValue = tool:FindFirstChild("Cooldown")
    if cooldownValue and cooldownValue:IsA("NumberValue") then
         cooldownValue.Value = 0.3
    end
end

for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
         adjustToolCooldown(tool)
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
         adjustToolCooldown(child)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    for _, tool in ipairs(character:GetChildren()) do
         if tool:IsA("Tool") then
              adjustToolCooldown(tool)
         end
    end
end)
