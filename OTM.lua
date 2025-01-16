-- Đặt script này vào ServerScriptService hoặc Workspace

-- Lấy Lighting service
local Lighting = game:GetService("Lighting")

-- Xóa các hiệu ứng cũ nếu có
for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        effect:Destroy()
    end
end

-- Cấu hình ánh sáng ban ngày
Lighting.Brightness = 4 -- Độ sáng tổng thể
Lighting.Ambient = Color3.fromRGB(200, 200, 200) -- Ánh sáng môi trường
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) -- Ánh sáng ngoài trời
Lighting.EnvironmentDiffuseScale = 3 -- Độ khuếch tán ánh sáng
Lighting.EnvironmentSpecularScale = 2.5 -- Độ phản chiếu ánh sáng
Lighting.GlobalShadows = true -- Bật bóng đổ toàn cục
Lighting.ClockTime = 12 -- Thời gian trong ngày (12 = trưa)
Lighting.GeographicLatitude = 35 -- Tọa độ địa lý (góc ánh sáng mặt trời)
Lighting.ShadowSoftness = 0.1 -- Độ mềm của bóng
Lighting.Technology = Enum.Technology.Future -- Công nghệ ánh sáng Future

-- Thêm hiệu ứng Bloom (ánh sáng chói)
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 3 -- Độ sáng của hiệu ứng
bloom.Size = 50 -- Kích thước hiệu ứng
bloom.Threshold = 0.8 -- Ngưỡng hiệu ứng
bloom.Parent = Lighting

-- Thêm hiệu ứng Sun Rays (tia sáng mặt trời)
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.4 -- Cường độ
sunRays.Spread = 0.8 -- Độ lan tỏa
sunRays.Parent = Lighting

-- Thêm hiệu ứng Color Correction (Hiệu chỉnh màu sắc)
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.1 -- Độ sáng
colorCorrection.Contrast = 0.5 -- Độ tương phản
colorCorrection.Saturation = 0.8 -- Độ bão hòa
colorCorrection.TintColor = Color3.fromRGB(255, 245, 220) -- Tông màu ấm
colorCorrection.Parent = Lighting

-- Thêm hiệu ứng Depth of Field (Làm mờ xa/gần)
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.InFocusRadius = 150 -- Bán kính lấy nét
depthOfField.NearIntensity = 0.5 -- Cường độ gần
depthOfField.FarIntensity = 0.4 -- Cường độ xa
depthOfField.FocusDistance = 100 -- Khoảng cách lấy nét
depthOfField.Parent = Lighting

-- Thêm hiệu ứng SurfaceAppearance (Nền đất bóng loáng phản chiếu)
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj:FindFirstChild("SurfaceAppearance") then
        local surfaceAppearance = Instance.new("SurfaceAppearance")
        surfaceAppearance.Reflectance = 0.5 -- Độ phản chiếu
        surfaceAppearance.Parent = obj
    end
end

-- Thêm bóng của người chơi
for _, player in pairs(game.Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CastShadow = true -- Bật bóng đổ cho từng phần cơ thể
            end
        end
    end)
end

print("Advanced daytime graphics applied!")
