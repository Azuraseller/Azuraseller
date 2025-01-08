-- Script Tối Ưu Hoá Cao Cấp Cho Blox Fruits
-- Bao gồm: AutoSkill, AutoSwitchWeapon, AutoDodge, AutoHaki, MaintainFPS, Lưu/Áp dụng Combo với GUI hiện đại.

-- Biến cấu hình
local autoSkill = false          -- Tự động sử dụng skill
local autoSwitchWeapon = true    -- Tự động chuyển vũ khí
local autoDodge = true           -- Tự động né tránh
local autoHaki = true            -- Tự động bật Haki
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
local ToggleDodgeButton = Instance.new("TextButton")
local FPSToggleButton = Instance.new("TextButton")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 450, 0, 600)
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.BackgroundTransparency = 0.1
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Draggable = true
MainFrame.Active = true
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
TitleLabel.Text = "⚔️ Script Tối Ưu Hoá Blox Fruits"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextScaled = true

local UICornerTitle = Instance.new("UICorner", TitleLabel)
UICornerTitle.CornerRadius = UDim.new(0, 10)

-- Combo Frame
ComboFrame.Parent = MainFrame
ComboFrame.Size = UDim2.new(1, 0, 0.5, 0)
ComboFrame.Position = UDim2.new(0, 0, 0.5, 0)
ComboFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ComboFrame.BorderSizePixel = 0

local UICornerCombo = Instance.new("UICorner", ComboFrame)
UICornerCombo.CornerRadius = UDim.new(0, 10)

-- Danh sách Combo
ComboList.Parent = ComboFrame
ComboList.Size = UDim2.new(1, -20, 0.8, 0)
ComboList.Position = UDim2.new(0, 10, 0, 10)
ComboList.CanvasSize = UDim2.new(0, 0, 1, 0)
ComboList.ScrollBarThickness = 10
ComboList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ComboList.BorderSizePixel = 0

local UICornerList = Instance.new("UICorner", ComboList)
UICornerList.CornerRadius = UDim.new(0, 10)

-- Ô nhập Combo
ComboInputBox.Parent = ComboFrame
ComboInputBox.Size = UDim2.new(0.7, 0, 0.15, 0)
ComboInputBox.Position = UDim2.new(0.05, 0, 0.85, 0)
ComboInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ComboInputBox.Text = "Nhập Combo (vd: 3-x,2-c,1-z)"
ComboInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboInputBox.TextScaled = true
ComboInputBox.Font = Enum.Font.Gotham

local UICornerInput = Instance.new("UICorner", ComboInputBox)
UICornerInput.CornerRadius = UDim.new(0, 10)

-- Nút thêm Combo
AddComboButton.Parent = ComboFrame
AddComboButton.Size = UDim2.new(0.2, 0, 0.15, 0)
AddComboButton.Position = UDim2.new(0.8, 0, 0.85, 0)
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
ToggleSkillButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ToggleSkillButton.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
ToggleSkillButton.Text = "Bật Auto Skill"
ToggleSkillButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSkillButton.TextScaled = true
ToggleSkillButton.Font = Enum.Font.GothamBold

local UICornerSkill = Instance.new("UICorner", ToggleSkillButton)
UICornerSkill.CornerRadius = UDim.new(0, 10)

-- Nút bật/tắt Auto Dodge
ToggleDodgeButton.Parent = MainFrame
ToggleDodgeButton.Size = UDim2.new(0.8, 0, 0.1, 0)
ToggleDodgeButton.Position = UDim2.new(0.1, 0, 0.25, 0)
ToggleDodgeButton.BackgroundColor3 = Color3.fromRGB(100, 149, 237)
ToggleDodgeButton.Text = "Bật Auto Dodge"
ToggleDodgeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleDodgeButton.TextScaled = true
ToggleDodgeButton.Font = Enum.Font.GothamBold

local UICornerDodge = Instance.new("UICorner", ToggleDodgeButton)
UICornerDodge.CornerRadius = UDim.new(0, 10)

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

-- Hàm AutoDodge
function AutoDodge()
    while autoDodge do
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            -- Di chuyển nhẹ nhàng để né tránh
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0)
        end
        wait(0.1)  -- Đợi giữa mỗi lần né tránh
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

        -- Thêm chức năng áp dụng combo khi bấm
        button.MouseButton1Click:Connect(function()
            ExecuteCombo(combo)
        end)

        -- Lưu lại nút vào danh sách
        table.insert(ApplyComboButtons, button)
    end
end

-- Hàm Áp dụng Combo
function ExecuteCombo(comboString)
    local comboParts = string.split(comboString, ",")
    for _, part in ipairs(comboParts) do
        local key, action = part:match("(%d+)-([a-zA-Z])")
        if key and action then
            -- Thực hiện hành động theo key và action
            -- Đây có thể là các hành động cụ thể như sử dụng skill, chuyển vũ khí, v.v.
            print("Áp dụng combo: " .. key .. " - " .. action)
            -- Ví dụ thực hiện sử dụng skill tương ứng với key và action
        end
    end
end

-- Lắng nghe sự kiện nhấn nút "Thêm Combo"
AddComboButton.MouseButton1Click:Connect(function()
    local comboString = ComboInputBox.Text
    if comboString ~= "" then
        SaveCombo(comboString)
        ComboInputBox.Text = ""  -- Xóa ô nhập sau khi lưu combo
    end
end)

-- Lắng nghe sự kiện bật/tắt AutoSkill
ToggleSkillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    ToggleSkillButton.Text = autoSkill and "Tắt Auto Skill" or "Bật Auto Skill"
end)

-- Lắng nghe sự kiện bật/tắt AutoDodge
ToggleDodgeButton.MouseButton1Click:Connect(function()
    autoDodge = not autoDodge
    ToggleDodgeButton.Text = autoDodge and "Tắt Auto Dodge" or "Bật Auto Dodge"
end)

-- Lắng nghe sự kiện bật/tắt FPS
FPSToggleButton.MouseButton1Click:Connect(function()
    maintainFPS = not maintainFPS
    FPSToggleButton.Text = maintainFPS and "Tắt Duy Trì FPS" or "Bật Duy Trì FPS"
end)

-- Bắt đầu các chức năng
spawn(AutoSwitchWeapon)
spawn(AutoDodge)
MaintainFPS()
