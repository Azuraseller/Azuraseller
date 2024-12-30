local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Cấu hình các tham số
local Prediction = 0.15  -- Dự đoán vị trí mục tiêu
local Radius = 250 -- Bán kính khóa mục tiêu
local BaseSmoothFactor = 0.2  -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.6  -- Mức độ mượt tối đa
local CameraRotationSpeed = 0.25  -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.15 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.1 -- Tốc độ chuyển mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính
local AIActive = false -- Trạng thái AI

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút X
local AIButton = Instance.new("TextButton") -- Nút AI
local AimCircle = Instance.new("Frame") -- Vòng tròn khi Aim

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "OFF" -- Văn bản mặc định
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18
ToggleButton.BorderRadius = UDim.new(0, 12) -- Bo tròn nút

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "⚙️"
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Màu xám trong suốt
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18
CloseButton.BorderRadius = UDim.new(0, 12) -- Bo tròn nút

-- Nút AI
AIButton.Parent = ScreenGui
AIButton.Size = UDim2.new(0, 100, 0, 50)
AIButton.Position = UDim2.new(0.75, 0, 0.01, 0)
AIButton.Text = "AI OFF" -- Văn bản mặc định
AIButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu nền khi tắt
AIButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
AIButton.Font = Enum.Font.SourceSans
AIButton.TextSize = 18
AIButton.BorderRadius = UDim.new(0, 12) -- Bo tròn nút

-- Vòng tròn Aim
AimCircle.Parent = ScreenGui
AimCircle.Size = UDim2.new(0, 50, 0, 50)
AimCircle.Position = UDim2.new(0.5, -25, 0.5, -25)
AimCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AimCircle.BorderSizePixel = 2
AimCircle.BorderColor3 = Color3.fromRGB(255, 255, 255)
AimCircle.Visible = false
AimCircle.AnchorPoint = Vector2.new(0.5, 0.5)

-- Hàm bật/tắt Aim qua nút X
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Ẩn/hiện nút ON/OFF theo trạng thái Aim
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
        AimCircle.Visible = false -- Ẩn vòng tròn khi Aim tắt
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        AimCircle.Visible = true -- Hiện vòng tròn khi Aim bật
    end
end)

-- Nút ON/OFF để bật/tắt ghim mục tiêu
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CurrentTarget = nil -- Hủy mục tiêu khi tắt CamLock
    end
end)

-- Nút AI ON/OFF
AIButton.MouseButton1Click:Connect(function()
    AIActive = not AIActive
    if AIActive then
        AIButton.Text = "AI ON"
        AIButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        AIButton.Text = "AI OFF"
        AIButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- AI Ghost: Ghi lại hành vi người chơi và mục tiêu
local AIBehavior = {
    playerActions = {},
    targetActions = {}
}

local function RecordPlayerBehavior()
    -- Ghi lại hành vi người chơi như di chuyển, tốc độ, tần suất thay đổi hướng, v.v.
    local behavior = {
        position = LocalPlayer.Character.HumanoidRootPart.Position,
        velocity = LocalPlayer.Character.HumanoidRootPart.Velocity
    }
    table.insert(AIBehavior.playerActions, behavior)
end

local function RecordTargetBehavior(target)
    -- Ghi lại hành vi mục tiêu
    if target and target:FindFirstChild("HumanoidRootPart") then
        local behavior = {
            position = target.HumanoidRootPart.Position,
            velocity = target.HumanoidRootPart.Velocity
        }
        table.insert(AIBehavior.targetActions, behavior)
    end
end

local function ImitatePlayerBehavior()
    -- Mô phỏng hành vi đã ghi lại khi người chơi không điều khiển
    for _, action in ipairs(AIBehavior.playerActions) do
        -- Thực hiện hành động của người chơi (di chuyển, tốc độ, v.v.)
    end
end

local function ImitateTargetBehavior()
    -- Mô phỏng hành vi của mục tiêu
    for _, action in ipairs(AIBehavior.targetActions) do
        -- Thực hiện hành động của mục tiêu (di chuyển, tốc độ, v.v.)
    end
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if AimActive then
        -- Tìm kẻ thù gần nhất
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            if not Locked then
                Locked = true
                ToggleButton.Text = "ON"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            end
            if not CurrentTarget then
                CurrentTarget = enemies[1] -- Chọn mục tiêu đầu tiên
            end
        else
            if Locked then
                Locked = false
                ToggleButton.Text = "OFF"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                CurrentTarget = nil -- Ngừng ghim khi không còn mục tiêu
            end
        end

        -- Theo dõi mục tiêu
        if CurrentTarget and Locked then
            local targetCharacter = CurrentTarget
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                local targetPosition = PredictTargetPosition(targetCharacter)

                -- Kiểm tra nếu mục tiêu không hợp lệ
                local distance = (targetCharacter.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if targetCharacter.Humanoid.Health <= 0 or distance > Radius then
                    CurrentTarget = nil
                else
                    -- Điều chỉnh vị trí camera
                    targetPosition = AdjustCameraPosition(targetPosition)

                    -- Tính toán SmoothFactor
                    local SmoothFactor = CalculateSmoothFactor(targetCharacter)

                    -- Sử dụng TargetLockSpeed để điều chỉnh tốc độ ghim
                    local TargetPositionSmooth = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), TargetLockSpeed)

                    -- Cập nhật camera chính
                    Camera.CFrame = TargetPositionSmooth
                end
            end
        end
    end
end)

-- Tự động bật script khi chuyển server
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        AimActive = true
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)
