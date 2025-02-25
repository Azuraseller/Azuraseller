--[[
  Advanced Camera Gun Script - Pro Edition 6.6 (Upgraded V4 + Enhanced)
  -------------------------------------------------------------
  Cải tiến:
   1. Adjustment Lock: Tự động kiểm tra và điều chỉnh lock nếu aim assist lệch khỏi mục tiêu.
   2. Smoothness Functions: Tối ưu chuyển động với low-pass filter và weighted average, mang lại cảm giác mượt mà.
   3. Predict Position, Movement in Multiple Directions: Dự đoán vị trí mục tiêu dựa trên vận tốc và hướng di chuyển với trung bình có trọng số
      nhằm tăng độ chính xác khi mục tiêu thay đổi hướng hoặc tốc độ.
--]]

-------------------------------------
-- CẤU HÌNH (có thể điều chỉnh) --
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 1000       -- Bán kính hiển thị Health Board (nếu cần)
local PREDICTION_ENABLED = true        -- Bật/tắt dự đoán mục tiêu

local MIN_PREDICTION_DISTANCE = 350    -- Dự đoán chỉ hoạt động nếu khoảng cách ≥ giá trị này
local CLOSE_RADIUS = 7                 -- Khi mục tiêu gần, giữ Y của gun (nếu cần)
local HEIGHT_DIFFERENCE_THRESHOLD = 5  -- Ngưỡng chênh lệch độ cao giữa vị trí dự đoán & điểm mục tiêu
local MOVEMENT_THRESHOLD = 0.1
local STATIONARY_TIMEOUT = 5

-- Tham số làm mượt & lock
local AIM_SMOOTH_FACTOR = 15           -- Hệ số Lerp (càng cao thì phản ứng càng nhanh nhưng vẫn mượt)
local TARGET_LOCK_SPEED = 100          -- Tốc độ lock (nâng cấp nhanh)
local MISALIGN_THRESHOLD = math.rad(5) -- Ngưỡng góc lệch 5° để điều chỉnh lại

-------------------------------------
-- BIẾN HỖ TRỢ DỰ ĐOÁN VÀ LOCK --
-------------------------------------
local lastTarget = nil                    -- Theo dõi mục tiêu frame trước
local lastPredictedPositions = {}         -- Lưu các vị trí dự đoán của vài frame trước
local lastPredictedPosition = nil          -- Vị trí dự đoán trung bình của frame trước
local aimAssistCFrame = nil               -- CFrame dùng cho aim assist (không thay đổi Camera)

-------------------------------------
-- DỊCH VỤ & ĐỐI TƯỢNG --
-------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-------------------------------------
-- BIẾN TRẠNG TOÀN CỤC --
-------------------------------------
local aimActive = true          -- Script đang hoạt động
local locked = false            -- Trạng thái aim lock On/Off
local currentTarget = nil       -- Mục tiêu hiện tại
local lastLocalPosition = nil  
local lastMovementTime = tick()

-- (Nếu cần hiển thị Health Board)
local healthBoards = {}

-------------------------------------
-- GIAO DIỆN GUI (Toggle & Close) --
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

-------------------------------------
-- SỰ KIỆN GUI cho Toggle & Close --
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
-- HÀM TIỆN ÍCH CHO AIM ASSIST --
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

-- Hàm tính toán CFrame cho Aim Assist dựa trên vị trí mục tiêu
local function calculateAimAssistCFrame(targetPosition)
    local localChar = LocalPlayer.Character
    local localPos = (localChar and localChar:FindFirstChild("HumanoidRootPart") and localChar.HumanoidRootPart.Position) or Vector3.new(0,0,0)
    return CFrame.new(localPos, targetPosition)
end

-------------------------------------
-- CHỨC NĂNG: Adjustment Lock (nâng cấp động) --
-------------------------------------
local function adjustAimLock(targetPosition)
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    local localPos = localChar.HumanoidRootPart.Position
    local desiredCFrame = CFrame.new(localPos, targetPosition)
    
    if aimAssistCFrame then
        local currentLookVector = aimAssistCFrame.LookVector
        local desiredLookVector = (targetPosition - localPos).Unit
        local angleDiff = math.acos(math.clamp(currentLookVector:Dot(desiredLookVector), -1, 1))
        -- Tỉ lệ điều chỉnh động: càng lệch nhiều thì Lerp nhanh hơn (tối đa 0.9)
        local lerpFactor = math.clamp(angleDiff / MISALIGN_THRESHOLD, 0, 1) * 0.9
        if angleDiff > MISALIGN_THRESHOLD then
            aimAssistCFrame = aimAssistCFrame:Lerp(desiredCFrame, lerpFactor)
        end
    else
        aimAssistCFrame = desiredCFrame
    end
end

-------------------------------------
-- CHỨC NĂNG: Smooth Aim Assist (low-pass filter nâng cao) --
-------------------------------------
local function smoothAimAssist(newCFrame)
    if aimAssistCFrame then
        -- Dùng AIM_SMOOTH_FACTOR làm hệ số điều chỉnh (càng lớn thì càng mượt)
        aimAssistCFrame = aimAssistCFrame:Lerp(newCFrame, 1 / AIM_SMOOTH_FACTOR)
    else
        aimAssistCFrame = newCFrame
    end
end

-------------------------------------
-- CHỨC NĂNG: Predict Position Multi-Directional (có trọng số) --
-------------------------------------
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end
    
    local distance = (hrp.Position - localChar.HumanoidRootPart.Position).Magnitude
    if distance < MIN_PREDICTION_DISTANCE then
        return head.Position
    end

    local velocity = hrp.Velocity
    local speed = velocity.Magnitude
    local baseOffset = 7  -- offset cơ bản
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

    -- Cập nhật buffer dự đoán: nếu mục tiêu thay đổi, reset buffer
    if lastTarget ~= target then
        lastPredictedPositions = {computedPrediction}
        lastTarget = target
    else
        table.insert(lastPredictedPositions, computedPrediction)
        if #lastPredictedPositions > 5 then
            table.remove(lastPredictedPositions, 1)
        end
    end

    -- Tính trung bình có trọng số: ưu tiên giá trị mới hơn
    local weightedSum = Vector3.new(0, 0, 0)
    local totalWeight = 0
    for i = 1, #lastPredictedPositions do
        local weight = i  -- trọng số tăng dần theo thời gian (phiên bản đơn giản)
        weightedSum = weightedSum + lastPredictedPositions[i] * weight
        totalWeight = totalWeight + weight
    end
    local averagePrediction = weightedSum / totalWeight
    lastPredictedPosition = averagePrediction

    return lastPredictedPosition
end

-------------------------------------
-- (Tùy chọn) Hàm hiển thị Health Board --
-------------------------------------
local function updateHealthBoardForTarget(enemy)
    if not enemy or not enemy:FindFirstChild("Head") or not enemy:FindFirstChild("Humanoid") then return end
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
    local boardWidth = headSize.X * 55
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
-- MAIN LOOP: RenderStepped Update --
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        -- Kiểm tra mục tiêu hợp lệ, nếu không chọn mục tiêu mới và reset buffer dự đoán
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
            lastPredictedPositions = {}
            lastPredictedPosition = nil
        end
        
        if currentTarget then
            locked = true
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
                -- Nếu mục tiêu ra ngoài bán kính hoặc chết, hủy lock
                if enemyHumanoid.Health <= 0 or distance > LOCK_RADIUS then
                    currentTarget = nil
                    locked = false
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        local newAimCFrame = calculateAimAssistCFrame(predictedPos)
                        -- Áp dụng smooth để chuyển dần sang vị trí mới
                        smoothAimAssist(newAimCFrame)
                        -- Sau đó điều chỉnh lại nếu có lệch
                        adjustAimLock(predictedPos)
                        -- (Ví dụ: GunScript.UpdateAim(aimAssistCFrame))
                    end
                end
            end
        end

        -- Hiệu ứng GUI cho nút Toggle dựa theo trạng thái lock
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
-- XỬ LÝ KHI PLAYER/CHARACTER RỜI SERVER --
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
    -- Để đảm bảo camera không bị khóa, không thay đổi Camera.CameraType
    Camera.CameraSubject = humanoid
end)
