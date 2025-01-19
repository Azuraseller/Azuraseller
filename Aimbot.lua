local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Cấu hình kỹ năng
local Skills = {
    Z = "Heatwave Cannon",
    X = "Infernal Pincer",
    C = "Scorching Downfall",
}

local Radius = 450 -- Bán kính tìm mục tiêu
local AimActive = true -- Trạng thái Aim (Bật/Tắt)

-- GUI - Nút ON/OFF
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0.85, 0, 0.01, 0)
ToggleButton.Text = "ON" -- Văn bản mặc định
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu nền khi bật
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu chữ
ToggleButton.Font = Enum.Font.SourceSans
ToggleButton.TextSize = 18

-- Tìm mục tiêu gần nhất trong phạm vi
local function FindClosestTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance < closestDistance and distance <= Radius then
                closestDistance = distance
                closestTarget = player.Character
            end
        end
    end
    return closestTarget
end

-- Tính toán hướng kỹ năng từ nhân vật đến mục tiêu
local function GetSkillDirection(target)
    if target and target:FindFirstChild("HumanoidRootPart") then
        local targetPosition = target.HumanoidRootPart.Position
        local startPosition = LocalPlayer.Character.HumanoidRootPart.Position
        return (targetPosition - startPosition).Unit -- Hướng từ nhân vật đến mục tiêu
    end
    return nil -- Không có mục tiêu
end

-- Hàm sử dụng kỹ năng
local function UseSkill(skillKey)
    if not AimActive then return end  -- Kiểm tra trạng thái Aim
    local target = FindClosestTarget()
    local direction

    if target then
        direction = GetSkillDirection(target)  -- Bắn vào mục tiêu
    else
        -- Nếu không có mục tiêu, bắn theo hướng mặc định (theo hướng của nhân vật)
        direction = Camera.CFrame.LookVector
    end

    -- Gửi thông tin kỹ năng đến server với hướng đã tính toán
    local skillEvent = Skills[skillKey]
    if skillEvent then
        ReplicatedStorage:WaitForChild(skillEvent):FireServer(direction)
    else
        warn("Skill event not found for key:", skillKey)
    end
end

-- Xử lý input từ người dùng
local function OnInput(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode.Name -- Lấy tên phím nhấn
    if Skills[key] then
        UseSkill(key)
    end
end

-- Xử lý sự kiện chạm màn hình (dành cho điện thoại)
local function OnTouchTap(_, touches)
    if not AimActive then return end  -- Kiểm tra trạng thái Aim

    -- Lấy vị trí chạm trên màn hình và tính toán mục tiêu
    local target = FindClosestTarget()
    if target then
        local direction = GetSkillDirection(target)  -- Bắn vào mục tiêu
        -- Gửi thông tin kỹ năng đến server
        ReplicatedStorage:WaitForChild("Heatwave Cannon"):FireServer(direction)
    end
end

-- Kết nối sự kiện nhấn phím từ UserInputService
UserInputService.InputBegan:Connect(OnInput)

-- Kết nối sự kiện chạm màn hình cho điện thoại
UserInputService.TouchTap:Connect(OnTouchTap)

-- Xử lý sự kiện nhấn nút ON/OFF
ToggleButton.MouseButton1Click:Connect(function()
    AimActive = not AimActive
    if AimActive then
        ToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

print("Auto Aim Script Loaded! Press Z, X, C to use skills with auto aim.")

-- Xử lý kỹ năng trên server
ReplicatedStorage:WaitForChild("Heatwave Cannon").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50 -- Khoảng cách 50 studs từ nhân vật
        -- Gọi hàm để bắn kỹ năng vào skillPosition
        print("Firing Heatwave Cannon towards:", skillPosition)
        -- Tạo hiệu ứng cho Heatwave Cannon ở đây
    end
end)

ReplicatedStorage:WaitForChild("Infernal Pincer").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50
        print("Firing Infernal Pincer towards:", skillPosition)
        -- Tạo hiệu ứng cho Infernal Pincer ở đây
    end
end)

ReplicatedStorage:WaitForChild("Scorching Downfall").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50
        print("Firing Scorching Downfall towards:", skillPosition)
        -- Tạo hiệu ứng cho Scorching Downfall ở đây
    end
end)
