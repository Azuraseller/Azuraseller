local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local LERP_SPEED = 10  -- Tốc độ xoay (radians/giây), bạn có thể điều chỉnh
local smoothRotation = true  -- Mặc định bật chế độ xoay mượt

-- Hàm xử lý khi nhân vật (Character) được tạo
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.AutoRotate = false  -- Tắt xoay tự động của Roblox
end

-- Nếu nhân vật đã có, áp dụng ngay
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Nhấn phím T để bật/tắt chế độ xoay mượt
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        smoothRotation = not smoothRotation
        if smoothRotation then
            print("Chế độ xoay mượt: BẬT")
        else
            print("Chế độ xoay mượt: TẮT")
        end
    end
end)

-- Cập nhật hướng nhân vật theo hướng camera mỗi frame
RunService.RenderStepped:Connect(function(delta)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camera = workspace.CurrentCamera
    local _, cameraYaw, _ = camera.CFrame:ToEulerAnglesYXZ()
    
    local currentCFrame = hrp.CFrame
    local currentPos = currentCFrame.Position
    local _, currentYaw, _ = currentCFrame:ToEulerAnglesYXZ()
    
    local desiredYaw = cameraYaw

    if smoothRotation then
        -- Tính hiệu lệch góc (đảm bảo hiệu lệch nhỏ nhất, xử lý trường hợp vượt quá 360°)
        local deltaAngle = (desiredYaw - currentYaw + math.pi) % (2 * math.pi) - math.pi
        local newYaw = currentYaw + deltaAngle * LERP_SPEED * delta
        hrp.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, newYaw, 0)
    else
        -- Xoay tức thì theo hướng camera
        hrp.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, desiredYaw, 0)
    end
end)
