local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1  -- Dự đoán vị trí mục tiêu
local Radius = 230 -- Bán kính khóa mục tiêu mặc định
local BaseSmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.5  -- Mức độ mượt tối đa
local CameraRotationSpeed = 0.3  -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.2 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.1 -- Tốc độ chuyển mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính
local PriorityTarget = nil -- Mục tiêu ưu tiên

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút ⚙️
local MenuButton = Instance.new("TextButton") -- Nút Menu
local RSliderButton = Instance.new("TextButton") -- Nút chỉnh R
local AimSliderButton = Instance.new("TextButton") -- Nút chỉnh tâm Aim
local RInputField = Instance.new("TextBox") -- Ô nhập R
local AimInputField = Instance.new("TextBox") -- Ô nhập tâm Aim

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
ToggleButton.AutoButtonColor = false
ToggleButton.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc

-- Nút ⚙️ (thay thế nút X)
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "⚙️"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18
CloseButton.AutoButtonColor = false
CloseButton.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc

-- Nút Menu
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.74, 0, 0.01, 0)
MenuButton.Text = "📄"
MenuButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
MenuButton.TextColor3 = Color3.fromRGB(0, 0, 0)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18
MenuButton.AutoButtonColor = false
MenuButton.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc

-- Nút chỉnh R
RSliderButton.Parent = ScreenGui
RSliderButton.Size = UDim2.new(0, 30, 0, 30)
RSliderButton.Position = UDim2.new(0.69, 0, 0.01, 0)
RSliderButton.Text = "🌐"
RSliderButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
RSliderButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RSliderButton.Font = Enum.Font.SourceSans
RSliderButton.TextSize = 18
RSliderButton.AutoButtonColor = false
RSliderButton.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc
RSliderButton.Visible = false

-- Nút chỉnh tâm Aim
AimSliderButton.Parent = ScreenGui
AimSliderButton.Size = UDim2.new(0, 30, 0, 30)
AimSliderButton.Position = UDim2.new(0.64, 0, 0.01, 0)
AimSliderButton.Text = "🎯"
AimSliderButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
AimSliderButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimSliderButton.Font = Enum.Font.SourceSans
AimSliderButton.TextSize = 18
AimSliderButton.AutoButtonColor = false
AimSliderButton.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc
AimSliderButton.Visible = false

-- Ô nhập R
RInputField.Parent = ScreenGui
RInputField.Size = UDim2.new(0, 100, 0, 30)
RInputField.Position = UDim2.new(0.69, 0, 0.07, 0)
RInputField.Text = tostring(Radius)
RInputField.Visible = false
RInputField.TextChanged:Connect(function()
    local newR = tonumber(RInputField.Text)
    if newR then
        Radius = math.clamp(newR, 100, 1000)
    end
end)
RInputField.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc

-- Ô nhập tâm Aim
AimInputField.Parent = ScreenGui
AimInputField.Size = UDim2.new(0, 100, 0, 30)
AimInputField.Position = UDim2.new(0.64, 0, 0.13, 0)
AimInputField.Text = "1.0,1.0,1.0"
AimInputField.Visible = false
AimInputField.TextChanged:Connect(function()
    local newAim = AimInputField.Text
    local values = {}
    for value in newAim:gmatch("([%d%.]+)") do
        table.insert(values, tonumber(value))
    end
    if #values == 3 then
        local x, y, z = values[1], values[2], values[3]
        -- Cập nhật giá trị tâm Aim
        -- Bạn có thể dùng các giá trị này để điều chỉnh camera
    end
end)
AimInputField.BorderRadius = UDim.new(0, 12) -- Làm tròn các góc

-- Nút ON/OFF để bật/tắt Aim
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Visible = AimActive -- Ẩn/hiện nút ON/OFF theo trạng thái Aim
    if not AimActive then
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Locked = false
        CurrentTarget = nil -- Ngừng ghim mục tiêu
    else
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Nút Menu
MenuButton.MouseButton1Click:Connect(function()
    -- Xử lý trạng thái On/Off của nút Menu
    if RSliderButton.Visible then
        RSliderButton.Visible = false
        AimSliderButton.Visible = false
    else
        RSliderButton.Visible = true
        AimSliderButton.Visible = true
    end
end)

-- Nút chỉnh R
RSliderButton.MouseButton1Click:Connect(function()
    RInputField.Visible = not RInputField.Visible
    if RInputField.Visible then
        AimSliderButton.Visible = false
    end
end)

-- Nút chỉnh tâm Aim
AimSliderButton.MouseButton1Click:Connect(function()
    AimInputField.Visible = not AimInputField.Visible
    if AimInputField.Visible then
        RInputField.Visible = false
    end
end)

-- Hàm dự đoán vị trí mục tiêu sẽ đi tới
local function PredictTargetPosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local velocity = humanoidRootPart.Velocity
        local direction = velocity.Unit
        local speed = velocity.Magnitude
        return humanoidRootPart.Position + velocity * Prediction
    end
    return target.HumanoidRootPart.Position
end

-- Cập nhật camera và các chức năng Aim
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
