-- Các biến cấu hình
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = game.Workspace.CurrentCamera
local aimbotEnabled = true
local freeLookEnabled = false
local target = nil
local CameraRotationSpeed = 0.3
local Radius = 230
local FOVAdjustment = false
local CameraZoom = 70
local AimActive = true
local Locked = false
local FocusMode = false

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local FocusButton = Instance.new("TextButton")
local AimCircle = Instance.new("Frame")

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "⚙️"
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Focus Mode Button
FocusButton.Parent = ScreenGui
FocusButton.Size = UDim2.new(0, 30, 0, 30)
FocusButton.Position = UDim2.new(0.79, 0, 0.07, 0)
FocusButton.Text = "🌀"
FocusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
FocusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FocusButton.Font = Enum.Font.SourceSans
FocusButton.TextSize = 18

-- Aim Circle
AimCircle.Parent = ScreenGui
AimCircle.Size = UDim2.new(0, 100, 0, 100)
AimCircle.Position = UDim2.new(0.5, -50, 0.5, -50)
AimCircle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AimCircle.BackgroundTransparency = 0.5
AimCircle.AnchorPoint = Vector2.new(0.5, 0.5)
AimCircle.Visible = false

-- Thêm UICorner để bo tròn các nút
local function addUICorner(button)
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 15)
    UICorner.Parent = button
end

addUICorner(ToggleButton)
addUICorner(CloseButton)
addUICorner(FocusButton)

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive
    FocusButton.Visible = AimActive
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        target = nil
        AimCircle.Visible = false
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        AimCircle.Visible = true
    end
end)

-- Nút Focus Mode
FocusButton.MouseButton1Click:Connect(function()
    FocusMode = not FocusMode
    if FocusMode then
        FocusButton.Text = "🌀 ON"
        FocusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        FocusButton.Text = "🌀 OFF"
        FocusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Tìm mục tiêu gần nhất
local function findClosestEnemy()
    local closestTarget = nil
    local closestDistance = math.huge  -- Bắt đầu với khoảng cách rất lớn

    for _, potentialTarget in pairs(game.Players:GetPlayers()) do
        if potentialTarget ~= player and potentialTarget.Character and potentialTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = potentialTarget.Character.HumanoidRootPart.Position
            local distance = (camera.CFrame.Position - targetPosition).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestTarget = potentialTarget.Character
            end
        end
    end

    return closestTarget
end

-- Cập nhật camera và aim
local function updateCameraAndAim(targetPosition)
    if not aimbotEnabled or not targetPosition then return end

    -- Cập nhật FOV và tốc độ camera dựa trên khoảng cách đến mục tiêu
    local distance = (camera.CFrame.Position - targetPosition).Magnitude
    local fov = math.clamp(distance / 10, 70, 120)  -- Điều chỉnh phạm vi FOV
    camera.FieldOfView = fov
    local cameraSpeed = math.clamp(distance / 10, 5, 20)  -- Điều chỉnh phạm vi tốc độ camera

    -- Aim vào vị trí mục tiêu
    local targetDirection = (targetPosition - camera.CFrame.Position).unit
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPosition)

    -- Điều chỉnh hướng của nhân vật (nếu Free Look không được bật)
    if not freeLookEnabled and character:FindFirstChild("HumanoidRootPart") then
        local characterDirection = (targetPosition - character.HumanoidRootPart.Position).unit
        character:SetPrimaryPartCFrame(CFrame.lookAt(character.HumanoidRootPart.Position, targetPosition))
    end
end

-- Điều khiển Free Look
local function handleFreeLook()
    if freeLookEnabled then
        -- Cho phép di chuyển camera tự do
        -- Tắt aimbot khi Free Look được kích hoạt
        aimbotEnabled = false
    else
        -- Bật lại aimbot khi Free Look bị tắt
        aimbotEnabled = true
    end
end

-- Tìm mục tiêu gần nhất
game:GetService("RunService").RenderStepped:Connect(function()
    if AimActive then
        -- Tìm mục tiêu gần nhất
        target = findClosestEnemy()
        if target and target:FindFirstChild("HumanoidRootPart") then
            updateCameraAndAim(target.HumanoidRootPart.Position)
        end
    end
end)

-- Toggle Free Look
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        freeLookEnabled = not freeLookEnabled
        handleFreeLook()
    end
end)

-- Cập nhật camera khi AimBot đang hoạt động
game:GetService("RunService").RenderStepped:Connect(function()
    if AimActive and target then
        local targetPosition = target.HumanoidRootPart.Position
        updateCameraAndAim(targetPosition)
    end
end)
