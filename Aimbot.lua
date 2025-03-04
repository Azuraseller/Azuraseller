--[[  
  Advanced Camera Gun Script - Pro Edition 6.6 (Upgraded V4 + Enhanced)
  
  Phiên bản này đã:
    • Loại bỏ các chức năng can thiệp vào lock mục tiêu (smoothing, dự đoán…)
       → Khi mục tiêu được chọn, hệ thống sẽ ghim (snap lock) trực tiếp theo lựa chọn “Ghim vào” (Đầu/Thân/Chân).
    • Xoá bỏ các ngưỡng không cần thiết.
    • Rút gọn bảng Settings: chỉ hiển thị thông số mặc định và các nút toggle với màu sắc đỏ (OFF) và xanh (ON).
    • Sửa một số nhược điểm nhỏ khác.
]]--

-------------------------------------
-- CẤU HÌNH CƠ BẢN (có thể điều chỉnh)
-------------------------------------
local LOCK_RADIUS = 600               -- Bán kính ghim mục tiêu
local HEALTH_BOARD_RADIUS = 1000       -- Bán kính hiển thị Health Board
local PREDICTION_ENABLED = true        -- (Giữ lại nhưng không sử dụng dự đoán)

-- Các tham số liên quan đến aim smoothing, dự đoán… được loại bỏ để ghim mục tiêu trực tiếp
local AIM_SMOOTH_FACTOR = 15           -- (Không dùng)
local TARGET_LOCK_SPEED = 100          -- (Không dùng)

-- Cấu hình giao diện Health Bar & các chức năng
local HEALTH_BAR_SIZE_X = 55           -- Kích thước Health Bar theo X (nhân với head.Size.X)
local HEALTH_BAR_SIZE_Y = 5            -- Kích thước Health Bar theo Y (nhân với head.Size.Y)
local SHOW_HEALTH_BAR = true           -- Hiển thị Health Bar
local AUTO_LOCK_ENABLED = true         -- Auto Lock (nếu tắt, có thể override qua nút Toggle)
local LOCK_TARGET_PART = "body"        -- Lựa chọn mục tiêu: "head", "body", "foot"

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

-- Nút Cài Đặt (⚙️) – đặt bên trái nút X, có kích thước giống nút X
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

-- Bảng Settings (Settings Panel) – giao diện nhỏ gọn
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Parent = screenGui
settingsFrame.Position = UDim2.new(0.65, -150, 0.03, baseButtonSize.Y + 10)
settingsFrame.Size = UDim2.new(0, 300, 0, 150)
settingsFrame.BackgroundColor3 = Color3.new(0,0,0)
settingsFrame.BackgroundTransparency = 0.3
settingsFrame.Visible = false
local settingsUICorner = Instance.new("UICorner", settingsFrame)
settingsUICorner.CornerRadius = UDim.new(0, 10)

local settingsLayout = Instance.new("UIListLayout", settingsFrame)
settingsLayout.FillDirection = Enum.FillDirection.Vertical
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 5)

-- Hàm tạo dòng hiển thị thông số (chỉ hiển thị giá trị mặc định)
local function createDisplaySetting(parent, labelText, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. tostring(value)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    return row
end

-- Hàm tạo nút toggle cho các tùy chọn (ON/OFF) với màu nền xanh (ON) và đỏ (OFF)
local function createToggleSetting(parent, labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton", row)
    toggleButton.Size = UDim2.new(0.35, 0, 1, 0)
    toggleButton.Position = UDim2.new(0.65, 0, 0, 0)
    toggleButton.BackgroundColor3 = defaultValue and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
    toggleButton.TextColor3 = Color3.new(1,1,1)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 14
    toggleButton.Text = defaultValue and "ON" or "OFF"
    local btnCorner = Instance.new("UICorner", toggleButton)
    btnCorner.CornerRadius = UDim.new(0, 10)

    return toggleButton
end

-- Hàm tạo lựa chọn "Ghim vào" (Đầu, Thân, Chân)
local function createSelectionSetting(parent, labelText, options, defaultOption)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("Frame", row)
    container.Size = UDim2.new(0.65, 0, 1, 0)
    container.Position = UDim2.new(0.35, 0, 0, 0)
    container.BackgroundTransparency = 1

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
        btn.TextSize = 14
        btn.Text = option
        btn.LayoutOrder = i
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 10)
        buttons[option] = btn
    end

    return buttons
end

-- Tạo các dòng hiển thị thông số mặc định
createDisplaySetting(settingsFrame, "Khoảng cách ghim mục tiêu", LOCK_RADIUS)
createDisplaySetting(settingsFrame, "Khoảng cách hiển thị Health bar", HEALTH_BOARD_RADIUS)
createDisplaySetting(settingsFrame, "Độ mượt", AIM_SMOOTH_FACTOR)
createDisplaySetting(settingsFrame, "Health Bar Size X", HEALTH_BAR_SIZE_X)
createDisplaySetting(settingsFrame, "Health Bar Size Y", HEALTH_BAR_SIZE_Y)

-- Tạo các nút toggle cho các tùy chọn
local predictionToggle = createToggleSetting(settingsFrame, "Dự đoán vị trí", PREDICTION_ENABLED)
local healthBarToggle = createToggleSetting(settingsFrame, "Hiển thị Health Bar", SHOW_HEALTH_BAR)
local autoLockToggle = createToggleSetting(settingsFrame, "Auto Lock", AUTO_LOCK_ENABLED)

-- Tạo lựa chọn "Ghim vào"
local lockPartButtons = createSelectionSetting(settingsFrame, "Ghim vào", {"Đầu", "Thân", "Chân"}, 
    (LOCK_TARGET_PART == "head" and "Đầu") or (LOCK_TARGET_PART == "foot" and "Chân") or "Thân")

-- Xử lý sự kiện cho các toggle
predictionToggle.MouseButton1Click:Connect(function()
    PREDICTION_ENABLED = not PREDICTION_ENABLED
    predictionToggle.Text = PREDICTION_ENABLED and "ON" or "OFF"
    predictionToggle.BackgroundColor3 = PREDICTION_ENABLED and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
end)
healthBarToggle.MouseButton1Click:Connect(function()
    SHOW_HEALTH_BAR = not SHOW_HEALTH_BAR
    healthBarToggle.Text = SHOW_HEALTH_BAR and "ON" or "OFF"
    healthBarToggle.BackgroundColor3 = SHOW_HEALTH_BAR and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
end)
autoLockToggle.MouseButton1Click:Connect(function()
    AUTO_LOCK_ENABLED = not AUTO_LOCK_ENABLED
    autoLockToggle.Text = AUTO_LOCK_ENABLED and "ON" or "OFF"
    autoLockToggle.BackgroundColor3 = AUTO_LOCK_ENABLED and Color3.fromRGB(0,200,0) or Color3.fromRGB(220,20,60)
end)
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
        if lastLocalPosition and (currentPos - lastLocalPosition).Magnitude > 0 then
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

-- Hàm tính toán CFrame cho Aim Assist dựa trên vị trí (trực tiếp, không smoothing)
local function calculateAimAssistCFrame(targetPosition)
    local localChar = LocalPlayer.Character
    local localPos = (localChar and localChar:FindFirstChild("HumanoidRootPart") and localChar.HumanoidRootPart.Position) or Vector3.new(0,0,0)
    return CFrame.new(localPos, targetPosition)
end

-------------------------------------
-- MAIN LOOP: RenderStepped Update
-------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    if aimActive then
        updateLocalMovement()
        
        if not isValidTarget(currentTarget) then
            currentTarget = selectTarget()
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
                    local targetPos = nil
                    if LOCK_TARGET_PART == "head" then
                        local head = currentTarget:FindFirstChild("Head")
                        if head then targetPos = head.Position end
                    elseif LOCK_TARGET_PART == "body" then
                        targetPos = enemyHRP.Position
                    elseif LOCK_TARGET_PART == "foot" then
                        targetPos = enemyHRP.Position - Vector3.new(0, 3, 0)
                    end
                    if targetPos then
                        local newAimCFrame = calculateAimAssistCFrame(targetPos)
                        -- Ghim trực tiếp vào mục tiêu (không dùng smoothing hay dự đoán)
                        aimAssistCFrame = newAimCFrame
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

    -- Cập nhật Health Board nếu bật
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyChar = player.Character
            if enemyChar then
                if SHOW_HEALTH_BAR then
                    if enemyChar:FindFirstChild("Head") and enemyChar:FindFirstChild("Humanoid") then
                        local humanoid = enemyChar.Humanoid
                        if humanoid.Health > 0 then
                            local headSize = enemyChar.Head.Size
                            local boardWidth = headSize.X * HEALTH_BAR_SIZE_X
                            local boardHeight = headSize.Y * HEALTH_BAR_SIZE_Y
                            if not healthBoards[enemyChar] then
                                local billboard = Instance.new("BillboardGui")
                                billboard.Name = "HealthBoard"
                                billboard.Adornee = enemyChar.Head
                                billboard.AlwaysOnTop = true
                                billboard.Size = UDim2.new(0, boardWidth, 0, boardHeight)
                                billboard.StudsOffset = Vector3.new(0, 1, 0)
                                billboard.Parent = enemyChar

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

                                healthBoards[enemyChar] = billboard
                            end
                        end
                    end
                else
                    if healthBoards[enemyChar] then
                        healthBoards[enemyChar]:Destroy()
                        healthBoards[enemyChar] = nil
                    end
                end
            end
        end
    end
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
    local humanoid = character:WaitForChild("Humanoid")
    Camera.CameraSubject = humanoid
end)
