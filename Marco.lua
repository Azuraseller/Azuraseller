-- Script Tối Ưu Cho Blox Fruits
-- Tích hợp sử dụng skill nhanh, tự động chuyển vũ khí, và giữ 60 FPS khi PVP

-- Biến cấu hình
local autoSkill = false          -- Tự động sử dụng skill
local actionInterval = 0.2       -- Thời gian chờ giữa mỗi hành động (giây)
local skillKeys = {"Z", "X", "C", "V", "F"} -- Phím kỹ năng
local weaponTypes = {"Melee", "Gun", "Sword", "Fruit"} -- Các loại vũ khí
local currentWeaponIndex = 1     -- Vũ khí hiện tại (bắt đầu từ Melee)
local maintainFPS = true         -- Duy trì 60 FPS

-- Lưu trạng thái với DataStore
local DataStoreService = game:GetService("DataStoreService")
local guiStateStore = DataStoreService:GetDataStore("AdvancedMacroState")
local savedState = guiStateStore:GetAsync("AdvancedState") or {
    autoSkill = false,
    actionInterval = 0.2,
    guiPosition = {x = 0.4, y = 0.8},
    maintainFPS = true
}

-- Khôi phục trạng thái
autoSkill = savedState.autoSkill
actionInterval = savedState.actionInterval
maintainFPS = savedState.maintainFPS

-- Hàm lưu trạng thái
local function saveState()
    guiStateStore:SetAsync("AdvancedState", {
        autoSkill = autoSkill,
        actionInterval = actionInterval,
        maintainFPS = maintainFPS,
        guiPosition = {
            x = MainFrame.Position.X.Scale,
            y = MainFrame.Position.Y.Scale
        }
    })
end

-- Hàm tự động chuyển vũ khí
function AutoSwitchWeapon()
    currentWeaponIndex = currentWeaponIndex + 1
    if currentWeaponIndex > #weaponTypes then
        currentWeaponIndex = 1
    end
    local backpack = game.Players.LocalPlayer.Backpack
    local weapon = backpack:FindFirstChild(weaponTypes[currentWeaponIndex])
    if weapon then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(weapon)
    end
end

-- Hàm tự động sử dụng skill
function AutoSkill()
    while wait(actionInterval) do
        if autoSkill then
            local UIS = game:GetService("UserInputService")
            for _, key in ipairs(skillKeys) do
                UIS:InputBegan:Fire(Enum.KeyCode[key])
                wait(actionInterval)
            end
            AutoSwitchWeapon()
        end
    end
end

-- Hàm duy trì 60 FPS
function MaintainFPS()
    if maintainFPS then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 -- Giảm chất lượng đồ họa
        game:GetService("RunService").RenderStepped:Connect(function()
            if game:GetService("Stats").FrameRateManager:GetAverageFPS() < 60 then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level10 -- Tăng chất lượng khi không PVP
            end
        end)
    end
end

-- Tạo GUI kéo thả
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ToggleSkillButton = Instance.new("TextButton")
local SpeedSlider = Instance.new("TextBox")
local FPSToggleButton = Instance.new("TextButton")
local Dragging = false
local DragStart, StartPos

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Cấu hình MainFrame
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(savedState.guiPosition.x, 0, savedState.guiPosition.y, 0)
MainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

-- Nút bật/tắt Auto Skill
ToggleSkillButton.Parent = MainFrame
ToggleSkillButton.Size = UDim2.new(0, 250, 0, 40)
ToggleSkillButton.Position = UDim2.new(0.5, -125, 0.1, 0)
ToggleSkillButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ToggleSkillButton.Text = autoSkill and "BẬT AUTO SKILL" or "TẮT AUTO SKILL"
ToggleSkillButton.TextColor3 = Color3.new(1, 1, 1)
ToggleSkillButton.TextScaled = true
ToggleSkillButton.Font = Enum.Font.SourceSans
ToggleSkillButton.BorderSizePixel = 0

-- Thanh điều chỉnh tốc độ
SpeedSlider.Parent = MainFrame
SpeedSlider.Size = UDim2.new(0, 250, 0, 40)
SpeedSlider.Position = UDim2.new(0.5, -125, 0.3, 0)
SpeedSlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
SpeedSlider.Text = "TỐC ĐỘ: " .. actionInterval .. "s"
SpeedSlider.TextColor3 = Color3.new(1, 1, 1)
SpeedSlider.TextScaled = true
SpeedSlider.Font = Enum.Font.SourceSans
SpeedSlider.BorderSizePixel = 0

-- Nút bật/tắt Duy trì FPS
FPSToggleButton.Parent = MainFrame
FPSToggleButton.Size = UDim2.new(0, 250, 0, 40)
FPSToggleButton.Position = UDim2.new(0.5, -125, 0.5, 0)
FPSToggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
FPSToggleButton.Text = maintainFPS and "BẬT DUY TRÌ 60 FPS" or "TẮT DUY TRÌ 60 FPS"
FPSToggleButton.TextColor3 = Color3.new(1, 1, 1)
FPSToggleButton.TextScaled = true
FPSToggleButton.Font = Enum.Font.SourceSans
FPSToggleButton.BorderSizePixel = 0

-- Xử lý bật/tắt Auto Skill
ToggleSkillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    ToggleSkillButton.Text = autoSkill and "BẬT AUTO SKILL" or "TẮT AUTO SKILL"
    saveState()
end)

-- Xử lý thay đổi tốc độ
SpeedSlider.FocusLost:Connect(function()
    local speed = tonumber(SpeedSlider.Text:match("%d+%.?%d*"))
    if speed and speed > 0 then
        actionInterval = speed
        SpeedSlider.Text = "TỐC ĐỘ: " .. speed .. "s"
        saveState()
    else
        SpeedSlider.Text = "TỐC ĐỘ: " .. actionInterval .. "s"
    end
end)

-- Xử lý bật/tắt Duy trì FPS
FPSToggleButton.MouseButton1Click:Connect(function()
    maintainFPS = not maintainFPS
    FPSToggleButton.Text = maintainFPS and "BẬT DUY TRÌ 60 FPS" or "TẮT DUY TRÌ 60 FPS"
    if maintainFPS then
        MaintainFPS()
    end
    saveState()
end)

-- Xử lý kéo thả GUI
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(
            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
        )
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
        saveState()
    end
end)

-- Chạy các hàm
spawn(AutoSkill)
if maintainFPS then
    MaintainFPS()
end
