-- Đặt script này vào ServerScriptService hoặc Workspace

-- Lấy Lighting service
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Xóa các hiệu ứng cũ nếu có
for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        effect:Destroy()
    end
end

-- Cấu hình ánh sáng cơ bản
Lighting.Technology = Enum.Technology.Future -- Công nghệ ánh sáng Future
Lighting.GlobalShadows = true -- Bật bóng đổ toàn cục
Lighting.ShadowSoftness = 0.2 -- Độ mềm của bóng

-- Hiệu ứng ngày và đêm
local function configureDayNightCycle()
    local isDay = true -- Ban đầu là ban ngày
    local dayBrightness = 1.4 -- Độ sáng ban ngày
    local nightBrightness = 0.7 -- Độ sáng ban đêm

    -- Thay đổi ánh sáng theo chu kỳ
    RunService.Stepped:Connect(function()
        local currentTime = Lighting.ClockTime

        -- Chuyển đổi giữa ngày và đêm
        if currentTime >= 6 and currentTime <= 18 then
            isDay = true
            Lighting.Brightness = dayBrightness
            Lighting.Ambient = Color3.fromRGB(150, 150, 150)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        else
            isDay = false
            Lighting.Brightness = nightBrightness
            Lighting.Ambient = Color3.fromRGB(50, 50, 50)
            Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80)
        end
    end)
end

-- Gọi hàm cấu hình chu kỳ ngày và đêm
configureDayNightCycle()

-- Thêm hiệu ứng Bloom (ánh sáng dịu)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 2 -- Độ sáng của hiệu ứng
bloom.Size = 40 -- Kích thước hiệu ứng
bloom.Threshold = 0.9 -- Ngưỡng hiệu ứng
bloom.Parent = Lighting

-- Thêm hiệu ứng Sun Rays (tia sáng mặt trời)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.8 -- Cường độ mạnh hơn
sunRays.Spread = 1.0 -- Độ lan tỏa
sunRays.Parent = Lighting

-- Thêm hiệu ứng Color Correction (Hiệu chỉnh màu sắc nâng cao)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.1 -- Độ sáng
colorCorrection.Contrast = 0.7 -- Độ tương phản cao
colorCorrection.Saturation = 1.2 -- Độ bão hòa màu rực rỡ
colorCorrection.TintColor = Color3.fromRGB(255, 240, 220) -- Tông màu ấm
colorCorrection.Parent = Lighting

-- Thêm hiệu ứng Depth of Field (Làm mờ xa/gần tự nhiên)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.InFocusRadius = 100 -- Bán kính lấy nét
depthOfField.NearIntensity = 0.4 -- Cường độ gần
depthOfField.FarIntensity = 0.3 -- Cường độ xa
depthOfField.FocusDistance = 50 -- Khoảng cách lấy nét
depthOfField.Parent = Lighting

-- Thêm hiệu ứng Auto Exposure để điều chỉnh độ chói
local autoExposure = Instance.new("ExposureCompensationEffect")
autoExposure.MinExposure = -0.5
autoExposure.MaxExposure = 1.5
autoExposure.Parent = Lighting

-- Tạo nền đất phản chiếu nâng cao
local function createReflectiveGround()
    local ground = Instance.new("Part")
    ground.Name = "ReflectiveGround"
    ground.Size = Vector3.new(1000, 1, 1000) -- Kích thước nền đất
    ground.Position = Vector3.new(0, 0, 0) -- Đặt nền đất ở gốc tọa độ
    ground.Anchored = true
    ground.Material = Enum.Material.SmoothPlastic -- Bề mặt mịn
    ground.Reflectance = 1.2 -- Độ phản chiếu cao
    ground.Color = Color3.fromRGB(90, 90, 90) -- Màu trung tính
    ground.Parent = workspace

    -- Thêm SurfaceAppearance để tăng phản chiếu
    local surfaceAppearance = Instance.new("SurfaceAppearance")
    surfaceAppearance.Reflectance = 1.2 -- Độ phản chiếu cực cao
    surfaceAppearance.Parent = ground
end

-- Gọi hàm tạo nền đất
createReflectiveGround()

-- Thêm hiệu ứng khói và sương mù
local fog = Instance.new("Atmosphere")
fog.Density = 0.1
fog.Offset = 0.1
fog.Parent = Lighting

-- Tăng độ chi tiết bóng đổ cho người chơi
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CastShadow = true -- Bật bóng đổ chi tiết
            end
        end
    end)
end)

-- Tạo hiệu ứng ánh sáng cho các kỹ năng (ví dụ: kỹ năng lửa)
local function createSkillEffect(skillName, color, size)
    local skillLight = Instance.new("PointLight")
    skillLight.Color = color
    skillLight.Range = size
    skillLight.Parent = workspace
end

-- Thêm ví dụ về hiệu ứng ánh sáng cho kỹ năng
createSkillEffect("FireSkill", Color3.fromRGB(255, 85, 0), 20)  -- Kỹ năng lửa
createSkillEffect("IceSkill", Color3.fromRGB(0, 255, 255), 15)  -- Kỹ năng băng

-- Thêm hiệu ứng chuyển động cho môi trường (mây di chuyển)
local cloud = Instance.new("Part")
cloud.Size = Vector3.new(100, 1, 100)
cloud.Position = Vector3.new(0, 100, 0)
cloud.Anchored = false
cloud.Material = Enum.Material.SmoothPlastic
cloud.Color = Color3.fromRGB(200, 200, 255)
cloud.Parent = workspace

-- Thêm chuyển động cho mây
RunService.Heartbeat:Connect(function()
    cloud.Position = cloud.Position + Vector3.new(0.1, 0, 0)
    if cloud.Position.X > 100 then
        cloud.Position = Vector3.new(-100, 100, 0)
    end
end)

print("Day-night cycle, enhanced RTX graphics, and environment effects applied!")
