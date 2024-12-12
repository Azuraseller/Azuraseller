-- Khởi tạo
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local defaultWalkSpeed = 16
local boostedWalkSpeed = 40
local aimbotEnabled = false
local speedEnabled = false
local aimRange = 250
local targetPlayer = nil

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local AimbotButton = Instance.new("TextButton")
local ToggleButton = Instance.new("TextButton")
local PlayerListButton = Instance.new("TextButton")
local PlayerListFrame = Instance.new("ScrollingFrame")
local ServerHopButton = Instance.new("TextButton")
local SpeedButton = Instance.new("TextButton")
local PlayerList = {}

ScreenGui.Parent = game.CoreGui

-- GUI chính
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.8, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Visible = false

-- Nút bật/tắt GUI
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.Position = UDim2.new(0.78, 0, 0.1, 0)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Text = "+"
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        ToggleButton.Text = "-"
    else
        ToggleButton.Text = "+"
    end
end)

-- Nút Aimbot
AimbotButton.Name = "AimbotButton"
AimbotButton.Parent = MainFrame
AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
AimbotButton.Position = UDim2.new(0.1, 0, 0.1, 0)
AimbotButton.Size = UDim2.new(0, 100, 0, 50)
AimbotButton.Text = "Aimbot OFF"
AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        AimbotButton.Text = "Aimbot ON"
        AimbotButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        AimbotButton.Text = "Aimbot OFF"
        AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- Nút Speed
SpeedButton.Name = "SpeedButton"
SpeedButton.Parent = MainFrame
SpeedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SpeedButton.Position = UDim2.new(0.1, 0, 0.3, 0)
SpeedButton.Size = UDim2.new(0, 100, 0, 50)
SpeedButton.Text = "Speed OFF"
SpeedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    if speedEnabled then
        SpeedButton.Text = "Speed ON"
        SpeedButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        LocalPlayer.Character.Humanoid.WalkSpeed = boostedWalkSpeed
    else
        SpeedButton.Text = "Speed OFF"
        SpeedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        LocalPlayer.Character.Humanoid.WalkSpeed = defaultWalkSpeed
    end
end)

-- Server Hop
ServerHopButton.Name = "ServerHopButton"
ServerHopButton.Parent = MainFrame
ServerHopButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ServerHopButton.Position = UDim2.new(0.1, 0, 0.5, 0)
ServerHopButton.Size = UDim2.new(0, 100, 0, 50)
ServerHopButton.Text = "Server Hop"
ServerHopButton.MouseButton1Click:Connect(function()
    local yesNoFrame = Instance.new("Frame")
    local yesButton = Instance.new("TextButton")
    local noButton = Instance.new("TextButton")

    yesNoFrame.Parent = MainFrame
    yesNoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    yesNoFrame.Size = UDim2.new(0, 100, 0, 50)
    yesNoFrame.Position = UDim2.new(0.1, 0, 0.7, 0)

    yesButton.Parent = yesNoFrame
    yesButton.Size = UDim2.new(0, 50, 0, 50)
    yesButton.Text = "Yes"
    yesButton.MouseButton1Click:Connect(function()
        -- Chuyển server (logic tìm server ít người)
        TeleportService:Teleport(game.PlaceId)
    end)

    noButton.Parent = yesNoFrame
    noButton.Size = UDim2.new(0, 50, 0, 50)
    noButton.Text = "No"
    noButton.Position = UDim2.new(0.5, 0, 0, 0)
    noButton.MouseButton1Click:Connect(function()
        yesNoFrame:Destroy()
    end)
end)

-- Chức năng Aimbot
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local closestPlayer = nil
        local shortestDistance = aimRange
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end

        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer = closestPlayer
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.HumanoidRootPart.Position)
        else
            targetPlayer = nil
        end
    end
end)

-- Chức năng xử lý khi player chết hoặc rời khỏi phạm vi
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid").Died:Connect(function()
            if targetPlayer == player then
                targetPlayer = nil
            end
        end)
    end)
end)

-- Cập nhật danh sách người chơi trong GUI
Players.PlayerAdded:Connect(function(player)
    local playerButton = Instance.new("TextButton")
    playerButton.Parent = PlayerListFrame
    playerButton.Size = UDim2.new(0, 180, 0, 30)
    playerButton.Text = player.Name
    playerButton.MouseButton1Click:Connect(function()
        -- Tạo các nút "View" và "Tele" cho mỗi player
        local viewButton = Instance.new("TextButton")
        local teleButton = Instance.new("TextButton")
        viewButton.Parent = playerButton
        teleButton.Parent = playerButton
        viewButton.Size = UDim2.new(0, 30, 0, 30)
        teleButton.Size = UDim2.new(0, 30, 0, 30)
        viewButton.Position = UDim2.new(1, 0, 0, 0)
        teleButton.Position = UDim2.new(1, 40, 0, 0)
        viewButton.Text = "View"
        teleButton.Text = "Tele"

        viewButton.MouseButton1Click:Connect(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, player.Character.HumanoidRootPart.Position)
            viewButton.Text = "Viewing"
        end)

        teleButton.MouseButton1Click:Connect(function()
            LocalPlayer.Character:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
        end)
    end)
end)

-- Tạo Player List Frame
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Parent = MainFrame
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
PlayerListFrame.Position = UDim2.new(0, 0, 0.6, 0)
PlayerListFrame.Size = UDim2.new(0, 180, 0, 120)
PlayerListFrame.ScrollBarThickness = 10
