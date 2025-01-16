-- Đặt script này vào ServerScriptService hoặc Workspace

-- Lấy Lighting service
local Lighting = game:GetService("Lighting")

-- Xóa các hiệu ứng cũ nếu có
for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        effect:Destroy()
    end
end

-- Cấu hình ánh sáng dịu và bóng đổ mượt
Lighting.Brightness = 3 -- Độ sáng tổng thể
Lighting.Ambient = Color3.fromRGB(180, 180, 180) -- Ánh sáng môi trường dịu
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) -- Ánh sáng ngoài trời
Lighting.EnvironmentDiffuseScale = 3 -- Độ khuếch tán ánh sáng
Lighting.EnvironmentSpecularScale = 4 -- Độ phản chiếu ánh sáng
Lighting.GlobalShadows = true -- Bật bóng đổ toàn cục
Lighting.ClockTime = 14 -- Thời gian trong ngày (14 = chiều)
Lighting.GeographicLatitude = 45 -- Tọa độ địa lý (góc ánh sáng mặt trời)
Lighting.ShadowSoftness = 0.05 -- Độ mềm của bóng
Lighting.Technology = Enum.Technology.Future -- Công nghệ ánh sáng Future

-- Thêm hiệu ứng Bloom (ánh sáng chói nhẹ)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 2 -- Độ sáng của hiệu ứng
bloom.Size = 35 -- Kích thước hiệu ứng
bloom.Threshold = 0.85 -- Ngưỡng hiệu ứng
bloom.Parent = Lighting

-- Thêm hiệu ứng Sun Rays (tia sáng mặt trời)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.5 -- Cường độ
sunRays.Spread = 1 -- Độ lan tỏa
sunRays.Parent = Lighting

-- Thêm hiệu ứng Color Correction (Hiệu chỉnh màu sắc dịu)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.15 -- Độ sáng
colorCorrection.Contrast = 0.4 -- Độ tương phản
colorCorrection.Saturation = 0.7 -- Độ bão hòa
colorCorrection.TintColor = Color3.fromRGB(255, 240, 220) -- Tông màu dịu
colorCorrection.Parent = Lighting

-- Thêm hiệu ứng Depth of Field (Làm mờ xa/gần)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.InFocusRadius = 200 -- Bán kính lấy nét
depthOfField.NearIntensity = 0.4 -- Cường độ gần
depthOfField.FarIntensity = 0.3 -- Cường độ xa
depthOfField.FocusDistance = 100 -- Khoảng cách lấy nét
depthOfField.Parent = Lighting

-- Tạo nền siêu bóng loáng
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        -- Thêm SurfaceAppearance nếu chưa có
        if not obj:FindFirstChild("SurfaceAppearance") then
            local surfaceAppearance = Instance.new("SurfaceAppearance")
            surfaceAppearance.Reflectance = 0.7 -- Độ phản chiếu cao
            surfaceAppearance.Parent = obj
        end

        -- Cấu hình vật liệu để tăng bóng loáng
        obj.Material = Enum.Material.SmoothPlastic
    end
end

-- Tăng độ chi tiết bóng đổ cho người chơi
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CastShadow = true -- Bật bóng đổ chi tiết
            end
        end
    end)
end)

print("Ultra RTX-style graphics applied!")
