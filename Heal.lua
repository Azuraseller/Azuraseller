local player = game.Players.LocalPlayer

function SetupGodMode(character)
    local humanoid = character:WaitForChild("Humanoid")
    local maxHealth = humanoid.MaxHealth -- Lấy máu tối đa
    local isHealing = false -- Biến kiểm tra đang hồi máu

    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health < maxHealth and not isHealing then
            isHealing = true -- Đánh dấu đang hồi máu
            task.delay(0.3, function()
                humanoid.Health = maxHealth -- Hồi đầy máu sau 0.3 giây
                isHealing = false -- Đặt lại trạng thái hồi máu
            end)
        end
    end)

    humanoid.Died:Connect(function()
        print("Player has died, waiting for respawn...")
    end)
end

-- Thiết lập khi nhân vật được thêm vào
player.CharacterAdded:Connect(function(character)
    SetupGodMode(character)
end)

-- Chạy script lần đầu cho nhân vật hiện tại
if player.Character then
    SetupGodMode(player.Character)
end
