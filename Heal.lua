local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local maxHealth = humanoid.MaxHealth -- Lấy giá trị máu tối đa
local previousHealth = humanoid.Health -- Lưu lượng máu hiện tại làm mốc

function GodMode()
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if previousHealth - humanoid.Health >= 100 then
            humanoid.Health = maxHealth -- Hồi đầy máu
            previousHealth = maxHealth -- Cập nhật mốc mới là đầy máu
        else
            previousHealth = humanoid.Health -- Cập nhật mốc hiện tại
        end
    end)
end

GodMode()
