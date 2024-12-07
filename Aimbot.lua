local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CamlockState = false
local Prediction = 0.16  -- Mức độ dự đoán chuyển động của đối thủ
local MaxDistance = 50  -- Bán kính tối đa để nhắm mục tiêu
local Locked = false
getgenv().Key = "c"  -- Phím để bật/tắt aimbot

local enemy = nil
local lastTargetPosition = nil  -- Vị trí của mục tiêu trước đó để chuyển động mượt mà
local lastVelocity = Vector3.new()  -- Tốc độ của mục tiêu để kiểm tra chuyển động
local smoothSpeed = 0.1  -- Mức độ mượt mà của chuyển động camera (giá trị nhỏ sẽ mượt mà hơn)

local isMobile = UserInputService.TouchEnabled

local currentDistance = MaxDistance  -- Khởi tạo khoảng cách hiện tại bằng MaxDistance

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

    -- Cập nhật nếu đối thủ gần nhất nằm trong phạm vi và tự động ngắm vào đối thủ
    if ClosestPlayer and (ClosestPlayer.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= MaxDistance then
        enemy = ClosestPlayer  -- Cập nhật đối thủ gần nhất
        CamlockState = true  -- Bật trạng thái Camlock
    end

    return ClosestPlayer
end

-- Hàm ngắm mượt mà vào vị trí mục tiêu (cộng với dự đoán chuyển động)
function SmoothAim(targetPosition)
    local camera = workspace.CurrentCamera
    local currentPosition = camera.CFrame.p
    local direction = (targetPosition - currentPosition).unit
    -- Tạo tween để di chuyển mượt mà
    local smoothFactor = 0.1  -- Chỉnh độ mượt của camera
    local newPosition = currentPosition + direction * smoothFactor
    camera.CFrame = CFrame.new(newPosition, targetPosition)
end

-- Hàm xử lý chuyển động camera mượt mà khi đối thủ di chuyển
RunService.Heartbeat:Connect(function()
    if CamlockState and enemy then
        if tick() - lastUpdate > 0.1 then  -- Chỉ cập nhật sau mỗi 100ms
            lastUpdate = tick()
            local targetPosition = enemy.Position + enemy.Velocity * Prediction

            -- Cập nhật khoảng cách hiện tại dựa trên vị trí của LocalPlayer và đối thủ
            currentDistance = (LocalPlayer.Character.HumanoidRootPart.Position - enemy.Position).Magnitude

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
Frame.Position = UDim2.new(1, -120, 0, 50)  -- Di chuyển GUI lên trên một chút
Frame.Size = UDim2.new(0, 100, 0, 100)    -- Làm GUI thành hình vuông (kích thước 100x100)
Frame.Active = true
Frame.Draggable = true

local function TopContainer()
    Frame.Position = UDim2.new(1, -Frame.AbsoluteSize.X - 10, 0, 50)  -- Điều chỉnh vị trí khi thay đổi kích thước
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
TextButton.Size = UDim2.new(0, 80, 0, 30)  -- Thay đổi kích thước nút một chút
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

-- Cải thiện mã xử lý Camlock trên PC
local function ToggleCamlockOnMobile()
    Locked = not Locked
    if Locked then
        -- Cập nhật lại enemy mỗi khi bật Camlock
        enemy = FindNearestEnemy()
        if enemy then
            CamlockState = true
        end
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
        CamlockState = false  -- Đặt lại Camlock khi nhân vật chết
        enemy = nil           -- Đặt lại mục tiêu
        TextButton.Text = "OFF"  -- Cập nhật UI thành OFF
    end)
end)
