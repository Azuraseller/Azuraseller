local lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Initial Lighting Setup
lighting.Ambient = Color3.fromRGB(20, 20, 25)
lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
lighting.Brightness = 1.5
lighting.ClockTime = 6
lighting.GeographicLatitude = 45
lighting.GlobalShadows = true
lighting.ShadowSoftness = 0.05

-- Lighting Effects
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.2
bloom.Size = 24
bloom.Threshold = 0.4
bloom.Parent = lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 1.5 -- Tăng để tia sáng rõ nét hơn
sunRays.Spread = 0.7 -- Điều chỉnh độ lan tỏa
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

local directionalLight = Instance.new("DirectionalLight")
directionalLight.Brightness = 2.5
directionalLight.Color = Color3.fromRGB(255, 240, 220)
directionalLight.Direction = Vector3.new(-0.5, -1, -0.3)
directionalLight.Shadows = true
directionalLight.Parent = lighting

-- Function to Create Point Lights
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

-- Create Sample Point Lights
local auxiliaryLight1 = createPointLight(Vector3.new(15, 6, 15), Color3.fromRGB(255, 190, 140), 18, 4)
local auxiliaryLight2 = createPointLight(Vector3.new(-15, 6, -15), Color3.fromRGB(140, 190, 255), 16, 3.5)

-- Function to Add Reflections to a Single Part
local function addReflectionToPart(part)
    if part:IsA("BasePart") then
        if part.Material == Enum.Material.Metal then
            part.Reflectance = 0.8
        elseif part.Material == Enum.Material.Glass then
            part.Reflectance = 0.6
        elseif part.Material == Enum.Material.Water then
            part.Reflectance = 0.4
        elseif part.Material == Enum.Material.Wood then
            part.Reflectance = 0.1
        end
    end
end

-- Function to Apply Material Effects Around the Player
local function applyMaterialEffects()
    local player = players.LocalPlayer
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local nearbyParts = workspace:GetPartBoundsInRadius(rootPart.Position, 50)
    for _, part in pairs(nearbyParts) do
        addReflectionToPart(part)
    end
end

-- Function to Create Area-Specific Effects
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

-- Apply Effects to Specific Areas
local forestArea = workspace:FindFirstChild("ForestArea")
if forestArea then
    createAreaEffects(forestArea, {Density = 0.6, Color = Color3.fromRGB(100, 150, 100)}, "rbxassetid://123456789")
end

local desertArea = workspace:FindFirstChild("DesertArea")
if desertArea then
    createAreaEffects(desertArea, {Density = 0.1, Color = Color3.fromRGB(255, 200, 150)}, "rbxassetid://987654321")
end

-- Dynamic Update Functions
local function updateShadowSoftness(time)
    if time >= 7 and time < 17 then
        lighting.ShadowSoftness = 0.05 -- Bóng sắc nét ban ngày
    else
        lighting.ShadowSoftness = 0.2 -- Bóng mềm hơn ban đêm
    end
end

local function updateAuxiliaryLights(time)
    local brightnessMultiplier
    if time >= 7 and time < 17 then
        brightnessMultiplier = 0.5 -- Giảm sáng ban ngày
    else
        brightnessMultiplier = 1.5 -- Tăng sáng ban đêm
    end
    auxiliaryLight1.Brightness = math.min(4 * brightnessMultiplier, 4)
    auxiliaryLight2.Brightness = math.min(3.5 * brightnessMultiplier, 3.5)
end

local function updateColorCorrection(time)
    if time >= 7 and time < 17 then
        colorCorrection.Contrast = 0.7 -- Tăng độ tương phản ban ngày
        colorCorrection.Saturation = 0.3
    else
        colorCorrection.Contrast = 0.4 -- Giảm độ tương phản ban đêm
        colorCorrection.Saturation = 0.2
    end
end

local timeSpeed = 0.15 -- Tốc độ tiến trình thời gian
local function updateLighting()
    lighting.ClockTime = (lighting.ClockTime + timeSpeed * runService.Heartbeat:Wait()) % 24
    local time = lighting.ClockTime
    local timeFraction = time / 24
    local angle = math.rad(timeFraction * 360)
    directionalLight.Direction = Vector3.new(math.sin(angle), -math.cos(angle), 0.2)

    -- Điều chỉnh màu sắc và hiệu ứng theo thời gian trong ngày
    if time >= 5 and time < 7 then -- Bình minh
        directionalLight.Color = Color3.fromRGB(255, 200, 150)
        bloom.Intensity = 1.0
        lighting.Ambient = Color3.fromRGB(30, 30, 35)
        lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 80)
    elseif time >= 7 and time < 17 then -- Ban ngày
        directionalLight.Color = Color3.fromRGB(255, 240, 220)
        bloom.Intensity = 1.2
        lighting.Ambient = Color3.fromRGB(20, 20, 25)
        lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
        lighting.Brightness = 2.0 -- Sáng hơn ban ngày
    elseif time >= 17 and time < 19 then -- Hoàng hôn
        directionalLight.Color = Color3.fromRGB(255, 150, 100) -- Màu cam nhẹ
        bloom.Intensity = 0.9
        lighting.Ambient = Color3.fromRGB(25, 25, 30)
        lighting.OutdoorAmbient = Color3.fromRGB(65, 65, 75)
    else -- Ban đêm
        directionalLight.Color = Color3.fromRGB(100, 100, 150)
        bloom.Intensity = 0.6
        lighting.Ambient = Color3.fromRGB(10, 10, 15)
        lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 40)
        lighting.Brightness = 1.0 -- Tối hơn ban đêm
    end

    -- Cập nhật các hiệu ứng động
    updateShadowSoftness(time)
    updateAuxiliaryLights(time)
    updateColorCorrection(time)
    applyMaterialEffects()
end

-- Kết nối với Heartbeat để cập nhật liên tục
runService.Heartbeat:Connect(updateLighting)
