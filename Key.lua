-- // 🧟 SURVIVING THE APOCALYPSE - KILL AURA 1 HIT v2.0
-- // Optimized & Stealth - Tested concept 2026

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Config = {
    Enabled = true,
    Range = 28,
    Delay = 0.07,
    OneHit = true,
    IncludePlayers = false
}

local connections = {}

-- Tìm Remote Damage (thường nằm trong ReplicatedStorage hoặc Character)
local damageRemote = nil
pcall(function()
    damageRemote = ReplicatedStorage:FindFirstChild("DamageEvent") or 
                   ReplicatedStorage:FindFirstChild("ZombieDamage") or
                   ReplicatedStorage:FindFirstChild("HitEvent")
end)

local function getZombies()
    local zombies = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum = v.Humanoid
            if hum.Health > 0 then
                local isPlayer = Players:GetPlayerFromCharacter(v) \~= nil
                if not isPlayer or Config.IncludePlayers then
                    if v.Name:lower():find("zombie") or hum.DisplayName:lower():find("zombie") or not isPlayer then
                        table.insert(zombies, v)
                    end
                end
            end
        end
    end
    return zombies
end

local function oneHitKill(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    local hum = target.Humanoid
    local root = target:FindFirstChild("HumanoidRootPart")
    
    if not root then return end

    pcall(function()
        if Config.OneHit then
            -- Layer 1: Set health trực tiếp
            hum.Health = 0
            
            -- Layer 2: Nếu có remote thì fire thêm (rất mạnh)
            if damageRemote then
                damageRemote:FireServer(hum, 999999, "Head")
            end
            
            -- Layer 3: Simulate hit mạnh (dành cho melee system)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myRoot = char.HumanoidRootPart
                firetouchinterest(myRoot, root, 0)
                task.wait()
                firetouchinterest(myRoot, root, 1)
            end
        end
    end)
end

-- Main Loop
local auraConn = RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local myRoot = LocalPlayer.Character.HumanoidRootPart
    local zombies = getZombies()

    for _, zombie in ipairs(zombies) do
        local zRoot = zombie:FindFirstChild("HumanoidRootPart")
        if zRoot then
            local dist = (myRoot.Position - zRoot.Position).Magnitude
            if dist <= Config.Range then
                oneHitKill(zombie)
                task.wait(Config.Delay)
            end
        end
    end
end)

table.insert(connections, auraConn)

-- Toggle bằng phím E
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        Config.Enabled = not Config.Enabled
        game.StarterGui:SetCore("SendNotification", {
            Title = "Kill Aura",
            Text = "Status: " .. (Config.Enabled and "ENABLED" or "DISABLED"),
            Duration = 2
        })
    end
end)

print("✅ Kill Aura v2.0 Loaded | Nhấn E để bật/tắt | Range: " .. Config.Range)

-- Cleanup
LocalPlayer.CharacterRemoving:Connect(function()
    for _, c in pairs(connections) do c:Disconnect() end
end)
