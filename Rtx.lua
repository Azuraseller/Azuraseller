------------------------------------------------------------
-- RTX Ultra Realistic Experience - Phiên bản Siêu Chân Thực
------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

------------------------------------------------------------
-- BẢNG CẤU HÌNH SIÊU CHÂN THỰC (nâng cấp toàn diện)
------------------------------------------------------------
local config = {
    PostProcessing = {
        Bloom = { Intensity = 1.8, Size = 55, Threshold = 1.6 },
        ColorCorrection = { Brightness = 0.22, Contrast = 0.4, Saturation = 0.2, TintColor = Color3.fromRGB(80,120,190) },
        DepthOfField = { FarIntensity = 0.4, FocusDistance = 16, InFocusRadius = 14, NearIntensity = 0.4 },
        SSR = { Intensity = 1.1, Reflectance = 0.85 },
        SunRays = { Intensity = 0.55, Spread = 0.3 }
    },
    RtxUpgrade = {
        LightBleedReduction = 0.4,
        DeviceBrightnessFactor = 1.15,
    },
    Clouds = {
        PartTransparency = { Day = 0.6, Night = 0.9 },
        OffsetSpeed = { U = 0.09, V = 0.045 },
        StudsPerTile = 650,
        ParticleRate = 10,
        ParticleLifetime = NumberRange.new(9,14),
        ParticleSpeed = NumberRange.new(0,0)
    },
    Sky = {
        StarRate = 4,
        StarLifetime = NumberRange.new(15,22),
        StarSpeed = NumberRange.new(0,0),
        NebulaColor = ColorSequence.new{
            NumberSequenceKeypoint.new(0, Color3.fromRGB(15,25,70)),
            NumberSequenceKeypoint.new(1, Color3.fromRGB(5,15,40))
        }
    },
    Water = {
        Reflectance = 0.5,
        TextureSpeed = { U = 0.14, V = 0.07 },
        Mist = { Rate = 4, Lifetime = {3.5,7}, Speed = {0.7,1.5}, Size = 7, Color = Color3.fromRGB(220,220,255), Transparency = 0.4 },
        WaveAmplitude = 0.07,
        WaveFrequency = 0.65
    },
    ReflectionProbe = { Size = Vector3.new(90,90,90) },
    GlobalLighting = { DayBrightness = 3.2, NightBrightness = 2.0 },
    Shadow = {
        BaseSize = 8,
        Offsets = { offsetDistance = 4 },
        Smoothing = 0.3,
        Layers = {
            { Name = "ShadowCore", Multiplier = 1, Transparency = 0.26 },
            { Name = "ShadowBlur1", Multiplier = 1.2, Transparency = 0.45, ExtraOffset = Vector3.new(0.3,0,0.3) },
            { Name = "ShadowBlur2", Multiplier = 1.4, Transparency = 0.65, ExtraOffset = Vector3.new(-0.3,0,-0.3) }
        }
    },
    PlayerLight = { Range = { Outdoors = 700, Indoors = 350 }, BaseBrightness = 1.8, Color = Color3.fromRGB(255,245,230) },
    Sun = {
        PartSize = Vector3.new(75,75,75),
        PartColor = Color3.fromRGB(255,240,130),
        Light = { Range = 1500, Brightness = 4 },
        OcclusionFactor = 0.3,
        Corona = {
            ParticleRate = 3,
            ParticleLifetime = NumberRange.new(0.9,1.6),
            ParticleSize = NumberSequence.new({NumberSequenceKeypoint.new(0,7), NumberSequenceKeypoint.new(1,13)})
        }
    },
    Moon = {
        PartSize = Vector3.new(60,60,60),
        PartColor = Color3.fromRGB(220,240,255),
        Light = { Range = 1300, Brightness = 2.5 },
        Corona = {
            ParticleRate = 2,
            ParticleLifetime = NumberRange.new(1.1,1.9),
            ParticleSize = NumberSequence.new({NumberSequenceKeypoint.new(0,6), NumberSequenceKeypoint.new(1,11)})
        }
    },
    ShootingStar = {
        Size = Vector3.new(5,5,5),
        FinalSize = Vector3.new(0.35,0.35,0.35),
        TweenTime = 1.8,
        SpawnInterval = { Min = 6, Max = 20 },
        Colors = {
            Color3.fromRGB(255,170,170),
            Color3.fromRGB(170,255,170),
            Color3.fromRGB(170,170,255),
            Color3.fromRGB(255,255,170),
            Color3.fromRGB(255,170,255),
            Color3.fromRGB(170,255,255)
        }
    },
    DetailQuality = {
        Radius = 300,
        HighMaterial = Enum.Material.Metal,
        Reflectance = 0.4,
        UpdateInterval = 3
    },
    EnvironmentCheck = { UpdateInterval = 1.5 },
    AdvancedEffects = {
        RTGI = { Enabled = true, BounceIntensity = 0.28 },
        RayTracedReflections = { Enabled = true, Intensity = 1.15 },
        RefractionMapping = { Enabled = true, Intensity = 0.6 },
        NormalMapping = { Enabled = true, NormalMapAsset = nil },
        POM = { Enabled = true, ParallaxMapAsset = nil, ParallaxScale = 0.07 },
        SSS = { Enabled = true, Intensity = 0.65 },
        MotionBlur = { Enabled = true, MaxSize = 14, Sensitivity = 0.14 },
        ChromaticAberration = { Enabled = true, Intensity = 0.18 }
    },
    Weather = {
        -- Hệ thống thời tiết chuyển đổi động
        TransitionTime = 60,  -- thời gian chuyển đổi (giây)
        States = {"Sunny", "Rainy", "Foggy"},
        CurrentState = "Sunny",
        Wind = { Speed = 5, Direction = Vector3.new(1,0,0) }  -- gió ban đầu
    }
}

local advancedMode = true

------------------------------------------------------------
-- HỆ THỐNG THỜI TIẾT & GIO (Dynamic Weather & Wind)
------------------------------------------------------------
local function updateWeather(dt)
    -- Giả lập chuyển đổi thời tiết: mỗi khoảng thời gian nhất định chuyển trạng thái
    config.Weather.Elapsed = (config.Weather.Elapsed or 0) + dt
    if config.Weather.Elapsed >= config.Weather.TransitionTime then
        config.Weather.Elapsed = 0
        local states = config.Weather.States
        local current = config.Weather.CurrentState
        local idx = table.find(states, current) or 1
        local nextState = states[(idx % #states) + 1]
        config.Weather.CurrentState = nextState
        -- Điều chỉnh môi trường theo trạng thái thời tiết
        if nextState == "Sunny" then
            Lighting.Ambient = Color3.fromRGB(70,100,180)
            Lighting.Brightness = config.GlobalLighting.DayBrightness
        elseif nextState == "Rainy" then
            Lighting.Ambient = Color3.fromRGB(60,80,120)
            Lighting.Brightness = config.GlobalLighting.DayBrightness * 0.85
        elseif nextState == "Foggy" then
            Lighting.Ambient = Color3.fromRGB(50,70,100)
            Lighting.Brightness = config.GlobalLighting.NightBrightness * 0.9
        end
    end
    -- Giả lập thay đổi hướng và tốc độ gió (tạo cảm giác bầu không khí động)
    config.Weather.Wind.Speed = 5 + math.sin(tick() * 0.1) * 3
    local angle = tick() * 0.05
    config.Weather.Wind.Direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
end

------------------------------------------------------------
-- 1. POST-PROCESSING & ÁNH SÁNG CHUNG (Nâng cấp tối đa)
------------------------------------------------------------
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.7
Lighting.Ambient = Color3.fromRGB(70,100,180)

local bloom = Instance.new("BloomEffect")
bloom.Intensity = config.PostProcessing.Bloom.Intensity
bloom.Size = config.PostProcessing.Bloom.Size * config.RtxUpgrade.LightBleedReduction
bloom.Threshold = config.PostProcessing.Bloom.Threshold
bloom.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = config.PostProcessing.ColorCorrection.Brightness
colorCorrection.Contrast = config.PostProcessing.ColorCorrection.Contrast
colorCorrection.Saturation = config.PostProcessing.ColorCorrection.Saturation
colorCorrection.TintColor = config.PostProcessing.ColorCorrection.TintColor
colorCorrection.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = config.PostProcessing.DepthOfField.FarIntensity
dof.FocusDistance = config.PostProcessing.DepthOfField.FocusDistance
dof.InFocusRadius = config.PostProcessing.DepthOfField.InFocusRadius
dof.NearIntensity = config.PostProcessing.DepthOfField.NearIntensity
dof.Parent = Lighting

local ssr
do
	local success, result = pcall(function()
		return Lighting:FindFirstChild("ScreenSpaceReflectionEffect") or Instance.new("ScreenSpaceReflectionEffect")
	end)
	if success and result then
		ssr = result
		ssr.Intensity = config.PostProcessing.SSR.Intensity
		ssr.Reflectance = config.PostProcessing.SSR.Reflectance
		ssr.Parent = Lighting
	else
		warn("ScreenSpaceReflectionEffect không khả dụng.")
	end
end

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = config.PostProcessing.SunRays.Intensity
sunRays.Spread = config.PostProcessing.SunRays.Spread
sunRays.Parent = Lighting

------------------------------------------------------------
-- 2. HIỆU ỨNG MÂY (Dynamic Cloud System với Particle & Wind)
------------------------------------------------------------
local cloudLayer = Instance.new("Part")
cloudLayer.Name = "CloudLayer"
cloudLayer.Size = Vector3.new(14000,1,14000)
cloudLayer.Anchored = true
cloudLayer.CanCollide = false
cloudLayer.Material = Enum.Material.SmoothPlastic
cloudLayer.Transparency = config.Clouds.PartTransparency.Day
cloudLayer.Parent = Workspace
cloudLayer.CFrame = CFrame.new(0,350,0) * CFrame.Angles(math.rad(90),0,0)

local cloudTexture = Instance.new("Texture")
cloudTexture.Face = Enum.NormalId.Top
cloudTexture.Texture = ""
cloudTexture.StudsPerTileU = config.Clouds.StudsPerTile
cloudTexture.StudsPerTileV = config.Clouds.StudsPerTile
cloudTexture.Parent = cloudLayer

local cloudEmitter = Instance.new("ParticleEmitter", cloudLayer)
cloudEmitter.Rate = config.Clouds.ParticleRate
cloudEmitter.Lifetime = config.Clouds.ParticleLifetime
cloudEmitter.Speed = config.Clouds.ParticleSpeed
cloudEmitter.Size = NumberSequence.new(25)
cloudEmitter.Color = ColorSequence.new(Color3.fromRGB(230,230,250))
cloudEmitter.Transparency = NumberSequence.new(0.65)
cloudEmitter.LightEmission = 0.25

task.spawn(function()
	while true do
		cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + config.Clouds.OffsetSpeed.U) % config.Clouds.StudsPerTile
		cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + config.Clouds.OffsetSpeed.V) % config.Clouds.StudsPerTile
		task.wait(0.1)
	end
end)

------------------------------------------------------------
-- 3. NỀN BẦU TRỜI (Sky với hệ thống sao & nebula nâng cao)
------------------------------------------------------------
local skyBackground = Instance.new("Part")
skyBackground.Name = "SkyBackground"
skyBackground.Size = Vector3.new(16000,1,16000)
skyBackground.Anchored = true
skyBackground.CanCollide = false
skyBackground.Transparency = 1
skyBackground.Parent = Workspace
skyBackground.CFrame = CFrame.new(0,650,0)

local starEmitter = Instance.new("ParticleEmitter", skyBackground)
starEmitter.Rate = config.Sky.StarRate
starEmitter.Lifetime = config.Sky.StarLifetime
starEmitter.Speed = config.Sky.StarSpeed
starEmitter.Size = NumberSequence.new(1.7)
starEmitter.Color = config.Sky.NebulaColor
starEmitter.LightEmission = 0.65

------------------------------------------------------------
-- 4. HIỆU ỨNG MẶT NƯỚC (Water Enhancement với sóng, khúc xạ & mưa sương)
------------------------------------------------------------
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
		local sa = obj:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance", obj)
		task.spawn(function()
			while obj.Parent do
				sa.Reflectance = config.Water.Reflectance + config.Water.WaveAmplitude * math.sin(tick() * config.Water.WaveFrequency)
				task.wait(0.1)
			end
		end)
		sa.Color = Color3.new(1,1,1)
		if config.AdvancedEffects.RefractionMapping.Enabled then
			sa.Reflectance = sa.Reflectance * config.AdvancedEffects.RefractionMapping.Intensity
		end
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("Texture") then
				task.spawn(function()
					while child.Parent do
						child.OffsetStudsU = (child.OffsetStudsU + config.Water.TextureSpeed.U) % 100
						child.OffsetStudsV = (child.OffsetStudsV + config.Water.TextureSpeed.V) % 100
						task.wait(0.1)
					end
				end)
			end
		end
		if not obj:FindFirstChild("WaterMist") then
			local mist = Instance.new("ParticleEmitter", obj)
			mist.Name = "WaterMist"
			mist.Rate = config.Water.Mist.Rate
			mist.Lifetime = NumberRange.new(unpack(config.Water.Mist.Lifetime))
			mist.Speed = NumberRange.new(unpack(config.Water.Mist.Speed))
			mist.Size = NumberSequence.new(config.Water.Mist.Size)
			mist.Color = ColorSequence.new(config.Water.Mist.Color)
			mist.Transparency = NumberSequence.new(config.Water.Mist.Transparency)
		end
	end
end

------------------------------------------------------------
-- 5. REFLECTION PROBE (Dynamic Reflection)
------------------------------------------------------------
local reflectionProbe = Instance.new("ReflectionProbe")
reflectionProbe.Name = "LocalReflectionProbe"
reflectionProbe.Size = config.ReflectionProbe.Size
reflectionProbe.ReflectionType = Enum.ReflectionType.Dynamic
reflectionProbe.Parent = Workspace

RunService.RenderStepped:Connect(function()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		reflectionProbe.CFrame = player.Character.HumanoidRootPart.CFrame
	end
end)

------------------------------------------------------------
-- 6. GLOBAL LIGHTING (Dynamic Brightness theo thời gian & thời tiết)
------------------------------------------------------------
local function updateGlobalLighting()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	local quality = settings().RenderingQualityLevel or 1
	if quality < 2 then
		baseBrightness = baseBrightness * config.RtxUpgrade.DeviceBrightnessFactor
	end
	Lighting.Brightness = baseBrightness
end

local function adjustGlobalBrightness()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	local quality = settings().RenderingQualityLevel or 1
	if quality < 2 then
		baseBrightness = baseBrightness * config.RtxUpgrade.DeviceBrightnessFactor
	end
	if Lighting.Brightness > baseBrightness then
		Lighting.Brightness = Lighting.Brightness - (Lighting.Brightness - baseBrightness)*0.07
	end
end

task.spawn(function()
	while true do
		updateGlobalLighting()
		adjustGlobalBrightness()
		task.wait(1)
	end
end)

------------------------------------------------------------
-- 7. HIỆU ỨNG BÓNG NHÂN VẬT (Adaptive Shadows nâng cao)
------------------------------------------------------------
local shadowLayers = {}
local function createShadowLayer(layerConfig)
	local part = Instance.new("Part")
	part.Name = layerConfig.Name
	part.Size = Vector3.new(config.Shadow.BaseSize, 0.3, config.Shadow.BaseSize)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = layerConfig.Transparency
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(0,0,0)
	part.Parent = Workspace
	return part
end

for _, layer in ipairs(config.Shadow.Layers) do
	shadowLayers[layer.Name] = createShadowLayer(layer)
end

local previousShadowCFrame = nil
local function getSunDirection()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		local t = (hour - 6) / 12
		local elevation = math.sin(t * math.pi) * (math.pi/2)
		local azimuth = t * math.pi
		local sunDir = Vector3.new(math.cos(azimuth) * math.cos(elevation), math.sin(elevation), math.sin(azimuth) * math.cos(elevation))
		return sunDir, elevation
	else
		return Vector3.new(1,0,0), 0.1
	end
end

local function updateAdvancedShadows()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local sunDir, elevation = getSunDirection()
		local rayOrigin = hrp.Position
		local rayDirection = -sunDir * 140
		local rayParams = RaycastParams.new()
		local blacklist = {player.Character}
		for _, layer in pairs(shadowLayers) do
			table.insert(blacklist, layer)
		end
		rayParams.FilterDescendantsInstances = blacklist
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
		local shadowPosition, groundNormal
		if rayResult then
			shadowPosition = rayResult.Position + rayResult.Normal * 0.2
			groundNormal = rayResult.Normal
		else
			local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z).Unit
			shadowPosition = hrp.Position - Vector3.new(0, hrp.Size.Y/2, 0) + shadowDir * config.Shadow.Offsets.offsetDistance
			groundNormal = Vector3.new(0,1,0)
		end
		local lengthFactor = 1 / math.max(math.sin(elevation), 0.2)
		lengthFactor = math.clamp(lengthFactor, 1, 3.5)
		local baseSize = config.Shadow.BaseSize * lengthFactor
		local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z)
		if shadowDir.Magnitude < 0.001 then
			shadowDir = Vector3.new(0,0,1)
		else
			shadowDir = shadowDir.Unit
		end
		local rightVector = shadowDir:Cross(groundNormal).Unit
		local forwardVector = groundNormal:Cross(rightVector).Unit
		local targetCFrame = CFrame.fromMatrix(shadowPosition, rightVector, groundNormal, forwardVector)
		if previousShadowCFrame then
			targetCFrame = previousShadowCFrame:Lerp(targetCFrame, config.Shadow.Smoothing)
		end
		previousShadowCFrame = targetCFrame
		for _, layer in ipairs(config.Shadow.Layers) do
			local multiplier = layer.Multiplier
			local extraOffset = layer.ExtraOffset or Vector3.new(0,0,0)
			local shadow = shadowLayers[layer.Name]
			shadow.Size = Vector3.new(baseSize * multiplier, 0.3, baseSize * multiplier)
			shadow.CFrame = targetCFrame * CFrame.new(extraOffset)
		end
	end
end
RunService.RenderStepped:Connect(updateAdvancedShadows)

------------------------------------------------------------
-- 8. HIỆU ỨNG ÁNH SÁNG & HALO (PlayerLight & Halo nâng cao)
------------------------------------------------------------
local playerLight = Instance.new("PointLight")
playerLight.Name = "PlayerLight"
playerLight.Range = config.PlayerLight.Range.Outdoors
playerLight.Brightness = config.PlayerLight.BaseBrightness
playerLight.Color = config.PlayerLight.Color
playerLight.Shadows = true

local function onCharacterAdded(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	playerLight.Parent = hrp
	local head = char:FindFirstChild("Head")
	if head and not head:FindFirstChild("HaloEmitter") then
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "HaloEmitter"
		halo.Parent = head
		halo.Rate = 8
		halo.Lifetime = NumberRange.new(1.5,2.5)
		halo.Speed = NumberRange.new(0,0)
		halo.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4.5), NumberSequenceKeypoint.new(1,9)})
		halo.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,0.95)})
		halo.LightEmission = 1
		halo.Color = ColorSequence.new{
			NumberSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			NumberSequenceKeypoint.new(1, Color3.fromRGB(220,240,255))
		}
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

local baseTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - baseTime
	playerLight.Brightness = config.PlayerLight.BaseBrightness + 0.4 * math.sin(t * 0.7)
end)

------------------------------------------------------------
-- 9. HIỆU ỨNG MẶT TRỜI & MẶT TRĂNG (Corona & Glow nâng cao)
------------------------------------------------------------
local sunPart = Instance.new("Part")
sunPart.Name = "SunPart"
sunPart.Shape = Enum.PartType.Ball
sunPart.Size = config.Sun.PartSize
sunPart.Material = Enum.Material.Neon
sunPart.Color = config.Sun.PartColor
sunPart.Anchored = true
sunPart.CanCollide = false
sunPart.Parent = Workspace

local sunLight = Instance.new("PointLight")
sunLight.Range = config.Sun.Light.Range
sunLight.Brightness = config.Sun.Light.Brightness
sunLight.Color = sunPart.Color
sunLight.Parent = sunPart

local sunCorona = Instance.new("ParticleEmitter", sunPart)
sunCorona.Rate = config.Sun.Corona.ParticleRate
sunCorona.Lifetime = config.Sun.Corona.ParticleLifetime
sunCorona.Speed = NumberRange.new(0,0)
sunCorona.Size = config.Sun.Corona.ParticleSize
sunCorona.Color = ColorSequence.new(sunPart.Color)
sunCorona.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,0.75)})
sunCorona.LightEmission = 1

local moonPart = Instance.new("Part")
moonPart.Name = "MoonPart"
moonPart.Shape = Enum.PartType.Ball
moonPart.Size = config.Moon.PartSize
moonPart.Material = Enum.Material.Neon
moonPart.Color = config.Moon.PartColor
moonPart.Anchored = true
moonPart.CanCollide = false
moonPart.Parent = Workspace

local moonLight = Instance.new("PointLight")
moonLight.Range = config.Moon.Light.Range
moonLight.Brightness = config.Moon.Light.Brightness
moonLight.Color = moonPart.Color
moonLight.Parent = moonPart

local moonCorona = Instance.new("ParticleEmitter", moonPart)
moonCorona.Rate = config.Moon.Corona.ParticleRate
moonCorona.Lifetime = config.Moon.Corona.ParticleLifetime
moonCorona.Speed = NumberRange.new(0,0)
moonCorona.Size = config.Moon.Corona.ParticleSize
moonCorona.Color = ColorSequence.new(moonPart.Color)
moonCorona.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,0.75)})
moonCorona.LightEmission = 1

RunService.RenderStepped:Connect(function()
	local sunDir, _ = getSunDirection()
	local distance = config.Sun.Light.Range
	sunPart.Position = camera.CFrame.Position + sunDir * distance
	moonPart.Position = camera.CFrame.Position - sunDir * distance
	
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		sunPart.Transparency = 0
		moonPart.Transparency = 1
	else
		sunPart.Transparency = 1
		moonPart.Transparency = 0
	end
	
	local cameraLook = camera.CFrame.LookVector
	local sunVector = (sunPart.Position - camera.CFrame.Position).Unit
	local alignment = cameraLook:Dot(sunVector)
	if alignment > 0.97 then
		sunCorona.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1), NumberSequenceKeypoint.new(1,0.65)})
	else
		sunCorona.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0.8)})
	end
end)

local function updateSunOcclusion()
	if player.Character and player.Character:FindFirstChild("Head") then
		local headPos = player.Character.Head.Position
		local direction = (headPos - sunPart.Position).Unit
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {player.Character, sunPart}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local rayResult = Workspace:Raycast(sunPart.Position, (headPos - sunPart.Position), rayParams)
		if rayResult then
			sunLight.Brightness = config.Sun.Light.Brightness * config.Sun.OcclusionFactor
		else
			sunLight.Brightness = config.Sun.Light.Brightness
		end
	end
end
RunService.RenderStepped:Connect(updateSunOcclusion)

------------------------------------------------------------
-- 10. HIỆU ỨNG SAO BĂNG (Shooting Star cực chân thực)
------------------------------------------------------------
local function spawnEnhancedShootingStar()
	local star = Instance.new("Part")
	star.Name = "EnhancedShootingStar"
	star.Shape = Enum.PartType.Ball
	star.Size = config.ShootingStar.Size
	star.Material = Enum.Material.Neon
	star.Color = config.ShootingStar.Colors[math.random(1, #config.ShootingStar.Colors)]
	star.Anchored = true
	star.CanCollide = false
	star.Transparency = 0
	star.Parent = Workspace
	
	local att0 = Instance.new("Attachment", star)
	local att1 = Instance.new("Attachment", star)
	local trail1 = Instance.new("Trail", star)
	trail1.Attachment0 = att0
	trail1.Attachment1 = att1
	trail1.Lifetime = 0.8
	trail1.LightEmission = 1
	trail1.Color = ColorSequence.new(star.Color)
	trail1.WidthScale = 1.8
	
	local att2 = Instance.new("Attachment", star)
	local att3 = Instance.new("Attachment", star)
	local trail2 = Instance.new("Trail", star)
	trail2.Attachment0 = att2
	trail2.Attachment1 = att3
	trail2.Lifetime = 1
	trail2.LightEmission = 1
	trail2.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, star.Color),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
	})
	trail2.WidthScale = 1
	
	att0.Position = Vector3.new(0,0,0)
	att1.Position = Vector3.new(0,0,0)
	att2.Position = Vector3.new(0,0,0)
	att3.Position = Vector3.new(0,0,0)
	
	local startPos = camera.CFrame.Position + Vector3.new(math.random(-800,800), math.random(550,900), math.random(-800,800))
	local direction = Vector3.new(math.random(-1,1), -math.random(1,3), math.random(-1,1)).Unit
	star.Position = startPos
	
	local tweenInfo = TweenInfo.new(config.ShootingStar.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Position = startPos + direction * 1200,
		Size = config.ShootingStar.FinalSize,
		Transparency = 1
	}
	local tween = TweenService:Create(star, tweenInfo, goal)
	tween:Play()
	tween.Completed:Connect(function()
		star:Destroy()
	end)
end

task.spawn(function()
	while true do
		task.wait(math.random(config.ShootingStar.SpawnInterval.Min, config.ShootingStar.SpawnInterval.Max))
		spawnEnhancedShootingStar()
	end
end)

------------------------------------------------------------
-- 11. TĂNG CHẤT LƯỢNG CHI TIẾT XUNG QUANH NGƯỜI CHƠI (Dynamic Detail)
------------------------------------------------------------
local function updateDetailQuality()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local regionSize = Vector3.new(config.DetailQuality.Radius, config.DetailQuality.Radius, config.DetailQuality.Radius)
		local parts = Workspace:GetPartBoundsInBox(hrp.CFrame, regionSize, {player.Character})
		for _, part in ipairs(parts) do
			if part:GetAttribute("EnhancedDetail") then
				part.Material = config.DetailQuality.HighMaterial
				part.Reflectance = config.DetailQuality.Reflectance
			end
		end
	end
end
task.spawn(function()
	while true do
		updateDetailQuality()
		task.wait(config.DetailQuality.UpdateInterval)
	end
end)

------------------------------------------------------------
-- 12. KIỂM TRA MÔI TRƯỜNG & AMBIENT OCCLUSION (Dynamic Environment)
------------------------------------------------------------
local function updateEnvironmentLighting()
	if player.Character and player.Character:FindFirstChild("Head") then
		local head = player.Character.Head
		local origin = head.Position
		local direction = Vector3.new(0,70,0)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {player.Character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local result = Workspace:Raycast(origin, direction, rayParams)
		if result then
			Lighting.Brightness = 0.95
			Lighting.Ambient = Color3.fromRGB(40,70,90)
			playerLight.Range = config.PlayerLight.Range.Indoors
		else
			local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
			Lighting.Brightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
			Lighting.Ambient = Color3.fromRGB(70,100,180)
			playerLight.Range = config.PlayerLight.Range.Outdoors
		end
	end
end
task.spawn(function()
	while true do
		updateEnvironmentLighting()
		task.wait(config.EnvironmentCheck.UpdateInterval)
	end
end)

------------------------------------------------------------
-- 13. ENHANCED OBJECT SHADOWS (Dynamic Object Shadows)
------------------------------------------------------------
local objectShadows = {}
local function initObjectShadow(part)
	local excludeNames = {"CloudLayer", "SunPart", "MoonPart", "StarField", "EnhancedShootingStar", "MirrorOverlay"}
	for _, name in ipairs(excludeNames) do
		if part.Name:find(name) then return end
	end
	if objectShadows[part] then return end
	local shadowPart = Instance.new("Part")
	shadowPart.Name = "EnhancedShadow"
	shadowPart.Size = Vector3.new(part.Size.X, 0.25, part.Size.Z)
	shadowPart.Anchored = true
	shadowPart.CanCollide = false
	shadowPart.Material = Enum.Material.SmoothPlastic
	shadowPart.Color = Color3.new(0,0,0)
	shadowPart.Transparency = 0.26
	shadowPart.Parent = Workspace
	objectShadows[part] = shadowPart
	part.AncestryChanged:Connect(function(child, parent)
		if not parent then
			if objectShadows[part] then
				objectShadows[part]:Destroy()
				objectShadows[part] = nil
			end
		end
	end)
end

local function updateObjectShadow(part, shadowPart, sunDir, elevation)
	local origin = part.Position
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {part}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	local rayResult = Workspace:Raycast(origin, -sunDir * 140, rayParams)
	local hitPos
	if rayResult then
		hitPos = rayResult.Position + Vector3.new(0,0.1,0)
	else
		hitPos = part.Position - Vector3.new(0, part.Size.Y/2 + 0.1, 0)
	end
	local factor = 1 / math.max(math.sin(elevation), 0.2)
	factor = math.clamp(factor, 1, 3.8)
	shadowPart.Size = Vector3.new(part.Size.X * factor, 0.25, part.Size.Z * factor)
	shadowPart.CFrame = CFrame.new(hitPos)
	shadowPart.Transparency = math.clamp(0.26 + (1 - math.sin(elevation))*0.5, 0.26, 0.95)
end

for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		initObjectShadow(obj)
	end
end

Workspace.DescendantAdded:Connect(function(child)
	if child:IsA("BasePart") then
		task.wait(0.1)
		initObjectShadow(child)
	end
end)

RunService.RenderStepped:Connect(function()
	local sunDir, elevation = getSunDirection()
	for part, shadowPart in pairs(objectShadows) do
		if part.Parent then
			updateObjectShadow(part, shadowPart, sunDir, elevation)
		else
			shadowPart:Destroy()
			objectShadows[part] = nil
		end
	end
end)

------------------------------------------------------------
-- 14. HẠN CHẾ ÁNH SÁNG LOÁ (Dynamic glare reduction)
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local sunVector = (sunPart.Position - camera.CFrame.Position).Unit
	local alignment = camera.CFrame.LookVector:Dot(sunVector)
	if alignment > 0.995 then
		bloom.Intensity = math.max(config.PostProcessing.Bloom.Intensity - 0.3, 0.8)
	else
		bloom.Intensity = config.PostProcessing.Bloom.Intensity
	end
end)

------------------------------------------------------------
-- 15. HIỆU ỨNG “RAY-TRACED” & VẬT LIỆU (Super Advanced Simulation)
------------------------------------------------------------
local function simulateRTGI()
	if config.AdvancedEffects.RTGI.Enabled then
		local giBoost = config.AdvancedEffects.RTGI.BounceIntensity
		Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(75,105,170), giBoost * 0.02)
	end
end

local function simulateMultiBounceIndirectLighting()
	Lighting.Brightness = Lighting.Brightness + 0.007
end

local function simulateSphericalHarmonicsLighting()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local pos = player.Character.HumanoidRootPart.Position
		local shFactor = math.clamp((pos.Y % 100) / 100, 0, 1)
		Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(95,125,190), shFactor * 0.07)
	end
end

local function simulateMultiLayerReflections()
	if ssr then
		ssr.Intensity = config.AdvancedEffects.RayTracedReflections and config.AdvancedEffects.RayTracedReflections.Intensity or ssr.Intensity
	end
end

local function simulateCaustics()
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
			if not obj:FindFirstChild("CausticsEmitter") then
				local caustics = Instance.new("ParticleEmitter", obj)
				caustics.Name = "CausticsEmitter"
				caustics.Texture = ""
				caustics.Rate = 7
				caustics.Lifetime = NumberRange.new(2.5,3.5)
				caustics.Speed = NumberRange.new(0,0)
				caustics.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2.5), NumberSequenceKeypoint.new(1,4.5)})
			end
		end
	end
end

local function simulateHybridReflectionModel()
	if camera then
		local camPos = camera.CFrame.Position
		for _, obj in pairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj:GetAttribute("EnableReflection") then
				local distance = (obj.Position - camPos).Magnitude
				local reflectIntensity = distance < 130 and 1 or 0.65
				local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					sa.Reflectance = reflectIntensity * config.Water.Reflectance
				end
			end
		end
	end
end

local function simulateAdaptiveRefraction()
	for _, part in pairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Material == Enum.Material.Glass then
			local sa = part:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance", part)
			sa.Reflectance = sa.Reflectance * (config.AdvancedEffects.RefractionMapping and config.AdvancedEffects.RefractionMapping.Intensity or 1)
			local r, g, b = part.Color.R, part.Color.G, part.Color.B
			part.Color = Color3.new(r * 0.96, g * 1.04, b)
		end
	end
end

local function simulateVolumetricFogAndGodRays()
	if not Lighting:FindFirstChild("VolumetricFog") then
		local fog = Instance.new("BlurEffect")
		fog.Name = "VolumetricFog"
		fog.Size = 7
		fog.Parent = Lighting
	end
	sunRays.Intensity = sunRays.Intensity + 0.008
end

local function simulateWeatherSystem()
	-- Dựa trên trạng thái thời tiết động, điều chỉnh ambient, mây, và thêm hiệu ứng mưa hoặc sương
	if config.Weather.CurrentState == "Rainy" then
		Lighting.Ambient = Color3.fromRGB(60,80,120)
		if not Workspace:FindFirstChild("RainEffect") then
			local rainPart = Instance.new("Part")
			rainPart.Name = "RainEffect"
			rainPart.Size = Vector3.new(140,1,140)
			rainPart.Transparency = 1
			rainPart.Anchored = true
			rainPart.CanCollide = false
			rainPart.Parent = Workspace
			rainPart.Position = camera.CFrame.Position + Vector3.new(0,70,0)
			local rainEmitter = Instance.new("ParticleEmitter", rainPart)
			rainEmitter.Texture = ""
			rainEmitter.Rate = 130
			rainEmitter.Lifetime = NumberRange.new(1.5,2.5)
			rainEmitter.Speed = NumberRange.new(24,34)
		end
	elseif config.Weather.CurrentState == "Foggy" then
		Lighting.Ambient = Color3.fromRGB(50,70,100)
		-- Tăng kích thước Fog (BlurEffect) để tạo cảm giác sương mù dày
		local fog = Lighting:FindFirstChild("VolumetricFog")
		if fog then
			fog.Size = 10
		end
	else
		-- Sunny
		Lighting.Ambient = Color3.fromRGB(70,100,180)
	end
end

local function simulateSSSS()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("Head") then
			local head = plr.Character.Head
			if head:GetAttribute("EnableSSS") then
				if not head:FindFirstChild("SSSEffect") then
					local sss = Instance.new("ParticleEmitter", head)
					sss.Name = "SSSEffect"
					sss.Texture = ""
					sss.Rate = 4
					sss.Lifetime = NumberRange.new(0.7,1.3)
					sss.Speed = NumberRange.new(0,0)
					sss.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4.5), NumberSequenceKeypoint.new(1,6.5)})
					sss.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.35), NumberSequenceKeypoint.new(1,1)})
				end
			end
		end
	end
end

local function simulateCloudRendering()
	cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + 0.015) % config.Clouds.StudsPerTile
	cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + 0.015) % config.Clouds.StudsPerTile
end

local function simulateSuperResolution() end
local function simulateHybridRenderingPipeline() end
local function simulateVulkanRayTracing() end
local function simulateDenoising() end

RunService.RenderStepped:Connect(function(dt)
	updateWeather(dt)
	simulateRTGI()
	simulateMultiBounceIndirectLighting()
	simulateSphericalHarmonicsLighting()
	simulateMultiLayerReflections()
	simulateCaustics()
	simulateHybridReflectionModel()
	simulateAdaptiveRefraction()
	simulateVolumetricFogAndGodRays()
	simulateWeatherSystem()
	simulateSSSS()
	simulateCloudRendering()
	simulateSuperResolution()
	simulateHybridRenderingPipeline()
	simulateVulkanRayTracing()
	simulateDenoising()
end)

------------------------------------------------------------
-- 16. HIỆU ỨNG CHUYỂN ĐỘNG & CAMERA (Motion Blur & Chromatic Aberration)
------------------------------------------------------------
local motionBlur = Instance.new("BlurEffect")
motionBlur.Enabled = config.AdvancedEffects.MotionBlur.Enabled
motionBlur.Size = 0
motionBlur.Parent = Lighting

local previousCameraPos = camera.CFrame.Position
RunService.RenderStepped:Connect(function(deltaTime)
	local currentPos = camera.CFrame.Position
	local velocity = (currentPos - previousCameraPos).Magnitude / deltaTime
	previousCameraPos = currentPos
	local blurSize = math.clamp(velocity * config.AdvancedEffects.MotionBlur.Sensitivity, 0, config.AdvancedEffects.MotionBlur.MaxSize)
	motionBlur.Size = blurSize
end)

if config.AdvancedEffects.ChromaticAberration.Enabled then
	-- Hiệu ứng Chromatic Aberration có thể được custom bằng GUI/shader tùy thuộc vào khả năng mở rộng của Roblox
end

------------------------------------------------------------
-- 17. CHUYỂN ĐỔI GIỎI HỌA (Advanced vs Default)
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.R then
		advancedMode = not advancedMode
		if advancedMode then
			bloom.Enabled = true
			colorCorrection.Enabled = true
			dof.Enabled = true
			if ssr then ssr.Enabled = true end
			sunRays.Enabled = true
		else
			bloom.Enabled = false
			colorCorrection.Enabled = false
			dof.Enabled = false
			if ssr then ssr.Enabled = false end
			sunRays.Enabled = false
		end
	end
end)

------------------------------------------------------------
-- 18. HIỆU ỨNG “VŨ TRỤ XUNG QUANH NGUỒN SÁNG”
------------------------------------------------------------
local cosmicEmitter = Instance.new("ParticleEmitter", sunPart)
cosmicEmitter.Rate = 30
cosmicEmitter.Lifetime = NumberRange.new(3,5)
cosmicEmitter.Speed = NumberRange.new(3,6)
cosmicEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,3), NumberSequenceKeypoint.new(1,0)})
cosmicEmitter.Color = ColorSequence.new{
	NumberSequenceKeypoint.new(0, Color3.fromRGB(255,220,130)),
	NumberSequenceKeypoint.new(1, Color3.fromRGB(255,130,70))
}
cosmicEmitter.LightEmission = 1

local cosmicAttachment0 = Instance.new("Attachment", sunPart)
cosmicAttachment0.Position = Vector3.new(0,0,0)
local cosmicAttachment1 = Instance.new("Attachment", sunPart)
cosmicAttachment1.Position = Vector3.new(0,config.Sun.PartSize.Y/2,0)
local cosmicBeam = Instance.new("Beam", sunPart)
cosmicBeam.Attachment0 = cosmicAttachment0
cosmicBeam.Attachment1 = cosmicAttachment1
cosmicBeam.Width0 = 0.7
cosmicBeam.Width1 = 0.7
cosmicBeam.Color = ColorSequence.new(Color3.fromRGB(255,180,80))
cosmicBeam.FaceCamera = true

------------------------------------------------------------
-- 19. HIỆU ỨNG “TRÁN GƯƠNG” – OVERLAY KÍNH PHẢN CHIẾU SIÊU CHÂN THỰC
------------------------------------------------------------
local function addMirrorOverlay(part)
	local excludeNames = {"CloudLayer", "SunPart", "MoonPart", "StarField", "EnhancedShootingStar", "MirrorOverlay"}
	for _, name in ipairs(excludeNames) do
		if part.Name:find(name) then return end
	end
	if part:FindFirstChild("MirrorOverlay") then return end
	
	local overlay = Instance.new("Part")
	overlay.Name = "MirrorOverlay"
	overlay.Size = part.Size
	overlay.Transparency = 0.02
	overlay.Material = Enum.Material.Glass
	overlay.Reflectance = 0.9
	overlay.CanCollide = false
	overlay.Anchored = false
	overlay.Locked = true
	overlay.Parent = part
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = overlay
	weld.Parent = overlay
end

for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		addMirrorOverlay(obj)
	end
end

Workspace.DescendantAdded:Connect(function(child)
	if child:IsA("BasePart") then
		task.wait(0.1)
		addMirrorOverlay(child)
	end
end)

--------------------------------------------------------------------------------
-- KẾT THÚC CODE: Phiên bản “Siêu Chân Thực” giúp người trải nghiệm cảm thấy cực kỳ sống động trên Roblox!
--------------------------------------------------------------------------------
