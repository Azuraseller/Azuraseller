-- Nút ESP
local ESPButton = Instance.new("TextButton")
ESPButton.Parent = ScreenGui
ESPButton.Size = UDim2.new(0, 30, 0, 30)
ESPButton.Position = UDim2.new(0.79, 0, 0.06, 0) -- Dưới nút X
ESPButton.Text = "ESP"
ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Mặc định tắt
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.Font = Enum.Font.SourceSans
ESPButton.TextSize = 18

local ESPActive = false -- Trạng thái ESP
local ESPRadius = 500 -- Bán kính hiển thị ESP
local ESPObjects = {} -- Lưu trữ các GUI ESP

-- Hàm tạo GUI hiển thị ESP
local function CreateESP(target)
    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Parent = target
    BillboardGui.Adornee = target:FindFirstChild("HumanoidRootPart")
    BillboardGui.Size = UDim2.new(6, 0, 3, 0)
    BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
    BillboardGui.AlwaysOnTop = true

    -- Hiển thị tên
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Parent = BillboardGui
    NameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu trắng
    NameLabel.TextScaled = true
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.Name = "NameLabel"

    -- Hiển thị máu
    local HealthBarBackground = Instance.new("Frame")
    HealthBarBackground.Parent = BillboardGui
    HealthBarBackground.Size = UDim2.new(1, 0, 0.2, 0)
    HealthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
    HealthBarBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Nền đen
    HealthBarBackground.Name = "HealthBarBackground"

    local HealthBar = Instance.new("Frame")
    HealthBar.Parent = HealthBarBackground
    HealthBar.Size = UDim2.new(1, 0, 1, 0)
    HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh lá
    HealthBar.Name = "HealthBar"

    -- Hiển thị khoảng cách
    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Parent = BillboardGui
    DistanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    DistanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu trắng
    DistanceLabel.TextScaled = true
    DistanceLabel.Font = Enum.Font.SourceSansBold
    DistanceLabel.Name = "DistanceLabel"

    return BillboardGui
end

-- Hàm cập nhật trạng thái ESP
local function UpdateESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Distance = (Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if Distance <= ESPRadius then
                    if not ESPObjects[Character] then
                        ESPObjects[Character] = CreateESP(Character)
                    end

                    -- Cập nhật GUI
                    local BillboardGui = ESPObjects[Character]
                    local NameLabel = BillboardGui:FindFirstChild("NameLabel")
                    local HealthBar = BillboardGui:FindFirstChild("HealthBarBackground"):FindFirstChild("HealthBar")
                    local DistanceLabel = BillboardGui:FindFirstChild("DistanceLabel")

                    NameLabel.Text = Player.Name
                    DistanceLabel.Text = string.format("Distance: %.1f", Distance)

                    -- Cập nhật thanh máu
                    local HealthPercentage = Character.Humanoid.Health / Character.Humanoid.MaxHealth
                    HealthBar.Size = UDim2.new(HealthPercentage, 0, 1, 0)
                    if HealthPercentage > 0.5 then
                        HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá
                    elseif HealthPercentage > 0.2 then
                        HealthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Vàng
                    else
                        HealthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ
                    end
                elseif ESPObjects[Character] then
                    ESPObjects[Character]:Destroy()
                    ESPObjects[Character] = nil
                end
            elseif ESPObjects[Character] then
                ESPObjects[Character]:Destroy()
                ESPObjects[Character] = nil
            end
        end
    end
end

-- Nút bật/tắt ESP
ESPButton.MouseButton1Click:Connect(function()
    ESPActive = not ESPActive
    if ESPActive then
        ESPButton.Text = "ON"
        ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Màu xanh lá khi bật
    else
        ESPButton.Text = "OFF"
        ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ khi tắt
        -- Xóa tất cả ESP khi tắt
        for _, gui in pairs(ESPObjects) do
            gui:Destroy()
        end
        ESPObjects = {}
    end
end)

-- Liên tục cập nhật ESP
RunService.RenderStepped:Connect(function()
    if ESPActive then
        UpdateESP()
    end
end)
