-- Script nâng cấp siêu chân thực giống RTX cho Roblox

local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

-- Thiết lập ban đầu
lighting.Ambient = Color3.fromRGB(20, 20, 25)
lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
lighting.Brightness = 2.8
lighting.ClockTime = 6  -- Bắt đầu từ sáng sớm
lighting.GeographicLatitude = 45
lighting.GlobalShadows = true
lighting.ShadowSoftness = 0.05  -- Bóng đổ mềm mại hơn

-- BloomEffect (ánh sáng rực rỡ)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.4
bloom.Parent = lighting

-- SunRaysEffect (tia nắng)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.6
sunRays.Spread = 0.9
sunRays.Parent = lighting

-- ColorCorrection (điều chỉnh màu sắc)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.25
colorCorrection.Contrast = 0.5
colorCorrection.Saturation = 0.35
colorCorrection.TintColor = Color3.fromRGB(255, 235, 210)
colorCorrection.Parent = lighting

-- DepthOfField (độ sâu trường ảnh)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.FarIntensity = 1.0
depthOfField.NearIntensity = 0.85
depthOfField.FocusDistance = 25
depthOfField.InFocusRadius = 20
depthOfField.Parent = lighting

-- Atmosphere (môi trường không khí)
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.45
atmosphere.Offset = 0.2
atmosphere.Color = Color3.fromRGB(185, 190, 195)
atmosphere.Decay = Color3.fromRGB(85, 90, 95)
atmosphere.Glare = 0.4
atmosphere.Haze = 0.7
atmosphere.Parent = lighting

-- Nguồn sáng DirectionalLight
local directionalLight = Instance.new("DirectionalLight")
directionalLight.Brightness = 2.5
directionalLight.Color = Color3.fromRGB(255, 240, 220)
directionalLight.Direction = Vector3.new(-0.5, -1, -0.3)
directionalLight.Shadows = true
directionalLight.Parent = lighting

-- Hàm tạo PointLight
local function createPointLight(position, color, range, brightness)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Position = position
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Transparency = 1
    part.Parent = workspace

    local light = Instance.new("PointLight")
    light.Brightness = brightness or 3.5
    light.Color = color
    light.Range = range
    light.Shadows = true
    light.Parent = part
end

-- Thêm PointLight
createPointLight(Vector3.new(15, 6, 15), Color3.fromRGB(255, 190, 140), 18, 4)
createPointLight(Vector3.new(-15, 6, -15), Color3.fromRGB(140, 190, 255), 16, 3.5)

-- Hàm thêm phản chiếu
local function addReflection(part, textureId)
    local surface = Instance.new("SurfaceAppearance")
    surface.ColorMap = textureId
    surface.MetalnessMap = textureId  -- Giả lập độ kim loại
    surface.Parent = part
end

-- Tạo bề mặt nước phản chiếu
local waterPart = Instance.new("Part")
waterPart.Anchored = true
waterPart.Position = Vector3.new(0, 1, 0)
waterPart.Size = Vector3.new(30, 0.3, 30)
waterPart.Material = Enum.Material.Glass
waterPart.Transparency = 0.4
waterPart.Parent = workspace
addReflection(waterPart, "rbxassetid://987654321")

-- Tạo vật thể kim loại phản chiếu
local metalPart = Instance.new("Part")
metalPart.Anchored = true
metalPart.Position = Vector3.new(10, 2, 10)
metalPart.Size = Vector3.new(5, 5, 5)
metalPart.Material = Enum.Material.Metal
metalPart.Reflectance = 0.8
metalPart.Parent = workspace
addReflection(metalPart, "rbxassetid://123456789")

-- Thay đổi ánh sáng và môi trường theo thời gian
local timeSpeed = 0.15  -- Tốc độ thay đổi thời gian
runService.Heartbeat:Connect(function(deltaTime)
    lighting.ClockTime = (lighting.ClockTime + timeSpeed * deltaTime) % 24
    local timeFraction = lighting.ClockTime / 24
    local angle = math.rad(timeFraction * 360)
    directionalLight.Direction = Vector3.new(math.sin(angle), -math.cos(angle), 0.2)

    -- Thay đổi Atmosphere theo thời gian
    if lighting.ClockTime < 6 or lighting.ClockTime > 18 then
        atmosphere.Density = 0.5  -- Sương mù dày hơn vào ban đêm
        atmosphere.Color = Color3.fromRGB(80, 85, 90)
    else
        atmosphere.Density = 0.35  -- Sương mù nhẹ hơn vào ban ngày
        atmosphere.Color = Color3.fromRGB(190, 195, 200)
    end
end)

-- Tự động điều chỉnh độ sáng và độ lan
local function adjustBrightness()
    local brightness = 0.25
    local contrast = 0.5
    if lighting.ClockTime > 6 and lighting.ClockTime < 18 then
        brightness = 0.25  -- Ban ngày sáng rõ
        contrast = 0.5
    else
        brightness = -0.15  -- Ban đêm dịu hơn
        contrast = 0.4
    end
    colorCorrection.Brightness = brightness
    colorCorrection.Contrast = contrast
end

runService.Heartbeat:Connect(adjustBrightness)
