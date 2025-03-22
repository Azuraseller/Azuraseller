local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Thiết lập giới hạn
local MAX_WALK_SPEED = 20
local CHECK_INTERVAL = 10 -- giây

-- Mã hóa dữ liệu (giả lập)
local function advancedEncrypt(data)
    -- Thay bằng AES-256 thực tế
    return data
end

-- Bảo vệ bộ nhớ (giả lập)
local function protectMemory()
    print("Đã kích hoạt bảo vệ bộ nhớ!")
    -- Tích hợp memory encryption hoặc polymorphic code
end

-- Chống debugging
local function antiDebugging()
    print("Kiểm tra debugger...")
    -- Thêm bẫy chống gỡ lỗi
end

-- Giám sát hành vi
local function monitorBehavior()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if humanoid.WalkSpeed > MAX_WALK_SPEED then
            humanoid.WalkSpeed = 16
            warn("Tốc độ bất thường, đã điều chỉnh!")
        end
    end
end

-- Kiểm tra ban/kick
local function checkBanKick()
    if LocalPlayer.KickReason ~= "" then
        warn("Bị kick: " .. LocalPlayer.KickReason)
        wait(math.random(5, 10))
        -- Tự động tham gia lại hoặc ẩn danh
    end
end

-- Giám sát máy chủ
local function monitorServerActivity()
    print("Đang giám sát máy chủ...")
    -- Phản ứng với yêu cầu bất thường
end

-- Hàm chính
local function main()
    protectMemory()
    antiDebugging()

    RunService.Heartbeat:Connect(monitorBehavior)
    spawn(function()
        while wait(CHECK_INTERVAL) do
            checkBanKick()
            monitorServerActivity()
        end
    end)
end

pcall(main)
print("Script bảo vệ nâng cao đã chạy!")
