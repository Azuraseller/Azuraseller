local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Tạo Camera phụ
local Camera2 = Instance.new("Camera")
Camera2.Parent = workspace

-- Cấu hình các tham số
local Prediction = 0.1
local Radius = 230
local BaseSmoothFactor = 0.15
local MaxSmoothFactor = 0.5
local TargetLockSpeed = 0.2
local Locked = false
local CurrentTarget = nil
local AimActive = true
local AimState = true -- Lưu trạng thái Aim

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local SettingsButton = Instance.new("TextButton")
local RangeButton = Instance.new("TextButton")
local RangeAdjustBox = Instance.new("TextBox")

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
ToggleButton.BorderSizePixel = 0
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.TextScaled = true

-- Nút ⚙️ (Settings)
SettingsButton.Parent = ScreenGui
SettingsButton.Size = UDim2.new(0, 50, 0, 50)
SettingsButton.Position = UDim2.new(0.79, 0, 0.01, 0)
SettingsButton.Text = "⚙️"
SettingsButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Font = Enum.Font.SourceSans
SettingsButton.TextSize = 18
SettingsButton.BorderSizePixel = 0
SettingsButton.BackgroundTransparency = 0.5
SettingsButton.TextScaled = true

-- Nút 🌐 (Adjust Range)
RangeButton.Parent = ScreenGui
RangeButton.Size = UDim2.new(0, 50, 0, 50)
RangeButton.Position = UDim2.new(0.74, 0, 0.01, 0)
RangeButton.Text = "🌐"
RangeButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
RangeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeButton.Font = Enum.Font.SourceSans
RangeButton.TextSize = 18
RangeButton.BorderSizePixel = 0
RangeButton.BackgroundTransparency = 0.5
RangeButton.TextScaled = true

-- TextBox Điều chỉnh R
RangeAdjustBox.Parent = ScreenGui
RangeAdjustBox.Size = UDim2.new(0, 200, 0, 50)
RangeAdjustBox.Position = UDim2.new(0.72, 0, 0.08, 0)
RangeAdjustBox.Text = "[ R: " .. tostring(Radius) .. " ]"
RangeAdjustBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RangeAdjustBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeAdjustBox.Font = Enum.Font.SourceSans
RangeAdjustBox.TextSize = 18
RangeAdjustBox.BorderSizePixel = 0
RangeAdjustBox.Visible = false
RangeAdjustBox.TextScaled = true

-- Hàm dự đoán vị trí phía trước mục tiêu
local function PredictFuturePosition(target)
    local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
    local cameraDirection = humanoidRootPart and humanoidRootPart.CFrame.LookVector
    if humanoidRootPart and cameraDirection then
        local velocity = humanoidRootPart.Velocity
        local predictedPosition = humanoidRootPart.Position + cameraDirection * 3 + velocity * Prediction
        return predictedPosition
    end
    return humanoidRootPart.Position
end

-- Hàm điều chỉnh camera
local function AdjustCameraPosition(targetPosition)
    local ray = Ray.new(Camera.CFrame.Position, targetPosition - Camera.CFrame.Position)
    local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hitPart then
        return Camera.CFrame.Position + (targetPosition - Camera.CFrame.Position).Unit * 5
    end
    return targetPosition
end

-- Tính toán SmoothFactor
local function CalculateSmoothFactor(target)
    local velocityMagnitude = target.HumanoidRootPart.Velocity.Magnitude
    local smoothFactor = BaseSmoothFactor + (velocityMagnitude / 100)
    return math.clamp(smoothFactor, BaseSmoothFactor, MaxSmoothFactor)
end

-- Luân phiên điều chỉnh Camera và Aim
local function AdjustAimAndCamera()
    if CurrentTarget and Locked then
        local targetCharacter = CurrentTarget
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local targetPosition = PredictFuturePosition(targetCharacter)

            -- Điều chỉnh vị trí camera
            targetPosition = AdjustCameraPosition(targetPosition)

            -- Tính toán SmoothFactor
            local SmoothFactor = CalculateSmoothFactor(targetCharacter)

            -- Sử dụng SmoothFactor để điều chỉnh tốc độ ghim
            local TargetPositionSmooth = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), SmoothFactor)

            -- Cập nhật camera chính (Camera 1)
            Camera.CFrame = TargetPositionSmooth

            -- Cập nhật camera phụ (Camera 2)
            Camera2.CFrame = TargetPositionSmooth
        end
    end
end

-- Kết nối RenderStepped
RunService.RenderStepped:Connect(function()
    if AimActive then
        AdjustAimAndCamera()
    end
end)

-- Bật/Tắt Aim
ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    ToggleButton.Text = AimActive and "ON" or "OFF"
    ToggleButton.BackgroundColor3 = AimActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    Locked = false
    CurrentTarget = nil
end)

-- Mở/Đóng cài đặt
SettingsButton.MouseButton1Click:Connect(function()
    local visible = not RangeButton.Visible
    RangeButton.Visible = visible
    RangeAdjustBox.Visible = visible
    ToggleButton.Visible = not visible
end)

-- Điều chỉnh R
RangeButton.MouseButton1Click:Connect(function()
    RangeAdjustBox.Visible = not RangeAdjustBox.Visible
end)

RangeAdjustBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newRadius = tonumber(RangeAdjustBox.Text:match("%d+"))
        if newRadius then
            Radius = math.clamp(newRadius, 50, 500)
            RangeAdjustBox.Text = "[ R: " .. tostring(Radius) .. " ]"
        end
    end
end)
