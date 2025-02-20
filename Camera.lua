--[[    
  Advanced Camera Gun Script - Pro Edition 6.1
  --------------------------------------------------
  Cải tiến:
   1. Aim–Target lock luôn ghim vào head mục tiêu với độ chính xác cao và cập nhật ngay tức thì.
   2. Dự đoán vị trí mục tiêu chỉ hoạt động nếu khoảng cách từ LocalPlayer đến mục tiêu ≥350.
   3. Auto Lock: Nếu mục tiêu trong bán kính 600 quá 5 giây, Aim tự động bật.
   4. Panel cài đặt (danh sách) nhỏ gọn, với text có kích thước nhỏ, nằm ngay dưới nút ⚙️ và không đè lên các nút khác.
   5. Nút ⚙️ được di chuyển để nằm ngay bên trái nút X.
--]]    

-------------------------------------
-- CẤU HÌNH (có thể điều chỉnh) --
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 900       -- Bán kính hiển thị Health Board
local HITBOX_OFFSET = 80              -- Mức mở rộng hitbox (mặc định 80)
local PREDICTION_ENABLED = true       -- Bật/tắt dự đoán mục tiêu
local HITBOX_ENABLED = true           -- Bật/tắt hitbox

local CAMERA_SMOOTH_FACTOR = 8        -- (Không dùng Lerp trong phiên bản này vì Aim cập nhật ngay)

-- Các tham số khác
local CLOSE_RADIUS = 7                -- Khi mục tiêu gần, giữ Y của camera
local HEIGHT_DIFFERENCE_THRESHOLD = 3 -- Ngưỡng chênh lệch độ cao giữa camera & mục tiêu
local MOVEMENT_THRESHOLD = 0.1
local STATIONARY_TIMEOUT = 0.1

-- Auto Lock: nếu mục tiêu trong bán kính 600 trong hơn 5 giây
local AUTO_LOCK_RADIUS = 600
local AUTO_LOCK_TIME = 5

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
local targetInRangeStart = nil  -- Thời gian mục tiêu trong bán kính AUTO_LOCK

-- Bảng lưu Health Board (key = Character)
local healthBoards = {}

-- Biến lưu hitbox (khi Aim lock)
local currentHitbox = nil

-------------------------------------
-- GIAO DIỆN GUI (Pro Edition tối giản) --
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")
screenGui.Name = "AdvancedCameraGUI"

-- Kích thước cơ bản cho các nút
local baseToggleSize = Vector2.new(100, 50)
local baseButtonSize = Vector2.new(30, 30)

-- Hàm thêm hiệu ứng hover cho nút (scale tween)
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

-- Nút Settings (⚙️) – di chuyển để nằm ngay bên trái nút X
local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Parent = screenGui
settingsButton.Size = UDim2.new(0, baseButtonSize.X, 0, baseButtonSize.Y)
settingsButton.Position = UDim2.new(0.70, 0, 0.03, 0)  -- đặt ngay bên trái nút X
settingsButton.AnchorPoint = Vector2.new(0.5, 0.5)
settingsButton.Text = "⚙️"
settingsButton.Font = Enum.Font.GothamBold
settingsButton.TextSize = 20
settingsButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
settingsButton.TextColor3 = Color3.new(1,1,1)
local settingsUICorner = Instance.new("UICorner", settingsButton)
settingsUICorner.CornerRadius = UDim.new(0, 10)
local settingsUIStroke = Instance.new("UIStroke", settingsButton)
settingsUIStroke.Color = Color3.new(1,1,1)
settingsUIStroke.Thickness = 2
addHoverEffect(settingsButton, baseButtonSize)

-- Panel Settings: hiển thị ngay dưới nút ⚙️ và không đè lên nút khác
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Parent = screenGui
settingsFrame.Size = UDim2.new(0, 250, 0, 220)  -- chứa 5 dòng cài đặt nhỏ gọn
-- Đặt panel mở ngay dưới nút Settings (ở vị trí x giống Settings, y > vị trí nút)
local settingsOpenPosition = UDim2.new(0.70, 0, 0.10, 0)
local settingsClosedPosition = UDim2.new(0.70, 0, -0.5, 0)
settingsFrame.Position = settingsClosedPosition
settingsFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
settingsFrame.BackgroundTransparency = 1
local settingsFrameUICorner = Instance.new("UICorner", settingsFrame)
settingsFrameUICorner.CornerRadius = UDim.new(0, 10)
local settingsUIScale = Instance.new("UIScale", settingsFrame)
settingsUIScale.Scale = 0

-- Hàm tạo dòng cài đặt theo bố cục dọc (mỗi dòng gồm label trên, control bên dưới)
local function createSettingRow(parent, yPos, labelText, defaultValue, isToggle)
    local rowFrame = Instance.new("Frame")
    rowFrame.Parent = parent
    rowFrame.Size = UDim2.new(1, -10, 0, 40)
    rowFrame.Position = UDim2.new(0, 5, 0, yPos)
    rowFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Parent = rowFrame
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.new(1,1,1)
    
    local control
    if isToggle then
        control = Instance.new("TextButton")
        control.Parent = rowFrame
        control.Size = UDim2.new(1, 0, 0.5, -5)
        control.Position = UDim2.new(0, 0, 0.5, 5)
        control.BackgroundColor3 = Color3.fromRGB(200,200,200)
        control.TextColor3 = Color3.new(0,0,0)
        control.Font = Enum.Font.GothamBold
        control.TextSize = 14
        control.Text = defaultValue and "On" or "Off"
        local uicorner = Instance.new("UICorner", control)
        uicorner.CornerRadius = UDim.new(0, 10)
        local uistroke = Instance.new("UIStroke", control)
        uistroke.Color = Color3.new(1,1,1)
        uistroke.Thickness = 2

        control.MouseButton1Click:Connect(function()
            defaultValue = not defaultValue
            control.Text = defaultValue and "On" or "Off"
            if labelText == "Prediction" then
                PREDICTION_ENABLED = defaultValue
            elseif labelText == "Hitbox" then
                HITBOX_ENABLED = defaultValue
            end
        end)
    else
        control = Instance.new("TextBox")
        control.Parent = rowFrame
        control.Size = UDim2.new(1, 0, 0.5, -5)
        control.Position = UDim2.new(0, 0, 0.5, 5)
        control.BackgroundColor3 = Color3.fromRGB(230,230,230)
        control.TextColor3 = Color3.new(0,0,0)
        control.Font = Enum.Font.Gotham
        control.TextSize = 14
        control.Text = tostring(defaultValue)
        control.ClearTextOnFocus = true
        control.PlaceholderText = tostring(defaultValue)
        local uicorner = Instance.new("UICorner", control)
        uicorner.CornerRadius = UDim.new(0, 10)
        local uistroke = Instance.new("UIStroke", control)
        uistroke.Color = Color3.new(1,1,1)
        uistroke.Thickness = 2

        control.FocusLost:Connect(function(enterPressed)
            if control.Text == "" then
                control.Text = tostring(defaultValue)
            else
                local num = tonumber(control.Text)
                if num then
                    if labelText == "Lock Radius" then
                        LOCK_RADIUS = num
                    elseif labelText == "Health Board" then
                        HEALTH_BOARD_RADIUS = num
                    elseif labelText == "Hitbox Offset" then
                        HITBOX_OFFSET = num
                    end
                    defaultValue = num
                else
                    control.Text = tostring(defaultValue)
                end
            end
        end)
    end
    -- Ban đầu các text ẩn (TextTransparency = 1)
    for _, obj in ipairs(rowFrame:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.TextTransparency = 1
        end
    end
end

-- Tạo 5 dòng cài đặt: Lock Radius, Health Board, Hitbox Offset, Prediction, Hitbox
createSettingRow(settingsFrame, 10, "Lock Radius", LOCK_RADIUS, false)
createSettingRow(settingsFrame, 60, "Health Board", HEALTH_BOARD_RADIUS, false)
createSettingRow(settingsFrame, 110, "Hitbox Offset", HITBOX_OFFSET, false)
createSettingRow(settingsFrame, 160, "Prediction", PREDICTION_ENABLED, true)
createSettingRow(settingsFrame, 210, "Hitbox", HITBOX_ENABLED, true)

-- Hàm tween text transparency cho các control trong panel
local function tweenPanelText(transparency)
    for _, obj in ipairs(settingsFrame:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj.Parent ~= settingsFrame then
            TweenService:Create(obj, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = transparency}):Play()
        end
    end
end

-- Hàm toggle panel: sử dụng UIScale và tween BackgroundTransparency, TextTransparency
local panelVisible = false
local tweenInfoPanel = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local function togglePanel()
    panelVisible = not panelVisible
    if panelVisible then
        TweenService:Create(settingsUIScale, tweenInfoPanel, {Scale = 1}):Play()
        tweenPanelText(0)
        TweenService:Create(settingsFrame, tweenInfoPanel, {BackgroundTransparency = 0.3}):Play()
    else
        TweenService:Create(settingsUIScale, tweenInfoPanel, {Scale = 0}):Play()
        tweenPanelText(1)
        TweenService:Create(settingsFrame, tweenInfoPanel, {BackgroundTransparency = 1}):Play()
    end
end

settingsButton.MouseButton1Click:Connect(togglePanel)

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
        targetInRangeStart = nil
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
        targetInRangeStart = nil
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

-- Hàm chọn mục tiêu theo khoảng cách và góc lệch
local function selectTarget()
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    if #enemies == 0 then return nil end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local localPos = localCharacter.HumanoidRootPart.Position
    local bestTarget, bestScore = nil, math.huge
    for _, enemy in ipairs(enemies) do
        if enemy and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
            local enemyHumanoid = enemy.Humanoid
            if enemyHumanoid.Health > 0 then
                local distance = (enemy.HumanoidRootPart.Position - localPos).Magnitude
                local dirToEnemy = (enemy.HumanoidRootPart.Position - localPos).Unit
                local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToEnemy), -1, 1))
                local score = distance + angleDiff * 100
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

-- Hàm dự đoán vị trí mục tiêu: nếu khoảng cách <350 thì dùng head.Position, nếu ≥350 và Prediction bật thì dự đoán theo vận tốc.
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

-- Health Board: hiển thị thanh máu
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
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
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
    local boardHeight = headSize.Y * 3
    if not healthBoards[enemy] then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBoard"
        billboard.Adornee = enemy.Head
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
        billboard.StudsOffset = Vector3.new(0, 50, 0)
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
        
        -- Nếu không có mục tiêu hợp lệ, chọn mục tiêu mới
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
            targetInRangeStart = currentTarget and tick() or nil
        end

        -- Kiểm tra Auto Lock: nếu mục tiêu nằm trong bán kính AUTO_LOCK quá 5 giây, tự bật Aim
        if currentTarget and isValidTarget(currentTarget) then
            local localPos = LocalPlayer.Character.HumanoidRootPart.Position
            local targetPos = currentTarget.HumanoidRootPart.Position
            local distance = (targetPos - localPos).Magnitude
            if distance <= AUTO_LOCK_RADIUS then
                if not targetInRangeStart then
                    targetInRangeStart = tick()
                elseif tick() - targetInRangeStart >= AUTO_LOCK_TIME then
                    locked = true
                    toggleButton.Text = "ON"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
                end
            else
                targetInRangeStart = nil
            end
        else
            targetInRangeStart = nil
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
                    targetInRangeStart = nil
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        -- Luôn lock vào head (đảm bảo chính xác) và cập nhật ngay tức thì
                        Camera.CFrame = calculateCameraRotation(predictedPos)
                    end
                end
            end
        end

        -- PHẦN HITBOX (áp dụng khi HITBOX_ENABLED)
        if locked and currentTarget and HITBOX_ENABLED then
            local enemyHRP = currentTarget:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = currentTarget:FindFirstChild("Humanoid")
            if enemyHRP and enemyHumanoid then
                if not currentHitbox then
                    currentHitbox = Instance.new("Part")
                    currentHitbox.Name = "ExpandedHitbox"
                    currentHitbox.Transparency = 0.9
                    currentHitbox.CanCollide = false
                    currentHitbox.Anchored = false
                    currentHitbox.Color = Color3.new(0,0,0.5)
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(HITBOX_OFFSET, HITBOX_OFFSET, HITBOX_OFFSET)
                    currentHitbox.Parent = currentTarget
                    local weld = Instance.new("WeldConstraint", currentHitbox)
                    weld.Part0 = enemyHRP
                    weld.Part1 = currentHitbox
                    currentHitbox:SetAttribute("LastHealth", enemyHumanoid.Health)
                else
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(HITBOX_OFFSET, HITBOX_OFFSET, HITBOX_OFFSET)
                    local lastHealth = currentHitbox:GetAttribute("LastHealth") or enemyHumanoid.Health
                    if enemyHumanoid.Health < lastHealth then
                        local originalColor = currentHitbox.Color
                        currentHitbox.Color = Color3.new(1,0,0)
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
    targetInRangeStart = nil
    if currentHitbox then
        currentHitbox:Destroy()
        currentHitbox = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    local hrp = character:WaitForChild("HumanoidRootPart")
    lastLocalPosition = hrp.Position
    lastMovementTime = tick()
    targetInRangeStart = nil
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
    Camera.CameraType = Enum.CameraType.Custom
end)
