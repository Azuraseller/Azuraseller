--[[  
  Advanced Camera Gun Script - Pro Edition 6.6 (Upgraded V4 + Enhanced)
  
  Script này bao gồm các chức năng chính của Aim Assist và giao diện GUI mở rộng:
  - Nút Toggle, Close, và nút Settings (⚙️).
  - Bảng cài đặt (Settings Panel) cho các thông số: khoảng cách, độ mượt, ngưỡng, kích thước Health Bar,
    bật/tắt dự đoán, hiển thị Health Bar, auto lock, và lựa chọn ghim vào (Đầu/Thân/Chân).
]]--

-------------------------------------
-- CẤU HÌNH & THAM SỐ CÓ THỂ ĐIỀU CHỈNH
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 1000       -- Bán kính hiển thị Health Board
local PREDICTION_ENABLED = true        -- Bật/tắt dự đoán vị trí
local MIN_PREDICTION_DISTANCE = 350    -- Khoảng cách tối thiểu để dự đoán
local CLOSE_RADIUS = 7                 -- Khi mục tiêu gần, giữ Y của gun (nếu cần)
local HEIGHT_DIFFERENCE_THRESHOLD = 5  -- Ngưỡng chênh lệch độ cao
local MOVEMENT_THRESHOLD = 0.1
local STATIONARY_TIMEOUT = 5

local AIM_SMOOTH_FACTOR = 15           -- Hệ số Lerp cho smoothing
local TARGET_LOCK_SPEED = 100          -- Tốc độ lock
local MISALIGN_THRESHOLD = math.rad(5) -- Ngưỡng góc lệch
local INSTANT_LOCK_THRESHOLD = math.rad(0)  -- Ngưỡng xoay lock tức thì

-- Các tham số mới để điều chỉnh Health Bar và các chức năng
local HEALTH_BAR_SIZE_X = 55           -- Kích thước Health Bar theo trục X (hệ số nhân với head.Size.X)
local HEALTH_BAR_SIZE_Y = 5            -- Kích thước Health Bar theo trục Y (hệ số nhân với head.Size.Y)
local SHOW_HEALTH_BAR = true           -- Hiển thị Health Bar
local AUTO_LOCK_ENABLED = true         -- Auto Lock
local LOCK_TARGET_PART = "body"        -- Lựa chọn ghim mục tiêu: "head", "body", "foot"

-------------------------------------
-- BIẾN HỖ TRỢ DỰ ĐOÁN & LOCK
-------------------------------------
local lastTarget = nil
local lastPredictedPositions = {}
local lastPredictedPosition = nil
local aimAssistCFrame = nil

-------------------------------------
-- DỊCH VỤ & ĐỐI TƯỢNG
-------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-------------------------------------
-- BIẾN TRẠNG TOÀN CỤC
-------------------------------------
local aimActive = true
local locked = false
local currentTarget = nil
local lastLocalPosition = nil    
local lastMovementTime = tick()

local healthBoards = {}

-------------------------------------
-- GIAO DIỆN GUI CHÍNH: Toggle, Close & Settings
-------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game:GetService("CoreGui")
screenGui.Name = "AdvancedCameraGUI"

local baseToggleSize = Vector2.new(100, 50)
local baseButtonSize = Vector2.new(30, 30)

local function addHoverEffect(button, baseSize)
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, baseSize.X * 1.1, 0, baseSize.Y * 1.1)})
        tween:Play()
    end)
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, baseSize.X, 0, baseSize.Y)})
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

-- Nút Cài Đặt (⚙️) – có cùng kích thước với nút X, đặt bên trái nút X
local gearButton = Instance.new("TextButton")
gearButton.Name = "GearButton"
gearButton.Parent = screenGui
gearButton.Size = UDim2.new(0, baseButtonSize.X, 0, baseButtonSize.Y)
gearButton.Position = UDim2.new(0.65, 0, 0.03, 0)
gearButton.AnchorPoint = Vector2.new(0.5, 0.5)
gearButton.Text = "⚙️"
gearButton.Font = Enum.Font.GothamBold
gearButton.TextSize = 18
gearButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
gearButton.TextColor3 = Color3.new(1,1,1)
local gearUICorner = Instance.new("UICorner", gearButton)
gearUICorner.CornerRadius = UDim.new(0, 10)
local gearUIStroke = Instance.new("UIStroke", gearButton)
gearUIStroke.Color = Color3.new(1,1,1)
gearUIStroke.Thickness = 2
addHoverEffect(gearButton, baseButtonSize)

-- Bảng cài đặt (Settings Panel)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Parent = screenGui
-- Đặt bên dưới nút ⚙️
settingsFrame.Position = UDim2.new(0.65, -150, 0.03, baseButtonSize.Y + 10)
settingsFrame.Size = UDim2.new(0, 300, 0, 400)
settingsFrame.BackgroundColor3 = Color3.new(0,0,0)
settingsFrame.BackgroundTransparency = 0.3
settingsFrame.Visible = false
local settingsUICorner = Instance.new("UICorner", settingsFrame)
settingsUICorner.CornerRadius = UDim.new(0, 10)

local settingsLayout = Instance.new("UIListLayout", settingsFrame)
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 5)

-- Các hàm tạo dòng cài đặt
local function createNumericSetting(parent, labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1

    local textbox = Instance.new("TextBox", row)
    textbox.Size = UDim2.new(0.35, 0, 1, 0)
    textbox.Position = UDim2.new(0.65, 0, 0, 0)
    textbox.BackgroundColor3 = Color3.new(0,0,0)
    textbox.BackgroundTransparency = 0.3
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.Font = Enum.Font.GothamBold
    textbox.TextSize = 16
    textbox.PlaceholderText = tostring(defaultValue)
    textbox.ClearTextOnFocus = false
    textbox.LayoutOrder = 2

    local boxCorner = Instance.new("UICorner", textbox)
    boxCorner.CornerRadius = UDim.new(0, 10)

    return textbox
end

local function createToggleSetting(parent, labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1

    local toggleButton = Instance.new("TextButton", row)
    toggleButton.Size = UDim2.new(0.35, 0, 1, 0)
    toggleButton.Position = UDim2.new(0.65, 0, 0, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
    toggleButton.TextColor3 = Color3.new(1,1,1)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 16
    toggleButton.Text = defaultValue and "ON" or "OFF"
    toggleButton.LayoutOrder = 2

    local btnCorner = Instance.new("UICorner", toggleButton)
    btnCorner.CornerRadius = UDim.new(0, 10)

    return toggleButton
end

local function createSelectionSetting(parent, labelText, options, defaultOption)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1

    local container = Instance.new("Frame", row)
    container.Size = UDim2.new(0.65, 0, 1, 0)
    container.Position = UDim2.new(0.35, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.LayoutOrder = 2

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    local buttons = {}
    for i, option in ipairs(options) do
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0, 50, 1, 0)
        btn.BackgroundColor3 = (option == defaultOption) and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Text = option
        btn.LayoutOrder = i
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 10)
        buttons[option] = btn
    end

    return buttons
end

-- Tạo các dòng cài đặt trong bảng Settings
local lockRadiusBox = createNumericSetting(settingsFrame, "Khoảng cách ghim mục tiêu:", LOCK_RADIUS)
local healthBoardRadiusBox = createNumericSetting(settingsFrame, "Khoảng cách hiển thị Health bar:", HEALTH_BOARD_RADIUS)
local aimSmoothBox = createNumericSetting(settingsFrame, "Độ mượt:", AIM_SMOOTH_FACTOR)
local heightDiffBox = createNumericSetting(settingsFrame, "Ngưỡng chênh lệch:", HEIGHT_DIFFERENCE_THRESHOLD)
local healthBarSizeXBox = createNumericSetting(settingsFrame, "Health Bar Size X:", HEALTH_BAR_SIZE_X)
local healthBarSizeYBox = createNumericSetting(settingsFrame, "Health Bar Size Y:", HEALTH_BAR_SIZE_Y)
local predictionToggle = createToggleSetting(settingsFrame, "Dự đoán vị trí:", PREDICTION_ENABLED)
local healthBarToggle = createToggleSetting(settingsFrame, "Hiển thị Health Bar:", SHOW_HEALTH_BAR)
local autoLockToggle = createToggleSetting(settingsFrame, "Auto Lock:", AUTO_LOCK_ENABLED)
local lockPartButtons = createSelectionSetting(settingsFrame, "Ghim vào:", {"Đầu", "Thân", "Chân"}, 
    (LOCK_TARGET_PART == "head" and "Đầu") or (LOCK_TARGET_PART == "foot" and "Chân") or "Thân")

-- Cập nhật giá trị khi người dùng thay đổi trong TextBox
lockRadiusBox.FocusLost:Connect(function()
    local num = tonumber(lockRadiusBox.Text)
    if num then
        LOCK_RADIUS = num
    else
        lockRadiusBox.Text = tostring(LOCK_RADIUS)
    end
end)

healthBoardRadiusBox.FocusLost:Connect(function()
    local num = tonumber(healthBoardRadiusBox.Text)
    if num then
        HEALTH_BOARD_RADIUS = num
    else
        healthBoardRadiusBox.Text = tostring(HEALTH_BOARD_RADIUS)
    end
end)

aimSmoothBox.FocusLost:Connect(function()
    local num = tonumber(aimSmoothBox.Text)
    if num then
        AIM_SMOOTH_FACTOR = num
    else
        aimSmoothBox.Text = tostring(AIM_SMOOTH_FACTOR)
    end
end)

heightDiffBox.FocusLost:Connect(function()
    local num = tonumber(heightDiffBox.Text)
    if num then
        HEIGHT_DIFFERENCE_THRESHOLD = num
    else
        heightDiffBox.Text = tostring(HEIGHT_DIFFERENCE_THRESHOLD)
    end
end)

healthBarSizeXBox.FocusLost:Connect(function()
    local num = tonumber(healthBarSizeXBox.Text)
    if num then
        HEALTH_BAR_SIZE_X = num
    else
        healthBarSizeXBox.Text = tostring(HEALTH_BAR_SIZE_X)
    end
end)

healthBarSizeYBox.FocusLost:Connect(function()
    local num = tonumber(healthBarSizeYBox.Text)
    if num then
        HEALTH_BAR_SIZE_Y = num
    else
        healthBarSizeYBox.Text = tostring(HEALTH_BAR_SIZE_Y)
    end
end)

-- Các toggle
predictionToggle.MouseButton1Click:Connect(function()
    PREDICTION_ENABLED = not PREDICTION_ENABLED
    predictionToggle.Text = PREDICTION_ENABLED and "ON" or "OFF"
end)

healthBarToggle.MouseButton1Click:Connect(function()
    SHOW_HEALTH_BAR = not SHOW_HEALTH_BAR
    healthBarToggle.Text = SHOW_HEALTH_BAR and "ON" or "OFF"
end)

autoLockToggle.MouseButton1Click:Connect(function()
    AUTO_LOCK_ENABLED = not AUTO_LOCK_ENABLED
    autoLockToggle.Text = AUTO_LOCK_ENABLED and "ON" or "OFF"
end)

-- Lựa chọn "Ghim vào": khi bấm, cập nhật LOCK_TARGET_PART và đánh dấu nút được chọn
for option, btn in pairs(lockPartButtons) do
    btn.MouseButton1Click:Connect(function()
        if option == "Đầu" then
            LOCK_TARGET_PART = "head"
        elseif option == "Thân" then
            LOCK_TARGET_PART = "body"
        elseif option == "Chân" then
            LOCK_TARGET_PART = "foot"
        end
        for opt, b in pairs(lockPartButtons) do
            b.BackgroundColor3 = (opt == option) and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
        end
    end)
end

-- Nút ⚙️: khi bấm sẽ ẩn/hiện bảng Settings
gearButton.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

-------------------------------------
-- SỰ KIỆN GUI cho Toggle & Close
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
    locked = true
    toggleButton.Text = "ON"
    toggleButton.BackgroundColor3 = Color3.fromRGB(0,200,0)
end)

-------------------------------------
-- HÀM TIỆN ÍCH CHO AIM ASSIST
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

-- Hàm chọn mục tiêu: tính điểm = khoảng cách + (góc lệch * 100)
local function selectTarget()
    local enemies = getEnemiesInRadius(LOCK_RADIUS)
    if #enemies == 0 then return nil end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end
    local localPos = localChar.HumanoidRootPart.Position
    local best, bestScore = nil, math.huge
    for _, enemy in ipairs(enemies) do
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        if enemyHRP then
            local distance = (enemyHRP.Position - localPos).Magnitude
            local dirToEnemy = (enemyHRP.Position - localPos).Unit
            local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToEnemy), -1, 1))
            local score = distance + angleDiff * 100
            if score < bestScore then
                bestScore = score
                best = enemy
            end
        end
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

local function calculateAimAssistCFrame(targetPosition)
    local localChar = LocalPlayer.Character
    local localPos = (localChar and localChar:FindFirstChild("HumanoidRootPart") and localChar.HumanoidRootPart.Position) or Vector3.new(0,0,0)
    return CFrame.new(localPos, targetPosition)
end

-- Hàm dự đoán vị trí mục tiêu với lựa chọn "Ghim vào": nếu nhỏ hơn MIN_PREDICTION_DISTANCE, sử dụng lựa chọn từ LOCK_TARGET_PART
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end

    local distance = (hrp.Position - localChar.HumanoidRootPart.Position).Magnitude
    if distance < MIN_PREDICTION_DISTANCE then
        if LOCK_TARGET_PART == "head" then
            return head.Position
        elseif LOCK_TARGET_PART == "body" then
            return hrp.Position
        elseif LOCK_TARGET_PART == "foot" then
            return hrp.Position - Vector3.new(0, 3, 0)
        else
            return hrp.Position
        end
    end

    local velocity = hrp.Velocity
    local speed = velocity.Magnitude
    local baseOffset = 7
    local predictionOffset = Vector3.new(0, 0, 0)
    if speed < 0.1 then
        predictionOffset = Vector3.new(0, 0, 0)
    else
        local faceDir = hrp.CFrame.LookVector
        local moveDir = velocity.Unit
        if faceDir:Dot(moveDir) < 0 then
            predictionOffset = moveDir * baseOffset
        else
            predictionOffset = faceDir * baseOffset
        end
    end

    local predictedTime = math.clamp(distance / 100, 0.5, 1)
    local computedPrediction = hrp.Position + hrp.Velocity * predictedTime + predictionOffset
    if math.abs(computedPrediction.Y - hrp.Position.Y) > HEIGHT_DIFFERENCE_THRESHOLD then
        computedPrediction = Vector3.new(computedPrediction.X, hrp.Position.Y, computedPrediction.Z)
    end

    if lastTarget ~= target then
        lastPredictedPositions = {computedPrediction}
        lastTarget = target
    else
        table.insert(lastPredictedPositions, computedPrediction)
        if #lastPredictedPositions > 5 then
            table.remove(lastPredictedPositions, 1)
        end
    end

    local weightedSum = Vector3.new(0, 0, 0)
    local totalWeight = 0
    for i = 1, #lastPredictedPositions do
        local weight = i
        weightedSum = weightedSum + lastPredictedPositions[i] * weight
        totalWeight = totalWeight + weight
    end
    local averagePrediction = weightedSum / totalWeight
    lastPredictedPosition = averagePrediction

    return lastPredictedPosition
end

local function smoothAimAssist(newCFrame, deltaTime)
    if aimAssistCFrame then
        local angleDiff = math.acos(math.clamp(aimAssistCFrame.LookVector:Dot(newCFrame.LookVector), -1, 1))
        if angleDiff > INSTANT_LOCK_THRESHOLD then
            aimAssistCFrame = newCFrame
        else
            local t = math.clamp(deltaTime * TARGET_LOCK_SPEED, 0, 1)
            aimAssistCFrame = aimAssistCFrame:Lerp(newCFrame, t)
        end
    else
        aimAssistCFrame = newCFrame
    end
end

-- (Tùy chọn) Hiển thị Health Board nếu SHOW_HEALTH_BAR = true
local function updateHealthBoardForTarget(enemy)
    if not enemy or not enemy:FindFirstChild("Head") or not enemy:FindFirstChild("Humanoid") then return end
    if not SHOW_HEALTH_BAR then 
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
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
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    local distance = (enemy.HumanoidRootPart.Position - localChar.HumanoidRootPart.Position).Magnitude
    if distance > HEALTH_BOARD_RADIUS then
        if healthBoards[enemy] then
            healthBoards[enemy]:Destroy()
            healthBoards[enemy] = nil
        end
        return
    end
    local headSize = enemy.Head.Size
    local boardWidth = headSize.X * HEALTH_BAR_SIZE_X
    local boardHeight = headSize.Y * HEALTH_BAR_SIZE_Y
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
-- MAIN LOOP: RenderStepped Update
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
            lastPredictedPositions = {}
            lastPredictedPosition = nil
        end
        
        if currentTarget then
            if AUTO_LOCK_ENABLED then
                locked = true
            end
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
                    local predictedPos = PREDICTION_ENABLED and predictTargetPosition(currentTarget) or enemyHRP.Position
                    if predictedPos then
                        local newAimCFrame = calculateAimAssistCFrame(predictedPos)
                        if #lastPredictedPositions <= 1 then
                            aimAssistCFrame = newAimCFrame
                        else
                            smoothAimAssist(newAimCFrame, deltaTime)
                        end
                        -- Ví dụ: GunScript.UpdateAim(aimAssistCFrame)
                    end
                end
            end
        end

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
-- XỬ LÝ KHI PLAYER/CHARACTER RỜI SERVER
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
    lastPredictedPositions = {}
    lastPredictedPosition = nil
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
end)
