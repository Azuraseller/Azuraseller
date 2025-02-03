-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Cấu hình
local SUN_RADIUS = 50
local STAR_DENSITY = 1500
local MAX_METEORS = 3
local PLAYER_LIGHT_RANGE = 15

--=== HỆ THỐNG TỰ SỬA LỖI ===--
local function SafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        warn("Lỗi hệ thống:", err)
    end
end

--=== CẢI TIẾN MẶT TRỜI ĐỘNG ===--
local function CreateSunSystem()
    local sun = Instance.new("Part")
    sun.Name = "AdvancedSun"
    sun.Size = Vector3.new(SUN_RADIUS, SUN_RADIUS, SUN_RADIUS)
    sun.Shape = Enum.PartType.Ball
    sun.Material = Enum.Material.Neon
    sun.Color = Color3.new(1, 0.75, 0.5)
    sun.Anchored = true
    sun.CanCollide = false
    sun.Position = Vector3.new(0, 500, 0)
    sun.Parent = workspace

    -- Hiệu ứng quang học
    local sunGlow = Instance.new("PointLight")
    sunGlow.Brightness = 2
    sunGlow.Range = 1000
    sunGlow.Color = sun.Color
    sunGlow.Parent = sun

    -- Tạo tia sáng
    local sunBeam = Instance.new("Beam")
    sunBeam.Attachment0 = Instance.new("Attachment", sun)
    sunBeam.Attachment1 = Instance.new("Attachment", workspace.Terrain)
    sunBeam.Width0 = 10
    sunBeam.Width1 = 100
    sunBeam.Color = ColorSequence.new(sun.Color)
    sunBeam.Parent = sun

    return sun
end

--=== HỆ SAO THẾ HỆ MỚI ===--
local function CreateStarField()
    local starContainer = Instance.new("Part")
    starContainer.Name = "StarField"
    starContainer.Size = Vector3.new(10000, 1, 10000)
    starContainer.Transparency = 1
    starContainer.Anchored = true
    starContainer.CanCollide = false
    starContainer.Parent = workspace

    local stars = Instance.new("ParticleEmitter")
    stars.Texture = "rbxassetid://9122145822" -- Thay bằng ID texture của bạn
    stars.Size = NumberSequence.new(0.05)
    stars.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    stars.Lifetime = NumberRange.new(100)
    stars.Rate = STAR_DENSITY
    stars.Speed = NumberRange.new(0)
    stars.Parent = starContainer

    -- Sao nhấp nháy
    RunService.Heartbeat:Connect(function()
        stars.Transparency = NumberSequence.new(math.random() * 0.5)
    end)
end

--=== HỆ SAO BĂNG THÔNG MINH ===--
local function CreateMeteorShower()
    local meteorTypes = {
        {color = Color3.new(1, 0.3, 0.2), speed = 75},
        {color = Color3.new(0.4, 0.8, 1), speed = 100},
        {color = Color3.new(1, 1, 0.6), speed = 60}
    }

    local activeMeteors = 0

    local function CreateMeteor()
        if activeMeteors >= MAX_METEORS then return end
        activeMeteors += 1

        local meteorData = meteorTypes[math.random(#meteorTypes)]
        local meteor = Instance.new("Part")
        meteor.Size = Vector3.new(3, 3, 10)
        meteor.Color = meteorData.color
        meteor.Material = Enum.Material.Neon
        meteor.CFrame = CFrame.new(
            math.random(-1500, 1500), 
            math.random(500, 700), 
            math.random(-1500, 1500)
        ) * CFrame.Angles(0, math.rad(math.random(360)), 0)
        meteor.Parent = workspace

        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(meteor.Color)
        trail.Transparency = NumberSequence.new(0.7)
        trail.LightEmission = 0.8
        trail.Parent = meteor

        local movement = TweenService:Create(
            meteor,
            TweenInfo.new(meteorData.speed/50, Enum.EasingStyle.Linear),
            {CFrame = meteor.CFrame * CFrame.new(0, -2000, 0)}
        )
        
        movement:Play()
        movement.Completed:Connect(function()
            meteor:Destroy()
            activeMeteors -= 1
        end)
    end

    spawn(function()
        while true do
            SafeCall(CreateMeteor)
            wait(math.random(5, 15))
        end
    end)
end

--=== HỆ ÁNH SÁNG NGƯỜI CHƠI ===--
local function SetupPlayerEffects()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoidRoot = character:WaitForChild("HumanoidRootPart")
            
            local auraLight = Instance.new("PointLight")
            auraLight.Name = "PlayerAura"
            auraLight.Brightness = 1.5
            auraLight.Range = PLAYER_LIGHT_RANGE
            auraLight.Color = Color3.new(0.8, 0.9, 1)
            auraLight.Parent = humanoidRoot

            -- Hiệu ứng nhấp nháy
            spawn(function()
                while auraLight.Parent do
                    auraLight.Brightness = 1 + math.sin(os.clock() * 5) * 0.5
                    wait(0.1)
                end
            end)
        end)
    end)
end

--=== HỆ THỐNG ÁNH SÁNG THÔNG MINH ===--
local function UpdateLightingSystem()
    local sun = workspace:FindFirstChild("AdvancedSun")
    if not sun then return end

    RunService.Heartbeat:Connect(function()
        SafeCall(function()
            local timeOfDay = Lighting.ClockTime
            local sunPosition = Vector3.new(
                math.cos(math.rad(timeOfDay * 15 - 90)) * 500,
                math.sin(math.rad(timeOfDay * 15 - 90)) * 500,
                0
            )
            
            sun.Position = sunPosition + Vector3.new(0, 500, 0)
            Lighting.SunColor = Color3.new(
                math.clamp(1 - (timeOfDay - 12)/6, 0.3, 1),
                math.clamp(0.8 - (timeOfDay - 12)/8, 0.2, 0.8),
                math.clamp(0.6 - (timeOfDay - 12)/10, 0.1, 0.6)
            )
        end)
    end)
end

--=== KHỞI ĐỘNG HỆ THỐNG ===--
SafeCall(CreateSunSystem)
SafeCall(CreateStarField)
SafeCall(CreateMeteorShower)
SafeCall(SetupPlayerEffects)
SafeCall(UpdateLightingSystem)

-- Debug
print("Hệ thống ánh sáng đã được kích hoạt thành công!")
