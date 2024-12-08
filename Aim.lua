-- Dịch vụ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Biến
local CamlockState = false
local Prediction = 0.2
local Radius = 50
local SecondaryCamRadius = 1.5
local SecondaryCamHeightOffset = Vector3.new(0, 5, 0)
local SecondaryCamSpeed = 0.5
local LerpSpeed = 0.5
local enemy = nil
local Locked = true
getgenv().Key = "c"

-- Giao diện Noel
local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
local ToggleButton = Instance.new("TextButton", ScreenGui)
local CloseButton = Instance.new("TextButton", ScreenGui)

-- Cài đặt giao diện nút On/Off
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 120, 0, 60)
ToggleButton.Position = UDim2.new(0.85, 0, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ Noel khi tắt
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Chữ màu trắng
ToggleButton.Text = "OFF"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16

-- Thêm viền và bo góc cho nút On/Off
local UIStroke = Instance.new("UIStroke", ToggleButton)
UIStroke.Color = Color3.fromRGB(0, 255, 0) -- Viền xanh Noel khi tắt
UIStroke.Thickness = 3

local UICorner = Instance.new("UICorner", ToggleButton)
UICorner.CornerRadius = UDim.new(0, 10)

-- Hình ảnh Noel cho nút On/Off
local Image = Instance.new("ImageLabel", ToggleButton)
Image.Size = UDim2.new(0.4, 0, 0.4, 0)
Image.Position = UDim2.new(0.3, 0, 0.3, 0)
Image.BackgroundTransparency = 1
Image.Image = "rbxassetid://1234567890" -- ID hình ảnh Noel khi tắt (ví dụ: cây thông)

-- Nút "Dấu X" (nút tắt)
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(0.9, 0, 0.05, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14

-- Bo góc cho nút Close
local CloseUICorner = Instance.new("UICorner", CloseButton)
CloseUICorner.CornerRadius = UDim.new(0, 5)

-- Trạng thái nút On/Off
local isOn = false
local doubleClickTime = 0.3 -- Thời gian cho phép bấm đúp
local lastClickTime = 0 -- Thời gian lần click cuối cùng

-- Chức năng nút On/Off
ToggleButton.MouseButton1Click:Connect(function()
    isOn = not isOn
    if isOn then
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh Noel khi bật
        UIStroke.Color = Color3.fromRGB(255, 0, 0) -- Viền đỏ
        Image.Image = "rbxassetid://2345678901" -- Hình ảnh khi bật
        CamlockState = true -- Kích hoạt Camlock
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ Noel khi tắt
        UIStroke.Color = Color3.fromRGB(0, 255, 0) -- Viền xanh
        Image.Image = "rbxassetid://1234567890" -- Hình ảnh khi tắt
        CamlockState = false -- Tắt Camlock
    end
end)

-- Chức năng nút "Dấu X" để ẩn giao diện On/Off
CloseButton.MouseButton1Click:Connect(function()
    local currentTime = tick() -- Thời gian hiện tại
    if currentTime - lastClickTime < doubleClickTime then
        -- Nếu bấm đúp thì mở lại giao diện
        ToggleButton.Visible = not ToggleButton.Visible
        CloseButton.Text = ToggleButton.Visible and "X" or "O" -- Chuyển nút sang "O" để mở lại
    else
        -- Cập nhật thời gian click
        lastClickTime = currentTime
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

-- Camera phụ
function UpdateSecondaryCameraPosition(mainCamPos, targetPos)
    local direction = (mainCamPos - targetPos).Unit
    local desiredPosition = targetPos + direction * SecondaryCamRadius + SecondaryCamHeightOffset
    return desiredPosition
end

-- Cập nhật camera
RunService.RenderStepped:Connect(function()
    if CamlockState and enemy then
        local targetPosition = enemy.Position + enemy.Velocity * Prediction

        -- Camera chính
        local newCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, LerpSpeed)

        -- Camera phụ
        local secondaryCamPosition = UpdateSecondaryCameraPosition(Camera.CFrame.Position, targetPosition)
        local secondaryCamCFrame = CFrame.new(secondaryCamPosition, targetPosition)
    end
end)

-- Tự động tìm đối thủ
RunService.RenderStepped:Connect(function()
    if not enemy and CamlockState then
        enemy = FindNearestEnemy()
    end
end)

-- Xử lý khi đối thủ rời phạm vi
RunService.RenderStepped:Connect(function()
    if enemy and CamlockState then
        local Distance = (enemy.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if Distance > Radius then
            enemy = nil
            CamlockState = false
        end
    end
end)
