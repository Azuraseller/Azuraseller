-- Script Tối Ưu Hoàn Chỉnh cho Mobile
-- Bao gồm: AutoSkill, AutoSwitchWeapon, MaintainFPS, Lưu/Áp dụng Combo, loại bỏ AutoDodge

-- Biến cấu hình
local autoSkill = false          -- Tự động sử dụng skill
local autoSwitchWeapon = true    -- Tự động chuyển vũ khí
local maintainFPS = true         -- Duy trì 60 FPS
local actionInterval = 0.15      -- Thời gian chờ giữa mỗi hành động (giây)
local skillKeys = {"Z", "X", "C", "V", "F"} -- Phím kỹ năng
local weaponTypes = {"Melee", "Gun", "Sword", "Fruit"} -- Các loại vũ khí
local currentWeaponIndex = 1     -- Vũ khí hiện tại (bắt đầu từ Melee)
local maxCombos = 3              -- Số combo tối đa
local combos = {}                -- Danh sách combo đã lưu
local activeCombo = nil          -- Combo đang được áp dụng

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local ComboFrame = Instance.new("Frame")
local AddComboButton = Instance.new("TextButton")
local ComboList = Instance.new("ScrollingFrame")
local ComboInputBox = Instance.new("TextBox")
local ToggleSkillButton = Instance.new("TextButton")
local FPSToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Giảm kích thước cho phù hợp với mobile)
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 250, 0, 400)  -- Kích thước nhỏ hơn
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -200)  -- Căn giữa màn hình
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.BackgroundTransparency = 0.1
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 2

-- Bo tròn góc
local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

-- Tiêu đề
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0.1, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.BorderSizePixel = 0
TitleLabel.Text = "⚔️ Blox Fruits"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextScaled = true

local UICornerTitle = Instance.new("UICorner", TitleLabel)
UICornerTitle.CornerRadius = UDim.new(0, 10)

-- Combo Frame
ComboFrame.Parent = MainFrame
ComboFrame.Size = UDim2.new(1, 0, 0.5, 0)  -- Giảm kích thước ComboFrame
ComboFrame.Position = UDim2.new(0, 0, 0.2, 0)  -- Đặt ComboFrame lên phía trên
ComboFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ComboFrame.BorderSizePixel = 0

local UICornerCombo = Instance.new("UICorner", ComboFrame)
UICornerCombo.CornerRadius = UDim.new(0, 10)

-- Danh sách Combo
ComboList.Parent = ComboFrame
ComboList.Size = UDim2.new(1, -20, 0.6, 0)  -- Giảm kích thước ComboList
ComboList.Position = UDim2.new(0, 10, 0, 10)
ComboList.CanvasSize = UDim2.new(0, 0, 1, 0)
ComboList.ScrollBarThickness = 10
ComboList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ComboList.BorderSizePixel = 0

local UICornerList = Instance.new("UICorner", ComboList)
UICornerList.CornerRadius = UDim.new(0, 10)

-- Ô nhập Combo
ComboInputBox.Parent = ComboFrame
ComboInputBox.Size = UDim2.new(0.7, 0, 0.2, 0)  -- Giảm kích thước ô nhập
ComboInputBox.Position = UDim2.new(0.05, 0, 0.75, 0)  -- Đặt ô nhập gần cuối
ComboInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ComboInputBox.Text = "Nhập Combo (vd: 3-x,2-x,z)"
ComboInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboInputBox.TextScaled = true
ComboInputBox.Font = Enum.Font.Gotham

local UICornerInput = Instance.new("UICorner", ComboInputBox)
UICornerInput.CornerRadius = UDim.new(0, 10)

-- Nút thêm Combo
AddComboButton.Parent = ComboFrame
AddComboButton.Size = UDim2.new(0.2, 0, 0.2, 0)  -- Giảm kích thước nút thêm
AddComboButton.Position = UDim2.new(0.8, 0, 0.75, 0)  -- Đặt nút thêm gần cuối
AddComboButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
AddComboButton.Text = "📜 Thêm"
AddComboButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AddComboButton.TextScaled = true
AddComboButton.Font = Enum.Font.GothamBold

local UICornerAdd = Instance.new("UICorner", AddComboButton)
UICornerAdd.CornerRadius = UDim.new(0, 10)

-- Nút bật/tắt Auto Skill
ToggleSkillButton.Parent = MainFrame
ToggleSkillButton.Size = UDim2.new(0.8, 0, 0.1, 0)
ToggleSkillButton.Position = UDim2.new(0.1, 0, 0.75, 0)
ToggleSkillButton.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
ToggleSkillButton.Text = "Bật Auto Skill"
ToggleSkillButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSkillButton.TextScaled = true
ToggleSkillButton.Font = Enum.Font.GothamBold

local UICornerSkill = Instance.new("UICorner", ToggleSkillButton)
UICornerSkill.CornerRadius = UDim.new(0, 10)

-- Nút bật/tắt FPS
FPSToggleButton.Parent = MainFrame
FPSToggleButton.Size = UDim2.new(0.8, 0, 0.1, 0)
FPSToggleButton.Position = UDim2.new(0.1, 0, 0.85, 0)
FPSToggleButton.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
FPSToggleButton.Text = "Bật Duy Trì FPS"
FPSToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSToggleButton.TextScaled = true
FPSToggleButton.Font = Enum.Font.GothamBold

local UICornerFPS = Instance.new("UICorner", FPSToggleButton)
UICornerFPS.CornerRadius = UDim.new(0, 10)

-- Tương tự các chức năng AutoSwitchWeapon, MaintainFPS, và xử lý combo như script trước đây.

-- Hàm AutoSwitchWeapon
function AutoSwitchWeapon()
    while autoSwitchWeapon do
        -- Chuyển vũ khí tự động theo vòng lặp
        currentWeaponIndex = currentWeaponIndex + 1
        if currentWeaponIndex > #weaponTypes then
            currentWeaponIndex = 1
        end
        local backpack = game.Players.LocalPlayer.Backpack
        local weapon = backpack:FindFirstChild(weaponTypes[currentWeaponIndex])
        if weapon then
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(weapon)
        end
        wait(actionInterval)  -- Đợi trước khi chuyển sang vũ khí tiếp theo
    end
end

-- Hàm duy trì FPS
function MaintainFPS()
    if maintainFPS then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game:GetService("RunService").RenderStepped:Connect(function()
            if game:GetService("Stats").FrameRateManager:GetAverageFPS() < 60 then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end
        end)
    end
end

-- Hàm Lưu Combo
function SaveCombo(comboString)
    if #combos < maxCombos then
        table.insert(combos, comboString)
        UpdateComboList()
    else
        -- Nếu đã đạt giới hạn combo, thông báo cho người dùng
        print("Đã đạt giới hạn combo!")
    end
end

-- Hàm Cập nhật danh sách Combo
function UpdateComboList()
    -- Xóa các nút cũ trong ComboList
    for _, button in pairs(ApplyComboButtons) do
        button:Destroy()
    end
    ApplyComboButtons = {}

    -- Tạo các nút mới cho mỗi combo đã lưu
    for i, combo in ipairs(combos) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 50)
        button.Position = UDim2.new(0, 10, 0, (i - 1) * 60)
        button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        button.Text = "Combo " .. i .. ": " .. combo
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = ComboList

        -- Bo tròn góc cho nút
        local UICornerButton = Instance.new("UICorner", button)
        UICornerButton.CornerRadius = UDim.new(0, 10)

        -- Lưu nút vào danh sách để quản lý
        table.insert(ApplyComboButtons, button)

        -- Thêm sự kiện cho nút combo
        button.MouseButton1Click:Connect(function()
            -- Áp dụng combo khi người dùng chọn
            activeCombo = combo
            ExecuteCombo(combo)
        end)
    end
end

-- Hàm thực hiện Combo
function ExecuteCombo(combo)
    local comboSteps = {}
    for step in combo:gmatch("[^,]+") do
        table.insert(comboSteps, step)
    end

    -- Thực hiện các bước của combo
    for _, step in ipairs(comboSteps) do
        local key, action = step:match("([%d%w]+)-([%w]+)")
        if key and action then
            -- Nhấn phím tương ứng với mỗi bước trong combo
            if action == "x" then
                -- Bấm phím tương ứng (ví dụ: sử dụng kỹ năng)
                game:GetService("VirtualInputManager"):SendKeyPress(Enum.KeyCode[key])
            end
            wait(actionInterval)  -- Đợi giữa các bước
        end
    end
end

-- Sự kiện khi người dùng nhấn nút "Thêm"
AddComboButton.MouseButton1Click:Connect(function()
    local comboString = ComboInputBox.Text
    if comboString ~= "" then
        SaveCombo(comboString)
        ComboInputBox.Text = ""  -- Xóa ô nhập sau khi thêm combo
    end
end)

-- Sự kiện khi bật/tắt AutoSkill
ToggleSkillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    if autoSkill then
        ToggleSkillButton.Text = "Tắt Auto Skill"
    else
        ToggleSkillButton.Text = "Bật Auto Skill"
    end
end)

-- Sự kiện khi bật/tắt FPS
FPSToggleButton.MouseButton1Click:Connect(function()
    maintainFPS = not maintainFPS
    if maintainFPS then
        FPSToggleButton.Text = "Tắt Duy Trì FPS"
    else
        FPSToggleButton.Text = "Bật Duy Trì FPS"
    end
end)

-- Bắt đầu các chức năng
if autoSwitchWeapon then
    AutoSwitchWeapon()
end
if maintainFPS then
    MaintainFPS()
end
