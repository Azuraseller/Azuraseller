local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local aimEnabled = false
local target = nil
local radius = 250
local closeRange = 45
local customCamera = Instance.new("Camera", workspace) -- Camera 2

-- Tạo giao diện
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotGui"

-- Nút bật/tắt Aimbot (nút "+")
local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Text = "+"
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(1, -50, 0, 10) -- Di chuyển sang bên phải
toggleButton.BackgroundColor3 = Color3.new(1, 1, 1)

-- Nút chính "Aim"
local mainButton = Instance.new("TextButton", screenGui)
mainButton.Text = "Aimbot: OFF"
mainButton.Size = UDim2.new(0, 100, 0, 50)
mainButton.Position = UDim2.new(1, -120, 0, 60) -- Di chuyển sang bên phải dưới nút "+"
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

-- Chuyển trạng thái Aim
local function toggleAimbot()
    aimEnabled = not aimEnabled
    mainButton.Text = aimEnabled and "Aimbot: ON" or "Aimbot: OFF"
    mainButton.BackgroundColor3 = aimEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    if aimEnabled then
        -- Chuyển sang camera 2
        customCamera.CFrame = camera.CFrame
        workspace.CurrentCamera = customCamera
    else
        -- Chuyển lại camera gốc
        workspace.CurrentCamera = camera
        target = nil -- Xóa mục tiêu khi tắt Aim
    end
end

toggleButton.MouseButton1Click:Connect(function()
    mainButton.Visible = not mainButton.Visible
    if mainButton.Visible then
        toggleButton.Text = "-"
        scaleButton(mainButton, 1.5) -- Phóng to khi hiển thị nút Aim
    else
        scaleButton(mainButton, 0.5) -- Thu nhỏ khi ẩn nút Aim
        wait(0.3)
        toggleButton.Text = "+"
    end
end)

mainButton.MouseButton1Click:Connect(toggleAimbot)

-- Tìm mục tiêu trong bán kính
local function findTarget()
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

    return closestPlayer
end

-- Camera tự động theo dõi mục tiêu
game:GetService("RunService").RenderStepped:Connect(function()
    if aimEnabled then
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            target = findTarget()
        end

        if target then
            local targetPosition = target.Character.HumanoidRootPart.Position
            local cameraPosition = customCamera.CFrame.Position

            -- Mượt hóa chuyển động của camera
            local smoothFactor = 0.15
            local direction = (targetPosition - cameraPosition).unit
            local newCFrame = CFrame.new(cameraPosition, cameraPosition + direction)

            -- Giữ góc nhìn của người chơi tự nhiên
            customCamera.CFrame = newCFrame
        end
    end
end)
