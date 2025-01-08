-- Script Macro Cao Cấp Cho Mobile Roblox
-- Tích hợp nhiều tính năng nâng cao với GUI tùy chỉnh

-- Biến cấu hình
local autoJump = false       -- Tự động nhảy
local autoClick = false      -- Tự động bắn hoặc click
local actionInterval = 0.5   -- Khoảng thời gian giữa mỗi hành động (giây)

-- Lưu trạng thái (dùng DataStore)
local DataStoreService = game:GetService("DataStoreService")
local guiStateStore = DataStoreService:GetDataStore("GuiStateStore")

-- Hàm tự động nhảy
function AutoJump()
    while autoJump do
        wait(actionInterval)
        local player = game.Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Jump = true
        end
    end
end

-- Hàm tự động click (bắn hoặc tương tác)
function AutoClick()
    while autoClick do
        wait(actionInterval)
        local UIS = game:GetService("UserInputService")
        UIS:InputBegan:Fire(Enum.UserInputType.MouseButton1)
    end
end

-- Kích hoạt macro
spawn(function()
    AutoJump()
end)

spawn(function()
    AutoClick()
end)

-- Tạo GUI kéo thả
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ToggleJumpButton = Instance.new("TextButton")
local ToggleClickButton = Instance.new("TextButton")
local SpeedSlider = Instance.new("TextBox")
local Dragging = false
local DragStart, StartPos

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Cấu hình MainFrame
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Position = UDim2.new(0.4, 0, 0.8, 0)
MainFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

-- Nút bật/tắt Auto Jump
ToggleJumpButton.Parent = MainFrame
ToggleJumpButton.Size = UDim2.new(0, 200, 0, 40)
ToggleJumpButton.Position = UDim2.new(0.5, -100, 0.2, -20)
ToggleJumpButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ToggleJumpButton.Text = "TẮT AUTO JUMP"
ToggleJumpButton.TextColor3 = Color3.new(1, 1, 1)
ToggleJumpButton.TextScaled = true
ToggleJumpButton.Font = Enum.Font.SourceSans
ToggleJumpButton.BorderSizePixel = 0

-- Nút bật/tắt Auto Click
ToggleClickButton.Parent = MainFrame
ToggleClickButton.Size = UDim2.new(0, 200, 0, 40)
ToggleClickButton.Position = UDim2.new(0.5, -100, 0.5, -20)
ToggleClickButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ToggleClickButton.Text = "TẮT AUTO CLICK"
ToggleClickButton.TextColor3 = Color3.new(1, 1, 1)
ToggleClickButton.TextScaled = true
ToggleClickButton.Font = Enum.Font.SourceSans
ToggleClickButton.BorderSizePixel = 0

-- Thanh điều chỉnh tốc độ
SpeedSlider.Parent = MainFrame
SpeedSlider.Size = UDim2.new(0, 200, 0, 40)
SpeedSlider.Position = UDim2.new(0.5, -100, 0.8, -20)
SpeedSlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
SpeedSlider.Text = "TỐC ĐỘ: 0.5s"
SpeedSlider.TextColor3 = Color3.new(1, 1, 1)
SpeedSlider.TextScaled = true
SpeedSlider.Font = Enum.Font.SourceSans
SpeedSlider.BorderSizePixel = 0

-- Xử lý bật/tắt Auto Jump
ToggleJumpButton.MouseButton1Click:Connect(function()
    autoJump = not autoJump
    if autoJump then
        ToggleJumpButton.Text = "BẬT AUTO JUMP"
    else
        ToggleJumpButton.Text = "TẮT AUTO JUMP"
    end
end)

-- Xử lý bật/tắt Auto Click
ToggleClickButton.MouseButton1Click:Connect(function()
    autoClick = not autoClick
    if autoClick then
        ToggleClickButton.Text = "BẬT AUTO CLICK"
    else
        ToggleClickButton.Text = "TẮT AUTO CLICK"
    end
end)

-- Xử lý thay đổi tốc độ
SpeedSlider.FocusLost:Connect(function()
    local speed = tonumber(SpeedSlider.Text:match("%d+%.?%d*"))
    if speed and speed > 0 then
        actionInterval = speed
        SpeedSlider.Text = "TỐC ĐỘ: " .. speed .. "s"
    else
        SpeedSlider.Text = "TỐC ĐỘ: 0.5s"
        actionInterval = 0.5
    end
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
    end
end)
