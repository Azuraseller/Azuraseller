--[[
  Advanced Anti-Interference Camera Clone Script for Roblox

  Mô tả:
  - Clone camera gốc và chuyển góc nhìn qua camera clone.
  - Thiết lập camera ban đầu sang Scriptable, khóa CameraMode và MouseBehavior để vô hiệu hóa shiftlock hay can thiệp từ bên ngoài.
  - Hệ thống "chống can hiệp": Theo dõi các thuộc tính quan trọng (CameraType, CameraMode, MouseBehavior)
    và tự động khôi phục nếu có sự thay đổi từ các script khác.
  - Hỗ trợ smooth transition giữa camera gốc và camera clone.
  - Cung cấp một controller để mở rộng thêm các tính năng (di chuyển, thay đổi FOV, …).
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local originalCamera = workspace.CurrentCamera

--------------------------
-- Thiết lập ban đầu:
--------------------------
-- Chuyển camera gốc sang chế độ Scriptable để hoàn toàn tự điều khiển
originalCamera.CameraType = Enum.CameraType.Scriptable

-- Khóa CameraMode của người chơi (ví dụ: LockFirstPerson) để vô hiệu shiftlock mặc định
player.CameraMode = Enum.CameraMode.LockFirstPerson

-- Đặt MouseBehavior thành LockCenter để hạn chế can thiệp từ input mặc định
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

-- Nếu có thuộc tính DevEnableMouseLock (dành cho một số game), tắt nó đi
if player.DevEnableMouseLock then
    player.DevEnableMouseLock = false
end

--------------------------
-- Clone và cấu hình cameraClone:
--------------------------
local cameraClone = originalCamera:Clone()
cameraClone.Name = "CameraClone"
cameraClone.Parent = workspace  -- Đảm bảo luôn nằm trong workspace

-- Bảng lưu trữ trạng thái mong muốn của cameraClone (có thể mở rộng thêm nếu cần)
local desiredState = {
    CFrame = cameraClone.CFrame,
    FieldOfView = cameraClone.FieldOfView,
    CameraSubject = cameraClone.CameraSubject,
    Focus = cameraClone.Focus,
}

--------------------------
-- Cấu hình Smooth Transition:
--------------------------
local useSmoothTransition = true
local smoothSpeed = 10  -- Điều chỉnh tốc độ chuyển mượt (cao hơn = nhanh hơn)

--------------------------
-- Hàm cập nhật camera mỗi frame:
--------------------------
local function updateCamera(dt)
    -- Bảo vệ thuộc tính: Nếu ai đó thay đổi, tự động khôi phục lại giá trị
    if originalCamera.CameraType ~= Enum.CameraType.Scriptable then
        originalCamera.CameraType = Enum.CameraType.Scriptable
    end
    if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    -- Cập nhật góc nhìn theo cameraClone (có smooth transition hoặc trực tiếp)
    if useSmoothTransition then
        originalCamera.CFrame = originalCamera.CFrame:Lerp(cameraClone.CFrame, math.clamp(dt * smoothSpeed, 0, 1))
        originalCamera.FieldOfView = originalCamera.FieldOfView + (cameraClone.FieldOfView - originalCamera.FieldOfView) * math.clamp(dt * smoothSpeed, 0, 1)
    else
        originalCamera.CFrame = cameraClone.CFrame
        originalCamera.FieldOfView = cameraClone.FieldOfView
    end

    -- Đồng bộ các thuộc tính khác
    originalCamera.CameraSubject = cameraClone.CameraSubject
    originalCamera.Focus = cameraClone.Focus
end

local renderSteppedConnection = RunService.RenderStepped:Connect(function(dt)
    updateCamera(dt)
end)

--------------------------
-- Hệ thống chống can hiệp: Sử dụng GetPropertyChangedSignal để theo dõi thay đổi
--------------------------
-- Bảo vệ cameraClone (nếu bị gỡ khỏi workspace, tự động gán lại)
cameraClone:GetPropertyChangedSignal("Parent"):Connect(function()
    if cameraClone.Parent ~= workspace then
        cameraClone.Parent = workspace
    end
end)

-- Theo dõi các thuộc tính của cameraClone để cập nhật trạng thái mong muốn
cameraClone:GetPropertyChangedSignal("CFrame"):Connect(function()
    desiredState.CFrame = cameraClone.CFrame
end)
cameraClone:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    desiredState.FieldOfView = cameraClone.FieldOfView
end)
cameraClone:GetPropertyChangedSignal("CameraSubject"):Connect(function()
    desiredState.CameraSubject = cameraClone.CameraSubject
end)
cameraClone:GetPropertyChangedSignal("Focus"):Connect(function()
    desiredState.Focus = cameraClone.Focus
end)

-- Ngoài ra, giám sát camera gốc và các thuộc tính quan trọng của người chơi:
originalCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
    if originalCamera.CameraType ~= Enum.CameraType.Scriptable then
        originalCamera.CameraType = Enum.CameraType.Scriptable
    end
end)
player:GetPropertyChangedSignal("CameraMode"):Connect(function()
    if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end)
UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

--------------------------
-- Controller: Cung cấp các hàm điều khiển mở rộng cho cameraClone
--------------------------
local CameraController = {}

-- Cho phép bật/tắt chuyển mượt và điều chỉnh tốc độ
function CameraController:SetSmoothTransition(enable, speed)
    useSmoothTransition = enable
    if speed then
        smoothSpeed = speed
    end
end

-- Di chuyển cameraClone đến vị trí mới (có thể kết hợp tweening, input, v.v.)
function CameraController:MoveCamera(newCFrame)
    cameraClone.CFrame = newCFrame
end

-- Thay đổi FieldOfView của cameraClone
function CameraController:SetFOV(newFOV)
    cameraClone.FieldOfView = newFOV
end

-- Hàm hủy bỏ script, giải phóng kết nối và reset lại camera gốc
function CameraController:Destroy()
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
        renderSteppedConnection = nil
    end
    originalCamera.CameraType = Enum.CameraType.Custom  -- Reset lại chế độ mặc định
    if cameraClone and cameraClone.Parent then
        cameraClone:Destroy()
    end
end

print("Advanced Anti-Interference Camera Clone Script đã được kích hoạt.")

-- Nếu dùng dạng ModuleScript, return đối tượng controller để sử dụng lại ở các script khác.
return CameraController
