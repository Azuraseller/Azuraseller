local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Cấu hình kỹ năng
local Skills = {
    Z = "HeatwaveCannon",
    X = "InfernalPincer",
    C = "ScorchingDownfall",
}

local Radius = 450 -- Bán kính tìm mục tiêu

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

-- Kết nối sự kiện nhấn phím từ UserInputService
UserInputService.InputBegan:Connect(OnInput)

-- Hỗ trợ cho điện thoại (chạm màn hình)
UserInputService.TouchTap:Connect(function(_, touches)
    -- Bạn có thể thêm GUI cho các nút ảo để người chơi chạm vào và sử dụng kỹ năng
end)

print("Auto Aim Script Loaded! Press Z, X, C to use skills with auto aim.")

-- Xử lý kỹ năng trên server
ReplicatedStorage:WaitForChild("HeatwaveCannon").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50 -- Khoảng cách 50 studs từ nhân vật
        -- Gọi hàm để bắn kỹ năng vào skillPosition
        print("Firing Heatwave Cannon towards:", skillPosition)
        -- Bạn có thể tạo hiệu ứng bắn kỹ năng ở đây
    end
end)

ReplicatedStorage:WaitForChild("InfernalPincer").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50
        print("Firing Infernal Pincer towards:", skillPosition)
        -- Tạo hiệu ứng cho Infernal Pincer ở đây
    end
end)

ReplicatedStorage:WaitForChild("ScorchingDownfall").OnServerEvent:Connect(function(player, direction)
    if direction then
        local startPosition = player.Character.HumanoidRootPart.Position
        local skillPosition = startPosition + direction * 50
        print("Firing Scorching Downfall towards:", skillPosition)
        -- Tạo hiệu ứng cho Scorching Downfall ở đây
    end
end)
