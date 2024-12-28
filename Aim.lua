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
local Radius = 200 -- Bán kính khóa mục tiêu (mặc định)
local BaseSmoothFactor = 0.15  -- Mức độ mượt khi camera theo dõi (cơ bản)
local MaxSmoothFactor = 0.5  -- Mức độ mượt tối đa
local CameraRotationSpeed = 0.3  -- Tốc độ xoay camera khi ghim mục tiêu
local TargetLockSpeed = 0.2 -- Tốc độ ghim mục tiêu
local TargetSwitchSpeed = 0.1 -- Tốc độ chuyển mục tiêu
local Locked = false
local CurrentTarget = nil
local AimActive = true -- Trạng thái aim (tự động bật/tắt)
local AutoAim = false -- Tự động kích hoạt khi có đối tượng trong bán kính
local TargetPrioritize = nil -- Mục tiêu ưu tiên

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút ⚙️ (Settings)
local MenuButton = Instance.new("TextButton") -- Nút Menu
local RadiusButton = Instance.new("TextButton") -- Nút chỉnh R
local AimCenterButton = Instance.new("TextButton") -- Nút chỉnh tâm Aim
local RadiusInput = Instance.new("TextBox") -- Input chỉnh R
local AimCenterInput = Instance.new("TextBox") -- Input chỉnh tâm Aim

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
ToggleButton.BorderRadius = UDim.new(0, 10) -- Round corners

-- Nút ⚙️ (Settings)
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "⚙️"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18
CloseButton.BorderRadius = UDim.new(0, 10) -- Round corners

-- Nút Menu
MenuButton.Parent = ScreenGui
MenuButton.Size = UDim2.new(0, 30, 0, 30)
MenuButton.Position = UDim2.new(0.74, 0, 0.01, 0)
MenuButton.Text = "📄"
MenuButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Font = Enum.Font.SourceSans
MenuButton.TextSize = 18
MenuButton.BorderRadius = UDim.new(0, 10) -- Round corners

-- Nút chỉnh R
RadiusButton.Parent = ScreenGui
RadiusButton.Size = UDim2.new(0, 30, 0, 30)
RadiusButton.Position = UDim2.new(0.64, 0, 0.01, 0)
RadiusButton.Text = "🌐"
RadiusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
RadiusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RadiusButton.Font = Enum.Font.SourceSans
RadiusButton.TextSize = 18
RadiusButton.BorderRadius = UDim.new(0, 10) -- Round corners

-- Nút chỉnh tâm Aim
AimCenterButton.Parent = ScreenGui
AimCenterButton.Size = UDim2.new(0, 30, 0, 30)
AimCenterButton.Position = UDim2.new(0.54, 0, 0.01, 0)
AimCenterButton.Text = "🎯"
AimCenterButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AimCenterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimCenterButton.Font = Enum.Font.SourceSans
AimCenterButton.TextSize = 18
AimCenterButton.BorderRadius = UDim.new(0, 10) -- Round corners

-- Input chỉnh R
RadiusInput.Parent = ScreenGui
RadiusInput.Size = UDim2.new(0, 100, 0, 30)
RadiusInput.Position = UDim2.new(0.64, 0, 0.07, 0) -- Đưa xuống một chút
RadiusInput.Text = "200"
RadiusInput.Visible = false
RadiusInput.BorderRadius = UDim.new(0, 10) -- Round corners

-- Input chỉnh tâm Aim
AimCenterInput.Parent = ScreenGui
AimCenterInput.Size = UDim2.new(0, 100, 0, 30)
AimCenterInput.Position = UDim2.new(0.54, 0, 0.07, 0) -- Đưa xuống một chút
AimCenterInput.Text = "1.0, 1.0, 1.0"
AimCenterInput.Visible = false
AimCenterInput.BorderRadius = UDim.new(0, 10) -- Round corners

-- Hàm bật/tắt Aim qua nút ⚙️
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
    local isVisible = RadiusButton.Visible
    RadiusButton.Visible = not isVisible
    AimCenterButton.Visible = not isVisible
    RadiusInput.Visible = not isVisible
    AimCenterInput.Visible = not isVisible
end)

-- Nút chỉnh R
RadiusButton.MouseButton1Click:Connect(function()
    RadiusInput.Visible = not RadiusInput.Visible
    if RadiusInput.Visible then
        RadiusInput.Text = tostring(Radius) -- Show current radius value
    end
end)

-- Nút chỉnh tâm Aim
AimCenterButton.MouseButton1Click:Connect(function()
    AimCenterInput.Visible = not AimCenterInput.Visible
    if AimCenterInput.Visible then
        AimCenterInput.Text = "1.0, 1.0, 1.0" -- Default Aim center
    end
end)

-- Cập nhật giá trị bán kính và tâm Aim
RadiusInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newRadius = tonumber(RadiusInput.Text)
        if newRadius and newRadius >= 100 and newRadius <= 1000 then
            Radius = newRadius
        end
        RadiusInput.Visible = false
    end
end)

AimCenterInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newCenter = AimCenterInput.Text:split(",")
        if #newCenter == 3 then
            local x, y, z = tonumber(newCenter[1]), tonumber(newCenter[2]), tonumber(newCenter[3])
            if x and y and z then
                -- Update the aim center values
                -- For now, just print the new values
                print("New Aim Center:", x, y, z)
            end
        end
        AimCenterInput.Visible = false
    end
end)

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius()
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                if distance <= Radius then
                    table.insert(targets, character)
                end
            end
        end
    end
    return targets
end

-- Hàm dự đoán vị trí mục tiêu
local function PredictTargetPosition(target, predictionTime)
    local targetVelocity = target.HumanoidRootPart.Velocity
    local predictedPosition = target.HumanoidRootPart.Position + targetVelocity * predictionTime
    return predictedPosition
end

-- Hàm cập nhật camera và aim
local function UpdateCamera()
    local enemies = FindEnemiesInRadius()
    if #enemies > 0 then
        local target = enemies[1] -- Chọn mục tiêu đầu tiên trong danh sách
        local predictedPosition = PredictTargetPosition(target, Prediction)
        
        -- Cập nhật camera theo vị trí mục tiêu
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
    end
end

-- Chạy hàm UpdateCamera mỗi frame
RunService.RenderStepped:Connect(function()
    if AimActive then
        UpdateCamera()
    end
end)
