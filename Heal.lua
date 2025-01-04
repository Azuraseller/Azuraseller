local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")

local maxHealth = humanoid.MaxHealth -- Lấy máu tối đa
local previousHealth = humanoid.Health -- Lưu mốc máu ban đầu

function GodMode()
    RunService.Heartbeat:Connect(function()
        if humanoid.Health < previousHealth - 100 then
            humanoid.Health = maxHealth -- Hồi đầy máu
            previousHealth = maxHealth -- Cập nhật mốc mới là đầy máu
        else
            previousHealth = humanoid.Health -- Cập nhật mốc hiện tại
        end
    end)
end

GodMode()
