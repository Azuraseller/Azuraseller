local player = game.Players.LocalPlayer
local character = player.Character
 
function GodMode()
    character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if character.Humanoid.Health < 100 then
            character.Humanoid.Health = 100
        end
    end)
end
 
 
GodMode()
