-- Dịch vụ cần thiết
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- RemoteEvent để gửi thông tin phím sang server (nếu cần)
local keyEvent = ReplicatedStorage:FindFirstChild("KeyEvent")
if not keyEvent then
    keyEvent = Instance.new("RemoteEvent")
    keyEvent.Name = "KeyEvent"
    keyEvent.Parent = ReplicatedStorage
end

-- Các cài đặt mặc định (có thể cấu hình qua Config Panel)
local autoFireDelay = 0.5     -- Thời gian chờ trước khi auto-fire (giây)
local autoFireInterval = 0.3  -- Khoảng thời gian giữa các lần kích hoạt auto-fire (giây)

-- Danh sách các phím (có thể thay đổi qua Config Panel)
local keys = {"1", "z", "2", "3", "q", "w", "e", "r"}
local currentIndex = 1

-- Tạo giao diện chính
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedProKeyGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Tạo nút chính (button)
local button = Instance.new("TextButton")
button.Name = "AutoKeyButton"
button.Size = UDim2.new(0, 120, 0, 60)
button.Position = UDim2.new(1, -140, 1, -90)  -- Góc dưới bên phải
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.BorderSizePixel = 0
button.Font = Enum.Font.SourceSansBold
button.TextSize = 24
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = keys[currentIndex]
button.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = button

-- Nhãn hiển thị phím kế tiếp
local nextKeyLabel = Instance.new("TextLabel")
nextKeyLabel.Name = "NextKeyLabel"
nextKeyLabel.Size = UDim2.new(1, 0, 0, 20)
nextKeyLabel.Position = UDim2.new(0, 0, 1, 5)
nextKeyLabel.BackgroundTransparency = 1
local nextIndex = currentIndex + 1 > #keys and 1 or currentIndex + 1
nextKeyLabel.Text = "Next: " .. keys[nextIndex]
nextKeyLabel.Font = Enum.Font.SourceSans
nextKeyLabel.TextSize = 18
nextKeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
nextKeyLabel.Parent = button

-- Tạo âm thanh click (thay SoundId theo ý bạn)
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://131072891"
clickSound.Volume = 0.5
clickSound.Parent = button

-- Tạo ParticleEmitter cho hiệu ứng phím (thay Texture theo ý bạn)
local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Texture = "rbxassetid://243660364"
particleEmitter.Rate = 0
particleEmitter.Lifetime = NumberRange.new(0.3, 0.5)
particleEmitter.Speed = NumberRange.new(50, 70)
particleEmitter.Parent = button

-- Tạo Progress Bar hiển thị tiến độ auto-fire delay
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(1, 0, 0, 5)
progressBar.Position = UDim2.new(0, 0, 1, -5)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
progressBar.BorderSizePixel = 0
progressBar.Parent = button
progressBar.Visible = false

-- Biến hỗ trợ auto-fire
local holding = false
local autoFireCoroutine

-- Hàm cập nhật giao diện hiển thị phím và phím kế tiếp
local function updateButtonText()
    button.Text = keys[currentIndex]
    local nextIndex = currentIndex + 1
    if nextIndex > #keys then
        nextIndex = 1
    end
    nextKeyLabel.Text = "Next: " .. keys[nextIndex]
end

-- Hiệu ứng particle khi kích hoạt phím
local function emitParticles()
    particleEmitter:Emit(20)
end

-- Hiệu ứng animation cho nút (scale, rotation)
local function animateButtonPress()
    local originalSize = button.Size
    local originalRotation = button.Rotation
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local tweenDown = TweenService:Create(button, tweenInfo, {
        Size = UDim2.new(0, originalSize.X.Offset * 0.9, 0, originalSize.Y.Offset * 0.9),
        Rotation = originalRotation - 5
    })
    tweenDown:Play()
    tweenDown.Completed:Connect(function()
        local tweenUp = TweenService:Create(button, tweenInfo, {
            Size = originalSize,
            Rotation = originalRotation
        })
        tweenUp:Play()
    end)
end

-- Hàm xử lý khi kích hoạt phím
local function handleKey()
    local key = keys[currentIndex]
    print("Activated key: " .. key)
    keyEvent:FireServer(key)  -- Gửi key sang server nếu cần
    
    clickSound:Play()
    animateButtonPress()
    emitParticles()
    
    currentIndex = currentIndex + 1
    if currentIndex > #keys then
        currentIndex = 1
    end
    updateButtonText()
end

-- Chế độ auto-fire: Khi giữ nút, sau khoảng delay cho trước sẽ tự kích hoạt key liên tục với khoảng interval cố định
local function startAutoFire()
    if holding then return end
    holding = true
    progressBar.Visible = true
    progressBar.Size = UDim2.new(0, 0, 0, 5)
    local startTime = tick()
    autoFireCoroutine = coroutine.create(function()
        -- Hiệu ứng progress bar đếm delay
        while tick() - startTime < autoFireDelay and holding do
            local elapsed = tick() - startTime
            local progress = math.clamp(elapsed / autoFireDelay, 0, 1)
            progressBar.Size = UDim2.new(progress, 0, 0, 5)
            RunService.RenderStepped:Wait()
        end
        if holding then
            -- Sau delay, auto-fire liên tục
            while holding do
                handleKey()
                progressBar.Size = UDim2.new(0, 0, 0, 5)
                wait(autoFireInterval)
            end
        end
        progressBar.Visible = false
    end)
    coroutine.resume(autoFireCoroutine)
end

local function stopAutoFire()
    holding = false
    progressBar.Visible = false
end

-- Sự kiện chuột cho nút
button.MouseButton1Click:Connect(function()
    if not holding then
        handleKey()
    end
end)

button.MouseButton1Down:Connect(function()
    startAutoFire()
end)

button.MouseButton1Up:Connect(function()
    stopAutoFire()
end)

button.MouseLeave:Connect(function()
    stopAutoFire()
end)

-- Hiệu ứng hover: thay đổi màu nền khi di chuột vào và ra
button.MouseEnter:Connect(function()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
    tween:Play()
end)

button.MouseLeave:Connect(function()
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)})
    tween:Play()
end)

--------------------------------------------------------------------
-- PHẦN CONFIG PANEL (mở bằng nhấn chuột phải trên nút)
--------------------------------------------------------------------
local configPanel = Instance.new("Frame")
configPanel.Name = "ConfigPanel"
configPanel.Size = UDim2.new(0, 250, 0, 180)
configPanel.Position = UDim2.new(0.5, -125, 0.5, -90)
configPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
configPanel.BorderSizePixel = 0
configPanel.Visible = false
configPanel.Parent = screenGui

local configUICorner = Instance.new("UICorner")
configUICorner.CornerRadius = UDim.new(0, 8)
configUICorner.Parent = configPanel

-- Tiêu đề Config
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Cài đặt Auto-Key"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = configPanel

-- Nhãn & TextBox cho Auto-Fire Delay
local delayLabel = Instance.new("TextLabel")
delayLabel.Name = "DelayLabel"
delayLabel.Size = UDim2.new(0, 100, 0, 25)
delayLabel.Position = UDim2.new(0, 10, 0, 40)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay (s):"
delayLabel.Font = Enum.Font.SourceSans
delayLabel.TextSize = 18
delayLabel.TextColor3 = Color3.new(1, 1, 1)
delayLabel.Parent = configPanel

local delayBox = Instance.new("TextBox")
delayBox.Name = "DelayBox"
delayBox.Size = UDim2.new(0, 120, 0, 25)
delayBox.Position = UDim2.new(0, 120, 0, 40)
delayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
delayBox.Text = tostring(autoFireDelay)
delayBox.ClearTextOnFocus = false
delayBox.Font = Enum.Font.SourceSans
delayBox.TextSize = 18
delayBox.TextColor3 = Color3.new(1, 1, 1)
delayBox.Parent = configPanel

-- Nhãn & TextBox cho Auto-Fire Interval
local intervalLabel = Instance.new("TextLabel")
intervalLabel.Name = "IntervalLabel"
intervalLabel.Size = UDim2.new(0, 100, 0, 25)
intervalLabel.Position = UDim2.new(0, 10, 0, 75)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Interval (s):"
intervalLabel.Font = Enum.Font.SourceSans
intervalLabel.TextSize = 18
intervalLabel.TextColor3 = Color3.new(1, 1, 1)
intervalLabel.Parent = configPanel

local intervalBox = Instance.new("TextBox")
intervalBox.Name = "IntervalBox"
intervalBox.Size = UDim2.new(0, 120, 0, 25)
intervalBox.Position = UDim2.new(0, 120, 0, 75)
intervalBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
intervalBox.Text = tostring(autoFireInterval)
intervalBox.ClearTextOnFocus = false
intervalBox.Font = Enum.Font.SourceSans
intervalBox.TextSize = 18
intervalBox.TextColor3 = Color3.new(1, 1, 1)
intervalBox.Parent = configPanel

-- Nhãn & TextBox cho danh sách keys
local keysLabel = Instance.new("TextLabel")
keysLabel.Name = "KeysLabel"
keysLabel.Size = UDim2.new(0, 100, 0, 25)
keysLabel.Position = UDim2.new(0, 10, 0, 110)
keysLabel.BackgroundTransparency = 1
keysLabel.Text = "Danh sách keys:"
keysLabel.Font = Enum.Font.SourceSans
keysLabel.TextSize = 18
keysLabel.TextColor3 = Color3.new(1, 1, 1)
keysLabel.Parent = configPanel

local keysBox = Instance.new("TextBox")
keysBox.Name = "KeysBox"
keysBox.Size = UDim2.new(0, 220, 0, 25)
keysBox.Position = UDim2.new(0, 10, 0, 140)
keysBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keysBox.Text = table.concat(keys, ",")
keysBox.ClearTextOnFocus = false
keysBox.Font = Enum.Font.SourceSans
keysBox.TextSize = 18
keysBox.TextColor3 = Color3.new(1, 1, 1)
keysBox.Parent = configPanel

-- Nút Lưu cài đặt
local saveButton = Instance.new("TextButton")
saveButton.Name = "SaveButton"
saveButton.Size = UDim2.new(0, 100, 0, 30)
saveButton.Position = UDim2.new(0.5, -50, 1, -40)
saveButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
saveButton.Text = "Lưu"
saveButton.Font = Enum.Font.SourceSansBold
saveButton.TextSize = 20
saveButton.TextColor3 = Color3.new(1, 1, 1)
saveButton.Parent = configPanel

saveButton.MouseButton1Click:Connect(function()
    local newDelay = tonumber(delayBox.Text)
    local newInterval = tonumber(intervalBox.Text)
    local newKeys = {}
    for key in string.gmatch(keysBox.Text, "([^,]+)") do
        table.insert(newKeys, key:gsub("^%s*(.-)%s*$", "%1"))
    end
    if newDelay and newInterval and #newKeys > 0 then
        autoFireDelay = newDelay
        autoFireInterval = newInterval
        keys = newKeys
        currentIndex = 1
        updateButtonText()
        configPanel.Visible = false
    else
        print("Cài đặt không hợp lệ!")
    end
end)

-- Ẩn Config Panel khi nhấn Escape
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Escape and configPanel.Visible then
        configPanel.Visible = false
    end
end)

-- Mở/tắt Config Panel khi nhấn chuột phải trên nút
button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        configPanel.Visible = not configPanel.Visible
    end
end)
