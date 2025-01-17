-- RTX NÂNG CẤP CAO NHẤT DỰA TRÊN CHI TIẾT TỪ 3 ẢNH
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Cấu hình Lighting tối đa
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 5
Lighting.EnvironmentSpecularScale = 5
Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
Lighting.FogEnd = 1000
Lighting.FogStart = 200
Lighting.FogColor = Color3.fromRGB(100, 100, 150)
Lighting.ClockTime = 12
Lighting.Technology = Enum.Technology.Future

-- Hiệu ứng Bloom (Glow mạnh mẽ)
local bloomEffect = Instance.new("BloomEffect", Lighting)
bloomEffect.Intensity = 10
bloomEffect.Threshold = 0.1
bloomEffect.Size = 56

-- Hiệu ứng SunRays (Tia sáng năng lượng)
local sunRaysEffect = Instance.new("SunRaysEffect", Lighting)
sunRaysEffect.Intensity = 1
sunRaysEffect.Spread = 1.8

-- Hiệu ứng ColorCorrection (Tăng cường màu sắc)
local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrection.Saturation = 1
colorCorrection.Contrast = 1.2
colorCorrection.TintColor = Color3.fromRGB(255, 240, 200)

-- Hiệu ứng DepthOfField (Chiều sâu trường ảnh)
local depthOfField = Instance.new("DepthOfFieldEffect", Lighting)
depthOfField.FarIntensity = 0.4
depthOfField.FocusDistance = 40
depthOfField.InFocusRadius = 15
depthOfField.NearIntensity = 0.8

-- Hiệu ứng Atmosphere (Không khí nâng cao)
local atmosphere = Instance.new("Atmosphere", Lighting)
atmosphere.Density = 0.6
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(180, 200, 255)
atmosphere.Decay = Color3.fromRGB(100, 120, 150)
atmosphere.Glare = 0.5
atmosphere.Haze = 0.4

-- Hiệu ứng nước phản chiếu
local function applyWaterReflection(part)
    if part:IsA("BasePart") and part.Material == Enum.Material.Water then
        local reflection = Instance.new("SurfaceAppearance", part)
        reflection.NormalMap = "rbxassetid://12345678" -- Thay bằng Normal Map thực tế
        reflection.MetalnessMap = "rbxassetid://87654321" -- Thay bằng Metalness Map thực tế
        reflection.RoughnessMap = "rbxassetid://23456789" -- Thay bằng Roughness Map thực tế
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    applyWaterReflection(part)
end

-- Hiệu ứng năng lượng phát sáng
local function createEnergyEffect(part)
    if part:IsA("BasePart") and not part:FindFirstChild("EnergyGlow") then
        local energyGlow = Instance.new("ParticleEmitter", part)
        energyGlow.Texture = "rbxassetid://98765432" -- Thay bằng texture năng lượng thực tế
        energyGlow.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100))
        }
        energyGlow.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 5),
            NumberSequenceKeypoint.new(1, 0)
        }
        energyGlow.Lifetime = NumberRange.new(1, 2)
        energyGlow.Rate = 50
        energyGlow.Speed = NumberRange.new(0, 5)
        energyGlow.Enabled = true
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    createEnergyEffect(part)
end

-- Hiệu ứng bóng nâng cao
Lighting.ShadowSoftness = 0.1
Lighting.EnvironmentSpecularScale = 10
Lighting.EnvironmentDiffuseScale = 10

-- Hiệu ứng ánh sáng động theo thời gian
local function updateLighting(clockTime)
    Lighting.ClockTime = clockTime
    if clockTime >= 6 and clockTime <= 18 then
        -- Ban ngày
        Lighting.Brightness = 4.5
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        sunRaysEffect.Intensity = 1
        colorCorrection.TintColor = Color3.fromRGB(255, 245, 230)
        atmosphere.Density = 0.5
    elseif clockTime > 18 and clockTime <= 20 then
        -- Hoàng hôn
        Lighting.Brightness = 3.5
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 120, 100)
        sunRaysEffect.Intensity = 1.2
        colorCorrection.TintColor = Color3.fromRGB(255, 200, 180)
        atmosphere.Density = 0.6
    elseif clockTime >= 4 and clockTime < 6 then
        -- Bình minh
        Lighting.Brightness = 3.5
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 200)
        sunRaysEffect.Intensity = 0.9
        colorCorrection.TintColor = Color3.fromRGB(255, 220, 240)
        atmosphere.Density = 0.55
    else
        -- Ban đêm
        Lighting.Brightness = 2.5
        Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 100)
        sunRaysEffect.Intensity = 0.5
        colorCorrection.TintColor = Color3.fromRGB(200, 200, 255)
        atmosphere.Density = 0.7
    end
end

-- Cập nhật ánh sáng theo thời gian
RunService.Heartbeat:Connect(function()
    local currentTime = tick() % 86400 / 3600 -- Giả lập 1 ngày trong 24 giờ
    updateLighting(currentTime)
end)

-- In thông báo khi script chạy
print("RTX siêu nâng cấp đã được kích hoạt!")
