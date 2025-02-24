------------------------------------------------------------
-- RTX-like Advanced Effects – Final Upgraded Version
------------------------------------------------------------

-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

------------------------------------------------------------
-- Configuration Table
------------------------------------------------------------
local config = {
    PostProcessing = {
        Bloom = { Intensity = 1.2, Size = 40, Threshold = 2 },
        ColorCorrection = { 
            Brightness = 0.15, 
            Contrast = 0.35, 
            Saturation = 0.1, 
            TintColor = Color3.fromRGB(155,195,230)  -- hơi ấm, giảm tint xanh
        },
        DepthOfField = { FarIntensity = 0.3, FocusDistance = 20, InFocusRadius = 10, NearIntensity = 0.3 },
        SSR = { Intensity = 0.8, Reflectance = 0.7 },
        SunRays = { Intensity = 0.7, Spread = 0.2 }
    },
    RtxUpgrade = {
        LightBleedReduction = 0.5,
        DeviceBrightnessFactor = 0.8,
    },
    Water = {
        Reflectance = 0.9,  -- tăng phản chiếu nước
        TextureSpeed = { U = 0.1, V = 0.05 },
        Mist = { Rate = 2, Lifetime = {3,5}, Speed = {0.5,1}, Size = 5, Color = Color3.fromRGB(200,200,255), Transparency = 0.5 },
        WaveAmplitude = 0.05,
        WaveFrequency = 0.5
    },
    ReflectionProbe = { Size = Vector3.new(70,70,70) },
    GlobalLighting = { DayBrightness = 2.5, NightBrightness = 1.5, MaxBrightness = 8 },
    Shadow = {
        BaseSize = 6,
        Offsets = { offsetDistance = 3 },
        Smoothing = 0.2,
        Layers = {
            { Name = "ShadowCore", Multiplier = 1, Transparency = 0.1 },
            { Name = "ShadowBlur1", Multiplier = 1.1, Transparency = 0.3, ExtraOffset = Vector3.new(0.2,0,0.2) },
            { Name = "ShadowBlur2", Multiplier = 1.2, Transparency = 0.5, ExtraOffset = Vector3.new(-0.2,0,-0.2) }
        }
    },
    PlayerLight = { Range = { Outdoors = 500, Indoors = 250 }, BaseBrightness = 1.5, Color = Color3.fromRGB(255,230,200) },
    Sun = {
        PartSize = Vector3.new(60,60,60),
        PartColor = Color3.fromRGB(255,220,100),
        Light = { Range = 1200, Brightness = 8 },
        Billboard = { Size = UDim2.new(4,0,4,0), FlareSize = UDim2.new(5,0,5,0), ImageTransparencyFocused = 0.15, ImageTransparencyNormal = 0.5 },
        OcclusionFactor = 0.2
    },
    Moon = {
        PartSize = Vector3.new(50,50,50),
        PartColor = Color3.fromRGB(200,220,255),
        Light = { Range = 1000, Brightness = 3 },
        Billboard = { Size = UDim2.new(3.5,0,3.5,0), ImageTransparency = 0.3 }
    },
    ShootingStar = {
        Size = Vector3.new(4,4,4),
        FinalSize = Vector3.new(0.5,0.5,0.5),
        TweenTime = 2.5,
        SpawnInterval = { Min = 10, Max = 30 },
        Colors = {
            Color3.fromRGB(255,150,150),
            Color3.fromRGB(150,255,150),
            Color3.fromRGB(150,150,255),
            Color3.fromRGB(255,255,150),
            Color3.fromRGB(255,150,255),
            Color3.fromRGB(150,255,255)
        }
    },
    DetailQuality = {
        Radius = 200,
        HighMaterial = Enum.Material.Metal,
        Reflectance = 1,  -- tăng reflectance cho vật liệu
        UpdateInterval = 5
    },
    EnvironmentCheck = { UpdateInterval = 3 },
    AdvancedEffects = {
        RTGI = { Enabled = true, BounceIntensity = 0.2 },
        RayTracedReflections = { Enabled = true, Intensity = 0.8 },
        RefractionMapping = { Enabled = true, Intensity = 0.5 },
        NormalMapping = { Enabled = true, NormalMapAsset = "rbxassetid://15121734759" },
        POM = { Enabled = true, ParallaxMapAsset = "rbxassetid://YourParallaxMapAsset", ParallaxScale = 0.05 },
        SSS = { Enabled = true, Intensity = 0.5 },
        MotionBlur = { Enabled = true, MaxSize = 10, Sensitivity = 0.1 },
        ChromaticAberration = { Enabled = true, Intensity = 0.1 }
    }
}

local advancedMode = true

------------------------------------------------------------
-- ENVIRONMENT: AMBIENT, FOG & COLOR CORRECTION
------------------------------------------------------------
Lighting.Ambient = Color3.fromRGB(120,150,170)
-- Fog thay đổi màu liên tục theo tham số nhỏ (sử dụng sin)
RunService.RenderStepped:Connect(function()
	local t = tick()
	-- Màu fog dao động từ (185,205,255) đến (195,215,255) ban ngày
	local r = math.floor(190 + 5 * math.sin(t * 0.1))
	local g = math.floor(210 + 5 * math.sin(t * 0.1 + 1))
	local b = math.floor(255 + 5 * math.sin(t * 0.1 + 2))
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		Lighting.FogColor = Color3.fromRGB(r, g, b)
		Lighting.FogStart = 50
		Lighting.FogEnd = 300
	else
		Lighting.FogColor = Color3.fromRGB(20,20,40)
		Lighting.FogStart = 30
		Lighting.FogEnd = 150
	end
end)

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = config.PostProcessing.ColorCorrection.Brightness
colorCorrection.Contrast = config.PostProcessing.ColorCorrection.Contrast
colorCorrection.Saturation = config.PostProcessing.ColorCorrection.Saturation
colorCorrection.TintColor = config.PostProcessing.ColorCorrection.TintColor
colorCorrection.Parent = Lighting

------------------------------------------------------------
-- POST-PROCESSING: Bloom, DOF, SSR, SunRays
------------------------------------------------------------
local bloom = Instance.new("BloomEffect")
bloom.Intensity = config.PostProcessing.Bloom.Intensity
bloom.Size = config.PostProcessing.Bloom.Size * config.RtxUpgrade.LightBleedReduction
bloom.Threshold = config.PostProcessing.Bloom.Threshold
bloom.Parent = Lighting

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
	end
end

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = config.PostProcessing.SunRays.Intensity
sunRays.Spread = config.PostProcessing.SunRays.Spread
sunRays.Parent = Lighting

------------------------------------------------------------
-- NGUỒN SÁNG: GroundLight và MiniLights quanh người dùng
------------------------------------------------------------
local function setupGroundLight(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and not hrp:FindFirstChild("GroundLight") then
		local groundLight = Instance.new("PointLight")
		groundLight.Name = "GroundLight"
		groundLight.Brightness = 3
		groundLight.Range = 50
		groundLight.Color = Color3.fromRGB(255,240,200)
		groundLight.Parent = hrp
	end
	-- Tạo một số mini-lights ngẫu nhiên quanh người dùng, với độ chói thấp và màu trong suốt
	if hrp and not hrp:FindFirstChild("MiniGroundLights") then
		local container = Instance.new("Folder", hrp)
		container.Name = "MiniGroundLights"
		for i = 1, 5 do
			local miniLight = Instance.new("PointLight")
			miniLight.Name = "MiniGroundLight_" .. i
			miniLight.Brightness = math.random(3, 4) / 10  -- rất nhẹ
			miniLight.Range = 8
			miniLight.Color = Color3.fromRGB(255,250,240)  -- màu ấm, nhẹ
			miniLight.Parent = container
		end
		task.spawn(function()
			while hrp.Parent do
				for _, ml in ipairs(container:GetChildren()) do
					ml.CFrame = hrp.CFrame * CFrame.new(math.random(-10,10)/10, -1, math.random(-10,10)/10)
				end
				task.wait(0.5)
			end
		end)
	end
end

------------------------------------------------------------
-- VIGNETTE EFFECT (giúp các vùng xung quanh trở nên tối hơn)
------------------------------------------------------------
local function setupVignette()
	if player:FindFirstChild("PlayerGui") and not player.PlayerGui:FindFirstChild("VignetteGui") then
		local vignetteGui = Instance.new("ScreenGui")
		vignetteGui.Name = "VignetteGui"
		vignetteGui.ResetOnSpawn = false
		vignetteGui.Parent = player.PlayerGui
		
		local vignette = Instance.new("ImageLabel", vignetteGui)
		vignette.Size = UDim2.new(1,0,1,0)
		vignette.BackgroundTransparency = 1
		vignette.Image = "rbxassetid://YourVignetteTexture"  -- Asset radial gradient cần có (phải thay bằng asset của bạn)
		vignette.ImageTransparency = 0.5
	end
end
setupVignette()

------------------------------------------------------------
-- CHARACTER SETUP: Gắn GroundLight, MiniLights, và Halo cho người chơi
------------------------------------------------------------
local function onCharacterAdded(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	setupGroundLight(char)
	if not char:FindFirstChild("UserHalo") then
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "UserHalo"
		halo.Texture = "rbxassetid://YourHaloTexture"  -- Thay asset của bạn
		halo.Rate = 5
		halo.Lifetime = NumberRange.new(1,2)
		halo.Speed = NumberRange.new(0,0)
		halo.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4), NumberSequenceKeypoint.new(1,8)})
		halo.LightEmission = 1
		halo.Parent = char.Head
	end
	playerLight.Parent = hrp
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

------------------------------------------------------------
-- COSMIC PARTICLE EFFECTS (xung quanh Mặt Trời)
------------------------------------------------------------
local function setupCosmicParticles()
	if sunPart and not sunPart:FindFirstChild("CosmicParticles") then
		local cosmicEmitter = Instance.new("ParticleEmitter")
		cosmicEmitter.Name = "CosmicParticles"
		cosmicEmitter.Texture = "rbxassetid://YourCosmicParticleTexture"  -- Thay asset của bạn
		cosmicEmitter.Rate = 10
		cosmicEmitter.Lifetime = NumberRange.new(2,3)
		cosmicEmitter.Speed = NumberRange.new(0,0)
		cosmicEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,2)})
		cosmicEmitter.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,255))
		cosmicEmitter.Parent = sunPart
	end
end

------------------------------------------------------------
-- MIRROR OVERLAY: Áp dụng lớp “gương” mỏng cho tất cả vật thể
------------------------------------------------------------
local function applyMirrorOverlay(part)
	local excludeList = {"SunPart", "MoonPart", "EnhancedShootingStar", "MirrorOverlay"}
	for _, str in ipairs(excludeList) do
		if part.Name:find(str) then return end
	end
	if not part:FindFirstChild("MirrorOverlay") then
		local mirror = Instance.new("SurfaceAppearance")
		mirror.Name = "MirrorOverlay"
		mirror.Reflectance = 0.95
		mirror.Parent = part
	end
end

for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		applyMirrorOverlay(obj)
	end
end
Workspace.DescendantAdded:Connect(function(child)
	if child:IsA("BasePart") then
		task.wait(0.1)
		applyMirrorOverlay(child)
	end
end)

------------------------------------------------------------
-- (Các chức năng sky, star, clouds đã bị loại bỏ)
------------------------------------------------------------

------------------------------------------------------------
-- HIỆU ỨNG MẶT NƯỚC (vẫn giữ nguyên nhưng tăng reflectance)
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
			local mist = Instance.new("ParticleEmitter")
			mist.Name = "WaterMist"
			mist.Parent = obj
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
-- REFLECTION PROBE (như cũ)
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
-- GLOBAL LIGHTING & ADJUSTMENT (với hạn chế chói)
------------------------------------------------------------
local function updateGlobalLighting()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	local quality = settings().RenderingQualityLevel or 1
	if quality < 2 then
		baseBrightness = baseBrightness * config.RtxUpgrade.DeviceBrightnessFactor
	end
	Lighting.Brightness = math.clamp(baseBrightness, 0, config.GlobalLighting.MaxBrightness)
end

local function adjustGlobalBrightness()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	local quality = settings().RenderingQualityLevel or 1
	if quality < 2 then
		baseBrightness = baseBrightness * config.RtxUpgrade.DeviceBrightnessFactor
	end
	if Lighting.Brightness > baseBrightness then
		Lighting.Brightness = Lighting.Brightness - (Lighting.Brightness - baseBrightness)*0.05
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
-- ADAPTIVE SHADOWS (với hiệu ứng bóng cải tiến)
------------------------------------------------------------
local shadowLayers = {}
local function createShadowLayer(layerConfig)
	local part = Instance.new("Part")
	part.Name = layerConfig.Name
	part.Size = Vector3.new(config.Shadow.BaseSize, 0.2, config.Shadow.BaseSize)
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
		local sunDir = Vector3.new(math.cos(azimuth)*math.cos(elevation), math.sin(elevation), math.sin(azimuth)*math.cos(elevation))
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
		local rayDirection = -sunDir * 100
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
			shadowPosition = rayResult.Position + rayResult.Normal * 0.1
			groundNormal = rayResult.Normal
		else
			local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z).Unit
			shadowPosition = hrp.Position - Vector3.new(0, hrp.Size.Y/2, 0) + shadowDir * config.Shadow.Offsets.offsetDistance
			groundNormal = Vector3.new(0,1,0)
		end
		local lengthFactor = 1 / math.max(math.sin(elevation), 0.2)
		lengthFactor = math.clamp(lengthFactor, 1, 3)
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
			shadow.Size = Vector3.new(baseSize * multiplier, 0.2, baseSize * multiplier)
			shadow.Transparency = math.clamp(0.1 + (1 - math.sin(elevation))*0.5, 0.1, 0.7)
			shadow.CFrame = targetCFrame * CFrame.new(extraOffset)
		end
	end
end
RunService.RenderStepped:Connect(updateAdvancedShadows)

------------------------------------------------------------
-- LIGHTING & HALO AROUND PLAYER
------------------------------------------------------------
local playerLight = Instance.new("PointLight")
playerLight.Name = "PlayerLight"
playerLight.Range = config.PlayerLight.Range.Outdoors
playerLight.Brightness = config.PlayerLight.BaseBrightness
playerLight.Color = config.PlayerLight.Color
playerLight.Shadows = true

local function onCharacterAdded(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	setupGroundLight(char)
	playerLight.Parent = hrp
	if not char:FindFirstChild("UserHalo") then
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "UserHalo"
		halo.Texture = "rbxassetid://YourHaloTexture"  -- Thay asset của bạn
		halo.Rate = 5
		halo.Lifetime = NumberRange.new(1,2)
		halo.Speed = NumberRange.new(0,0)
		halo.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4), NumberSequenceKeypoint.new(1,8)})
		halo.LightEmission = 1
		halo.Parent = char.Head
	end
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

local baseTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - baseTime
	playerLight.Brightness = config.PlayerLight.BaseBrightness + 0.3 * math.sin(t * 0.5)
end)

------------------------------------------------------------
-- MẶT TRỜI & MẶT TRĂNG
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

local sunBillboard = Instance.new("BillboardGui")
sunBillboard.Adornee = sunPart
sunBillboard.Size = config.Sun.Billboard.Size
sunBillboard.AlwaysOnTop = true
sunBillboard.Parent = sunPart

local sunImage = Instance.new("ImageLabel")
sunImage.Size = UDim2.new(1,0,1,0)
sunImage.BackgroundTransparency = 1
sunImage.Image = "rbxassetid://YourSunCoronaImage"  -- Thay asset của bạn
sunImage.ImageTransparency = config.Sun.Billboard.ImageTransparencyNormal
sunImage.Parent = sunBillboard

local sunFlareEmitter = Instance.new("ParticleEmitter")
sunFlareEmitter.Rate = 2
sunFlareEmitter.Lifetime = NumberRange.new(1,2)
sunFlareEmitter.Speed = NumberRange.new(0,0)
sunFlareEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,5), NumberSequenceKeypoint.new(1,10)})
sunFlareEmitter.Color = ColorSequence.new(config.Sun.PartColor)
sunFlareEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)})
sunFlareEmitter.LightEmission = 1
sunFlareEmitter.Parent = sunPart

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

local moonBillboard = Instance.new("BillboardGui")
moonBillboard.Adornee = moonPart
moonBillboard.Size = config.Moon.Billboard.Size
moonBillboard.AlwaysOnTop = true
moonBillboard.Parent = moonPart

local moonImage = Instance.new("ImageLabel")
moonImage.Size = UDim2.new(1,0,1,0)
moonImage.BackgroundTransparency = 1
moonImage.Image = "rbxassetid://YourMoonCoronaImage"  -- Thay asset của bạn
moonImage.ImageTransparency = config.Moon.Billboard.ImageTransparency
moonImage.Parent = moonBillboard

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
	if alignment > 0.95 then
		sunImage.ImageTransparency = config.Sun.Billboard.ImageTransparencyFocused
		sunBillboard.Size = config.Sun.Billboard.FlareSize
	else
		sunImage.ImageTransparency = config.Sun.Billboard.ImageTransparencyNormal
		sunBillboard.Size = config.Sun.Billboard.Size
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
			sunLight.Brightness = config.Sun.Light.Brightness * 0.2
		else
			sunLight.Brightness = config.Sun.Light.Brightness
		end
	end
end
RunService.RenderStepped:Connect(updateSunOcclusion)

------------------------------------------------------------
-- ENHANCED SHOOTING STARS
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
	local trail1 = Instance.new("Trail")
	trail1.Attachment0 = att0
	trail1.Attachment1 = att1
	trail1.Lifetime = 0.6
	trail1.LightEmission = 1
	trail1.Color = ColorSequence.new(star.Color)
	trail1.WidthScale = 1.5
	trail1.Parent = star
	
	local att2 = Instance.new("Attachment", star)
	local att3 = Instance.new("Attachment", star)
	local trail2 = Instance.new("Trail")
	trail2.Attachment0 = att2
	trail2.Attachment1 = att3
	trail2.Lifetime = 0.8
	trail2.LightEmission = 1
	trail2.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, star.Color),
		ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
	})
	trail2.WidthScale = 1
	trail2.Parent = star
	
	att0.Position = Vector3.new(0,0,0)
	att1.Position = Vector3.new(0,0,0)
	att2.Position = Vector3.new(0,0,0)
	att3.Position = Vector3.new(0,0,0)
	
	local startPos = camera.CFrame.Position + Vector3.new(math.random(-600,600), math.random(400,700), math.random(-600,600))
	local direction = Vector3.new(math.random(-1,1), -math.random(1,3), math.random(-1,1)).Unit
	star.Position = startPos
	
	local tweenInfo = TweenInfo.new(config.ShootingStar.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Position = startPos + direction * 1000,
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
-- DETAIL QUALITY: Cải tiến vật liệu (nếu có "EnhancedMaterial")
------------------------------------------------------------
local function updateDetailQuality()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local regionSize = Vector3.new(config.DetailQuality.Radius, config.DetailQuality.Radius, config.DetailQuality.Radius)
		local parts = Workspace:GetPartBoundsInBox(hrp.CFrame, regionSize, {player.Character})
		for _, part in ipairs(parts) do
			if part:GetAttribute("EnhancedMaterial") then
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
-- ENVIRONMENT & AMBIENT OCCLUSION
------------------------------------------------------------
local function updateEnvironmentLighting()
	if player.Character and player.Character:FindFirstChild("Head") then
		local head = player.Character.Head
		local origin = head.Position
		local direction = Vector3.new(0,50,0)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {player.Character}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		local result = Workspace:Raycast(origin, direction, rayParams)
		if result then
			Lighting.Brightness = 0.8
			Lighting.Ambient = Color3.fromRGB(90,120,140)
			playerLight.Range = config.PlayerLight.Range.Indoors
		else
			local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
			Lighting.Brightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
			Lighting.Ambient = Color3.fromRGB(120,150,170)
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
-- ENHANCED OBJECT SHADOWS
------------------------------------------------------------
local objectShadows = {}
local function initObjectShadow(part)
	local excludeNames = { "SunPart", "MoonPart", "EnhancedShootingStar" }
	for _, name in ipairs(excludeNames) do
		if part.Name:find(name) then return end
	end
	if objectShadows[part] then return end
	local shadowPart = Instance.new("Part")
	shadowPart.Name = "EnhancedShadow"
	shadowPart.Size = Vector3.new(part.Size.X, 0.1, part.Size.Z)
	shadowPart.Anchored = true
	shadowPart.CanCollide = false
	shadowPart.Material = Enum.Material.SmoothPlastic
	shadowPart.Color = Color3.new(0,0,0)
	shadowPart.Transparency = 0.3
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
	local rayResult = Workspace:Raycast(origin, -sunDir * 100, rayParams)
	local hitPos
	if rayResult then
		hitPos = rayResult.Position + Vector3.new(0,0.05,0)
	else
		hitPos = part.Position - Vector3.new(0, part.Size.Y/2 + 0.1, 0)
	end
	local factor = 1 / math.max(math.sin(elevation), 0.2)
	factor = math.clamp(factor, 1, 3)
	shadowPart.Size = Vector3.new(part.Size.X * factor, 0.1, part.Size.Z * factor)
	shadowPart.CFrame = CFrame.new(hitPos)
	shadowPart.Transparency = math.clamp(0.1 + (1 - math.sin(elevation))*0.5, 0.1, 0.7)
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
-- HẠN CHẾ ÁNH SÁNG LOÁ
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local sunVector = (sunPart.Position - camera.CFrame.Position).Unit
	local alignment = camera.CFrame.LookVector:Dot(sunVector)
	if alignment > 0.98 then
		bloom.Intensity = math.max(config.PostProcessing.Bloom.Intensity - 0.2, 0.8)
	else
		bloom.Intensity = config.PostProcessing.Bloom.Intensity
	end
end)

------------------------------------------------------------
-- SIMULATION EFFECTS (RTGI, Reflections, Caustics, etc.)
------------------------------------------------------------
local function simulateRTGI()
	if config.AdvancedEffects.RTGI.Enabled then
		local giBoost = config.AdvancedEffects.RTGI.BounceIntensity
		Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(200,220,255), giBoost * 0.01)
	end
end

local function simulateMultiBounceIndirectLighting()
	Lighting.Brightness = Lighting.Brightness + 0.005
end

local function simulateSphericalHarmonicsLighting()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local pos = player.Character.HumanoidRootPart.Position
		local shFactor = math.clamp((pos.Y % 100) / 100, 0, 1)
		Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(220,230,255), shFactor * 0.05)
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
				local caustics = Instance.new("ParticleEmitter")
				caustics.Name = "CausticsEmitter"
				caustics.Texture = "rbxassetid://YourCausticsTexture"  -- Thay asset của bạn
				caustics.Rate = 5
				caustics.Lifetime = NumberRange.new(2,3)
				caustics.Speed = NumberRange.new(0,0)
				caustics.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,2), NumberSequenceKeypoint.new(1,4)})
				caustics.Parent = obj
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
				local reflectIntensity = distance < 100 and 1 or 0.5
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
			part.Color = Color3.new(r * 0.98, g * 1.02, b)
		end
	end
end

local function simulateVolumetricFogAndGodRays()
	if not Lighting:FindFirstChild("VolumetricFog") then
		local fog = Instance.new("BlurEffect")
		fog.Name = "VolumetricFog"
		fog.Size = 5
		fog.Parent = Lighting
	end
	sunRays.Intensity = sunRays.Intensity + 0.005
end

local function simulateWeatherSystem()
	local isRaining = false
	if isRaining then
		Lighting.Ambient = Color3.fromRGB(150,150,170)
		if not Workspace:FindFirstChild("RainEffect") then
			local rainPart = Instance.new("Part")
			rainPart.Name = "RainEffect"
			rainPart.Size = Vector3.new(100,1,100)
			rainPart.Transparency = 1
			rainPart.Anchored = true
			rainPart.CanCollide = false
			rainPart.Parent = Workspace
			rainPart.Position = camera.CFrame.Position + Vector3.new(0,50,0)
			local rainEmitter = Instance.new("ParticleEmitter", rainPart)
			rainEmitter.Texture = "rbxassetid://YourRainTexture"
			rainEmitter.Rate = 100
			rainEmitter.Lifetime = NumberRange.new(1,2)
			rainEmitter.Speed = NumberRange.new(20,30)
		end
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
					sss.Texture = "rbxassetid://YourSSSTexture"
					sss.Rate = 2
					sss.Lifetime = NumberRange.new(0.5,1)
					sss.Speed = NumberRange.new(0,0)
					sss.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,4), NumberSequenceKeypoint.new(1,6)})
					sss.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)})
				end
			end
		end
	end
end

local function simulateCloudRendering() end
local function simulateSuperResolution() end
local function simulateHybridRenderingPipeline() end
local function simulateVulkanRayTracing() end
local function simulateDenoising() end

RunService.RenderStepped:Connect(function(deltaTime)
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
	setupCosmicParticles()
end)

------------------------------------------------------------
-- MOTION BLUR & CHROMATIC ABERRATION
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
	-- Placeholder: Implement custom chromatic aberration using GUI layers or post-processing shader if available.
end

------------------------------------------------------------
-- SWITCH GRAPHICS MODE (Advanced vs Default)
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
