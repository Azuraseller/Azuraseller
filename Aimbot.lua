local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

local CamlockState = false
local Prediction = 0.16
local Radius = 200 -- Bán kính khóa mục tiêu
local SecondaryCamRadius = 1.2 -- Bán kính giới hạn camera phụ
local SecondaryCamHeightOffset = Vector3.new(0, 4, 0) -- Offset chiều cao camera phụ (sau và trên nhân vật)
local SecondaryCamSpeed = 0.2 -- Tốc độ di chuyển camera phụ
local enemy = nil
local Locked = true

getgenv().Key = "c"

-- Giao diện GUI (Nút On/Off và nút X để tắt GUI)
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")  -- Nút X để tắt GUI

ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "CamLockGUI"
ToggleButton.Parent = ScreenGui
CloseButton.Parent = ScreenGui

ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.02, 0) -- Vị trí nút nâng lên cao hơn
ToggleButton.Text = "CamLock: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 20

-- Nút X để tắt GUI (được di chuyển sang trái của nút On/Off)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.79, 0, 0.02, 0) -- Vị trí nút X di chuyển sang trái của nút On/Off
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 18

-- Biến để xử lý nhấn đúp nút X
local lastClickTime = 0
local doubleClickThreshold = 0.5 -- Thời gian giữa 2 lần nhấn để xem như nhấn đúp (0.5 giây)

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

-- Hàm để ẩn/hiện GUI khi nhấn vào nút X
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    
    -- Kiểm tra xem lần nhấn có xảy ra trong khoảng thời gian của nhấn đúp không
    if currentTime - lastClickTime < doubleClickThreshold then
        -- Nếu đúng, ẩn GUI
        ScreenGui.Visible = false
    else
        -- Nếu không phải nhấn đúp, hiển thị GUI lại
        ScreenGui.Visible = true
    end
    
    lastClickTime = currentTime
end)

-- Kiểm tra đồng đội (Ally) và tìm đối thủ gần nhất trong phạm vi
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = Radius, nil
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and not Player.Team == LocalPlayer.Team then  -- Kiểm tra nếu người chơi không phải là đồng đội
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

-- Tạo ESP cho tên mục tiêu
function CreateESPForTarget(target)
    if target then
        -- Kiểm tra nếu BillboardGui đã tồn tại thì không tạo lại
        if target:FindFirstChild("ESP") then
            return
        end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESP"
        billboardGui.Parent = target:FindFirstChild("Head")
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.Adornee = target:FindFirstChild("Head")
        billboardGui.StudsOffset = Vector3.new(0, 2, 0)  -- Đặt nó trên đầu của nhân vật
        billboardGui.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboardGui
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = target.Parent.Name  -- Hiển thị tên của người chơi
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextSize = 14
        textLabel.TextAlign = Enum.TextAnchor.MiddleCenter
    end
end

-- Cập nhật camera mượt mà hơn, nhanh hơn khi mục tiêu thay đổi vị trí
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        -- Vị trí mục tiêu và dự đoán
        local targetPosition = enemy.Position + enemy.Velocity * Prediction
        local targetVelocity = enemy.Velocity.Magnitude

        -- Điều chỉnh tốc độ ghim mục tiêu khi đối thủ di chuyển nhanh
        local cameraSpeed = targetVelocity > 50 and 0.05 or 0.2  -- Tăng tốc khi đối thủ di chuyển nhanh

        -- Cập nhật camera chính mượt mà hơn, nhanh hơn khi mục tiêu di chuyển nhanh
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, cameraSpeed)  -- Dùng Lerp để mượt mà hơn

        -- Cập nhật camera phụ (theo trong hình cầu)
        local secondaryCamPosition = UpdateSecondaryCameraPosition(Camera.CFrame.Position, targetPosition)
        local secondaryCamCFrame = CFrame.new(secondaryCamPosition, targetPosition)

        -- Tạo ESP cho tên mục tiêu nếu chưa có
        CreateESPForTarget(enemy.Parent)
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

-- Xử lý khi đối thủ ra khỏi phạm vi hoặc chết
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

        -- Kiểm tra nếu đối thủ chết hoặc ra ngoài phạm vi
        if Distance > Radius or enemy.Parent == nil or enemy.Parent:FindFirstChild("Humanoid") == nil or enemy.Parent.Humanoid.Health <= 0 then
            enemy = nil
            CamlockState = false
            ToggleButton.Text = "CamLock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)
