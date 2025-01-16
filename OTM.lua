-- Đặt script này vào ServerScriptService hoặc Workspace

-- Lấy Lighting service
local Lighting = game:GetService("Lighting")

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

-- Cấu hình ánh sáng ngày và đêm
local function configureDayNightCycle()
    local dayBrightness = 1.2 -- Độ sáng ban ngày
    local nightBrightness = 0.7-- Độ sáng ban đêm
    local dayAmbient = Color3.fromRGB(150, 150, 150) -- Môi trường ban ngày
    local nightAmbient = Color3.fromRGB(50, 50, 50) -- Môi trường ban đêm

    game:GetService("RunService").Stepped:Connect(function()
        local currentTime = Lighting.ClockTime
        if currentTime >= 6 and currentTime <= 18 then
            -- Ban ngày
            Lighting.Brightness = dayBrightness
            Lighting.Ambient = dayAmbient
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        else
            -- Ban đêm
            Lighting.Brightness = nightBrightness
            Lighting.Ambient = nightAmbient
            Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80)
        end
    end)
end

-- Gọi hàm cấu hình chu kỳ ngày và đêm
configureDayNightCycle()

-- Hiệu ứng Bloom (giảm độ chói)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1 -- Độ sáng của hiệu ứng
bloom.Size = 25 -- Kích thước hiệu ứng
bloom.Threshold = 0.85 -- Ngưỡng hiệu ứng
bloom.Parent = Lighting

-- Hiệu ứng Sun Rays (tia sáng mặt trời khi nhìn thẳng)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.7 -- Cường độ
sunRays.Spread = 1 -- Độ lan tỏa
sunRays.Parent = Lighting

-- Hiệu ứng Color Correction (Hiệu chỉnh màu sắc nâng cao)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.2 -- Độ sáng
colorCorrection.Contrast = 0.6 -- Độ tương phản
colorCorrection.Saturation = 1.2 -- Độ bão hòa màu
colorCorrection.TintColor = Color3.fromRGB(255, 240, 220) -- Tông màu ấm
colorCorrection.Parent = Lighting

-- Hiệu ứng Depth of Field (Làm mờ xa/gần tự nhiên)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.InFocusRadius = 100 -- Bán kính lấy nét
depthOfField.NearIntensity = 0.4 -- Cường độ gần
depthOfField.FarIntensity = 0.3 -- Cường độ xa
depthOfField.FocusDistance = 50 -- Khoảng cách lấy nét
depthOfField.Parent = Lighting

-- Tăng độ bóng loáng trên tất cả vật thể
local function enhanceReflection()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic -- Bề mặt mịn
            obj.Reflectance = 0.9 -- Độ phản chiếu cao
            obj.CastShadow = true -- Bật bóng đổ
        end
    end
end

-- Gọi hàm nâng cấp phản chiếu
enhanceReflection()

-- Theo dõi người chơi và tăng bóng loáng cho item, trang phục
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.SmoothPlastic -- Bề mặt mịn
                part.Reflectance = 0.9 -- Độ phản chiếu cao
                part.CastShadow = true -- Bật bóng đổ chi tiết
            end
        end
    end)
end)

-- Tạo nền đất siêu phản chiếu
local function createReflectiveGround()
    local ground = Instance.new("Part")
    ground.Name = "ReflectiveGround"
    ground.Size = Vector3.new(1000, 1, 1000) -- Kích thước nền đất
    ground.Position = Vector3.new(0, 0, 0) -- Đặt nền đất ở gốc tọa độ
    ground.Anchored = true
    ground.Material = Enum.Material.SmoothPlastic -- Bề mặt mịn
    ground.Reflectance = 2 -- Độ phản chiếu cực cao
    ground.Color = Color3.fromRGB(90, 90, 90) -- Màu trung tính
    ground.Parent = workspace

    -- Thêm SurfaceAppearance để tăng phản chiếu
    local surfaceAppearance = Instance.new("SurfaceAppearance")
    surfaceAppearance.Reflectance = 2 -- Độ phản chiếu giống gương
    surfaceAppearance.Parent = ground
end

-- Gọi hàm tạo nền đất
createReflectiveGround()

print("Enhanced graphics with reflection, reduced glare, and day-night cycle applied!")
