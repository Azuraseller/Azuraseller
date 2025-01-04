local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local maxHealth = humanoid.MaxHealth -- Lấy máu tối đa
local isHealing = false -- Biến kiểm tra đang hồi máu

function GodMode()
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health < maxHealth and not isHealing then
            isHealing = true -- Đánh dấu đang hồi máu
            task.delay(1, function()
                humanoid.Health = maxHealth -- Hồi đầy máu sau 1 giây
                isHealing = false -- Đặt lại trạng thái hồi máu
            end)
        end
    end)
end

GodMode()
