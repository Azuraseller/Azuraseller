--[[    
  Advanced Camera Gun Script - Phiên bản nâng cấp chuyên sâu (v5 + Shiftlock cải tiến)
  
  Cải tiến:
  - Cải thiện xoay nhân vật khi đứng yên (chỉ xoay nếu hiệu chênh > 5°).
  - Sử dụng BodyGyro để ổn định xoay khi bị tác động bởi lực bên ngoài.
  - Kiểm tra tồn tại của HumanoidRootPart trước khi thao tác.
  - Khi tắt Aim, tự động bật lại AutoRotate để nhân vật xoay theo hướng di chuyển.
  - Cài đặt CameraSubject đảm bảo camera luôn gắn vào nhân vật.
--]]    

-------------------------------    
-- Services & Cấu hình chung --    
-------------------------------    
local Players = game:GetService("Players")  
local RunService = game:GetService("RunService")  
local TweenService = game:GetService("TweenService")  
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer  
local Camera = workspace.CurrentCamera  

-- Các tham số cấu hình cho Camera Gun  
local PREDICTION_TIME = 0.1               -- Thời gian dự đoán
local LOCK_RADIUS = 600                   -- Bán kính ghim mục tiêu
local CLOSE_RADIUS = 7                    -- Nếu mục tiêu quá gần, lock theo ngang
local PRIORITY_HOLD_TIME = 3              -- Thời gian ưu tiên (giây)
local HEALTH_PRIORITY_THRESHOLD = 0     -- HP dưới 30% được ưu tiên
local CAMERA_ROTATION_SPEED = 0.55        -- Tốc độ xoay cơ bản (dùng cho tính năng Camera Gun)
local FAST_ROTATION_MULTIPLIER = 2        -- Tốc độ xoay nhanh tối đa
local HEALTH_BOARD_RADIUS = 900           -- Bán kính hiển thị Health Board
local HEIGHT_DIFFERENCE_THRESHOLD = 20    -- Ngưỡng chênh lệch theo trục Y

-- Các thông số chuyển động của LocalPlayer    
local MOVEMENT_THRESHOLD = 0.1              
local STATIONARY_TIMEOUT = 5                

-------------------------------    
-- Biến trạng thái toàn cục --    
-------------------------------    
local locked = false                    -- Trạng thái ghim mục tiêu (ON/OFF)
local aimActive = true                  -- Script có đang hoạt động (và Shiftlock được bật)
local currentTarget = nil               -- Mục tiêu hiện tại
local targetTimeTracker = {}            -- Thời gian mục tiêu ở trong vùng

local lastLocalPosition = nil  
local lastMovementTime = tick()  

-- Bảng lưu Health Board (key = Character)  
local healthBoards = {}  

-- Biến lưu hitbox (chỉ tồn tại khi Aim ghim vào mục tiêu)  
local currentHitbox = nil  

-------------------------------    
-- Thiết lập GUI    
-------------------------------    
local screenGui = Instance.new("ScreenGui")  
screenGui.Parent = game:GetService("CoreGui")  

local baseToggleSize = Vector2.new(100, 50)  
local baseCloseSize = Vector2.new(30, 30)  

-- Nút Toggle (On/Off)  
local toggleButton = Instance.new("TextButton")  
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

-------------------------------------    
-- Sự kiện GUI --    
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

-- Lựa chọn mục tiêu dựa trên khoảng cách, thời gian, HP và góc lệch  
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
                local dirToEnemy = (enemy.HumanoidRootPart.Position - localPos).Unit  
                local angleDiff = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(dirToEnemy), -1, 1))  
                local angleScore = angleDiff * 100  
                local score = 0  
                if timeInRange >= PRIORITY_HOLD_TIME or healthRatio <= HEALTH_PRIORITY_THRESHOLD then  
                    score = distance + angleScore + (healthRatio * 500)  
                else  
                    score = distance + angleScore + 500  
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

--[[  
  Dự đoán vị trí mục tiêu:
  - Nếu khoảng cách < 440, ghim trực tiếp vào đầu (Head.Position).
  - Nếu khoảng cách ≥ 450, dựa vào hướng mà mục tiêu đang nhìn (LookVector) với offset 5 studs nếu mục tiêu đang di chuyển.
  - Với khoảng cách 440 ≤ r < 450, nội suy giữa 2 vị trí.
]]  
local function predictTargetPosition(target)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not hrp or not head then return nil end
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local distance = (hrp.Position - localCharacter.HumanoidRootPart.Position).Magnitude
    if distance < 440 then
        return head.Position
    elseif distance >= 450 then
        local offset = 0
        if hrp.Velocity.Magnitude > 0.1 then
            offset = 5
        end
        return hrp.Position + (hrp.CFrame.LookVector * offset)
    else
        local alpha = (distance - 440) / 10  -- nội suy trong khoảng 440-450
        local predictedFar = hrp.Position + (((hrp.Velocity.Magnitude > 0.1) and hrp.CFrame.LookVector or Vector3.new(0,0,0)) * 5)
        return head.Position:Lerp(predictedFar, alpha)
    end
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

-- Health Board: Thanh hiển thị HP trên đầu enemy  
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
    local boardWidth = headSize.X * 50  
    local boardHeight = headSize.Y * 15  

    if not healthBoards[enemy] then  
        local billboard = Instance.new("BillboardGui")  
        billboard.Name = "HealthBoard"  
        billboard.Adornee = enemy.Head  
        billboard.AlwaysOnTop = true  
        billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)  
        billboard.StudsOffset = Vector3.new(0, 2, 0)  
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
        billboard.StudsOffset = Vector3.new(0, 2, 0)  
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
        updateTargetTimers(deltaTime)  
          
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
            if enemyHRP then  
                if not currentHitbox then  
                    currentHitbox = Instance.new("Part")  
                    currentHitbox.Name = "ExpandedHitbox"  
                    currentHitbox.Transparency = 0.7  
                    currentHitbox.CanCollide = false  
                    currentHitbox.Anchored = false  
                    currentHitbox.Color = Color3.new(1, 0, 0)  
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(50,50,50)  
                    currentHitbox.Parent = currentTarget  
                    local weld = Instance.new("WeldConstraint")  
                    weld.Part0 = enemyHRP  
                    weld.Part1 = currentHitbox  
                    weld.Parent = currentHitbox  
                else  
                    currentHitbox.Size = enemyHRP.Size + Vector3.new(50,50,50)  
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
    -- Đảm bảo camera luôn gắn vào nhân vật  
    local humanoid = character:WaitForChild("Humanoid")  
    Camera.CameraSubject = humanoid  
    Camera.CameraType = Enum.CameraType.Custom  
end)  

----------------------------------------------------------------  
--        TÍNH NĂNG SHIFTLOCK CẢM ỨNG (CẢI TIẾN)                --
----------------------------------------------------------------  

-- Các biến cấu hình cho Shiftlock cải tiến  
local idleSpeedThreshold = 0.5   -- Nếu vận tốc HRP dưới ngưỡng này, coi như đứng yên  
local angleThreshold = 5         -- Ngưỡng cập nhật xoay (độ), nếu hiệu chênh nhỏ hơn thì không xoay  
-- Sử dụng BodyGyro để ổn định hướng xoay khi Aim On

RunService.RenderStepped:Connect(function(delta)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if aimActive then  -- Khi Aim đang bật, Shiftlock được cải tiến
         humanoid.AutoRotate = false
         local hrp = character:FindFirstChild("HumanoidRootPart")
         if not hrp then return end
         
         -- Tạo hoặc lấy BodyGyro để điều khiển xoay
         local bg = hrp:FindFirstChild("ShiftlockBodyGyro")
         if not bg then
              bg = Instance.new("BodyGyro")
              bg.Name = "ShiftlockBodyGyro"
              bg.Parent = hrp
              bg.MaxTorque = Vector3.new(0, math.huge, 0)
              bg.P = 3000
              bg.D = 500
         end
         
         -- Lấy hướng camera (yaw) theo Euler, chuyển đổi sang độ
         local _, cameraYawRad, _ = Camera.CFrame:ToEulerAnglesYXZ()
         local desiredYaw = math.deg(cameraYawRad)
         
         -- Lấy hướng hiện tại của HRP (theo Y)
         local currentYaw = hrp.Orientation.Y
         local diff = math.abs(currentYaw - desiredYaw)
         if diff > 180 then diff = 360 - diff end
         
         -- Nếu nhân vật đứng yên (vận tốc thấp) thì chỉ cập nhật nếu chênh lệch vượt ngưỡng
         if hrp.Velocity.Magnitude < idleSpeedThreshold then
             if diff > angleThreshold then
                 bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(desiredYaw), 0)
             end
         else
             bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(desiredYaw), 0)
         end
    else
         humanoid.AutoRotate = true
         -- Khi Aim tắt, xóa BodyGyro nếu có để nhân vật tự xoay theo AutoRotate
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
