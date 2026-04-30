-- // 🧟 SURVIVING THE APOCALYPSE - KILL AURA 1 HIT v4.0
-- // Optimized for Delta Executor on Mobile
-- // Nhấn E để BẬT / TẮT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

getgenv().STA_KillAura = getgenv().STA_KillAura or {
    Enabled = false,
    Range = 25,
    Delay = 0.08,
}

local Config = getgenv().STA_KillAura

print("🔄 Đang load Kill Aura cho Delta Mobile...")
game.StarterGui:SetCore("SendNotification", {
    Title = "Kill Aura",
    Text = "Đang load phiên bản Mobile...",
    Duration = 3
})

local function getZombies()
    local zombies = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum = v.Humanoid
            if hum.Health > 0 then
                local isPlayer = Players:GetPlayerFromCharacter(v) \~= nil
                if not isPlayer then
                    table.insert(zombies, v)
                end
            end
        end
    end
    return zombies
end

local function KillAuraLoop()
    if not Config.Enabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local myRoot = LocalPlayer.Character.HumanoidRootPart
    local zombies = getZombies()

    for _, zombie in ipairs(zombies) do
        pcall(function()
            local zRoot = zombie:FindFirstChild("HumanoidRootPart")
            if zRoot then
                local dist = (myRoot.Position - zRoot.Position).Magnitude
                if dist <= Config.Range and dist > 3 then
                    local hum = zombie.Humanoid
                    hum.Health = 0   -- 1 Hit chính

                    -- Simulate touch (hữu ích trên mobile)
                    firetouchinterest(myRoot, zRoot, 0)
                    task.wait(0.015)
                    firetouchinterest(myRoot, zRoot, 1)

                    task.wait(Config.Delay)
                end
            end
        end)
    end
end

-- Main Loop (Heartbeat nhẹ hơn trên mobile)
local mainConn = RunService.Heartbeat:Connect(KillAuraLoop)

-- Toggle bằng phím E (hoặc Virtual Button nếu Delta hỗ trợ)
local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        Config.Enabled = not Config.Enabled
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "Kill Aura",
            Text = "Trạng thái: " .. (Config.Enabled and "BẬT ✅" or "TẮT ❌") .. "\nRange: " .. Config.Range,
            Duration = 4
        })
        
        print("Kill Aura:", Config.Enabled and "BẬT" or "TẮT")
    end
end)

print("✅ Kill Aura Mobile Loaded!")
print("Nhấn phím **E** để bật/tắt Kill Aura")
game.StarterGui:SetCore("SendNotification", {
    Title = "Kill Aura v4.0",
    Text = "Load thành công!\nNhấn E để bật/tắt",
    Duration = 5
})

-- Cleanup
LocalPlayer.CharacterRemoving:Connect(function()
    pcall(function() mainConn:Disconnect() end)
    pcall(function() toggleConn:Disconnect() end)
end)
