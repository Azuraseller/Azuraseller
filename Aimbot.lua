local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CamlockState = false
local Prediction = 0.16  -- Mức độ dự đoán chuyển động của đối thủ
local MaxDistance = 17  -- Bán kính tối đa để nhắm mục tiêu
local Locked = false
getgenv().Key = "c"  -- Phím để bật/tắt aimbot

local enemy = nil
local lastTargetPosition = nil  -- Vị trí của mục tiêu trước đó để chuyển động mượt mà
local lastVelocity = Vector3.new()  -- Tốc độ của mục tiêu để kiểm tra chuyển động
local smoothSpeed = 0.1  -- Mức độ mượt mà của chuyển động camera (giá trị nhỏ sẽ mượt mà hơn)

local isMobile = UserInputService.TouchEnabled

-- Hàm để tìm đối thủ gần nhất trong phạm vi tối đa
function FindNearestEnemy()
    local ClosestDistance, ClosestPlayer = math.huge, nil
    local CenterPosition = Vector2.new(
        game:GetService("GuiService"):GetScreenResolution().X / 2,
        game:GetService("GuiService"):GetScreenResolution().Y / 2
    )
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                -- Tìm phần thân của đối thủ
                local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
                if torso then
                    local Position, IsVisibleOnViewport = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(torso.Position)
                    if IsVisibleOnViewport then
                        local Distance = (CenterPosition - Vector2.new(Position.X, Position.Y)).Magnitude
                        local distanceToPlayer = (torso.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        -- Lọc đối thủ trong phạm vi và tìm đối thủ gần nhất
                        if Distance < ClosestDistance and distanceToPlayer <= MaxDistance then
                            ClosestPlayer = torso
                            ClosestDistance = Distance
                        end
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

-- Hàm ngắm mượt mà vào vị trí mục tiêu (cộng với dự đoán chuyển động)
function SmoothAim(targetPosition)
    local camera = workspace.CurrentCamera
    local currentPosition = camera.CFrame.p
    local direction = (targetPosition - currentPosition).unit
    -- Tính toán vị trí mới của camera bằng cách sử dụng lerp (nội suy tuyến tính)
    local newPosition = currentPosition + direction * smoothSpeed
    camera.CFrame = CFrame.new(newPosition, targetPosition)
end

-- Hàm xử lý chuyển động camera mượt mà khi đối thủ di chuyển
RunService.Heartbeat:Connect(function()
    if CamlockState and enemy then
        local targetPosition = enemy.Position + enemy.Velocity * Prediction

        -- Nếu đối thủ không di chuyển đáng kể (tốc độ nhỏ), giữ nguyên vị trí camera mà không giật
        if enemy.Velocity.Magnitude < 0.1 then
            -- Đặt camera ngay vào vị trí của đối thủ mà không cần chuyển động
            local camera = workspace.CurrentCamera
            camera.CFrame = CFrame.new(camera.CFrame.p, targetPosition)
        else
            -- Chuyển động mượt mà khi đối thủ di chuyển
            SmoothAim(targetPosition)
        end
    end
end)

-- Tạo GUI và tương tác với nó
local BladLock = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Logo = Instance.new("ImageLabel")
local TextButton = Instance.new("TextButton")

-- Cấu hình cho GUI
BladLock.Name = "BladLock"
BladLock.Parent = game.CoreGui
BladLock.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = BladLock
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(1, -212, 0, 10)  -- GUI ở góc trên bên phải
Frame.Size = UDim2.new(0, 202, 0, 70)
Frame.Active = true
Frame.Draggable = true

local function TopContainer()
    Frame.Position = UDim2.new(1, -Frame.AbsoluteSize.X - 10, 0, 10) -- Giữ vị trí ở góc trên bên phải
end
TopContainer()

Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(TopContainer)

UICorner.Parent = Frame

Logo.Name = "Logo"
Logo.Parent = Frame
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BackgroundTransparency = 1
Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
Logo.BorderSizePixel = 0
Logo.Position = UDim2.new(0.15, 0, 0, 0)
Logo.Size = UDim2.new(0, 50, 0, 50)
Logo.Image = "rbxassetid://16792732223"
Logo.ImageTransparency = 0.2

TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BackgroundTransparency = 1
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.35, 0, 0.15, 0)
TextButton.Size = UDim2.new(0, 130, 0, 40)
TextButton.Font = Enum.Font.SourceSansSemibold
TextButton.Text = "Toggle CamLock"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextScaled = true
TextButton.TextSize = 14
TextButton.TextWrapped = true

local state = true

-- Tương tác trên mobile
if isMobile then
    TextButton.TouchTap:Connect(function()
        state = not state
        if not state then
            TextButton.Text = "ON"
            CamlockState = true
            enemy = FindNearestEnemy()
        else
            TextButton.Text = "OFF"
            CamlockState = false
            enemy = nil
        end
    end)
else
    -- Tắt button trên mobile nếu không phải mobile
    TextButton.Visible = false
end

-- Xử lý chuyển trạng thái Camlock bằng phím trên PC
local function ToggleCamlockOnMobile()
    Locked = not Locked
    if Locked then
        enemy = FindNearestEnemy()
        CamlockState = true
    else
        enemy = nil
        CamlockState = false
    end
end

if not isMobile then
    -- Thêm sự kiện nhấn phím để chuyển trạng thái Camlock
    local Mouse = LocalPlayer:GetMouse()
    Mouse.KeyDown:Connect(function(k)
        if k:lower() == getgenv().Key then
            ToggleCamlockOnMobile()
        end
    end)
end

-- Lắng nghe khi nhân vật chết và đặt lại trạng thái Camlock
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        CamlockState = false  -- Đặt lại Camlock khi người chơi chết
        enemy = nil
        TextButton.Text = "OFF"  -- Cập nhật UI thành OFF
    end)
end)

-- Đảm bảo Camlock luôn OFF khi script bắt đầu
CamlockState = false
TextButton.Text = "OFF"
