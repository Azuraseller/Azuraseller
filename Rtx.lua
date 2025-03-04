local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

-- Thiết lập ban đầu cho Lighting
lighting.Ambient = Color3.fromRGB(20, 20, 25)
lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
lighting.Brightness = 1.5
lighting.ClockTime = 6
lighting.GeographicLatitude = 45
lighting.GlobalShadows = true
lighting.ShadowSoftness = 0.05

-- Tạo các hiệu ứng ánh sáng
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.4
bloom.Parent = lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.8
sunRays.Spread = 1.0
sunRays.Parent = lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.25
colorCorrection.Contrast = 0.5
colorCorrection.Saturation = 0.35
colorCorrection.TintColor = Color3.fromRGB(255, 235, 210) -- Màu trắng ngà ấm
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

local directionalLight = Instance.new("DirectionalLight")
directionalLight.Brightness = 2.5
directionalLight.Color = Color3.fromRGB(255, 240, 220)
directionalLight.Direction = Vector3.new(-0.5, -1, -0.3)
directionalLight.Shadows = true
directionalLight.Parent = lighting

-- Hàm tạo PointLight
local function createPointLight(position, color, range, maxBrightness)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Position = position
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Transparency = 1
    part.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = math.min(range, 15)
    light.Brightness = math.min(maxBrightness, 3)
    light.Shadows = true
    light.Parent = part
    return light
end

-- Tạo một số PointLight mẫu
createPointLight(Vector3.new(15, 6, 15), Color3.fromRGB(255, 190, 140), 18, 4)
createPointLight(Vector3.new(-15, 6, -15), Color3.fromRGB(140, 190, 255), 16, 3.5)

-- Hàm thêm phản chiếu cho vật liệu
local function addReflectionToAll()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Material == Enum.Material.Metal then
                part.Reflectance = 0.8
                local surface = Instance.new("SurfaceAppearance")
                surface.ColorMap = "rbxassetid://987654321" -- Thay bằng texture kim loại
                surface.MetalnessMap = "rbxassetid://987654321"
                surface.Parent = part
            elseif part.Material == Enum.Material.Glass then
                part.Reflectance = 0.6
                local surface = Instance.new("SurfaceAppearance")
                surface.ColorMap = "rbxassetid://123456789" -- Thay bằng texture kính
                surface.Parent = part
            elseif part.Material == Enum.Material.Water then
                part.Reflectance = 0.4
                local surface = Instance.new("SurfaceAppearance")
                surface.ColorMap = "rbxassetid://123456789" -- Thay bằng texture nước
                surface.Parent = part
            elseif part.Material == Enum.Material.Wood then
                part.Reflectance = 0.1
            end
        end
    end
end
addReflectionToAll()

-- Hàm tạo hiệu ứng môi trường cho từng khu vực
local function createAreaEffects(areaPart, atmosphereParams, particleTexture)
    local atmosphereClone = atmosphere:Clone()
    atmosphereClone.Density = atmosphereParams.Density
    atmosphereClone.Color = atmosphereParams.Color
    atmosphereClone.Parent = areaPart

    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Texture = particleTexture
    particleEmitter.Size = NumberSequence.new(1, 3)
    particleEmitter.Transparency = NumberSequence.new(0.6)
    particleEmitter.Lifetime = NumberRange.new(2, 4)
    particleEmitter.Rate = 20
    particleEmitter.Parent = areaPart
end

-- Áp dụng hiệu ứng cho khu vực rừng
local forestArea = workspace:FindFirstChild("ForestArea")
if forestArea then
    createAreaEffects(forestArea, {Density = 0.6, Color = Color3.fromRGB(100, 150, 100)}, "rbxassetid://123456789")
end

-- Áp dụng hiệu ứng cho khu vực sa mạc
local desertArea = workspace:FindFirstChild("DesertArea")
if desertArea then
    createAreaEffects(desertArea, {Density = 0.1, Color = Color3.fromRGB(255, 200, 150)}, "rbxassetid://987654321")
end

-- Tạo nguồn sáng phụ
local auxiliaryLight = createPointLight(Vector3.new(0, 10, 0), Color3.fromRGB(255, 255, 255), 20, 1.5)

-- Hàm cập nhật động
local function updateShadowSoftness()
    local time = lighting.ClockTime
    if time >= 7 and time < 17 then
        lighting.ShadowSoftness = 0.05 -- Ban ngày: bóng sắc nét
    else
        lighting.ShadowSoftness = 0.3 -- Ban đêm: bóng mờ
    end
end

local function updateAuxiliaryLight()
    local time = lighting.ClockTime
    if time >= 7 and time < 17 then
        auxiliaryLight.Brightness = 2.0 -- Ban ngày: sáng mạnh
    else
        auxiliaryLight.Brightness = 0.5 -- Ban đêm: sáng yếu
    end
end

local function updateColorCorrection()
    local time = lighting.ClockTime
    if time >= 7 and time < 17 then
        colorCorrection.Contrast = 0.6 -- Ban ngày: vùng sáng/tối rõ
        colorCorrection.Saturation = 0.3 -- Màu tươi
    else
        colorCorrection.Contrast = 0.4 -- Ban đêm: tương phản thấp
        colorCorrection.Saturation = 0.2 -- Màu nhạt, dễ chịu
    end
end

local timeSpeed = 0.15 -- Tốc độ thay đổi thời gian
local function updateLighting()
    lighting.ClockTime = (lighting.ClockTime + timeSpeed * runService.Heartbeat:Wait()) % 24
    local time = lighting.ClockTime
    local timeFraction = time / 24
    local angle = math.rad(timeFraction * 360)
    directionalLight.Direction = Vector3.new(math.sin(angle), -math.cos(angle), 0.2)

    -- Thay đổi màu sắc ánh sáng theo thời gian
    if time >= 5 and time < 7 then -- Bình minh
        directionalLight.Color = Color3.fromRGB(255, 200, 150)
        bloom.Intensity = 1.0
    elseif time >= 7 and time < 17 then -- Ban ngày
        directionalLight.Color = Color3.fromRGB(255, 240, 220)
        bloom.Intensity = 1.2
    elseif time >= 17 and time < 19 then -- Hoàng hôn
        directionalLight.Color = Color3.fromRGB(255, 150, 100)
        bloom.Intensity = 0.9
    else -- Ban đêm
        directionalLight.Color = Color3.fromRGB(100, 100, 150)
        bloom.Intensity = 0.6
    end

    updateShadowSoftness()
    updateAuxiliaryLight()
    updateColorCorrection()
end

-- Kết nối hàm cập nhật với Heartbeat
runService.Heartbeat:Connect(updateLighting)
