local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local DetectionRadius = 600 -- Bán kính phát hiện mục tiêu
local HitboxRadius = 50 -- Bán kính hitbox
local HitboxColorNormal = Color3.fromRGB(255, 255, 255) -- Màu trắng
local HitboxColorDamaged = Color3.fromRGB(255, 0, 0) -- Màu đỏ

-- Hàm tính khoảng cách giữa hai điểm
local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Hàm tạo hitbox dạng hình cầu
local function CreateHitbox(target)
    if target:FindFirstChild("HumanoidRootPart") and not target:FindFirstChild("HitboxAdornment") then
        local humanoidRootPart = target.HumanoidRootPart

        -- Tạo SphereHandleAdornment cho hitbox
        local hitbox = Instance.new("SphereHandleAdornment")
        hitbox.Name = "HitboxAdornment"
        hitbox.Adornee = humanoidRootPart
        hitbox.Radius = HitboxRadius
        hitbox.Color3 = HitboxColorNormal
        hitbox.AlwaysOnTop = true
        hitbox.ZIndex = 5
        hitbox.Parent = humanoidRootPart
    end
end

-- Hàm cập nhật màu hitbox khi bị sát thương
local function UpdateHitboxColor(target)
    local humanoid = target:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function()
            local hitbox = target.HumanoidRootPart:FindFirstChild("HitboxAdornment")
            if hitbox then
                hitbox.Color3 = HitboxColorDamaged
                task.wait(0.2) -- Thời gian chuyển lại màu trắng
                hitbox.Color3 = HitboxColorNormal
            end
        end)
    end
end

-- Hàm tạo ESP (hiển thị tên và thanh máu)
local function CreateESP(target)
    if not target:FindFirstChild("HumanoidRootPart") then return end
    if target:FindFirstChild("ESPBillboard") then return end

    local humanoidRootPart = target.HumanoidRootPart
    local humanoid = target:FindFirstChild("Humanoid")

    -- Tạo BillboardGui cho ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(4, 0, 2, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = humanoidRootPart

    -- Tạo thanh máu
    local healthBarBackground = Instance.new("Frame")
    healthBarBackground.Size = UDim2.new(1, 0, 0.2, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.8, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Parent = billboard

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh lá mặc định
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground

    -- Tạo nhãn tên
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = target.Name
    nameLabel.Parent = billboard

    -- Cập nhật thanh máu và màu sắc
    humanoid.HealthChanged:Connect(function()
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)

        -- Đổi màu theo lượng máu
        if healthPercent > 0.5 then
            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá
        elseif healthPercent > 0.2 then
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Vàng
        else
            healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
        end
    end)
end

-- Theo dõi mục tiêu trong phạm vi và áp dụng hitbox, ESP
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local character = player.Character
            local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, character.HumanoidRootPart.Position)

            if distance <= DetectionRadius then
                -- Tạo hitbox và ESP
                CreateHitbox(character)
                UpdateHitboxColor(character)
                CreateESP(character)
            else
                -- Xóa hitbox và ESP nếu ngoài phạm vi
                if character:FindFirstChild("HumanoidRootPart") then
                    if character.HumanoidRootPart:FindFirstChild("HitboxAdornment") then
                        character.HumanoidRootPart.HitboxAdornment:Destroy()
                    end
                    if character.HumanoidRootPart:FindFirstChild("ESPBillboard") then
                        character.HumanoidRootPart.ESPBillboard:Destroy()
                    end
                end
            end
        end
    end
end)
