local Players = game:GetService("Players") local RunService = game:GetService("RunService") local player = Players.LocalPlayer local camera = workspace.CurrentCamera

-- Tạo camera clone local clonedCamera = Instance.new("Camera") clonedCamera.CFrame = camera.CFrame clonedCamera.FieldOfView = camera.FieldOfView clonedCamera.Parent = workspace

-- Ngắt liên kết với camera gốc player.CameraMode = Enum.CameraMode.LockFirstPerson camera.CameraType = Enum.CameraType.Scriptable

-- Cập nhật camera clone mỗi frame game:GetService("RunService").RenderStepped:Connect(function() camera.CFrame = clonedCamera.CFrame camera.FieldOfView = clonedCamera.FieldOfView end)

print("Camera clone đã được kích hoạt!")

