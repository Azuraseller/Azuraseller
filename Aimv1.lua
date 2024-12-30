local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1 -- Dự đoán vị trí mục tiêu
local Radius = 230 -- Bán kính khóa mục tiêu (có thể thay đổi qua GUI)
local BaseSmoothFactor = 0.15 -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.5 -- Mức độ mượt tối đa
local TargetLockSpeed = 0.2 -- Tốc độ ghim mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local MultiTargetMode = false -- Chế độ nhắm đa mục tiêu
local EvadeAssist = false -- Chế độ chống né
local DebugMode = false -- Chế độ debug
local GhostMode = false -- Chế độ AI Ghost
local PlayerActions = {} -- Lưu trữ hành vi người chơi

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local MultiTargetButton = Instance.new("TextButton")
local FOVSlider = Instance.new("TextButton")
local EvadeButton = Instance.new("TextButton")
local DebugButton = Instance.new("TextButton")
local GhostButton = Instance.new("TextButton")

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

-- Nút Multi-Target
MultiTargetButton.Parent = ScreenGui
MultiTargetButton.Size = UDim2.new(0, 100, 0, 50)
MultiTargetButton.Position = UDim2.new(0.85, 0, 0.08, 0)
MultiTargetButton.Text = "Multi OFF"
MultiTargetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
MultiTargetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MultiTargetButton.Font = Enum.Font.SourceSans
MultiTargetButton.TextSize = 18

-- Nút FOV Slider
FOVSlider.Parent = ScreenGui
FOVSlider.Size = UDim2.new(0, 100, 0, 50)
FOVSlider.Position = UDim2.new(0.85, 0, 0.15, 0)
FOVSlider.Text = "FOV: 230"
FOVSlider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
FOVSlider.TextColor3 = Color3.fromRGB(0, 0, 0)
FOVSlider.Font = Enum.Font.SourceSans
FOVSlider.TextSize = 18

-- Nút Evade
EvadeButton.Parent = ScreenGui
EvadeButton.Size = UDim2.new(0, 100, 0, 50)
EvadeButton.Position = UDim2.new(0.85, 0, 0.22, 0)
EvadeButton.Text = "Evade OFF"
EvadeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
EvadeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EvadeButton.Font = Enum.Font.SourceSans
EvadeButton.TextSize = 18

-- Nút Debug
DebugButton.Parent = ScreenGui
DebugButton.Size = UDim2.new(0, 100, 0, 50)
DebugButton.Position = UDim2.new(0.85, 0, 0.29, 0)
DebugButton.Text = "Debug OFF"
DebugButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
DebugButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DebugButton.Font = Enum.Font.SourceSans
DebugButton.TextSize = 18

-- Nút Ghost
GhostButton.Parent = ScreenGui
GhostButton.Size = UDim2.new(0, 100, 0, 50)
GhostButton.Position = UDim2.new(0.85, 0, 0.36, 0)
GhostButton.Text = "Ghost OFF"
GhostButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
GhostButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GhostButton.Font = Enum.Font.SourceSans
GhostButton.TextSize = 18

-- Điều chỉnh FOV
FOVSlider.MouseButton1Click:Connect(function()
    Radius = Radius + 10
    if Radius > 500 then
        Radius = 100
    end
    FOVSlider.Text = "FOV: " .. Radius
end)

-- Bật/Tắt Evade
EvadeButton.MouseButton1Click:Connect(function()
    EvadeAssist = not EvadeAssist
    EvadeButton.Text = EvadeAssist and "Evade ON" or "Evade OFF"
    EvadeButton.BackgroundColor3 = EvadeAssist and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Bật/Tắt Debug
DebugButton.MouseButton1Click:Connect(function()
    DebugMode = not DebugMode
    DebugButton.Text = DebugMode and "Debug ON" or "Debug OFF"
    DebugButton.BackgroundColor3 = DebugMode and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Bật/Tắt Ghost
GhostButton.MouseButton1Click:Connect(function()
    GhostMode = not GhostMode
    GhostButton.Text = GhostMode and "Ghost ON" or "Ghost OFF"
    GhostButton.BackgroundColor3 = GhostMode and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Ghi lại hành vi người chơi
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        table.insert(PlayerActions, {Action = input.KeyCode, Time = tick()})
    end
end)

-- Học hành vi từ Ghost Mode
local function ReplayGhostActions()
    for _, action in ipairs(PlayerActions) do
        wait(action.Time - tick())
        UserInputService:SendKeyEvent(true, action.Action, false, nil)
    end
end

RunService.RenderStepped:Connect(function()
    if GhostMode then
        ReplayGhostActions()
    end
end)
