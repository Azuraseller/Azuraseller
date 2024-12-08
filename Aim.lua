local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local CamlockState = false
local Prediction = 0.1 -- Tăng dự đoán để theo kịp chuyển động của mục tiêu
local Radius = 200 -- Bán kính khóa mục tiêu
local SecondaryCamRadius = 1.2 -- Bán kính giới hạn camera phụ
local SecondaryCamHeightOffset = Vector3.new(0, 5, 0) -- Offset chiều cao camera phụ (sau và trên nhân vật)
local SecondaryCamSpeed = 0.2 -- Tăng tốc độ di chuyển camera phụ
local LerpSpeed = 0.3 -- Tăng tốc độ ghim mục tiêu
local enemy = nil
local Locked = true

getgenv().Key = "c"

-- Kiểm tra xem người chơi có đang sử dụng điện thoại không
if UserInputService.TouchEnabled then
    -- Tạo GUI cho nút On/Off và dấu X
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = LocalPlayer.PlayerGui
    local ToggleButton = Instance.new("Frame")
    ToggleButton.Size = UDim2.new(0, 100, 0, 100)  -- Nút vuông
    ToggleButton.Position = UDim2.new(1, -110, 0, 10)  -- Vị trí ở góc phải trên màn hình
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Màu đỏ khi tắt
    ToggleButton.Parent = ScreenGui

    -- Tạo chữ "Cam Lock Off"
    local ToggleText = Instance.new("TextLabel")
    ToggleText.Size = UDim2.new(1, 0, 1, 0)
    ToggleText.Text = "Cam Lock Off"
    ToggleText.TextSize = 18
    ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleText.BackgroundTransparency = 1
    ToggleText.Parent = ToggleButton

    -- Tạo dấu "X" để đóng GUI
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(0, 0, 0, 0)  -- Vị trí dấu "X" ở góc trái trên
    CloseButton.Text = "X"
    CloseButton.TextSize = 24
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    CloseButton.BackgroundTransparency = 0.5
    CloseButton.Parent = ToggleButton

    -- Đóng GUI khi nhấn vào dấu "X"
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Tạo biến để kiểm tra nhấn đúp
    local lastClickTime = 0
    local doubleClickThreshold = 0.5 -- Thời gian để xem như nhấn đúp (giây)

    -- Tính năng bật/tắt CamLock khi nhấn vào nút
    ToggleButton.MouseButton1Click:Connect(function()
        local currentTime = tick()
        if currentTime - lastClickTime <= doubleClickThreshold then
            -- Nhấn đúp để bật lại GUI
            ScreenGui.Parent = LocalPlayer.PlayerGui
            lastClickTime = 0
        else
            lastClickTime = currentTime
        end

        -- Bật/tắt cam lock khi nhấn vào nút
        Locked = not Locked
        if Locked then
            enemy = FindNearestEnemy()
            CamlockState = true
            ToggleText.Text = "Cam Lock On"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- Màu xanh khi bật
        else
            enemy = nil
            CamlockState = false
            ToggleText.Text = "Cam Lock Off"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Màu đỏ khi tắt
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

    -- Tự động bật CamLock khi có đối thủ trong phạm vi
    RunService.RenderStepped:Connect(function()
        if not CamlockState then
            local nearestEnemy = FindNearestEnemy()
            if nearestEnemy then
                CamlockState = true
                enemy = nearestEnemy
            end
        end

        -- Xử lý khi đối thủ ra khỏi phạm vi
        if CamlockState and enemy then
            local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if Distance > Radius then
                enemy = nil
                CamlockState = false
                ToggleText.Text = "Cam Lock Off"
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- Màu đỏ khi tắt
            end
        end
    end)
end
