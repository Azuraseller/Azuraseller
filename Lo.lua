local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- Hàm gây sát thương vô hạn
function InfiniteDamage(target)
    if target and target.Parent then
        local humanoid = target.Parent:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0 -- Đặt máu của đối tượng thành 0
        end
    end
end

-- Lắng nghe sự kiện khi người chơi nhấn chuột
mouse.Button1Down:Connect(function()
    local target = mouse.Target -- Lấy đối tượng mà chuột đang trỏ vào
    InfiniteDamage(target)
end)
