local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local aimEnabled = false
local target = nil
local radius = 250
local closeRange = 45

-- Tạo giao diện
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotGui"

-- Nút "+" (dùng để mở rộng giao diện)
local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Text = "+"
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.new(1, 1, 1)
toggleButton.Visible = true

-- Nút Aimbot (chính)
local mainButton = Instance.new("TextButton", screenGui)
mainButton.Text = "Aimbot: OFF"
mainButton.Size = UDim2.new(0, 100, 0, 50)
mainButton.Position = UDim2.new(0, 10, 0, 60)
mainButton.BackgroundColor3 = Color3.new(1, 0, 0)
mainButton.Visible = false

-- Hiệu ứng thu nhỏ/phóng to
local TweenService = game:GetService("TweenService")

local function scaleButton(button, scale)
    local goal = {Size = button.Size * scale}
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(button, tweenInfo, goal)
    tween:Play()
end

-- Sự kiện bấm nút "+"
toggleButton.MouseButton1Click:Connect(function()
    mainButton.Visible = not mainButton.Visible
    if mainButton.Visible then
        toggleButton.Text = "-"
        scaleButton(mainButton, 1.5) -- Phóng to
    else
        scaleButton(mainButton, 0.5) -- Thu nhỏ
        wait(0.3)
        toggleButton.Text = "+"
    end
end)

-- Sự kiện bấm nút Aimbot
mainButton.MouseButton1Click:Connect(function()
    aimEnabled = not aimEnabled
    mainButton.Text = aimEnabled and "Aimbot: ON" or "Aimbot: OFF"
    mainButton.BackgroundColor3 = aimEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
end)

-- Tìm mục tiêu trong bán kính
local function findTarget()
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (player.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
        if distance > radius or not target.Character:FindFirstChild("Humanoid") or target.Character.Humanoid.Health <= 0 then
            target = nil
        end
    end

    if not target then
        local closestPlayer = nil
        local closestDistance = radius

        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - otherPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance and distance > closeRange then
                    closestDistance = distance
                    closestPlayer = otherPlayer
                end
            end
        end

        target = closestPlayer
    end

    return target
end

-- Camera theo dõi mục tiêu
game:GetService("RunService").RenderStepped:Connect(function()
    if aimEnabled then
        target = findTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = target.Character.HumanoidRootPart.Position
            local direction = (targetPosition - camera.CFrame.Position).unit
            camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + direction)
        else
            target = nil
        end
    end
end)
