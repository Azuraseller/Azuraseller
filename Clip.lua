-- LocalScript

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local noclipEnabled = false
local button = nil

-- Tạo nút On/Off ở góc phải phía trên
local function createButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player.PlayerGui

    button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 50)
    button.Position = UDim2.new(1, -110, 0, 10) -- Góc phải phía trên
    button.Text = "Noclip: Off" -- Mặc định là Off
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        noclipEnabled = not noclipEnabled
        button.Text = "Noclip: " .. (noclipEnabled and "On" or "Off")
    end)
end

-- Gọi hàm tạo nút
createButton()

-- Hàm kiểm tra xem có vật liệu dưới chân không
local function isGrounded()
    local ray = Ray.new(humanoidRootPart.Position, Vector3.new(0, -5, 0)) -- Bắn tia xuống dưới 5 đơn vị
    local hit, position = workspace:FindPartOnRay(ray, character) -- Bỏ qua nhân vật
    return hit ~= nil -- Trả về true nếu có vật liệu dưới chân
end

-- Hàm xử lý Noclip
local function onNoclip()
    if noclipEnabled then
        -- Bật Noclip: cho phép đi xuyên qua các vật liệu ngang
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        -- Tắt Noclip: khôi phục va chạm bình thường
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Cập nhật liên tục để xử lý vật liệu dưới chân
game:GetService("RunService").Stepped:Connect(function()
    if noclipEnabled then
        if isGrounded() then
            -- Nếu có vật liệu dưới chân, giữ nhân vật không rơi xuống
            humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 0, humanoidRootPart.Velocity.Z)
        end
    end
    onNoclip()
end)
