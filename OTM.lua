-- Đảm bảo script được đặt trong ServerScriptService hoặc StarterPlayerScripts

local lighting = game:GetService("Lighting")
local runService = game:GetService("RunService")

-- Cài đặt ban đầu cho Lighting
lighting.EnvironmentDiffuseScale = 3 -- Tăng cường độ khuếch tán ánh sáng
lighting.EnvironmentSpecularScale = 3.5 -- Tăng độ phản chiếu ánh sáng
lighting.GlobalShadows = true
lighting.Brightness = 3
lighting.ShadowSoftness = 0.2 -- Bóng mềm mại hơn

-- Thêm hiệu ứng Bloom
local bloom = Instance.new("BloomEffect", lighting)
bloom.Intensity = 0.6 -- Hiệu ứng ánh sáng mạnh hơn
bloom.Size = 15 -- Kích thước vùng sáng
bloom.Threshold = 1.6 -- Tăng ngưỡng để ánh sáng chỉ tập trung ở vùng sáng mạnh

-- Thêm hiệu ứng ColorCorrection
local colorCorrection = Instance.new("ColorCorrectionEffect", lighting)
colorCorrection.Brightness = 0.2 -- Làm sáng tổng thể
colorCorrection.Contrast = 0.5 -- Tăng độ tương phản để làm nổi bật vùng sáng tối
colorCorrection.Saturation = 0.5 -- Tăng độ bão hòa để màu sắc rực rỡ hơn
colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

-- Thêm hiệu ứng SunRays
local sunRays = Instance.new("SunRaysEffect", lighting)
sunRays.Intensity = 0.2 -- Hiệu ứng tia sáng mạnh hơn
sunRays.Spread = 1 -- Tăng vùng lan tỏa của tia sáng

-- Thêm hiệu ứng DepthOfField
local depthOfField = Instance.new("DepthOfFieldEffect", lighting)
depthOfField.FarIntensity = 0.5 -- Làm mờ các vật thể xa
depthOfField.FocusDistance = 70 -- Khoảng cách lấy nét
depthOfField.InFocusRadius = 25 -- Vùng rõ nét
depthOfField.NearIntensity = 0.8 -- Làm mờ các vật thể gần

-- Cài đặt ánh sáng mặt trời
lighting.SunAngularSize = 25 -- Kích thước mặt trời lớn hơn
lighting.SunRaysEnabled = true -- Bật hiệu ứng tia sáng mặt trời
lighting.ClockTime = 12 -- Bắt đầu với ánh sáng ban ngày

-- Cài đặt ánh sáng theo từng khung giờ
local function updateLighting(clockTime)
    if clockTime >= 5 and clockTime < 7 then
        -- Bình minh
        lighting.Ambient = Color3.fromRGB(255, 200, 150)
        lighting.OutdoorAmbient = Color3.fromRGB(200, 150, 100)
        lighting.Brightness = 2.8
        lighting.EnvironmentDiffuseScale = 2.5
        lighting.EnvironmentSpecularScale = 3
        colorCorrection.TintColor = Color3.fromRGB(255, 180, 140)
        sunRays.Intensity = 0.3
    elseif clockTime >= 7 and clockTime < 12 then
        -- Sáng sớm
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
        lighting.Brightness = 3.2
        lighting.EnvironmentDiffuseScale = 3
        lighting.EnvironmentSpecularScale = 3.5
        colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
        sunRays.Intensity = 0.2
    elseif clockTime >= 12 and clockTime < 17 then
        -- Ban ngày
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.OutdoorAmbient = Color3.fromRGB(230, 230, 230)
        lighting.Brightness = 3.5
        lighting.EnvironmentDiffuseScale = 3.5
        lighting.EnvironmentSpecularScale = 4
        colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
        sunRays.Intensity = 0.15
    elseif clockTime >= 17 and clockTime < 19 then
        -- Hoàng hôn
        lighting.Ambient = Color3.fromRGB(255, 150, 100)
        lighting.OutdoorAmbient = Color3.fromRGB(200, 100, 50)
        lighting.Brightness = 2.8
        lighting.EnvironmentDiffuseScale = 2.8
        lighting.EnvironmentSpecularScale = 3.2
        colorCorrection.TintColor = Color3.fromRGB(255, 150, 100)
        sunRays.Intensity = 0.25
    else
        -- Ban đêm
        lighting.Ambient = Color3.fromRGB(50, 50, 100)
        lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 50)
        lighting.Brightness = 1.8
        lighting.EnvironmentDiffuseScale = 2
        lighting.EnvironmentSpecularScale = 2.5
        colorCorrection.TintColor = Color3.fromRGB(200, 200, 255)
        sunRays.Intensity = 0.1
    end
end

-- Cập nhật ánh sáng liên tục
runService.Heartbeat:Connect(function()
    local currentTime = lighting.ClockTime + 0.01 -- Tăng thời gian liên tục
    if currentTime >= 24 then
        currentTime = 0
    end
    lighting.ClockTime = currentTime
    updateLighting(currentTime)
end)

print("Ultra RTX lighting with enhanced sun reflections applied!")
