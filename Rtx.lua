------------------------------------------------------------
-- RTX-like Effects (Advanced Simulation) trên Roblox Mobile --
-- Script được nâng cấp với các cải tiến:
-- 1. Hiệu ứng bóng (shadow) động theo hướng mặt trời, cập nhật nhanh cho
--    vật thể di chuyển nhanh và thay đổi theo hướng của mặt trời.
-- 2. Ánh sáng xung quanh người chơi (radius = 500) với hiệu ứng nhấp nháy,
--    màu sắc đậm nhạt nhưng không quá chói.
-- 3. Hiệu ứng mặt trời và mặt trăng được cải tiến, hiển thị tự nhiên theo giờ.
-- 4. Thêm hiệu ứng sao (star field) và sao băng (shooting star) với màu sắc đa dạng,
--    xuất hiện ngẫu nhiên từ 10-30 giây.
-- 5. Cải tiến hiệu ứng phản chiếu của các vật thể, vật liệu và mặt nước.
------------------------------------------------------------

-- Đặt LocalScript vào: StarterPlayer → StarterPlayerScripts

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

---------------------------------------------
-- 1. THIẾT LẬP ÁNH SÁNG & POST-PROCESSING (giữ nguyên)
---------------------------------------------
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.6
Lighting.Ambient = Color3.fromRGB(100, 100, 100)  -- ánh sáng môi trường vừa phải

-- Bloom: tạo hiệu ứng quang không quá chói
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.8
bloom.Size = 30
bloom.Threshold = 2
bloom.Parent = Lighting

-- Color Correction: điều chỉnh màu sắc chung
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.1
colorCorrection.Contrast = 0.15
colorCorrection.Saturation = 0.1
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
colorCorrection.Parent = Lighting

-- Depth of Field (tăng chiều sâu mà không quá nổi bật)
local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0.2
dof.FocusDistance = 20
dof.InFocusRadius = 10
dof.NearIntensity = 0.25
dof.Parent = Lighting

-- Screen Space Reflection: nhẹ để mô phỏng phản chiếu trên bề mặt
local ssr
local success, result = pcall(function()
	return Lighting:FindFirstChild("ScreenSpaceReflectionEffect") or Instance.new("ScreenSpaceReflectionEffect")
end)
if success and result then
	ssr = result
	ssr.Intensity = 0.6
	ssr.Reflectance = 0.6
	ssr.Parent = Lighting
else
	warn("ScreenSpaceReflectionEffect không khả dụng.")
end

---------------------------------------------
-- 2. CLOUDS DI CHUYỂN (BAN NGÀY) (giữ nguyên)
---------------------------------------------
local cloudLayer = Instance.new("Part")
cloudLayer.Name = "CloudLayer"
cloudLayer.Size = Vector3.new(10000, 1, 10000)
cloudLayer.Anchored = true
cloudLayer.CanCollide = false
cloudLayer.Material = Enum.Material.SmoothPlastic
cloudLayer.Transparency = 0.7  -- nhẹ, không quá nổi bật
cloudLayer.Parent = Workspace

cloudLayer.CFrame = CFrame.new(0, 300, 0) * CFrame.Angles(math.rad(90), 0, 0)

local cloudTexture = Instance.new("Texture")
cloudTexture.Face = Enum.NormalId.Top
cloudTexture.Texture = "rbxassetid://412757221"  
cloudTexture.StudsPerTileU = 500
cloudTexture.StudsPerTileV = 500
cloudTexture.Parent = cloudLayer

spawn(function()
	while true do
		cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + 0.05) % 500
		cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + 0.02) % 500
		wait(0.1)
	end
end)

---------------------------------------------
-- 3. SKYBOX & HIỆU ỨNG AURORA/STAR (Ban ngày/ban đêm)
---------------------------------------------
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

-- Hiệu ứng Aurora cũ (ParticleEmitter)
local skyEffectPart = Instance.new("Part")
skyEffectPart.Name = "SkyEffect"
skyEffectPart.Size = Vector3.new(1,1,1)
skyEffectPart.Anchored = true
skyEffectPart.CanCollide = false
skyEffectPart.Transparency = 1
skyEffectPart.Parent = Workspace
skyEffectPart.Position = Vector3.new(0, 150, -2000)

local skyAttachment = Instance.new("Attachment", skyEffectPart)
local skyEmitter = Instance.new("ParticleEmitter")
skyEmitter.Parent = skyAttachment
skyEmitter.Rate = 5
skyEmitter.Lifetime = NumberRange.new(5,7)
skyEmitter.Speed = NumberRange.new(0,0)
skyEmitter.RotSpeed = NumberRange.new(10,30)
skyEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 10),
	NumberSequenceKeypoint.new(1, 20)
})
skyEmitter.LightEmission = 1
skyEmitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 200))
})
skyEmitter.Enabled = false

-- Thêm StarField (hiệu ứng sao) cho ban đêm
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
starEmitter.Rate = 20
starEmitter.Lifetime = NumberRange.new(10,12)
starEmitter.Speed = NumberRange.new(0,0)
starEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.5),
	NumberSequenceKeypoint.new(1, 0.5)
})
starEmitter.Transparency = NumberSequence.new(0)
starEmitter.LightEmission = 1
starEmitter.Color = ColorSequence.new(Color3.new(1,1,1))
starEmitter.Enabled = false

-- Hàm cập nhật bầu trời, hiệu ứng Aurora và StarField theo giờ
local function updateSkyAndAurora()
	local timeOfDay = Lighting.TimeOfDay  -- định dạng "HH:MM:SS"
	local hour = tonumber(timeOfDay:sub(1,2))
	
	if hour >= 6 and hour < 18 then
		-- Ban ngày
		for key, asset in pairs(daySky) do
			sky[key] = asset
		end
		cloudLayer.Transparency = 0.7
		skyEmitter.Enabled = true
		starEmitter.Enabled = false
		skyEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 200))
		})
	else
		-- Ban đêm
		for key, asset in pairs(nightSky) do
			sky[key] = asset
		end
		cloudLayer.Transparency = 1
		skyEmitter.Enabled = false
		starEmitter.Enabled = true
	end
end

spawn(function()
	while true do
		updateSkyAndAurora()
		wait(10)
	end
end)

---------------------------------------------
-- 4. HIỆU ỨNG NƯỚC PHẢN CHIẾU (giữ nguyên)
---------------------------------------------
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
		if not obj:FindFirstChildOfClass("SurfaceAppearance") then
			local sa = Instance.new("SurfaceAppearance")
			sa.Reflectance = 0.3
			sa.Color = Color3.new(1, 1, 1)
			sa.Parent = obj
		end
	end
end

---------------------------------------------
-- 5. REFLECTION PROBE TRONG VÙNG R = 35 XUNG QUANH PLAYER (giữ nguyên)
---------------------------------------------
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

---------------------------------------------
-- 6. ĐIỀU CHỈNH ÁNH SÁNG CHUNG (giữ nguyên)
---------------------------------------------
local function updateGlobalLighting()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		Lighting.Brightness = 2
	else
		Lighting.Brightness = 1
	end
end

spawn(function()
	while true do
		updateGlobalLighting()
		wait(5)
	end
end)

---------------------------------------------
-- 7. CẢI TIẾN HIỆU ỨNG PHẢN CHIẾU (Reflection) cho VẬT THỂ
---------------------------------------------
local function updateReflectivityForNearbyObjects()
	if not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local origin = hrp.Position
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local dist = (obj.Position - origin).Magnitude
			local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
			if not sa then
				sa = Instance.new("SurfaceAppearance")
				sa.Parent = obj
			end
			if obj.Material == Enum.Material.Water then
				sa.Reflectance = 0.3
				sa.Color = Color3.new(1,1,1)
			else
				if dist <= 35 then
					sa.Reflectance = 0.5
				elseif dist <= 100 then
					sa.Reflectance = 0.5 - ((dist - 35) / (100 - 35)) * (0.5 - 0.1)
				else
					sa.Reflectance = 0.1
				end
			end
		end
	end
end

spawn(function()
	while true do
		updateReflectivityForNearbyObjects()
		wait(2)
	end
end)

---------------------------------------------
-- 8. HIỆU ỨNG BÓNG DYNAMIC THEO HƯỚNG MẶT TRỜI (Cải tiến 1)
---------------------------------------------
-- Hàm tính hướng mặt trời dựa vào Lighting.TimeOfDay
local function getSunDirection()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	-- Chỉ tính cho ban ngày (6h-18h); ngoài khoảng này dùng mặc định
	if hour >= 6 and hour < 18 then
		local t = (hour - 6) / 12  -- từ 0 đến 1
		-- Góc cao của mặt trời: 0 ở lúc mọc, đạt 90° giữa trưa, về 0 lúc hoàng hôn
		local elevation = math.sin(t * math.pi) * (math.pi/2)
		-- Góc phương vị: từ 0 (đông) đến π (tây)
		local azimuth = t * math.pi
		-- Tính vector hướng mặt trời
		local sunDir = Vector3.new(math.cos(azimuth) * math.cos(elevation), math.sin(elevation), math.sin(azimuth) * math.cos(elevation))
		return sunDir, elevation
	else
		return Vector3.new(1, 0, 0), 0.1
	end
end

-- Tạo Part hiển thị bóng của người chơi
local playerShadow = Instance.new("Part")
playerShadow.Name = "PlayerShadow"
playerShadow.Size = Vector3.new(6, 0.2, 6)
playerShadow.Anchored = true
playerShadow.CanCollide = false
playerShadow.Transparency = 0.4
playerShadow.Material = Enum.Material.SmoothPlastic
playerShadow.Color = Color3.new(0,0,0)
playerShadow.Parent = Workspace

-- (Tùy chọn) Thêm Decal để tạo hiệu ứng bóng mềm (thay YOUR_SHADOW_TEXTURE_ASSET_ID bằng asset id thật)
local shadowDecal = Instance.new("Decal")
shadowDecal.Face = Enum.NormalId.Top
shadowDecal.Texture = "rbxassetid://YOUR_SHADOW_TEXTURE_ASSET_ID"  
shadowDecal.Transparency = 0.4
shadowDecal.Parent = playerShadow

-- Cập nhật vị trí và kích thước bóng dựa trên hướng mặt trời và vị trí người chơi
local function updatePlayerShadow()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = player.Character.HumanoidRootPart
		local sunDir, elevation = getSunDirection()
		-- Lấy hướng bóng trên mặt đất (loại bỏ thành phần Y)
		local shadowDir = Vector3.new(-sunDir.X, 0, -sunDir.Z).Unit
		-- Tính hệ số kéo dài bóng: khi mặt trời thấp bóng dài hơn
		local lengthFactor = 1 / math.max(math.sin(elevation), 0.2)
		lengthFactor = math.clamp(lengthFactor, 1, 3)
		-- Cập nhật kích thước bóng
		local baseSize = 6
		playerShadow.Size = Vector3.new(baseSize * lengthFactor, 0.2, baseSize * lengthFactor)
		-- Tính vị trí bóng: đặt ngay dưới chân và lệch theo hướng đối diện mặt trời
		local offsetDistance = 3 * lengthFactor
		local shadowPos = hrp.Position - Vector3.new(0, hrp.Size.Y/2 + 0.1, 0) + shadowDir * offsetDistance
		playerShadow.CFrame = CFrame.new(shadowPos) * CFrame.Angles(0, math.atan2(shadowDir.Z, shadowDir.X) - math.pi/2, 0)
	end
end

RunService.RenderStepped:Connect(updatePlayerShadow)

---------------------------------------------
-- 9. HIỆU ỨNG ÁNH SÁNG XUNG QUANH NGƯỜI CHƠI (Cải tiến 2)
---------------------------------------------
local playerLight = Instance.new("PointLight")
playerLight.Name = "PlayerLight"
playerLight.Range = 500
playerLight.Brightness = 1
playerLight.Color = Color3.fromRGB(255, 230, 200)  -- màu ấm nhẹ
playerLight.Shadows = true

-- Khi nhân vật spawn, gắn ánh sáng vào HumanoidRootPart
local function onCharacterAdded(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	playerLight.Parent = hrp
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Cập nhật hiệu ứng nhấp nháy (pulsing) của ánh sáng theo thời gian
local startTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - startTime
	local brightnessVariation = 0.2 * math.sin(t * 0.5)
	playerLight.Brightness = 1 + brightnessVariation
	-- (Có thể mở rộng: Lerp giữa 2 màu nếu muốn thay đổi màu theo thời gian)
end)

---------------------------------------------
-- 10. HIỆU ỨNG MẶT TRỜI VÀ MẶT TRĂNG (Cải tiến 3)
---------------------------------------------
-- Tạo Part cho mặt trời
local sunPart = Instance.new("Part")
sunPart.Name = "SunPart"
sunPart.Shape = Enum.PartType.Ball
sunPart.Size = Vector3.new(50, 50, 50)
sunPart.Material = Enum.Material.Neon
sunPart.Color = Color3.fromRGB(255, 200, 50)
sunPart.Anchored = true
sunPart.CanCollide = false
sunPart.Parent = Workspace

local sunLight = Instance.new("PointLight")
sunLight.Range = 1000
sunLight.Brightness = 2
sunLight.Color = sunPart.Color
sunLight.Parent = sunPart

-- Tạo Part cho mặt trăng
local moonPart = Instance.new("Part")
moonPart.Name = "MoonPart"
moonPart.Shape = Enum.PartType.Ball
moonPart.Size = Vector3.new(40, 40, 40)
moonPart.Material = Enum.Material.Neon
moonPart.Color = Color3.fromRGB(200, 200, 255)
moonPart.Anchored = true
moonPart.CanCollide = false
moonPart.Parent = Workspace

local moonLight = Instance.new("PointLight")
moonLight.Range = 800
moonLight.Brightness = 1
moonLight.Color = moonPart.Color
moonLight.Parent = moonPart

-- Cập nhật vị trí của mặt trời và mặt trăng dựa trên TimeOfDay và vị trí camera
RunService.RenderStepped:Connect(function()
	local sunDir, _ = getSunDirection()
	local distance = 1000
	sunPart.Position = camera.CFrame.Position + sunDir * distance
	moonPart.Position = camera.CFrame.Position - sunDir * distance
	
	-- Hiển thị: ban ngày hiện mặt trời, ban đêm hiện mặt trăng
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

---------------------------------------------
-- 11. HIỆU ỨNG SAO BĂNG (Cải tiến 4)
---------------------------------------------
local shootingStarColors = {
	Color3.fromRGB(255, 100, 100),
	Color3.fromRGB(100, 255, 100),
	Color3.fromRGB(100, 100, 255),
	Color3.fromRGB(255, 255, 100),
	Color3.fromRGB(255, 100, 255),
	Color3.fromRGB(100, 255, 255)
}

local function spawnShootingStar()
	-- Tạo Part cho sao băng
	local star = Instance.new("Part")
	star.Name = "ShootingStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(3, 3, 3)
	star.Material = Enum.Material.Neon
	star.Color = shootingStarColors[math.random(1, #shootingStarColors)]
	star.Anchored = true
	star.CanCollide = false
	star.Transparency = 0
	star.Parent = Workspace
	
	-- Thêm Trail để tạo hiệu ứng vệt sáng
	local trail = Instance.new("Trail")
	local att0 = Instance.new("Attachment", star)
	local att1 = Instance.new("Attachment", star)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(star.Color)
	trail.Lifetime = 0.5
	trail.LightInfluence = 1
	trail.Parent = star
	
	-- Xác định vị trí ban đầu và hướng di chuyển ngẫu nhiên (ở vùng bầu trời)
	local startPos = camera.CFrame.Position + Vector3.new(math.random(-500,500), math.random(300,600), math.random(-500,500))
	local direction = Vector3.new(math.random(-1,1), -math.random(1,2), math.random(-1,1)).Unit
	star.Position = startPos
	
	-- Sử dụng Tween để di chuyển sao băng, giảm kích thước và tăng độ trong suốt
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {
		Position = startPos + direction * 800,
		Size = Vector3.new(0.5, 0.5, 0.5),
		Transparency = 1
	}
	local tween = TweenService:Create(star, tweenInfo, goal)
	tween:Play()
	tween.Completed:Connect(function()
		star:Destroy()
	end)
end

-- Tạo sao băng ngẫu nhiên mỗi 10-30 giây
spawn(function()
	while true do
		wait(math.random(10,30))
		spawnShootingStar()
	end
end)

print("RTX-like Effects advanced đã được kích hoạt (mô phỏng trong giới hạn Roblox).")
