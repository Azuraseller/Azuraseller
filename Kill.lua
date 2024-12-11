-- Khai báo các biến cần thiết
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local KillAuraButton = Instance.new("TextButton")
KillAuraButton.Parent = ScreenGui
KillAuraButton.Size = UDim2.new(0, 100, 0, 50)
KillAuraButton.Position = UDim2.new(1, -110, 0, 10) -- Góc phải phía trên
KillAuraButton.Text = "Kill Aura: OFF"
KillAuraButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ khi tắt
KillAuraButton.TextColor3 = Color3.fromRGB(255, 255, 255)
KillAuraButton.Font = Enum.Font.SourceSans
KillAuraButton.TextSize = 18

local UICorner = Instance.new("UICorner")
UICorner.Parent = KillAuraButton
UICorner.CornerRadius = UDim.new(0.2, 0)

-- Biến trạng thái
local killAuraEnabled = false

-- Bán kính tấn công
local attackRadius = 400

-- Kiểm tra khoảng cách giữa hai vector
local function isWithinRadius(position1, position2, radius)
    return (position1 - position2).Magnitude <= radius
end

-- Thực hiện tấn công
local function attack(targetPlayer)
    -- Bỏ qua nếu không có nhân vật hoặc humanoid
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Humanoid") then
        return
    end

    -- Tấn công humanoid
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid:TakeDamage(10) -- Gây 10 sát thương
    end
end

-- Kích hoạt Kill Aura
RunService.RenderStepped:Connect(function()
    if not killAuraEnabled then return end -- Chỉ chạy khi bật Kill Aura

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local localPosition = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = player.Character.HumanoidRootPart.Position

            -- Kiểm tra khoảng cách và tấn công nếu trong bán kính
            if isWithinRadius(localPosition, targetPosition, attackRadius) then
                attack(player)
            end
        end
    end
end)

-- Xử lý nút On/Off
KillAuraButton.MouseButton1Click:Connect(function()
    killAuraEnabled = not killAuraEnabled

    if killAuraEnabled then
        KillAuraButton.Text = "Kill Aura: ON"
        KillAuraButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh lá khi bật
    else
        KillAuraButton.Text = "Kill Aura: OFF"
        KillAuraButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ khi tắt
    end
end)
