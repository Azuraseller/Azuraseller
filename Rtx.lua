------------------------------------------------------------
-- RTX-like Advanced Effects - Nâng cấp RTX (với các cải tiến mới)
------------------------------------------------------------
--[[
  CÁC CẢI TIẾN:
  1. Giảm thiểu hiệu ứng lan của ánh sáng bằng cách giảm bloom.Size.
  2. Tự động điều chỉnh độ chói theo môi trường & chất lượng thiết bị (nếu Brightness vượt quá giá trị gốc sẽ được hạ dần).
  3. Môi trường có sắc xanh dương nhạt nhẹ (Lighting.Ambient và TintColor).
  4. Hiệu ứng che ánh sáng: raycasting kiểm tra vật cản làm giảm Brightness của ánh sáng nguồn.
  5. Khi ánh sáng bị che bởi vật liệu, ánh sáng của bóng sẽ nhỏ hơn ánh sáng ngoài.
  
  Lưu ý: Các chức năng ban đầu (clouds, skybox, water, shadows, shooting stars, v.v.) vẫn được bảo toàn.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Bảng cấu hình hiệu ứng
local config = {
	PostProcessing = {
		Bloom = { Intensity = 1.2, Size = 40, Threshold = 2 },
		ColorCorrection = { Brightness = 0.15, Contrast = 0.25, Saturation = 0.1, TintColor = Color3.fromRGB(180,210,255) }, -- tint xanh dương nhạt
		DepthOfField = { FarIntensity = 0.3, FocusDistance = 20, InFocusRadius = 10, NearIntensity = 0.3 },
		SSR = { Intensity = 0.8, Reflectance = 0.7 },
		SunRays = { Intensity = 0.35, Spread = 0.2 }
	},
	-- Các tham số mới để nâng cấp RTX:
	RtxUpgrade = {
		LightBleedReduction = 0.5,        -- hệ số giảm bloom.Size (giảm lan của ánh sáng)
		DeviceBrightnessFactor = 0.8,       -- nếu thiết bị kém, giảm độ chói
	},
	Clouds = {
		PartTransparency = { Day = 0.7, Night = 1 },
		OffsetSpeed = { U = 0.07, V = 0.03 },
		StudsPerTile = 500
	},
	Skybox = {
		Day = {
			SkyboxBk = "rbxassetid://1234567890",
			SkyboxDn = "rbxassetid://1234567891",
			SkyboxFt = "rbxassetid://1234567892",
			SkyboxLf = "rbxassetid://1234567893",
			SkyboxRt = "rbxassetid://1234567894",
			SkyboxUp = "rbxassetid://1234567895"
		},
		Night = {
			SkyboxBk = "rbxassetid://2234567890",
			SkyboxDn = "rbxassetid://2234567891",
			SkyboxFt = "rbxassetid://2234567892",
			SkyboxLf = "rbxassetid://2234567893",
			SkyboxRt = "rbxassetid://2234567894",
			SkyboxUp = "rbxassetid://2234567895"
		}
	},
	Water = {
		Reflectance = 0.4,
		TextureSpeed = { U = 0.1, V = 0.05 },
		Mist = { Rate = 2, Lifetime = {3,5}, Speed = {0.5,1}, Size = 5, Color = Color3.fromRGB(200,200,255), Transparency = 0.5 }
	},
	ReflectionProbe = { Size = Vector3.new(70,70,70) },
	GlobalLighting = { DayBrightness = 2.5, NightBrightness = 1.5 },
	Shadow = {
		BaseSize = 6,
		Offsets = { offsetDistance = 3 },
		Smoothing = 0.2,  -- nội suy chuyển động bóng mượt
		Layers = {
			{ Name = "ShadowCore", Multiplier = 1, Transparency = 0.3 },
			{ Name = "ShadowBlur1", Multiplier = 1.1, Transparency = 0.5, ExtraOffset = Vector3.new(0.2,0,0.2) },
			{ Name = "ShadowBlur2", Multiplier = 1.2, Transparency = 0.7, ExtraOffset = Vector3.new(-0.2,0,-0.2) }
		}
	},
	PlayerLight = { Range = { Outdoors = 500, Indoors = 250 }, BaseBrightness = 1.5, Color = Color3.fromRGB(255,230,200) },
	Sun = {
		PartSize = Vector3.new(60,60,60),
		PartColor = Color3.fromRGB(255,220,100),
		Light = { Range = 1200, Brightness = 3 },
		Billboard = { Size = UDim2.new(4,0,4,0), FlareSize = UDim2.new(5,0,5,0), ImageTransparencyFocused = 0.2, ImageTransparencyNormal = 0.5 },
		OcclusionFactor = 0.4  -- hệ số giảm độ chói nếu ánh sáng bị che (với vật cản)
	},
	Moon = {
		PartSize = Vector3.new(50,50,50),
		PartColor = Color3.fromRGB(200,220,255),
		Light = { Range = 1000, Brightness = 2 },
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
		Reflectance = 0.3,
		UpdateInterval = 5
	},
	EnvironmentCheck = { UpdateInterval = 3 }
}

-- Chế độ Advanced hay Default
local advancedMode = true

------------------------------------------------------------
-- 1. POST-PROCESSING & ÁNH SÁNG CHUNG
------------------------------------------------------------
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.6
-- Cập nhật môi trường: ánh sáng nền xanh dương nhạt của bầu trời
Lighting.Ambient = Color3.fromRGB(180,210,255)

local bloom = Instance.new("BloomEffect")
bloom.Intensity = config.PostProcessing.Bloom.Intensity
-- GIẢM hiệu ứng lan của ánh sáng bằng cách giảm kích thước bloom
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
-- 2. HIỆU ỨNG MÂY DI CHUYỂN
------------------------------------------------------------
local cloudLayer = Instance.new("Part")
cloudLayer.Name = "CloudLayer"
cloudLayer.Size = Vector3.new(10000,1,10000)
cloudLayer.Anchored = true
cloudLayer.CanCollide = false
cloudLayer.Material = Enum.Material.SmoothPlastic
cloudLayer.Transparency = config.Clouds.PartTransparency.Day
cloudLayer.Parent = Workspace
cloudLayer.CFrame = CFrame.new(0,300,0) * CFrame.Angles(math.rad(90),0,0)

local cloudTexture = Instance.new("Texture")
cloudTexture.Face = Enum.NormalId.Top
cloudTexture.Texture = "rbxassetid://412757221"  -- Thay asset id mây của bạn
cloudTexture.StudsPerTileU = config.Clouds.StudsPerTile
cloudTexture.StudsPerTileV = config.Clouds.StudsPerTile
cloudTexture.Parent = cloudLayer

task.spawn(function()
	while true do
		cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + config.Clouds.OffsetSpeed.U) % config.Clouds.StudsPerTile
		cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + config.Clouds.OffsetSpeed.V) % config.Clouds.StudsPerTile
		task.wait(0.1)
	end
end)

------------------------------------------------------------
-- 3. SKYBOX & HIỆU ỨNG SAO/CHIẾU
------------------------------------------------------------
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
local function updateSkyAndClouds()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		for key, asset in pairs(config.Skybox.Day) do
			sky[key] = asset
		end
		cloudLayer.Transparency = config.Clouds.PartTransparency.Day
		starEmitter.Enabled = false
	else
		for key, asset in pairs(config.Skybox.Night) do
			sky[key] = asset
		end
		cloudLayer.Transparency = config.Clouds.PartTransparency.Night
		starEmitter.Enabled = true
	end
end

local starFieldPart = Instance.new("Part")
starFieldPart.Name = "StarField"
starFieldPart.Size = Vector3.new(1,1,1)
starFieldPart.Anchored = true
starFieldPart.CanCollide = false
starFieldPart.Transparency = 1
starFieldPart.Parent = Workspace
starFieldPart.Position = Vector3.new(0,500,0)

local starAttachment = Instance.new("Attachment", starFieldPart)
local starEmitter = Instance.new("ParticleEmitter")
starEmitter.Parent = starAttachment
starEmitter.Rate = 30
starEmitter.Lifetime = NumberRange.new(10,12)
starEmitter.Speed = NumberRange.new(0,0)
starEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 0.3)
})
starEmitter.Transparency = NumberSequence.new(0)
starEmitter.LightEmission = 1
starEmitter.Color = ColorSequence.new(Color3.new(1,1,1))
starEmitter.Enabled = false

task.spawn(function()
	while true do
		updateSkyAndClouds()
		task.wait(10)
	end
end)

------------------------------------------------------------
-- 4. HIỆU ỨNG MẶT NƯỚC (Nâng cao & tối ưu)
------------------------------------------------------------
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
		local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
		if not sa then
			sa = Instance.new("SurfaceAppearance")
			sa.Parent = obj
		end
		sa.Reflectance = config.Water.Reflectance
		sa.Color = Color3.new(1,1,1)
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
-- 5. REFLECTION PROBE (cập nhật theo nhân vật)
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
-- 6. GLOBAL LIGHTING (cập nhật theo TimeOfDay & tự động điều chỉnh Brightness)
------------------------------------------------------------
local function updateGlobalLighting()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	
	-- Kiểm tra chất lượng thiết bị (nếu có thuộc tính RenderingQualityLevel)
	local quality = settings().RenderingQualityLevel or 1
	if quality < 2 then
		baseBrightness = baseBrightness * config.RtxUpgrade.DeviceBrightnessFactor
	end
	
	Lighting.Brightness = baseBrightness
end

-- Hàm điều chỉnh Brightness nếu có sự chênh lệch (giảm dần về giá trị cơ sở)
local function adjustGlobalBrightness()
	local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
	local baseBrightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
	-- Nếu thiết bị kém, áp dụng thêm hệ số
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
-- 7. HIỆU ỨNG BÓNG NHÂN VẬT (Advanced Shadows - Nâng cấp)
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
		-- Dự đoán vị trí bóng bằng raycasting từ vị trí nhân vật theo hướng ngược Mặt Trời
		local rayOrigin = hrp.Position
		local rayDirection = -sunDir * 100
		local rayParams = RaycastParams.new()
		-- Loại trừ nhân vật và các layer bóng
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
		
		-- Tính hướng bóng theo mặt đất
		local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z)
		if shadowDir.Magnitude < 0.001 then
			shadowDir = Vector3.new(0,0,1)
		else
			shadowDir = shadowDir.Unit
		end
		local rightVector = shadowDir:Cross(groundNormal).Unit
		local forwardVector = groundNormal:Cross(rightVector).Unit
		local targetCFrame = CFrame.fromMatrix(shadowPosition, rightVector, groundNormal, forwardVector)
		
		-- Nội suy chuyển động bóng cho mượt
		if previousShadowCFrame then
			targetCFrame = previousShadowCFrame:Lerp(targetCFrame, config.Shadow.Smoothing)
		end
		previousShadowCFrame = targetCFrame
		
		for _, layer in ipairs(config.Shadow.Layers) do
			local multiplier = layer.Multiplier
			local extraOffset = layer.ExtraOffset or Vector3.new(0,0,0)
			local shadow = shadowLayers[layer.Name]
			shadow.Size = Vector3.new(baseSize * multiplier, 0.2, baseSize * multiplier)
			shadow.CFrame = targetCFrame * CFrame.new(extraOffset)
		end
	end
end
RunService.RenderStepped:Connect(updateAdvancedShadows)

------------------------------------------------------------
-- 8. HIỆU ỨNG ÁNH SÁNG XUNG QUANH NHÂN VẬT & HALO
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
	-- Thêm halo cho đầu nhân vật
	local head = char:FindFirstChild("Head")
	if head and not head:FindFirstChild("HaloEmitter") then
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "HaloEmitter"
		halo.Parent = head
		halo.Texture = "rbxassetid://YourHaloTexture"  -- Thay asset id halo của bạn
		halo.Rate = 5
		halo.Lifetime = NumberRange.new(1,2)
		halo.Speed = NumberRange.new(0,0)
		halo.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,3), NumberSequenceKeypoint.new(1,6)})
		halo.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,1)})
		halo.LightEmission = 1
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

local baseTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - baseTime
	playerLight.Brightness = config.PlayerLight.BaseBrightness + 0.3 * math.sin(t * 0.5)
end)

------------------------------------------------------------
-- 9. HIỆU ỨNG MẶT TRỜI & MẶT TRĂNG (Với Lens Flare & Occlusion)
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
sunImage.Image = "rbxassetid://YourSunCoronaImage"  -- Thay asset id corona của bạn
sunImage.ImageTransparency = config.Sun.Billboard.ImageTransparencyNormal
sunImage.Parent = sunBillboard

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
moonImage.Image = "rbxassetid://YourMoonCoronaImage"  -- Thay asset id corona của bạn
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

-- HIỆU ỨNG CHE ÁNH SÁNG: Nếu raycasting từ SunPart đến đầu nhân vật bị che, giảm độ chói ánh sáng (mô phỏng bóng của vật cản)
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
-- 10. HIỆU ỨNG SAO BĂNG (Enhanced Shooting Stars)
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
-- 11. TĂNG CHẤT LƯỢNG CHI TIẾT XUNG QUANH NGƯỜI CHƠI
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
-- 12. KIỂM TRA MÔI TRƯỜNG (Indoors/Outdoors)
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
			-- Indoors: giảm Brightness và phạm vi ánh sáng của nhân vật
			Lighting.Brightness = 1
			playerLight.Range = config.PlayerLight.Range.Indoors
		else
			local hour = tonumber(Lighting.TimeOfDay:sub(1,2))
			Lighting.Brightness = (hour >= 6 and hour < 18) and config.GlobalLighting.DayBrightness or config.GlobalLighting.NightBrightness
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
-- 13. CHUYỂN ĐỔI GIỎI HỌA (Advanced vs Default)
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
			print("Chế độ RTX-like Advanced Effects được kích hoạt.")
		else
			bloom.Enabled = false
			colorCorrection.Enabled = false
			dof.Enabled = false
			if ssr then ssr.Enabled = false end
			sunRays.Enabled = false
			print("Chuyển sang chế độ đồ họa Roblox mặc định.")
		end
	end
end)

------------------------------------------------------------
-- 14. THÔNG BÁO HOÀN THIỆN
------------------------------------------------------------
print("RTX-like Advanced Effects đã được nâng cấp với các cải tiến mới: giảm hiệu ứng lan ánh sáng, tự động điều chỉnh độ chói, môi trường xanh dương nhạt và hiệu ứng che ánh sáng thành công!")
