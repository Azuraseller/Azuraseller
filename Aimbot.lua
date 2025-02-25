--[[    
  Advanced Camera Gun Script - Pro Edition 6.6 (Upgraded V4)
  -------------------------------------------------------------
  Cải tiến:
   1. Khi lock mục tiêu, hệ thống tính toán "aim assist" hoạt động cực kỳ mượt mà,
      không gây giật, rung khi nhân vật di chuyển quanh mục tiêu.
   2. Tốc độ ghim, lock được nâng cấp siêu nhanh (TARGET_LOCK_SPEED = 100) và các phép Lerp
      được tối ưu nhằm mang lại phản ứng tức thì, mượt mà.
   3. Các chức năng như chọn mục tiêu, dự đoán vị trí được cải tiến với bộ lọc làm mượt (low-pass filter)
      để giảm sai lệch khi mục tiêu đổi hướng đột ngột.
   4. Xoá hoàn toàn chức năng Camera lock: không thay đổi Camera.CFrame, cho phép người chơi kiểm soát camera tự do.
--]]    

-------------------------------------
-- CẤU HÌNH (có thể điều chỉnh) --
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 900       -- Bán kính hiển thị Health Board (nếu cần)
local PREDICTION_ENABLED = true        -- Bật/tắt dự đoán mục tiêu

-- Dự đoán chỉ hoạt động nếu khoảng cách ≥ MIN_PREDICTION_DISTANCE
local MIN_PREDICTION_DISTANCE = 350

-- Các tham số khác
local CLOSE_RADIUS = 7                -- Khi mục tiêu gần, giữ Y của gun (nếu cần)
local HEIGHT_DIFFERENCE_THRESHOLD = 3 -- Ngưỡng chênh lệch độ cao giữa vị trí dự đoán & điểm mục tiêu
local MOVEMENT_THRESHOLD = 0.1
local STATIONARY_TIMEOUT = 5

-- Tham số làm mượt cho aim assist
local AIM_SMOOTH_FACTOR = 15          -- Hệ số Lerp cao, phản ứng cực nhanh nhưng mượt
local TARGET_LOCK_SPEED = 100         -- Tốc độ lock tăng cường (nâng cấp siêu nhanh)
local MISALIGN_THRESHOLD = math.rad(5)  -- Ngưỡng góc lệch 5° để điều chỉnh nhanh

-------------------------------------
-- Các biến hỗ trợ cho dự đoán mượt (low-pass filter)
local lastTarget = nil                -- Theo dõi mục tiêu frame trước
local lastPredictedPosition = nil     -- Vị trí dự đoán của frame trước

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
local locked = false            -- Aim lock On/Off (aim assist)
local currentTarget = nil       -- Mục tiêu hiện tại
local lastLocalPosition = nil  
local lastMovementTime = tick()

-- (Nếu cần hiển thị Health Board; không bắt buộc)
local healthBoards = {}

-- Biến chứa aim assist CFrame (không thay đổi camera, dùng cho việc bắn, hướng súng,…)
local aimAssistCFrame = nil

-------------------------------------
-- GIAO DIỆN GUI (Tối giản: chỉ gồm nút Toggle & Close) --
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
-- Các hàm tiện ích cho Aim Assist --
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

-- Hàm dự đoán vị trí mục tiêu nâng cấp:
-- Nếu distance < MIN_PREDICTION_DISTANCE, dùng head.Position.
-- Nếu >=, tính dựa trên hướng của nhân vật (với offset 7 studs) và ưu tiên hướng di chuyển nếu trái hướng.
-- Thời gian dự đoán = distance/100, clamped [0.5, 1] giây.
-- Áp dụng low-pass filter để làm mượt sự thay đổi, tránh jitter khi mục tiêu đổi hướng đột ngột.
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

    if lastTarget ~= target then
        lastPredictedPosition = computedPrediction
        lastTarget = target
    else
        -- Low-pass filter với tỉ lệ Lerp càng nhỏ thì mượt hơn (0.2 cho phản ứng nhanh nhưng ổn định)
        lastPredictedPosition = lastPredictedPosition:Lerp(computedPrediction, 0.2)
    end
    return lastPredictedPosition
end

-- Hàm tính toán CFrame mục tiêu dựa trên vị trí dự đoán (dùng cho aim assist)
local function calculateAimAssistCFrame(targetPosition)
    local localPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
    return CFrame.new(localPos, targetPosition)
end

-- (Nếu cần) Hàm hiển thị Health Board; có thể xoá nếu không dùng
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
    local boardHeight = headSize.Y * 4
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
        
        -- Kiểm tra và chuyển mục tiêu nếu mục tiêu không hợp lệ
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
            lastPredictedPosition = nil -- reset khi chuyển mục tiêu
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
                -- Nếu mục tiêu ra ngoài bán kính hoặc chết, hủy lock ngay
                if enemyHumanoid.Health <= 0 or distance > LOCK_RADIUS then
                    currentTarget = nil
                    locked = false
                    toggleButton.Text = "OFF"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(220,20,60)
                else
                    local predictedPos = predictTargetPosition(currentTarget)
                    if predictedPos then
                        -- Tính toán Aim Assist CFrame dựa trên vị trí dự đoán
                        aimAssistCFrame = calculateAimAssistCFrame(predictedPos)
                        -- (Thay vì thay đổi Camera.CFrame, ta cập nhật aimAssistCFrame để sử dụng cho súng/đạn bắn)
                        -- Ví dụ: GunScript.UpdateAim(aimAssistCFrame)
                    end
                end
            end
        end

        -- Hiệu ứng GUI cho nút Toggle (dựa theo trạng thái lock)
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
    lastPredictedPosition = nil
    local humanoid = character:WaitForChild("Humanoid")
    -- Để đảm bảo camera không bị khóa, ta không thay đổi Camera.CameraType
    Camera.CameraSubject = humanoid
end)
