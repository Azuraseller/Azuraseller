local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera

-- Cài đặt
local fov = 100
local aimMode = false
local lockOnMode = false
local softLock = true
local transitionSpeed = 0.15
local highlightColor = Color3.fromRGB(255, 0, 0)
local reticleSize = 10
local dynamicFOV = true
local autoAim = true
local targetPart = "Head"

-- Vòng FOV
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

-- Tâm hướng
local Reticle = Drawing.new("Circle")
Reticle.Visible = false
Reticle.Thickness = 2
Reticle.Color = Color3.fromRGB(255, 255, 0)
Reticle.Filled = true
Reticle.Radius = reticleSize

-- Highlight mục tiêu
local highlight = Instance.new("Highlight")
highlight.Enabled = false
highlight.FillTransparency = 0.5
highlight.FillColor = highlightColor
highlight.OutlineTransparency = 1
highlight.Parent = workspace

-- GUI
local ScreenGui = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
local FOVLabel = Instance.new("TextLabel", ScreenGui)
FOVLabel.Size = UDim2.new(0, 200, 0, 50)
FOVLabel.Position = UDim2.new(0, 10, 0, 10)
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.BackgroundTransparency = 0.5
FOVLabel.Text = "FOV: " .. fov
FOVLabel.Visible = true

-- Cập nhật vòng FOV
local function updateDrawings()
    local camViewportSize = Cam.ViewportSize
    FOVring.Position = camViewportSize / 2
    FOVring.Radius = fov
end

-- Camera di chuyển mượt mà
local function smoothLookAt(targetPosition)
    local currentCFrame = Cam.CFrame
    local targetCFrame = CFrame.new(Cam.CFrame.Position, targetPosition)
    Cam.CFrame = currentCFrame:Lerp(targetCFrame, transitionSpeed)
end

-- Tìm mục tiêu gần nhất
local function getClosestPlayerInFOV()
    local nearest = nil
    local last = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) then
            local part = player.Character:FindFirstChild(targetPart)
            local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
            local distance = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude

            if distance < last and isVisible and distance < fov then
                last = distance
                nearest = player
            end
        end
    end

    return nearest
end

-- Hiển thị tâm hướng
local function updateReticle(target)
    if target and target.Character and target.Character:FindFirstChild(targetPart) then
        local part = target.Character:FindFirstChild(targetPart)
        local screenPos, isVisible = Cam:WorldToViewportPoint(part.Position)

        if isVisible then
            Reticle.Visible = true
            Reticle.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            Reticle.Visible = false
        end
    else
        Reticle.Visible = false
    end
end

-- Camera và Aim
local function aimAtTarget(target)
    if aimMode and target and target.Character and target.Character:FindFirstChild(targetPart) then
        local part = target.Character:FindFirstChild(targetPart)
        smoothLookAt(part.Position)

        if lockOnMode then
            highlight.Enabled = true
            highlight.Adornee = target.Character
        else
            highlight.Enabled = false
        end
    end
end

-- Phím tắt
local function onKeyDown(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        RunService:UnbindFromRenderStep("FOVUpdate")
        FOVring:Remove()
        Reticle.Visible = false
        highlight:Destroy()
    elseif input.KeyCode == Enum.KeyCode.F then
        aimMode = not aimMode
    elseif input.KeyCode == Enum.KeyCode.L then
        lockOnMode = not lockOnMode
    elseif input.KeyCode == Enum.KeyCode.Plus then
        fov = math.min(fov + 10, 150)
        FOVLabel.Text = "FOV: " .. fov
    elseif input.KeyCode == Enum.KeyCode.Minus then
        fov = math.max(fov - 10, 50)
        FOVLabel.Text = "FOV: " .. fov
    end
end

UserInputService.InputBegan:Connect(onKeyDown)

-- Vòng lặp chính
RunService.RenderStepped:Connect(function()
    updateDrawings()
    local closest = getClosestPlayerInFOV()
    if closest then
        aimAtTarget(closest)
        updateReticle(closest)
    else
        highlight.Enabled = false
        Reticle.Visible = false
    end
end)
