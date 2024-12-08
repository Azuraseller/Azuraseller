local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Cấu hình các tham số
local CamlockState = false
local Prediction = 0.15 -- Dự đoán vị trí di chuyển của mục tiêu
local Radius = 200 -- Bán kính khóa mục tiêu
local CameraSpeed = 0.4 -- Tăng tốc độ phản hồi camera
local SmoothFactor = 0.2 -- Độ mượt khi theo dõi mục tiêu (giảm để nhanh hơn)
local Locked = false
local CurrentTarget = nil -- Mục tiêu hiện tại

getgenv().Key = "c"

-- Giao diện GUI
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton") -- Nút X

ScreenGui.Parent = game:GetService("CoreGui")

-- Nút ON/OFF
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút X
CloseButton.Parent = ScreenGui
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.01, 0)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Biến trạng thái
local ToggleVisible = true
local AimActive = true -- Trạng thái Aim (Kích hoạt hoặc tắt Aim)

-- Hàm bật/tắt trạng thái CamLock từ nút
local function ToggleCamlock()
    if AimActive then
        Locked = not Locked
        if Locked then
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            CamlockState = true
        else
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            CamlockState = false
        end
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleCamlock)

-- Nút X để bật/tắt Aim và ẩn/hiện nút ON/OFF
CloseButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        CamlockState = true
        ToggleButton.Visible = true
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        CamlockState = false
        ToggleButton.Visible = false
        CurrentTarget = nil
    end
end)

-- Tìm tất cả đối thủ trong phạm vi
local function FindEnemiesInRadius()
    local targets = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    table.insert(targets, Character.HumanoidRootPart)
                end
            end
        end
    end
    return targets
end

-- Chuyển đổi góc nhìn camera mượt mà
local function SmoothAim(targetPosition)
    local direction = (targetPosition - Camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, SmoothFactor)
end

-- Cập nhật camera theo mục tiêu
RunService.RenderStepped:Connect(function()
    if CurrentTarget then
        local targetPart = CurrentTarget
        if targetPart and targetPart.Parent and targetPart.Parent:FindFirstChild("Humanoid") then
            local targetPosition = targetPart.Position + (targetPart.Velocity * Prediction)

            -- Kiểm tra khoảng cách và mục tiêu có còn hợp lệ
            local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance > Radius or targetPart.Parent.Humanoid.Health <= 0 then
                CurrentTarget = nil -- Hủy ghim nếu mục tiêu không còn hợp lệ
                return
            end

            -- Chỉnh Camera chính xác vào mục tiêu
            SmoothAim(targetPosition)
        else
            CurrentTarget = nil -- Hủy ghim nếu mục tiêu không còn tồn tại
        end
    else
        -- Tìm mục tiêu mới trong phạm vi
        local enemies = FindEnemiesInRadius()
        if #enemies > 0 then
            CurrentTarget = enemies[1] -- Lựa chọn mục tiêu đầu tiên
        end
    end
end)
