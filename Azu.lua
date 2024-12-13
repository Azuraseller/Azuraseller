local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local aimEnabled = false
local target = nil
local radius = 250
local closeRange = 45
local customCamera = Instance.new("Camera", workspace) -- Tạo camera 2

-- Tạo giao diện
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AimbotGui"

-- Nút bật/tắt Aimbot (nút "+")
local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Text = "+"
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(1, -50, 0, 10) -- Vị trí bên phải
toggleButton.BackgroundColor3 = Color3.new(1, 1, 1)

-- Nút chính "Aim"
local mainButton = Instance.new("TextButton", screenGui)
mainButton.Text = "Aimbot: OFF"
mainButton.Size = UDim2.new(0, 100, 0, 50)
mainButton.Position = UDim2.new(1, -120, 0, 60) -- Vị trí bên phải dưới nút "+"
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

-- Tự động bật/tắt Aim dựa trên khoảng cách
local function autoToggleAimbot()
    target = findTarget()
    if target then
        if not aimEnabled then
            aimEnabled = true
            mainButton.Text = "Aimbot: ON"
            mainButton.BackgroundColor3 = Color3.new(0, 1, 0)
            customCamera.CFrame = camera.CFrame -- Đồng bộ camera 2 với camera gốc
            workspace.CurrentCamera = customCamera
        end
    else
        if aimEnabled then
            aimEnabled = false
            mainButton.Text = "Aimbot: OFF"
            mainButton.BackgroundColor3 = Color3.new(1, 0, 0)
            workspace.CurrentCamera = camera -- Trả về camera gốc
        end
    end
end

-- Camera 2 hoạt động độc lập
local function updateCustomCamera()
    if aimEnabled and target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = target.Character.HumanoidRootPart.Position
        local cameraPosition = customCamera.CFrame.Position

        -- Mượt hóa chuyển động của camera
        local smoothFactor = 0.15
        local direction = (targetPosition - cameraPosition).unit
        local newCFrame = CFrame.new(cameraPosition, cameraPosition + direction)

        customCamera.CFrame = newCFrame
    else
        -- Giữ camera 2 không bị ảnh hưởng khi không có mục tiêu
        customCamera.CFrame = camera.CFrame
    end
end

-- Sự kiện bấm nút "+"
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

-- Vòng lặp kiểm tra và cập nhật Aim
game:GetService("RunService").RenderStepped:Connect(function()
    autoToggleAimbot() -- Tự động bật/tắt Aim
    updateCustomCamera() -- Cập nhật camera 2
end)
