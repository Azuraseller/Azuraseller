--[[    
  Advanced Camera Gun Script - Siêu Nâng Cấp 4.2 (Pro Final)
  -----------------------------------------------------------
  Các nâng cấp mới:
   • Hitbox nâng cao: Nếu mục tiêu di chuyển nhanh hoặc nhận sát thương, hitbox flash đỏ nhanh hơn.
   • Nếu mục tiêu di chuyển nhanh hoặc nằm sau Aim (góc lệch > 90°), camera sẽ xoay nhanh để theo kịp.
   • Dự đoán vị trí được nâng cao: sử dụng vận tốc và ước tính gia tốc với hệ số điều chỉnh.
   • Panel Settings của nút ⚙️ khi bấm sẽ từ kích thước nhỏ (ẩn) phóng to ra (250×200) hiển thị các thông số; bấm lại sẽ thu nhỏ và ẩn hoàn toàn.
   • Các chức năng khác (Shiftlock, Skill Speed, …) giữ nguyên và được cải tiến.
--]]    

-------------------------------------
-- CẤU HÌNH (có thể chỉnh qua GUI) --
-------------------------------------
local SKILL_SPEED = 50            -- Tốc độ skill (units/sec)
local LOCK_RADIUS = 600           -- Bán kính lock mục tiêu
local HEALTH_BOARD_RADIUS = 900   -- Bán kính hiển thị Health Board
local HITBOX_OFFSET = 80          -- Mức mở rộng hitbox (80,80,80)
local PREDICTION_ENABLED = true   -- Bật/tắt dự đoán mục tiêu

-- Các tham số khác
local CLOSE_RADIUS = 7
local CAMERA_ROTATION_SPEED = 0.55
local FAST_ROTATION_MULTIPLIER = 2
local HEIGHT_DIFFERENCE_THRESHOLD = 3
local MOVEMENT_THRESHOLD = 0.1              
local STATIONARY_TIMEOUT = 5

-- Hệ số dự đoán nâng cao: sử dụng gia tốc (nếu có)
local ACCELERATION_FACTOR = 0.5  

-- Ngưỡng xoay “gấp tốc” nếu mục tiêu di chuyển nhanh hoặc nằm sau (90°)
local QUICK_ROTATE_ANGLE = math.rad(90)
local QUICK_ROTATE_SPEED = 1  -- Snap nhanh

-- Ngưỡng tốc độ của target để coi là di chuyển nhanh (ví dụ > 30)
local TARGET_FAST_SPEED = 30

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
-- BIẾN TRẠNG TOÀN CỤC --
-------------------------------------
local locked = false           -- Aim lock On/Off
local aimActive = true         -- Script (và Shiftlock) bật
local currentTarget = nil      -- Mục tiêu hiện tại
local lastLocalPosition = nil  
local lastMovementTime = tick()
local previousVelocity = nil   -- Dùng để tính gia tốc của target

-- Bảng lưu Health Board và reticle
local healthBoards = {}
local targetReticle = nil

-- Biến lưu hitbox (chỉ khi Aim lock)
local currentHitbox = nil

-------------------------------------
-- GUI: Tạo ScreenGui và các nút --
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")

-- Kích thước cơ bản cho các nút
local baseToggleSize = Vector2.new(100, 50)
local baseCloseSize = Vector2.new(30, 30)

-- Hàm tạo hiệu ứng hover cho nút (cho Toggle, Close, Settings)
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
addHoverEffect(toggleButton, baseToggleSize)

-- Nút Close (X)
local closeButton = Instance.new("TextButton")
closeButton.Parent = screenGui
closeButton.Size = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
closeButton.Position = UDim2.new(0.75, 0, 0.03, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Text = "X"
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
addHoverEffect(closeButton, baseCloseSize)

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
addHoverEffect(settingsButton, baseCloseSize)

-- Panel Settings: Ban đầu ẩn đi (kích thước nhỏ bằng nút ⚙️), vị trí căn chỉnh (offset X = -25)
local settingsClosedSize = UDim2.new(0, baseCloseSize.X, 0, baseCloseSize.Y)
local settingsOpenSize = UDim2.new(0, 250, 0, 200)
local settingsClosedPosition = UDim2.new(0.65, -25, 0.03, 0)
local settingsOpenPosition = UDim2.new(0.65, -25, 0.12, 0)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Parent = screenGui
settingsFrame.Size = settingsClosedSize
settingsFrame.Position = settingsClosedPosition
-- Thêm UIGradient cho panel Settings (giao diện pro)
local uiGrad = Instance.new("UIGradient")
uiGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20,20,20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))})
uiGrad.Parent = settingsFrame
settingsFrame.BackgroundTransparency = 0.2
local settingsFrameUICorner = Instance.new("UICorner")
settingsFrameUICorner.CornerRadius = UDim.new(0, 10)
settingsFrameUICorner.Parent = settingsFrame

local settingsOpen = false
local tweenInfoSettings = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Chức năng toggle panel Settings: Khi bấm ⚙️, nếu panel đang ẩn, mở ra (với tween); nếu đang mở, thu nhỏ về 0 và ẩn.
settingsButton.MouseButton1Click:Connect(function()
    if settingsOpen then
        -- Thu nhỏ panel Settings về 0 và ẩn
        local tween = TweenService:Create(settingsFrame, tweenInfoSettings, {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function()
            settingsFrame.Visible = false
            settingsOpen = false
        end)
    else
        settingsFrame.Visible = true
        local tween = TweenService:Create(settingsFrame, tweenInfoSettings, {Size = settingsOpenSize, Position = settingsOpenPosition})
        tween:Play()
        settingsOpen = true
    end
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

-- Hàm chọn mục tiêu: sử dụng khoảng cách và góc lệch.
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

-- Hàm dự đoán vị trí mục tiêu nâng cao: sử dụng vận tốc và gia tốc.
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
    local currentVel = hrp.Velocity
    local accel = Vector3.new(0,0,0)
    if previousVelocity then
        accel = (currentVel - previousVelocity) / deltaTime
    end
    previousVelocity = currentVel
    if currentVel.Magnitude > TARGET_FAST_SPEED then
        predictedTime = 0.5
    end
    local predictedPos = hrp.Position + currentVel * predictedTime + accel * predictedTime * predictedTime * ACCELERATION_FACTOR
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

-- Tạo reticle hiển thị trên head của mục tiêu lock
local function createReticle(target)
    if not target or not target:FindFirstChild("Head") then return end
    local head = target.Head
    local reticle = Instance.new("ImageLabel")
    reticle.Name = "TargetReticle"
    reticle.Size = UDim2.new(0, 50, 0, 50)
    reticle.BackgroundTransparency = 1
    reticle.Image = "rbxassetid://6034818372"
    reticle.ImageColor3 = Color3.new(1, 0, 0)
    reticle.Parent = head
    return reticle
end

local function removeReticle(target)
    if target and target:FindFirstChild("Head") then
        local head = target.Head
        local reticle = head:FindFirstChild("TargetReticle")
        if reticle then reticle:Destroy() end
    end
end

-- Health Board: chỉnh sửa kích thước & vị trí (cách head 1 stud)
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
    local boardWidth = headSize.X * 70
    local boardHeight = headSize.Y * 5
    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = enemy.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 30, 0)
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
        
        -- Nếu mục tiêu không hợp lệ, chọn lại và tạo reticle
        if not isValidTarget(currentTarget) then
            removeReticle(currentTarget)
            local selected = selectTarget()
            if selected then
                currentTarget = selected
                locked = true
                toggleButton.Text = "ON"
                toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                removeReticle(currentTarget)
                targetReticle = createReticle(currentTarget)
            else
                currentTarget = nil
                locked = false
                toggleButton.Text = "OFF"
                toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end

        -- Cho phép chuyển mục tiêu bằng phím E (sắp xếp theo khoảng cách)
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
            local candidates = getEnemiesInRadius(LOCK_RADIUS)
            table.sort(candidates, function(a, b)
                return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            if #candidates > 1 then
                for i, enemy in ipairs(candidates) do
                    if enemy == currentTarget and candidates[i+1] then
                        currentTarget = candidates[i+1]
                        removeReticle(currentTarget)
                        targetReticle = createReticle(currentTarget)
                        break
                    end
                end
            end
        end

        if currentTarget and locked then
            local enemyHumanoid = currentTarget:FindFirstChild("Humanoid")
            local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
            local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if enemyHumanoid and enemyHRP and localHRP then
                local distance = (enemyHRP.Position - localHRP.Position).Magnitude
                if enemyHumanoid.Health <= 0 or distance > LOCK_RADIUS then
                    removeReticle(currentTarget)
                    currentTarget = nil
                    locked = false
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        local camDir = Camera.CFrame.LookVector
                        local targetDir = (predictedPos - localHRP.Position).Unit
                        local angleDiff = math.acos(math.clamp(camDir:Dot(targetDir), -1, 1))
                        local dynamicSpeed = CAMERA_ROTATION_SPEED + (angleDiff / math.pi) * (FAST_ROTATION_MULTIPLIER - CAMERA_ROTATION_SPEED)
                        if angleDiff > QUICK_ROTATE_ANGLE or enemyHRP.Velocity.Magnitude > TARGET_FAST_SPEED then
                            dynamicSpeed = QUICK_ROTATE_SPEED
                        end
                        if distance <= CLOSE_RADIUS then
                            predictedPos = Vector3.new(predictedPos.X, Camera.CFrame.Position.Y, predictedPos.Z)
                        end
                        local targetCFrame = calculateCameraRotation(predictedPos)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, dynamicSpeed)
                    end
                end
            end
        end

        -- ========== HITBOX ==========
        if locked and currentTarget then
            local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = currentTarget:FindFirstChild("Humanoid")
            if enemyHRP and enemyHumanoid then
                if not currentHitbox then
                    currentHitbox = Instance.new("Part")
                    currentHitbox.Name = "ExpandedHitbox"
                    currentHitbox.Transparency = 0.9
                    currentHitbox.CanCollide = false
                    currentHitbox.Anchored = false
                    currentHitbox.Color = Color3.new(0, 0, 0.5)
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
                    local flashTime = 0.1
                    if enemyHRP.Velocity.Magnitude > TARGET_FAST_SPEED then
                        flashTime = 0.05
                    end
                    if enemyHumanoid.Health < lastHealth then
                        local originalColor = currentHitbox.Color
                        currentHitbox.Color = Color3.new(1, 0, 0)
                        task.delay(flashTime, function()
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
    removeReticle(currentTarget)
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

----------------------------------------------------------------
-- TÍNH NĂNG SHIFTLOCK CẢM ỨNG (CẢI TIẾN) --
----------------------------------------------------------------
local idleSpeedThreshold = 0.5   -- Nếu HRP đứng yên
local angleThreshold = 5         -- Ngưỡng xoay (độ)
RunService.RenderStepped:Connect(function(delta)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    if aimActive then
         humanoid.AutoRotate = false
         local hrp = character:FindFirstChild("HumanoidRootPart")
         if not hrp then return end
         local bg = hrp:FindFirstChild("ShiftlockBodyGyro")
         if not bg then
              bg = Instance.new("BodyGyro")
              bg.Name = "ShiftlockBodyGyro"
              bg.Parent = hrp
              bg.MaxTorque = Vector3.new(0, math.huge, 0)
              bg.P = 3000
              bg.D = 500
         end
         local _, cameraYawRad, _ = Camera.CFrame:ToEulerAnglesYXZ()
         local desiredYaw = math.deg(cameraYawRad)
         local currentYaw = hrp.Orientation.Y
         local diff = math.abs(currentYaw - desiredYaw)
         if diff > 180 then diff = 360 - diff end
         if hrp.Velocity.Magnitude < idleSpeedThreshold then
             if diff > angleThreshold then
                 bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(desiredYaw), 0)
             end
         else
             bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(desiredYaw), 0)
         end
    else
         humanoid.AutoRotate = true
         local character = LocalPlayer.Character
         if character then
             local hrp = character:FindFirstChild("HumanoidRootPart")
             if hrp then
                 local bg = hrp:FindFirstChild("ShiftlockBodyGyro")
                 if bg then
                     bg:Destroy()
                 end
             end
         end
    end
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
