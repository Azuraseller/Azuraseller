-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Terrain = workspace:WaitForChild("Terrain")
local UserGameSettings = UserSettings().GameSettings

-- Cấu hình nâng cao
local SUN_GLARE_INTENSITY = 0.8
local STAR_TWINKLE_SPEED = 0.5
local PLAYER_BLOOM_RADIUS = 15

--=== CẢI TIẾN HỆ MẶT TRỜI 3D ===--
local function createVolumetricSun()
    local sun = workspace:FindFirstChild("VolumetricSun") or Instance.new("Part")
    sun.Name = "VolumetricSun"
    sun.Size = Vector3.new(30, 30, 30)
    sun.Material = Enum.Material.Neon
    sun.Color = Color3.new(1, 0.7, 0.4)
    sun.Position = Vector3.new(0, 500, 0)
    sun.Parent = workspace

    -- Hiệu ứng quang học 3D
    local sunCorona = Instance.new("ParticleEmitter")
    sunCorona.Texture = "rbxassetid://9019212836"
    sunCorona.Size = NumberSequence.new(15)
    sunCorona.Transparency = NumberSequence.new(0.5)
    sunCorona.Lifetime = NumberRange.new(1)
    sunCorona.Rate = 50
    sunCorona.Speed = NumberRange.new(5)
    sunCorona.Rotation = NumberRange.new(-180, 180)
    sunCorona.Parent = sun

    -- Lens flare động
    local flareContainer = Instance.new("BillboardGui")
    flareContainer.Size = UDim2.new(10, 0, 10, 0)
    flareContainer.Adornee = sun

    local flares = {
        {Position = UDim2.new(0.3, 0, 0.3, 0), Size = 0.4},
        {Position = UDim2.new(0.6, 0, 0.6, 0), Size = 0.6},
        {Position = UDim2.new(0.8, 0, 0.2, 0), Size = 0.3}
    }

    for _, flare in pairs(flares) do
        local flareImg = Instance.new("ImageLabel")
        flareImg.Image = "rbxassetid://9123478901"
        flareImg.Size = UDim2.new(flare.Size, 0, flare.Size, 0)
        flareImg.Position = flare.Position
        flareImg.BackgroundTransparency = 1
        flareImg.Parent = flareContainer
    end
    flareContainer.Parent = sun

    -- Tương tác với mây
    local cloudPass = Instance.new("ParticleEmitter")
    cloudPass.Texture = "rbxassetid://9123782910"
    cloudPass.Size = NumberSequence.new(50)
    cloudPass.Transparency = NumberSequence.new(0.7)
    cloudPass.Lifetime = NumberRange.new(20)
    cloudPass.Rate = 5
    cloudPass.Speed = NumberRange.new(10)
    cloudPass.Parent = sun
end

--=== HỆ NGÔI SAO ĐA TẦNG ===--
local function createGalaxyEffect()
    -- Tầng sao xa
    local distantStars = Instance.new("ParticleEmitter")
    distantStars.Texture = "rbxassetid://9122145822"
    distantStars.Size = NumberSequence.new(0.05)
    distantStars.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    distantStars.Lifetime = NumberRange.new(100)
    distantStars.Rate = 2000
    distantStars.Speed = NumberRange.new(0)
    distantStars.Parent = workspace:WaitForChild("StarField")

    -- Tầng sao nhấp nháy
    local twinkleStars = distantStars:Clone()
    twinkleStars.Texture = "rbxassetid://9122154637"
    twinkleStars.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    twinkleStars.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0.5)
    })
    twinkleStars.Parent = workspace:WaitForChild("StarField")

    -- Hiệu ứng thiên hà xoáy
    local spiralGalaxy = Instance.new("Part")
    spiralGalaxy.Size = Vector3.new(5000, 1, 5000)
    spiralGalaxy.Transparency = 1
    spiralGalaxy.Anchored = true
    spiralGalaxy.Parent = workspace

    local spiralParticles = Instance.new("ParticleEmitter")
    spiralParticles.Texture = "rbxassetid://9123478901"
    spiralParticles.Size = NumberSequence.new(0.1, 0.5)
    spiralParticles.Lifetime = NumberRange.new(50)
    spiralParticles.Rate = 500
    spiralParticles.RotSpeed = NumberRange.new(-50, 50)
    spiralParticles.VelocitySpread = 500
    spiralParticles.Parent = spiralGalaxy
end

--=== HỆ PHẢN CHIẾU NƯỚC THỰC TẾ ===--
local function createAdvancedWaterReflections()
    local waterMaterial = Enum.Material.Water
    local waveGenerator = Instance.new("Part")
    waveGenerator.Size = Vector3.new(1000, 1, 1000)
    waveGenerator.Transparency = 1
    waveGenerator.Anchored = true
    waveGenerator.Parent = workspace

    local waveEmitter = Instance.new("ParticleEmitter")
    waveEmitter.Texture = "rbxassetid://9123782910"
    waveEmitter.Size = NumberSequence.new(10)
    waveEmitter.Transparency = NumberSequence.new(0.7)
    waveEmitter.Lifetime = NumberRange.new(5)
    waveEmitter.Rate = 100
    waveEmitter.Speed = NumberRange.new(2)
    waveEmitter.Parent = waveGenerator

    workspace.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") and child.Material == waterMaterial then
            child.Reflectance = 0.85
            local ripples = Instance.new("Texture")
            rixtures.Texture = "rbxassetid://9123654789"
            ripples.StudsPerTileU = 2
            ripples.StudsPerTileV = 2
            ripples.Parent = child
        end
    end)
end

--=== HIỆU ỨNG QUANG HỌC NGƯỜI CHƠI ===--
local function createPlayerLightEffects()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local root = character:WaitForChild("HumanoidRootPart")
            
            -- Quầng sáng động
            local auraSphere = Instance.new("Part")
            auraSphere.Shape = Enum.PartType.Ball
            auraSphere.Size = Vector3.new(PLAYER_BLOOM_RADIUS*2, PLAYER_BLOOM_RADIUS*2, PLAYER_BLOOM_RADIUS*2)
            auraSphere.Transparency = 1
            auraSphere.Parent = character

            local weld = Instance.new("Weld")
            weld.Part0 = root
            weld.Part1 = auraSphere
            weld.Parent = auraSphere

            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = 2
            pointLight.Range = PLAYER_BLOOM_RADIUS
            pointLight.Shadows = true
            pointLight.Parent = auraSphere

            -- Hiệu ứng nhiễu động quang học
            RunService.Heartbeat:Connect(function()
                pointLight.Brightness = 1.5 + math.sin(os.clock()*5)*0.5
                auraSphere.Size = Vector3.new(
                    PLAYER_BLOOM_RADIUS*2 + math.random(),
                    PLAYER_BLOOM_RADIUS*2 + math.random(),
                    PLAYER_BLOOM_RADIUS*2 + math.random()
                )
            end)
        end)
    end)
end

--=== HỆ THỐNG THỜI TIẾT ĐỘNG ===--
local function createDynamicWeather()
    local weatherController = Instance.new("Part")
    weatherController.Name = "WeatherSystem"
    weatherController.Transparency = 1
    weatherController.Parent = workspace

    -- Tạo mây động
    local cloudEmitter = Instance.new("ParticleEmitter")
    cloudEmitter.Texture = "rbxassetid://9123782910"
    cloudEmitter.Size = NumberSequence.new(50, 100)
    cloudEmitter.Transparency = NumberSequence.new(0.7)
    cloudEmitter.Lifetime = NumberRange.new(60)
    cloudEmitter.Rate = 20
    cloudEmitter.Speed = NumberRange.new(10)
    cloudEmitter.Rotation = NumberRange.new(-180, 180)
    cloudEmitter.Parent = weatherController

    -- Hiệu ứng gió
    local windForce = Instance.new("BodyForce")
    windForce.Force = Vector3.new(math.random(-10,10), 0, math.random(-10,10))
    windForce.Parent = weatherController

    -- Tự động thay đổi thời tiết
    spawn(function()
        while true do
            wait(math.random(1200, 3000))
            windForce.Force = Vector3.new(math.random(-50,50), 0, math.random(-50,50))
            cloudEmitter.Rate = math.random(10, 50)
        end
    end)
end

--=== KÍCH HOẠT HỆ THỐNG ===--
createVolumetricSun()
createGalaxyEffect()
createAdvancedWaterReflections()
createPlayerLightEffects()
createDynamicWeather()

-- Cập nhật thời gian thực
RunService.RenderStepped:Connect(function()
    -- Đồng bộ hiệu ứng với thời gian trong game
    local timeFactor = math.sin(Lighting.ClockTime * math.pi/12)
    Lighting.Bloom.Intensity = 1.5 + timeFactor * 0.5
    Lighting.ColorCorrection.Contrast = 0.1 + timeFactor * 0.05
end)
