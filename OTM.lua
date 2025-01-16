-- Đặt script này vào ServerScriptService hoặc Workspace

-- Lấy Lighting service
local Lighting = game:GetService("Lighting")

-- Xóa các hiệu ứng cũ nếu có
for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        effect:Destroy()
    end
end

-- Cấu hình ánh sáng nâng cao
Lighting.Brightness = 2 -- Giảm độ sáng tổng thể để phù hợp với ánh sáng dịu
Lighting.Ambient = Color3.fromRGB(150, 150, 150) -- Ánh sáng môi trường trung tính
Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200) -- Ánh sáng ngoài trời dịu
Lighting.EnvironmentDiffuseScale = 4 -- Độ khuếch tán ánh sáng cao
Lighting.EnvironmentSpecularScale = 5 -- Độ phản chiếu ánh sáng cao
Lighting.GlobalShadows = true -- Bật bóng đổ toàn cục
Lighting.ClockTime = 13 -- Thời gian trong ngày (13 = trưa)
Lighting.GeographicLatitude = 45 -- Tọa độ địa lý (góc ánh sáng mặt trời)
Lighting.ShadowSoftness = 0.03 -- Độ mềm của bóng
Lighting.Technology = Enum.Technology.Future -- Công nghệ ánh sáng Future

-- Thêm hiệu ứng Bloom (ánh sáng chói tự nhiên)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 2.5 -- Độ sáng của hiệu ứng
bloom.Size = 40 -- Kích thước hiệu ứng
bloom.Threshold = 0.9 -- Ngưỡng hiệu ứng
bloom.Parent = Lighting

-- Thêm hiệu ứng Sun Rays (tia sáng mặt trời)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.7 -- Cường độ
sunRays.Spread = 0.9 -- Độ lan tỏa
sunRays.Parent = Lighting

-- Thêm hiệu ứng Color Correction (Hiệu chỉnh màu sắc chân thực)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.1 -- Độ sáng
colorCorrection.Contrast = 0.6 -- Độ tương phản
colorCorrection.Saturation = 0.9 -- Độ bão hòa
colorCorrection.TintColor = Color3.fromRGB(255, 245, 230) -- Tông màu dịu
colorCorrection.Parent = Lighting

-- Thêm hiệu ứng Depth of Field (Làm mờ xa/gần tự nhiên)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.InFocusRadius = 100 -- Bán kính lấy nét
depthOfField.NearIntensity = 0.5 -- Cường độ gần
depthOfField.FarIntensity = 0.4 -- Cường độ xa
depthOfField.FocusDistance = 50 -- Khoảng cách lấy nét
depthOfField.Parent = Lighting

-- Tạo nền đất siêu bóng loáng phản chiếu
local function createReflectiveGround()
    local ground = Instance.new("Part")
    ground.Name = "ReflectiveGround"
    ground.Size = Vector3.new(1000, 1, 1000) -- Kích thước nền đất
    ground.Position = Vector3.new(0, 0, 0) -- Đặt nền đất ở gốc tọa độ
    ground.Anchored = true
    ground.Material = Enum.Material.SmoothPlastic -- Bề mặt mịn
    ground.Reflectance = 0.98 -- Độ phản chiếu cực cao
    ground.Color = Color3.fromRGB(120, 120, 120) -- Màu xám trung tính
    ground.Parent = workspace

    -- Thêm SurfaceAppearance để tăng phản chiếu
    local surfaceAppearance = Instance.new("SurfaceAppearance")
    surfaceAppearance.Reflectance = 0.98 -- Độ phản chiếu cao
    surfaceAppearance.Parent = ground
end

-- Gọi hàm tạo nền đất
createReflectiveGround()

-- Tăng độ chi tiết bóng đổ cho nhân vật và vật thể
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CastShadow = true -- Bật bóng đổ chi tiết
            end
        end
    end)
end)

-- Cải thiện bóng và phản chiếu cho các vật thể trong Workspace
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        obj.CastShadow = true -- Bật bóng đổ
        obj.Material = Enum.Material.Glass -- Thay đổi vật liệu để tăng phản chiếu
        obj.Reflectance = 0.6 -- Tăng phản chiếu
    end
end

print("Maximum RTX-style graphics applied!")
