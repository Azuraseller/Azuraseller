------------------------------------------------------------
-- RTX-like Effects (Advanced Simulation) trên Roblox Mobile --
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
-- 1. THIẾT LẬP ÁNH SÁNG & POST-PROCESSING
---------------------------------------------
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.6
Lighting.Ambient = Color3.fromRGB(100, 100, 100)  -- ánh sáng môi trường vừa phải

-- Bloom: không quá chói, vừa đủ để tạo hiệu ứng quang
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

-- Depth of Field (vừa để tăng chiều sâu, không quá nổi bật)
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
-- 2. CLOUDS DI CHUYỂN (BAN NGÀY)
---------------------------------------------
-- Tạo một Part lớn làm lớp mây (chỉ hiển thị ban ngày)
local cloudLayer = Instance.new("Part")
cloudLayer.Name = "CloudLayer"
cloudLayer.Size = Vector3.new(10000, 1, 10000)
cloudLayer.Anchored = true
cloudLayer.CanCollide = false
cloudLayer.Material = Enum.Material.SmoothPlastic
cloudLayer.Transparency = 0.7  -- nhẹ, không quá nổi bật
cloudLayer.Parent = Workspace

-- Đặt cloudLayer cao trên bầu trời (ví dụ Y = 300) và hơi nghiêng
cloudLayer.CFrame = CFrame.new(0, 300, 0) * CFrame.Angles(math.rad(90), 0, 0)

-- Sử dụng Texture với offset thay đổi để mô phỏng mây chuyển động
local cloudTexture = Instance.new("Texture")
cloudTexture.Face = Enum.NormalId.Top
-- AssetID mẫu: thay thế bằng ảnh mây có độ phân giải phù hợp
cloudTexture.Texture = "rbxassetid://412757221"  
cloudTexture.StudsPerTileU = 500
cloudTexture.StudsPerTileV = 500
cloudTexture.Parent = cloudLayer

-- Cập nhật offset để tạo chuyển động
spawn(function()
	while true do
		-- Tăng offset từng chút, tạo cảm giác mây trôi
		cloudTexture.OffsetStudsU = (cloudTexture.OffsetStudsU + 0.05) % 500
		cloudTexture.OffsetStudsV = (cloudTexture.OffsetStudsV + 0.02) % 500
		wait(0.1)
	end
end)

---------------------------------------------
-- 3. SKYBOX VÀ HIỆU ỨNG AURORA/STAR (Ban ngày/ban đêm)
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

-- Aurora/Star hiệu ứng: sử dụng một Part với ParticleEmitter
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
-- Ban ngày: Aurora màu xanh nhẹ; Ban đêm: chuyển sang sao lấp lánh
skyEmitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 200))
})
skyEmitter.Enabled = false  -- bật chỉ theo thời gian

-- Hàm cập nhật bầu trời và hiệu ứng theo giờ
local function updateSkyAndAurora()
	local timeOfDay = Lighting.TimeOfDay  -- "HH:MM:SS"
	local hour = tonumber(timeOfDay:sub(1,2))
	
	if hour >= 6 and hour < 18 then
		-- Ban ngày
		for key, asset in pairs(daySky) do
			sky[key] = asset
		end
		-- Hiển thị mây (cloudLayer) và hiệu ứng Aurora nhẹ
		cloudLayer.Transparency = 0.7
		skyEmitter.Enabled = true
		-- Đặt màu Aurora ban ngày (màu xanh không quá chói)
		skyEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 200))
		})
	else
		-- Ban đêm
		for key, asset in pairs(nightSky) do
			sky[key] = asset
		end
		-- Ẩn cloudLayer để không che bớt bầu trời đầy sao
		cloudLayer.Transparency = 1
		-- Tắt Aurora, có thể tạo thêm hiệu ứng sao lấp lánh riêng (ở đây đơn giản tắt)
		skyEmitter.Enabled = false
	end
end

spawn(function()
	while true do
		updateSkyAndAurora()
		wait(10)
	end
end)

---------------------------------------------
-- 4. HIỆU ỨNG NƯỚC PHẢN CHIẾU
---------------------------------------------
-- Nếu sử dụng Terrain có Water, Roblox engine tự xử lý phần phản chiếu.
-- Nếu dùng Part với Material Water, ta có thể thêm SurfaceAppearance.
for _, obj in pairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then
		-- Nếu chưa có SurfaceAppearance, thêm vào để cải thiện phản chiếu
		if not obj:FindFirstChildOfClass("SurfaceAppearance") then
			local sa = Instance.new("SurfaceAppearance")
			-- Giá trị phản chiếu vừa phải
			sa.Reflectance = 0.3
			-- Màu ánh sáng phản chiếu hơi ấm
			sa.Color = Color3.new(1, 1, 1)
			sa.Parent = obj
		end
	end
end

---------------------------------------------
-- 5. REFLECTION PROBE CHỈ HOẠT ĐỘNG TRONG VÙNG R = 35 XUNG QUANH PLAYER
---------------------------------------------
-- Sử dụng ReflectionProbe “di chuyển theo” người chơi, kích thước vùng bao phủ là 70 (bán kính 35)
local reflectionProbe = Instance.new("ReflectionProbe")
reflectionProbe.Name = "LocalReflectionProbe"
reflectionProbe.Size = Vector3.new(70, 70, 70)
reflectionProbe.ReflectionType = Enum.ReflectionType.Dynamic  -- cập nhật liên tục
reflectionProbe.Parent = Workspace

-- Cập nhật vị trí ReflectionProbe theo vị trí của nhân vật
local function updateReflectionProbe()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		reflectionProbe.CFrame = player.Character.HumanoidRootPart.CFrame
	end
end

RunService.RenderStepped:Connect(updateReflectionProbe)

---------------------------------------------
-- 6. ĐIỀU CHỈNH ÁNH SÁNG CHUNG (vừa ban ngày, vừa ban đêm)
---------------------------------------------
-- Có thể tinh chỉnh Brightness của Lighting theo thời gian để tránh ánh sáng “chói”
local function updateGlobalLighting()
	local timeOfDay = Lighting.TimeOfDay
	local hour = tonumber(timeOfDay:sub(1,2))
	if hour >= 6 and hour < 18 then
		-- Ban ngày: ánh sáng vừa phải
		Lighting.Brightness = 2
	else
		-- Ban đêm: ánh sáng dịu nhẹ
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
-- 7. PHẢN CHIẾU VẬT THỂ (CHỈ HIỆN Ở VÙNG GẦN PLAYER, dưới chân ~35)
---------------------------------------------
-- Lưu ý: Roblox không cho phép điều chỉnh “phản chiếu” của từng đối tượng một cách thủ công ngoài các hiệu ứng toàn cục.
-- Ta sử dụng ReflectionProbe để “điều chỉnh” vùng phản chiếu, do đó mọi vật thể trong vùng probe sẽ được hiển thị phản chiếu.
-- Ngoài ra, nếu một số đối tượng cần tăng hiệu ứng phản chiếu, bạn có thể thêm SurfaceAppearance với giá trị Reflectance cao.
local function enhanceLocalReflectivity()
	if not player.Character then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local origin = hrp.Position
	-- Duyệt qua các đối tượng trong Workspace (cẩn thận với hiệu năng)
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Chỉ áp dụng nếu vật ở gần vùng dưới chân (ví dụ khoảng cách từ vị trí của vật đến origin < 35 và nằm dưới)
			if (obj.Position - origin).Magnitude <= 35 and obj.Position.Y < origin.Y + 5 then
				-- Nếu chưa có SurfaceAppearance, thêm vào để tăng tính phản chiếu
				if not obj:FindFirstChildOfClass("SurfaceAppearance") then
					local sa = Instance.new("SurfaceAppearance")
					sa.Reflectance = 0.5  -- giá trị phản chiếu cao hơn trong vùng này
					sa.Color = obj.Color
					sa.Parent = obj
				end
			else
				-- Tùy chọn: nếu vật ra khỏi vùng, có thể giảm Reflectance (nếu đã có SurfaceAppearance)
				local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
				if sa then
					-- Cài đặt giá trị thấp hơn
					sa.Reflectance = 0.1
				end
			end
		end
	end
end

-- Cập nhật định kỳ (chú ý đến hiệu năng, khoảng 2 giây/lần)
spawn(function()
	while true do
		enhanceLocalReflectivity()
		wait(2)
	end
end)

print("RTX-like Effects advanced đã được kích hoạt (mô phỏng trong giới hạn Roblox).")
