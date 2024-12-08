local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local SecondaryCamRadius = 1.2 -- Bán kính giới hạn camera phụ
local SecondaryCamHeightOffset = Vector3.new(0, 5, 0) -- Offset chiều cao camera phụ (sau và trên nhân vật)
local SecondaryCamSpeed = 0.3 -- Tốc độ di chuyển camera phụ
local enemy = nil
local Locked = true

getgenv().Key = "c"

-- Tăng tốc độ ghim mục tiêu (LerpSpeed)
local LerpSpeed = 0.15 -- Giảm giá trị này để tăng tốc độ phản hồi camera

-- Giao diện GUI (Nút On/Off và Định vị mục tiêu)
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local LocateButton = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Enabled = true -- Bật GUI khi bắt đầu
local uiVisibilityTween = TweenService:Create(ScreenGui, TweenInfo.new(0.5), {Transparency = 0}) -- GUI hiện lên mượt mà

-- Nút On/Off
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.02, 0) -- Vị trí nút nâng lên cao hơn
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Thêm dấu X vào góc trái phía trên của nút
CloseButton.Parent = ToggleButton
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(0, 0, 0, 0) -- Vị trí dấu X
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 20

-- Nút định vị mục tiêu
LocateButton.Parent = ScreenGui
LocateButton.Size = UDim2.new(0, 100, 0, 50)
LocateButton.Position = UDim2.new(0.85, 0, 0.1, 0) -- Vị trí dưới ToggleButton
LocateButton.Text = "Locate Target"
LocateButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
LocateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LocateButton.Font = Enum.Font.SourceSans
LocateButton.TextSize = 20

-- Biến lưu trữ thời gian nhấn đúp
local lastClickTime = 0
local doubleClickInterval = 0.3 -- Khoảng thời gian cho phép nhấn đúp

-- Hàm bật/tắt trạng thái CamLock từ nút
ToggleButton.MouseButton1Click:Connect(function()
    Locked = not Locked
    if Locked then
        ToggleButton.Text = "CamLock: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        enemy = FindNearestEnemy()
        CamlockState = true
    else
        ToggleButton.Text = "CamLock: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        enemy = nil
        CamlockState = false
    end
end)

-- Xử lý dấu X để đóng/mở GUI
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    if currentTime - lastClickTime <= doubleClickInterval then
        -- Nhấn đúp vào dấu X, tắt GUI
        local hideTween = TweenService:Create(ScreenGui, TweenInfo.new(0.5), {Transparency = 1}) -- Ẩn GUI mượt mà
        hideTween:Play()
        hideTween.Completed:Connect(function()
            ScreenGui.Enabled = false
        end)
    else
        -- Nhấn một lần, bật GUI
        ScreenGui.Enabled = true
        uiVisibilityTween:Play()
    end
    lastClickTime = currentTime
end)

-- Nút định vị mục tiêu
LocateButton.MouseButton1Click:Connect(function()
    local target = FindNearestEnemy()
    if target then
        -- Di chuyển camera về vị trí mục tiêu (sử dụng một hiệu ứng mượt cho camera)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end)

-- Tìm đối thủ gần nhất trong phạm vi
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = Radius, nil
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= Radius then
                    if Distance < ClosestDistance then
                        ClosestPlayer = Character.HumanoidRootPart
                        ClosestDistance = Distance
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

-- Camera phụ (di chuyển trong phạm vi hình cầu)
function UpdateSecondaryCameraPosition(mainCamPos, targetPos)
    local direction = (mainCamPos - targetPos).Unit -- Hướng từ mục tiêu về camera chính
    local desiredPosition = targetPos + direction * SecondaryCamRadius + SecondaryCamHeightOffset -- Camera phụ phía trên và sau mục tiêu
    return desiredPosition
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        -- Vị trí mục tiêu và dự đoán
        local targetPosition = enemy.Position + enemy.Velocity * Prediction

        -- Cập nhật camera chính
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, LerpSpeed) -- Tăng tốc độ phản hồi camera chính

        -- Cập nhật camera phụ (theo trong hình cầu)
        local secondaryCamPosition = UpdateSecondaryCameraPosition(Camera.CFrame.Position, targetPosition)
        local secondaryCamCFrame = CFrame.new(secondaryCamPosition, targetPosition)
        Camera.CFrame = secondaryCamCFrame -- Di chuyển camera đến vị trí camera phụ
    end
end)

-- Tự động bật aimbot khi có đối thủ trong phạm vi
RunService.RenderStepped:Connect(function()
    if not CamlockState then
        local nearestEnemy = FindNearestEnemy()
        if nearestEnemy then
            CamlockState = true
            enemy = nearestEnemy
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)

-- Phím bật/tắt CamLock bằng phím tắt
Mouse.KeyDown:Connect(function(k)
    if k == getgenv().Key then
        Locked = not Locked
        if Locked then
            ToggleButton.Text = "CamLock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            enemy = FindNearestEnemy()
            CamlockState = true
        else
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            enemy = nil
            CamlockState = false
        end
    end
end)

-- Xử lý khi đối thủ ra khỏi phạm vi
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if Distance > Radius then
            enemy = nil
            CamlockState = false
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)
