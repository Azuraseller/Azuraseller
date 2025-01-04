local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

function GodMode()
    -- Đặt MaxHealth thành giá trị rất lớn để máu vô hạn
    character.Humanoid.MaxHealth = math.huge
    character.Humanoid.Health = math.huge

    -- Tự động hồi máu nếu máu giảm
    character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if character.Humanoid.Health < math.huge then
            character.Humanoid.Health = math.huge
        end
    end)
end

GodMode()
