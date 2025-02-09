local screenOverlay = Drawing.new("Square")
screenOverlay.Size = Vector2.new(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y)
screenOverlay.Position = Vector2.new(0, 0)
screenOverlay.Color = Color3.fromRGB(173, 216, 230) -- Xanh dương siêu nhạt (Light Blue)
screenOverlay.Transparency = 0.3 -- Độ trong suốt
screenOverlay.Filled = true
screenOverlay.Visible = true

-- Cập nhật kích thước khi thay đổi kích thước màn hình
game:GetService("RunService").RenderStepped:Connect(function()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    screenOverlay.Size = Vector2.new(viewportSize.X, viewportSize.Y)
end)
