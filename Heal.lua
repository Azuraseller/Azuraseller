local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local previousHealth = humanoid.Health -- Lưu lượng máu hiện tại làm mốc

function GodMode()
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health < previousHealth then
            humanoid.Health = previousHealth -- Hồi lại lượng máu trước đó
        end
        previousHealth = humanoid.Health -- Cập nhật mốc mới
    end)
end

GodMode()
