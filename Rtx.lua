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
bloom.Intensity = 0.4  -- Giảm độ chói
bloom.Size = 24
bloom.Threshold = 0.4
bloom.Parent = lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.6 -- Giảm độ chói
sunRays.Spread = 0.7
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

-- Sun and Moon Setup
local sun = Instance.new("DirectionalLight")
sun.Brightness = 2.5
sun.Color = Color3.fromRGB(255, 240, 220)
sun.Direction = Vector3.new(-0.5, -1, -0.3)
sun.Shadows = true
sun.Parent = lighting

local moon = Instance.new("DirectionalLight")
moon.Brightness = 0.6  -- Mặt trăng sáng yếu hơn
moon.Color = Color3.fromRGB(200, 200, 255)
moon.Direction = Vector3.new(0.5, -1, 0.3)
moon.Shadows = true
moon.Parent = lighting

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
    light.Range = math.min(range, 7)  -- Giảm phạm vi để hạn chế lan tỏa
    light.Brightness = math.min(maxBrightness, 2)  -- Giảm độ sáng
    light.Shadows = true
    light.Parent = part
    return light
end

-- Create Sample Point Lights
local auxiliaryLight1 = createPointLight(Vector3.new(15, 6, 15), Color3.fromRGB(255, 190, 140), 12, 2.5)
local auxiliaryLight2 = createPointLight(Vector3.new(-15, 6, -15), Color3.fromRGB(140, 190, 255), 10, 2)

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

-- Sky Setup
local sky = Instance.new("Sky")
sky.SunAngularSize = 10
sky.MoonAngularSize = 5
sky.Parent = lighting

-- Dynamic Update Functions
local function updateShadowSoftness(time)
    if time >= 7 and time < 17 then
        lighting.ShadowSoftness = 0.06  -- Bóng sắc nét hơn ban ngày
    else
        lighting.ShadowSoftness = 0.1   -- Bóng mềm hơn ban đêm
    end
end

local function updateAuxiliaryLights(time)
    local brightnessMultiplier
    if time >= 7 and time < 17 then
        brightnessMultiplier = 0.3  -- Giảm sáng ban ngày
    else
        brightnessMultiplier = 1.0  -- Tăng sáng ban đêm
    end
    auxiliaryLight1.Brightness = math.min(2.5 * brightnessMultiplier, 2.5)
    auxiliaryLight2.Brightness = math.min(2 * brightnessMultiplier, 2)
end

local function updateColorCorrection(time)
    if time >= 7 and time < 17 then
        colorCorrection.Contrast = 0.6
        colorCorrection.Saturation = 0.4
    else
        colorCorrection.Contrast = 0.3
        colorCorrection.Saturation = 0.2
    end
end

local timeSpeed = 0.15
local function updateLighting()
    lighting.ClockTime = (lighting.ClockTime + timeSpeed * runService.Heartbeat:Wait()) % 24
    local time = lighting.ClockTime
    local timeFraction = time / 24
    local angle = math.rad(timeFraction * 360)

    -- Update Sun and Moon Position and Visibility
    if time >= 5 and time < 19 then
        sun.Enabled = true
        moon.Enabled = false
        sun.Direction = Vector3.new(math.sin(angle), -math.cos(angle), 0.2)
    else
        sun.Enabled = false
        moon.Enabled = true
        moon.Direction = Vector3.new(math.sin(angle + math.pi), -math.cos(angle + math.pi), 0.2)
    end

    -- Adjust Colors and Effects Based on Time
    if time >= 5 and time < 7 then  -- Bình minh
        sun.Color = Color3.fromRGB(255, 200, 150)
        bloom.Intensity = 0.7
        lighting.Ambient = Color3.fromRGB(30, 30, 35)
        lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 80)
    elseif time >= 7 and time < 17 then  -- Ban ngày
        sun.Color = Color3.fromRGB(255, 240, 220)
        bloom.Intensity = 0.8
        lighting.Ambient = Color3.fromRGB(20, 20, 25)
        lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
        lighting.Brightness = 1.8
    elseif time >= 17 and time < 19 then  -- Hoàng hôn
        sun.Color = Color3.fromRGB(255, 150, 100)
        bloom.Intensity = 0.6
        lighting.Ambient = Color3.fromRGB(25, 25, 30)
        lighting.OutdoorAmbient = Color3.fromRGB(65, 65, 75)
    else  -- Ban đêm
        moon.Color = Color3.fromRGB(200, 200, 255)
        bloom.Intensity = 0.4
        lighting.Ambient = Color3.fromRGB(10, 10, 15)
        lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 40)
        lighting.Brightness = 0.8
    end

    -- Update Dynamic Effects
    updateShadowSoftness(time)
    updateAuxiliaryLights(time)
    updateColorCorrection(time)
    applyMaterialEffects()
end

-- Connect to Heartbeat for Continuous Updates
runService.Heartbeat:Connect(updateLighting)
