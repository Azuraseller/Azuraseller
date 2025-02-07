------------------------------------------------------------
-- RTX-like Advanced Effects - Nâng cấp cao cấp
--
-- Các cải tiến bao gồm:
-- 1. Hiệu ứng post-processing nâng cao (bloom, dof, SSR, sunrays).
-- 2. Mây chuyển động với offset tinh vi.
-- 3. Skybox thay đổi (ban ngày/ban đêm) kèm hiệu ứng sao.
-- 4. Hiệu ứng mặt nước động với SurfaceAppearance và "mist".
-- 5. ReflectionProbe cập nhật theo vị trí nhân vật.
-- 6. Điều chỉnh ánh sáng global theo thời gian.
-- 7. Hiệu ứng bóng nhân vật nâng cao với nhiều lớp (soft shadow).
-- 8. Ánh sáng xung quanh nhân vật kết hợp với halo (Particle).
-- 9. Hiệu ứng mặt trời và mặt trăng “sống động” với corona (BillboardGui + Particle).
-- 10. Hiệu ứng sao băng nâng cao với dual trail và Tween động.
------------------------------------------------------------

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

------------------------------------------------------------
-- 1. THIẾT LẬP ÁNH SÁNG & POST-PROCESSING (nâng cao)
------------------------------------------------------------
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.6
Lighting.Ambient = Color3.fromRGB(100, 100, 100)

-- Bloom: tăng độ sáng và kích thước để tạo glow mạnh mẽ hơn
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 1.0
bloom.Size = 35
bloom.Threshold = 2
bloom.Parent = Lighting

-- Color Correction
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.15
colorCorrection.Contrast = 0.2
colorCorrection.Saturation = 0.1
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
colorCorrection.Parent = Lighting

-- Depth of Field
local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0.3
dof.FocusDistance = 20
dof.InFocusRadius = 10
dof.NearIntensity = 0.3
dof.Parent = Lighting

-- Screen Space Reflection
local ssr
local success, result = pcall(function()
	return Lighting:FindFirstChild("ScreenSpaceReflectionEffect") or Instance.new("ScreenSpaceReflectionEffect")
end)
if success and result then
	ssr = result
	ssr.Intensity = 0.8
	ssr.Reflectance = 0.7
	ssr.Parent = Lighting
else
	warn("ScreenSpaceReflectionEffect không khả dụng.")
end

-- Sun Rays Effect (volumetric light)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.3
sunRays.Spread = 0.2
sunRays.Parent = Lighting

------------------------------------------------------------
-- 2. CLOUDS DI CHUYỂN (BAN NGÀY)
------------------------------------------------------------
local cloudLayer = Instance.new("Part")
cloudLayer.Name = "CloudLayer"
cloudLayer.Size = Vector3.new(10000, 1, 10000)
cloudLayer.Anchored = true
cloudLayer.CanCollide = false
cloudLayer.Material = Enum.Material.SmoothPlastic
cloudLayer.Transparency = 0.7
cloudLayer.Parent = Workspace
cloudLayer.CFrame = CFrame.new(0, 300, 0) * CFrame.Angles(math.rad(90), 0, 0)

local cloudTexture = Instance.new("Texture")
cloudTexture.Face = Enum.NormalId.Top
cloudTexture.Texture = "rbxassetid://412757221"  -- thay asset id mây của bạn nếu cần
cloudTexture.StudsPerTileU = 500
cloudTexture.StudsPerTileV = 500
cloudTexture.Parent = cloudLayer

spawn(function()
	while true do
		cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + 0.07) % 500
		cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + 0.03) % 500
		wait(0.1)
	end
end)

------------------------------------------------------------
-- 3. SKYBOX & HIỆU ỨNG AURORA/STAR
------------------------------------------------------------
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)

local daySky = {
	SkyboxBk = "rbxassetid://1234567890",
	SkyboxDn = "rbxassetid://1234567891",
	SkyboxFt = "rbxassetid://1234567892",
	SkyboxLf = "rbxassetid://1234567893",
	SkyboxRt = "rbxassetid://1234567894",
	SkyboxUp = "rbxassetid://1234567895"
}

local nightSky = {
	SkyboxBk = "rbxassetid://2234567890",
	SkyboxDn = "rbxassetid://2234567891",
	SkyboxFt = "rbxassetid://2234567892",
	SkyboxLf = "rbxassetid://2234567893",
	SkyboxRt = "rbxassetid://2234567894",
	SkyboxUp = "rbxassetid://2234567895"
}

-- Hiệu ứng sao: ParticleEmitter cho bầu trời đêm
local starFieldPart = Instance.new("Part")
starFieldPart.Name = "StarField"
starFieldPart.Size = Vector3.new(1,1,1)
starFieldPart.Anchored = true
starFieldPart.CanCollide = false
starFieldPart.Transparency = 1
starFieldPart.Parent = Workspace
starFieldPart.Position = Vector3.new(0, 500, 0)

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

local function updateSkyAndEffects()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		for key, asset in pairs(daySky) do
			sky[key] = asset
		end
		cloudLayer.Transparency = 0.7
		starEmitter.Enabled = false
	else
		for key, asset in pairs(nightSky) do
			sky[key] = asset
		end
		cloudLayer.Transparency = 1
		starEmitter.Enabled = true
	end
end

spawn(function()
	while true do
		updateSkyAndEffects()
		wait(10)
	end
end)

------------------------------------------------------------
-- 4. HIỆU ỨNG MẶT NƯỚC NÂNG CAO
------------------------------------------------------------
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
		local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
		if not sa then
			sa = Instance.new("SurfaceAppearance")
			sa.Parent = obj
		end
		sa.Reflectance = 0.4  -- tăng chút reflectance
		sa.Color = Color3.new(1,1,1)
		-- Nếu có Texture áp dụng, animate offset để mô phỏng sóng
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("Texture") then
				spawn(function()
					while child.Parent do
						child.OffsetStudsU = (child.OffsetStudsU + 0.1) % 100
						child.OffsetStudsV = (child.OffsetStudsV + 0.05) % 100
						wait(0.1)
					end
				end)
			end
		end
		-- Thêm hiệu ứng “mist” nhẹ phía trên mặt nước
		if not obj:FindFirstChild("WaterMist") then
			local mist = Instance.new("ParticleEmitter")
			mist.Name = "WaterMist"
			mist.Parent = obj
			mist.Rate = 2
			mist.Lifetime = NumberRange.new(3,5)
			mist.Speed = NumberRange.new(0.5,1)
			mist.Size = NumberSequence.new(5)
			mist.Color = ColorSequence.new(Color3.fromRGB(200,200,255))
			mist.Transparency = NumberSequence.new(0.5)
		end
	end
end

------------------------------------------------------------
-- 5. REFLECTION PROBE (theo vùng xung quanh nhân vật)
------------------------------------------------------------
local reflectionProbe = Instance.new("ReflectionProbe")
reflectionProbe.Name = "LocalReflectionProbe"
reflectionProbe.Size = Vector3.new(70, 70, 70)
reflectionProbe.ReflectionType = Enum.ReflectionType.Dynamic
reflectionProbe.Parent = Workspace

local function updateReflectionProbe()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		reflectionProbe.CFrame = player.Character.HumanoidRootPart.CFrame
	end
end
RunService.RenderStepped:Connect(updateReflectionProbe)

------------------------------------------------------------
-- 6. ĐIỀU CHỈNH ÁNH SÁNG TOÀN CỤC THEO THỜI GIAN
------------------------------------------------------------
local function updateGlobalLighting()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		Lighting.Brightness = 2.5
	else
		Lighting.Brightness = 1.5
	end
end
spawn(function()
	while true do
		updateGlobalLighting()
		wait(5)
	end
end)

------------------------------------------------------------
-- 7. HIỆU ỨNG BÓNG NHÂN VẬT NÂNG CAO (Nhiều lớp soft shadow)
------------------------------------------------------------
local shadowLayers = {}

local function createShadowLayer(name, sizeMultiplier, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(6, 0.2, 6) * sizeMultiplier
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = transparency
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(0,0,0)
	part.Parent = Workspace
	return part
end

shadowLayers.core = createShadowLayer("ShadowCore", 1, 0.3)
shadowLayers.blur1 = createShadowLayer("ShadowBlur1", 1.2, 0.5)
shadowLayers.blur2 = createShadowLayer("ShadowBlur2", 1.5, 0.7)

-- Hàm tính hướng mặt trời dựa vào TimeOfDay (chỉ cho ban ngày)
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
		return Vector3.new(1, 0, 0), 0.1
	end
end

local function updateAdvancedShadows()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local sunDir, elevation = getSunDirection()
		-- Hướng bóng: đối diện với hướng mặt trời (loại bỏ thành phần Y)
		local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z).Unit
		-- Khi mặt trời thấp bóng dài hơn
		local lengthFactor = 1 / math.max(math.sin(elevation), 0.2)
		lengthFactor = math.clamp(lengthFactor, 1, 3)
		local baseSize = 6 * lengthFactor
		local offsetDistance = 3 * lengthFactor
		local shadowPos = hrp.Position - Vector3.new(0, hrp.Size.Y/2 + 0.1, 0) + shadowDir * offsetDistance
		local rotation = math.atan2(shadowDir.Z, shadowDir.X) - math.pi/2
		for name, shadow in pairs(shadowLayers) do
			local multiplier = 1
			local extraOffset = Vector3.new(0,0,0)
			if name == "blur1" then
				multiplier = 1.1
				extraOffset = Vector3.new(0.2, 0, 0.2)
			elseif name == "blur2" then
				multiplier = 1.2
				extraOffset = Vector3.new(-0.2, 0, -0.2)
			end
			shadow.Size = Vector3.new(baseSize, 0.2, baseSize) * multiplier
			shadow.CFrame = CFrame.new(shadowPos + extraOffset) * CFrame.Angles(0, rotation, 0)
		end
	end
end
RunService.RenderStepped:Connect(updateAdvancedShadows)

------------------------------------------------------------
-- 8. HIỆU ỨNG ÁNH SÁNG XUNG QUANH NHÂN VẬT & HALO
------------------------------------------------------------
local playerLight = Instance.new("PointLight")
playerLight.Name = "PlayerLight"
playerLight.Range = 500
playerLight.Brightness = 1.5
playerLight.Color = Color3.fromRGB(255, 230, 200)
playerLight.Shadows = true

local function onCharacterAdded(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	playerLight.Parent = hrp
	
	-- Thêm hiệu ứng halo (Particle) ở đầu nhân vật
	local head = char:FindFirstChild("Head")
	if head and not head:FindFirstChild("HaloEmitter") then
		local halo = Instance.new("ParticleEmitter")
		halo.Name = "HaloEmitter"
		halo.Parent = head
		halo.Texture = "rbxassetid://YourHaloTexture"  -- thay asset id halo của bạn
		halo.Rate = 5
		halo.Lifetime = NumberRange.new(1,2)
		halo.Speed = NumberRange.new(0,0)
		halo.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 6)})
		halo.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
		halo.LightEmission = 1
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

local startTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - startTime
	local brightnessVariation = 0.3 * math.sin(t * 0.5)
	playerLight.Brightness = 1.5 + brightnessVariation
end)

------------------------------------------------------------
-- 9. HIỆU ỨNG MẶT TRỜI & MẶT TRĂNG NÂNG CAO
------------------------------------------------------------
local sunPart = Instance.new("Part")
sunPart.Name = "SunPart"
sunPart.Shape = Enum.PartType.Ball
sunPart.Size = Vector3.new(60, 60, 60)
sunPart.Material = Enum.Material.Neon
sunPart.Color = Color3.fromRGB(255, 220, 100)
sunPart.Anchored = true
sunPart.CanCollide = false
sunPart.Parent = Workspace

local sunLight = Instance.new("PointLight")
sunLight.Range = 1200
sunLight.Brightness = 3
sunLight.Color = sunPart.Color
sunLight.Parent = sunPart

-- Corona cho mặt trời: BillboardGui hiển thị hình ảnh corona mờ nhẹ
local sunBillboard = Instance.new("BillboardGui")
sunBillboard.Adornee = sunPart
sunBillboard.Size = UDim2.new(4,0,4,0)
sunBillboard.AlwaysOnTop = true
sunBillboard.Parent = sunPart

local sunImage = Instance.new("ImageLabel")
sunImage.Size = UDim2.new(1,0,1,0)
sunImage.BackgroundTransparency = 1
sunImage.Image = "rbxassetid://YourSunCoronaImage"  -- thay asset id corona mặt trời của bạn
sunImage.ImageTransparency = 0.5
sunImage.Parent = sunBillboard

local moonPart = Instance.new("Part")
moonPart.Name = "MoonPart"
moonPart.Shape = Enum.PartType.Ball
moonPart.Size = Vector3.new(50, 50, 50)
moonPart.Material = Enum.Material.Neon
moonPart.Color = Color3.fromRGB(200, 220, 255)
moonPart.Anchored = true
moonPart.CanCollide = false
moonPart.Parent = Workspace

local moonLight = Instance.new("PointLight")
moonLight.Range = 1000
moonLight.Brightness = 2
moonLight.Color = moonPart.Color
moonLight.Parent = moonPart

local moonBillboard = Instance.new("BillboardGui")
moonBillboard.Adornee = moonPart
moonBillboard.Size = UDim2.new(3.5,0,3.5,0)
moonBillboard.AlwaysOnTop = true
moonBillboard.Parent = moonPart

local moonImage = Instance.new("ImageLabel")
moonImage.Size = UDim2.new(1,0,1,0)
moonImage.BackgroundTransparency = 1
moonImage.Image = "rbxassetid://YourMoonCoronaImage"  -- thay asset id corona mặt trăng của bạn
moonImage.ImageTransparency = 0.3
moonImage.Parent = moonBillboard

RunService.RenderStepped:Connect(function()
	local sunDir, _ = getSunDirection()
	local distance = 1200
	sunPart.Position = camera.CFrame.Position + sunDir * distance
	moonPart.Position = camera.CFrame.Position - sunDir * distance
	
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		sunPart.Transparency = 0
		moonPart.Transparency = 1
	else
		sunPart.Transparency = 1
		moonPart.Transparency = 0
	end
end)

------------------------------------------------------------
-- 10. HIỆU ỨNG SAO BĂNG NÂNG CAO
------------------------------------------------------------
local shootingStarColors = {
	Color3.fromRGB(255, 150, 150),
	Color3.fromRGB(150, 255, 150),
	Color3.fromRGB(150, 150, 255),
	Color3.fromRGB(255, 255, 150),
	Color3.fromRGB(255, 150, 255),
	Color3.fromRGB(150, 255, 255)
}

local function spawnEnhancedShootingStar()
	local star = Instance.new("Part")
	star.Name = "EnhancedShootingStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(4,4,4)
	star.Material = Enum.Material.Neon
	star.Color = shootingStarColors[math.random(1, #shootingStarColors)]
	star.Anchored = true
	star.CanCollide = false
	star.Transparency = 0
	star.Parent = Workspace
	
	-- Tạo hai bộ Trail để tạo hiệu ứng vệt sáng phức hợp
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
	
	-- Đặt vị trí ban đầu cho các attachment
	att0.Position = Vector3.new(0,0,0)
	att1.Position = Vector3.new(0,0,0)
	att2.Position = Vector3.new(0,0,0)
	att3.Position = Vector3.new(0,0,0)
	
	-- Vị trí khởi tạo ngẫu nhiên trong vùng “bầu trời”
	local startPos = camera.CFrame.Position + Vector3.new(math.random(-600,600), math.random(400,700), math.random(-600,600))
	local direction = Vector3.new(math.random(-1,1), -math.random(1,3), math.random(-1,1)).Unit
	star.Position = startPos
	
	-- Dùng Tween để di chuyển, giảm kích thước và tăng độ trong suốt
	local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Position = startPos + direction * 1000,
		Size = Vector3.new(0.5,0.5,0.5),
		Transparency = 1
	}
	local tween = TweenService:Create(star, tweenInfo, goal)
	tween:Play()
	tween.Completed:Connect(function()
		star:Destroy()
	end)
end

spawn(function()
	while true do
		wait(math.random(10,30))
		spawnEnhancedShootingStar()
	end
end)

------------------------------------------------------------
-- 11. THÔNG BÁO HOÀN THIỆN
------------------------------------------------------------
print("RTX-like Advanced Effects đã được nâng cấp cao cấp thành công!")
