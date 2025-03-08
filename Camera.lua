local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Tạo RemoteEvent để giao tiếp giữa client và server
local AttackEvent = Instance.new("RemoteEvent")
AttackEvent.Name = "AttackEvent"
AttackEvent.Parent = ReplicatedStorage

-- Các thông số có thể tùy chỉnh
local PUSH_RADIUS = 45 -- Bán kính đẩy sinh vật
local KILL_RADIUS = 60 -- Bán kính giết sinh vật
local PUSH_FORCE = 500 -- Lực đẩy
local ATTACK_DAMAGE = 20 -- Sát thương khi tấn công

-- Hàm xử lý sinh vật
local function processEnemies(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    -- Kích hoạt God Mode
    humanoid:SetAttribute("GodMode", true)
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge

    -- Duyệt qua các sinh vật trong workspace
    for _, enemy in pairs(workspace:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy ~= character then
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemy:FindFirstChild("Humanoid")
            if enemyRoot and enemyHumanoid then
                local distance = (rootPart.Position - enemyRoot.Position).Magnitude

                -- Giết sinh vật trong bán kính KILL_RADIUS
                if distance <= KILL_RADIUS then
                    enemyHumanoid:TakeDamage(enemyHumanoid.Health)
                    -- Hiệu ứng khi tiêu diệt
                    local explosion = Instance.new("Explosion")
                    explosion.Position = enemyRoot.Position
                    explosion.BlastRadius = 5
                    explosion.BlastPressure = 0 -- Không gây lực đẩy
                    explosion.Parent = workspace
                    Debris:AddItem(explosion, 1)
                -- Đẩy sinh vật trong bán kính PUSH_RADIUS
                elseif distance <= PUSH_RADIUS then
                    local direction = (enemyRoot.Position - rootPart.Position).Unit
                    local bodyForce = Instance.new("BodyVelocity")
                    bodyForce.Velocity = direction * PUSH_FORCE
                    bodyForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bodyForce.Parent = enemyRoot
                    Debris:AddItem(bodyForce, 0.1)
                end
            end
        end
    end
end

-- Xử lý khi người chơi tham gia
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = 20 -- Tăng tốc độ di chuyển
        humanoid.JumpPower = 60 -- Tăng lực nhảy

        -- Lặp liên tục để xử lý sinh vật
        while task.wait(0.1) do
            if character and character.Parent then
                processEnemies(player)
            else
                break
            end
        end
    end)
end)

-- Xử lý tấn công từ client
AttackEvent.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character.HumanoidRootPart
    local direction = rootPart.CFrame.LookVector
    local ray = Ray.new(rootPart.Position, direction * 100)
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction)

    if raycastResult then
        local hitPart = raycastResult.Instance
        local enemy = hitPart:FindFirstAncestorOfClass("Model")
        if enemy and enemy:FindFirstChild("Humanoid") then
            local enemyHumanoid = enemy.Humanoid
            enemyHumanoid:TakeDamage(ATTACK_DAMAGE)
            -- Hiệu ứng tấn công
            local spark = Instance.new("Sparkles")
            spark.Parent = hitPart
            Debris:AddItem(spark, 0.5)
        end
    end
end)
