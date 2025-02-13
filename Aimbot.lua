--[[  
  Advanced Camera Gun Script - Phiên bản nâng cấp chuyên sâu  
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
local CAMERA_ROTATION_SPEED = 0.55        -- Tốc độ xoay camera cơ bản  
local FAST_ROTATION_MULTIPLIER = 2        -- Hệ số tăng tốc xoay khi mục tiêu “sau lưng”  
local METER_DETECTION_RADIUS = 700        -- Bán kính kích hoạt meter  
local HEALTH_BOARD_RADIUS = 900           -- Bán kính hiển thị Health Board  
local HEALTH_BAR_SCALE = 1.5                -- Tỉ lệ phóng to ban đầu của Health Board  
local HEIGHT_DIFFERENCE_THRESHOLD = 20    -- Ngưỡng chênh lệch theo trục Y để xoay toàn bộ  
  
-- Các thông số liên quan đến dự đoán chuyển động của LocalPlayer  
local MOVEMENT_THRESHOLD = 0.1            -- Ngưỡng chuyển động tối thiểu  
local STATIONARY_TIMEOUT = 5              -- Thời gian cho “dự đoán” khi người chơi dừng (chưa quá 5 giây)  
  
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
  
-- Nút On/Off: vị trí (0.85, 0.01), kích thước (100,50)  
local toggleButton = Instance.new("TextButton")  
toggleButton.Parent = screenGui  
toggleButton.Size = UDim2.new(0, 100, 0, 50)  
toggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)  
toggleButton.Text = "OFF"  
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- đỏ khi tắt  
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)  
toggleButton.Font = Enum.Font.SourceSans  
toggleButton.TextSize = 18  
toggleButton.Visible = false  -- ban đầu ẩn, chỉ hiện khi nhấn nút X  
  
-- Nút X: vị trí (0.79, 0.01), kích thước (30,30)  
local closeButton = Instance.new("TextButton")  
closeButton.Parent = screenGui  
closeButton.Size = UDim2.new(0, 30, 0, 30)  
closeButton.Position = UDim2.new(0.79, 0, 0.01, 0)  
closeButton.Text = "X"  
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)  
closeButton.Font = Enum.Font.SourceSans  
closeButton.TextSize = 18  
  
-- “Meter” dưới nút On/Off  
local meterLine = Instance.new("Frame")  
meterLine.Parent = toggleButton  
meterLine.Size = UDim2.new(1, -10, 0, 5)   -- chiều rộng gần toàn bộ, chiều cao 5 pixel ban đầu  
meterLine.Position = UDim2.new(0, 5, 1, -5)  
meterLine.BackgroundColor3 = Color3.new(0, 0, 0)  

-- Thêm UICorner để bo tròn  
local meterCorner = Instance.new("UICorner")
meterCorner.CornerRadius = UDim.new(0, 3)
meterCorner.Parent = meterLine

-- Thêm UIStroke để viền  
local meterStroke = Instance.new("UIStroke")
meterStroke.Color = Color3.fromRGB(255, 255, 255)
meterStroke.Thickness = 2
meterStroke.Parent = meterLine
  
-------------------------------------  
-- Xử lý sự kiện cho các nút GUI --  
-------------------------------------  
-- Nút X: bật/tắt toàn bộ script (và hiển thị/ẩn nút On/Off)  
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
  
-- Nút On/Off: chuyển đổi trạng thái ghim mục tiêu  
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
  
-- Cập nhật vị trí của LocalPlayer để theo dõi chuyển động  
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
  
-- Cập nhật thời gian mỗi mục tiêu đã có trong vùng LOCK_RADIUS  
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
  
-- Chọn mục tiêu ưu tiên dựa theo thời gian có trong vùng, khoảng cách và HP của mục tiêu  
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
  
                -- Nếu mục tiêu đã có mặt trên 3 giây hoặc HP thấp, ưu tiên hơn  
                if timeInRange >= PRIORITY_HOLD_TIME or healthRatio <= HEALTH_PRIORITY_THRESHOLD then  
                    score = distance + (healthRatio * 1000)  
                else  
                    score = distance + 1000  -- phạt nếu chưa đủ thời gian hay HP không đủ thấp  
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
  
-- Dự đoán vị trí tương lai của mục tiêu  
local function predictTargetPosition(target)  
    local hrp = target:FindFirstChild("HumanoidRootPart")  
    if not hrp then return nil end  
  
    -- Dự đoán cơ bản: vị trí hiện tại + vận tốc * PREDICTION_TIME  
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
  
-- Tính toán CFrame xoay camera để hướng về mục tiêu  
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
  
-- Cập nhật (hoặc tạo mới) Health Board cho một mục tiêu  
local function updateHealthBoardForTarget(enemy)  
    if not enemy or not enemy:FindFirstChild("Head") or not enemy:FindFirstChild("Humanoid") then
        return  
    end  
  
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
  
    -- Tính tỷ lệ kích thước Health Board dựa trên khoảng cách từ Camera đến enemy.Head  
    local camPos = Camera.CFrame.Position  
    local headPos = enemy.Head.Position  
    local headDistance = (camPos - headPos).Magnitude  
    local baseDistance = 50  -- khoảng cách chuẩn (có thể điều chỉnh)  
    local minScale = 0.5  
    local maxScale = 2  
    local scaleFactor = math.clamp(headDistance / baseDistance, minScale, maxScale)
  
    if not healthBoards[enemy] then  
        -- Tạo mới BillboardGui cho Health Board  
        local billboard = Instance.new("BillboardGui")  
        billboard.Name = "HealthBoard"  
        billboard.Adornee = enemy.Head  
        billboard.AlwaysOnTop = true  
        billboard.Size = UDim2.new(0, 100 * scaleFactor, 0, 10 * scaleFactor)  
        billboard.StudsOffset = Vector3.new(0, 3 * scaleFactor, 0)  
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
        -- Cập nhật kích thước và vị trí theo scaleFactor  
        billboard.Size = UDim2.new(0, 100 * scaleFactor, 0, 10 * scaleFactor)  
        billboard.StudsOffset = Vector3.new(0, 3 * scaleFactor, 0)  
  
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
  
-------------------------------------  
-- Main Loop: RenderStepped Update --  
-------------------------------------  
RunService.RenderStepped:Connect(function(deltaTime)  
    if aimActive then  
        updateLocalMovement()  
        updateTargetTimers(deltaTime)  
  
        -- Lựa chọn mục tiêu ưu tiên  
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
  
        -- Nếu có mục tiêu được ghim, cập nhật góc xoay camera  
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
  
        -- Cập nhật “meter” dưới nút On/Off  
        local enemiesForMeter = getEnemiesInRadius(METER_DETECTION_RADIUS)  
        if #enemiesForMeter > 0 then  
            local amplitude = 10  -- biên độ dao động tối đa  
            local oscillation = (math.sin(tick() * 5) + 1) / 2  -- dao động từ 0 đến 1  
            local newMeterHeight = 5 + oscillation * amplitude  
            meterLine:TweenSize(UDim2.new(1, -10, 0, newMeterHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)  
        else  
            meterLine:TweenSize(UDim2.new(1, -10, 0, 5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)  
        end  
    end  
  
    -- Luôn cập nhật Health Board cho các đối thủ  
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
