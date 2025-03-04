-- Script RTX Shader hoàn chỉnh cho Roblox
local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

-- Thiết lập ban đầu cho ánh sáng môi trường
lighting.Ambient = Color3.fromRGB(20, 20, 25)
lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
lighting.Brightness = 1.8
lighting.ClockTime = 6  -- Bắt đầu từ sáng sớm
lighting.GeographicLatitude = 45
lighting.GlobalShadows = true
lighting.ShadowSoftness = 0.05  -- Bóng đổ sắc nét và chi tiết

-- Thêm các hiệu ứng ánh sáng
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.4
bloom.Parent = lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.6
sunRays.Spread = 0.9
sunRays.Parent = lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.25
colorCorrection.Contrast = 0.5
colorCorrection.Saturation = 0.35
colorCorrection.TintColor = Color3.fromRGB(255, 235, 210)
colorCorrection.Parent = lighting

local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.FarIntensity = 1.0
depthOfField.NearIntensity = 0.85
depthOfField.FocusDistance = 25
depthOfField.InFocusRadius = 20
depthOfField.Parent = lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.45
atmosphere.Offset = 0.2
atmosphere.Color = Color3.fromRGB(185, 190, 195)
atmosphere.Decay = Color3.fromRGB(85, 90, 95)
atmosphere.Glare = 0.4
atmosphere.Haze = 0.7
atmosphere.Parent = lighting

-- Nguồn sáng DirectionalLight (ánh sáng chính)
local directionalLight = Instance.new("DirectionalLight")
directionalLight.Brightness = 2.5
directionalLight.Color = Color3.fromRGB(255, 240, 220)
directionalLight.Direction = Vector3.new(-0.5, -1, -0.3)
directionalLight.Shadows = true
directionalLight.Parent = lighting

-- Hàm tạo PointLight với kiểm soát độ chói
local function createPointLight(position, color, range, maxBrightness)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Position = position
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Transparency = 1
    part.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = math.min(range, 15)  -- Giới hạn độ lan
    light.Brightness = math.min(maxBrightness, 3)  -- Giới hạn độ chói
    light.Shadows = true
    light.Parent = part
    return light
end

-- Tạo các nguồn sáng điểm
createPointLight(Vector3.new(15, 6, 15), Color3.fromRGB(255, 190, 140), 18, 4)
createPointLight(Vector3.new(-15, 6, -15), Color3.fromRGB(140, 190, 255), 16, 3.5)

-- Hàm thêm phản chiếu cho tất cả vật liệu
local function addReflectionToAll()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Material == Enum.Material.Metal or part.Material == Enum.Material.Glass then
                part.Reflectance = 0.7
                local surface = Instance.new("SurfaceAppearance")
                surface.ColorMap = "rbxassetid://987654321"  -- Thay bằng texture phản chiếu thực tế
                surface.MetalnessMap = "rbxassetid://987654321"  -- Giả lập độ kim loại
                surface.Parent = part
            elseif part.Material == Enum.Material.Water then
                part.Reflectance = 0.4
                local surface = Instance.new("SurfaceAppearance")
                surface.ColorMap = "rbxassetid://123456789"  -- Texture nước phản chiếu
                surface.Parent = part
            end
        end
    end
end

addReflectionToAll()

-- Hàm tạo hiệu ứng gió cho môi trường
local function createWindEffect()
    local windPart = Instance.new("Part")
    windPart.Anchored = true
    windPart.Position = Vector3.new(0, 10, 0)
    windPart.Size = Vector3.new(100, 1, 100)
    windPart.Transparency = 1
    windPart.Parent = workspace

    local windEmitter = Instance.new("ParticleEmitter")
    windEmitter.Texture = "rbxassetid://123456789"  -- Thay bằng texture gió
    windEmitter.Size = NumberSequence.new(2, 5)
    windEmitter.Transparency = NumberSequence.new(0.8)
    windEmitter.Lifetime = NumberRange.new(3, 5)
    windEmitter.Rate = 10
    windEmitter.VelocitySpread = 10
    windEmitter.Parent = windPart
end

createWindEffect()

-- Hàm tạo bề mặt nước gợn sóng
local function createWaterWaves()
    local waterPart = Instance.new("Part")
    waterPart.Anchored = true
    waterPart.Position = Vector3.new(0, 1, 0)
    waterPart.Size = Vector3.new(30, 0.3, 30)
    waterPart.Material = Enum.Material.Glass
    waterPart.Transparency = 0.4
    waterPart.Parent = workspace

    local waveEmitter = Instance.new("ParticleEmitter")
    waveEmitter.Texture = "rbxassetid://987654321"  -- Texture sóng nước
    waveEmitter.Size = NumberSequence.new(1, 3)
    waveEmitter.Transparency = NumberSequence.new(0.6)
    waveEmitter.Lifetime = NumberRange.new(2, 4)
    waveEmitter.Rate = 20
    waveEmitter.SpreadAngle = Vector2.new(360, 360)
    waveEmitter.Parent = waterPart

    local surface = Instance.new("SurfaceAppearance")
    surface.ColorMap = "rbxassetid://123456789"  -- Texture phản chiếu nước
    surface.Parent = waterPart
end

createWaterWaves()

-- Tự động điều chỉnh ánh sáng và độ lan từ nguồn sáng
local function adjustLightSpread()
    for _, light in pairs(workspace:GetDescendants()) do
        if light:IsA("PointLight") or light:IsA("SpotLight") then
            local timeFactor = math.clamp((lighting.ClockTime - 6) / 12, 0, 1)  -- 0: đêm, 1: ngày
            light.Brightness = math.min(light.Brightness, 3 * (0.5 + 0.5 * timeFactor))  -- Giảm độ chói ban đêm
            light.Range = math.min(light.Range, 15 * (0.7 + 0.3 * timeFactor))  -- Giảm độ lan ban đêm
        end
    end
end

-- Cập nhật ánh sáng theo thời gian thực
local timeSpeed = 0.15  -- Tốc độ thay đổi thời gian
local function updateLighting()
    lighting.ClockTime = (lighting.ClockTime + timeSpeed * runService.Heartbeat:Wait()) % 24
    local time = lighting.ClockTime
    local timeFraction = time / 24
    local angle = math.rad(timeFraction * 360)
    directionalLight.Direction = Vector3.new(math.sin(angle), -math.cos(angle), 0.2)

    -- Thay đổi ánh sáng và môi trường theo khung giờ
    if time >= 5 and time < 7 then  -- Bình minh
        directionalLight.Color = Color3.fromRGB(255, 200, 150)
        atmosphere.Density = 0.3
        atmosphere.Color = Color3.fromRGB(200, 180, 160)
        colorCorrection.Brightness = 0.2
        bloom.Intensity = 1.0
    elseif time >= 7 and time < 17 then  -- Ban ngày
        directionalLight.Color = Color3.fromRGB(255, 240, 220)
        atmosphere.Density = 0.2
        atmosphere.Color = Color3.fromRGB(185, 190, 195)
        colorCorrection.Brightness = 0.25
        bloom.Intensity = 1.2
    elseif time >= 17 and time < 19 then  -- Hoàng hôn
        directionalLight.Color = Color3.fromRGB(255, 150, 100)
        atmosphere.Density = 0.4
        atmosphere.Color = Color3.fromRGB(200, 140, 120)
        colorCorrection.Brightness = 0.15
        bloom.Intensity = 0.9
    else  -- Ban đêm
        directionalLight.Color = Color3.fromRGB(100, 100, 150)
        atmosphere.Density = 0.5
        atmosphere.Color = Color3.fromRGB(80, 85, 90)
        colorCorrection.Brightness = -0.15
        bloom.Intensity = 0.6
    end

    adjustLightSpread()
end

-- Kết nối vòng lặp thời gian thực
runService.Heartbeat:Connect(updateLighting)

-- Khởi chạy ban đầu
print("RTX Shader đã được kích hoạt!")
