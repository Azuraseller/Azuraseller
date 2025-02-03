-- Phiên bản Premium với các tính năng AI-Driven
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--[[ 
    CẤU HÌNH THẾ HỆ MỚI V5.0
    Tích hợp machine learning và hệ thống adaptive
]]
local Config = {
    NeuralPrediction = {
        LearningRate = 0.15,
        HistorySize = 30,
        PatternDetection = {
            MovementThreshold = 2.5,
            DirectionChangeWeight = 0.7
        },
        EnvironmentalFactors = {
            Gravity = 0.5,
            TerrainFriction = 0.3
        }
    },

    TargetSystem = {
        LockProtocol = {
            Acquisition = {
                FOV = math.rad(50),
                PriorityWeights = {
                    ThreatLevel = 1.8,
                    Visibility = 2.2,
                    Proximity = 1.5,
                    RecentDamage = 0.9
                },
                AutoSwitchDelay = 0.4
            },
            Retention = {
                BreakConditions = {
                    Angle = math.rad(35),
                    Distance = 150,
                    OcclusionTime = 1.2
                }
            }
        },
        SignatureAnalysis = {
            BodyPartPriorities = {
                Head = 4.0,
                Torso = 3.0,
                Limbs = 1.5
            }
        }
    },

    AdaptiveCamera = {
        CollisionAvoidance = {
            SphereCastRadius = 1.5,
            BufferDistance = 0.8,
            RecoverySpeed = 5.0
        },
        DynamicFraming = {
            VerticalConstraints = {
                MinAngle = -math.rad(20),
                MaxAngle = math.rad(60)
            },
            DistanceBasedOffset = {
                NearRange = 5,
                FarRange = 50,
                HeightModifier = 0.3
            }
        }
    },

    HolographicUI = {
        LockDisplay = {
            BaseSize = UDim2.new(0, 120, 0, 120),
            NeuralPulse = {
                Speed = 3,
                Intensity = 0.15
            },
            TargetInfo = {
                NameTag = {
                    FontSize = 20,
                    TextStroke = 2,
                    Offset = UDim2.new(0, 0, 0.25, 0)
                },
                HealthBar = {
                    Size = UDim2.new(0.6, 0, 0.03, 0),
                    Offset = UDim2.new(0, 0, 0.4, 0)
                }
            }
        },
        ControlPanel = {
            SlideAnimation = {
                Duration = 0.4,
                EasingStyle = "Quint"
            }
        }
    }
}

--[[
    HỆ THỐNG NEURAL NETWORK
]]
local NeuralCore = {
    PredictionModel = {
        Weights = {
            Velocity = 0.65,
            Acceleration = 0.28,
            PlayerInput = 0.07
        },
        LastPositions = {},
        VelocityBuffer = {}
    },

    TrainingModule = function(self, delta)
        -- Adaptive learning algorithm
        local errorCorrection = delta.Magnitude * Config.NeuralPrediction.LearningRate
        self.Weights.Velocity = math.clamp(self.Weights.Velocity + errorCorrection * 0.8, 0.4, 0.8)
        self.Weights.Acceleration = math.clamp(self.Weights.Acceleration + errorCorrection * 0.15, 0.1, 0.3)
        self.Weights.PlayerInput = 1 - (self.Weights.Velocity + self.Weights.Acceleration)
    end
}

--[[
    HỆ THỐNG TARGET PROFILE
]]
local TargetProfile = {
    CurrentTarget = nil,
    TargetHistory = {},
    ThreatAssessment = {},

    CalculateThreat = function(self, target)
        local threatScore = 0
        local char = target.Parent
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        threatScore += Config.TargetSystem.SignatureAnalysis.BodyPartPriorities[target.Name] or 1.0
        threatScore += (humanoid and (1 - humanoid.Health/humanoid.MaxHealth)) * 2.5
        threatScore += self.ThreatAssessment[target] or 0
        
        return threatScore * Config.TargetSystem.LockProtocol.Acquisition.PriorityWeights.ThreatLevel
    end,

    UpdateProfile = function(self, target, deltaTime)
        -- Threat decay system
        for t,_ in pairs(self.ThreatAssessment) do
            self.ThreatAssessment[t] = math.max(0, self.ThreatAssessment[t] - deltaTime * 0.5)
        end
        self.ThreatAssessment[target] = (self.ThreatAssessment[target] or 0) + deltaTime * 1.2
    end
}

--[[
    HỆ THỐNG CAMERA THÔNG MINH
]]
local SmartCamera = {
    DesiredPosition = Camera.CFrame.Position,
    ObstructionOffset = Vector3.new(),

    UpdateCamera = function(self, targetPosition)
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPos = character:GetPivot().Position
        local toTarget = targetPosition - rootPos
        local distance = toTarget.Magnitude
        
        -- Dynamic framing calculation
        local verticalMod = math.clamp(
            (distance - Config.AdaptiveCamera.DynamicFraming.DistanceBasedOffset.NearRange) / 
            (Config.AdaptiveCamera.DynamicFraming.DistanceBasedOffset.FarRange - Config.AdaptiveCamera.DynamicFraming.DistanceBasedOffset.NearRange),
            0, 1
        ) * Config.AdaptiveCamera.DynamicFraming.DistanceBasedOffset.HeightModifier
        
        local desiredLook = CFrame.lookAt(
            rootPos + Vector3.new(0, verticalMod * distance, 0),
            targetPosition + Vector3.new(0, verticalMod * distance * 0.5, 0)
        )
        
        -- Collision avoidance
        local castResult = workspace:SphereCast(
            desiredLook.Position,
            Config.AdaptiveCamera.CollisionAvoidance.SphereCastRadius,
            (targetPosition - desiredLook.Position).Unit * 50,
            nil,
            true
        )
        
        if castResult then
            self.ObstructionOffset = (castResult.Position - desiredLook.Position).Unit * 
                (castResult.Distance - Config.AdaptiveCamera.CollisionAvoidance.BufferDistance)
        else
            self.ObstructionOffset = self.ObstructionOffset:Lerp(
                Vector3.new(),
                Config.AdaptiveCamera.CollisionAvoidance.RecoverySpeed * RunService.Heartbeat:Wait()
            )
        end
        
        Camera.CFrame = CFrame.lookAt(
            desiredLook.Position + self.ObstructionOffset,
            targetPosition + Vector3.new(0, verticalMod * distance * 0.5, 0)
        )
    end
}

--[[
    HỆ THỐNG GIAO DIỆN HOLO
]]
local HolographicUI = {
    Elements = {},
    
    CreateDisplay = function(self)
        local gui = Instance.new("ScreenGui")
        gui.Name = "AimAssistHUD"
        gui.ResetOnSpawn = false
        
        -- Neural Lock Indicator
        local lockRing = Instance.new("ImageLabel")
        lockRing.Image = "rbxassetid://3570695787"
        lockRing.Size = Config.HolographicUI.LockDisplay.BaseSize
        lockRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        lockRing.AnchorPoint = Vector2.new(0.5, 0.5)
        lockRing.BackgroundTransparency = 1
        lockRing.ImageColor3 = Color3.fromRGB(255, 60, 60)
        
        -- Neural Pulse Effect
        task.spawn(function()
            while true do
                lockRing.ImageTransparency = 0.3
                TweenService:Create(lockRing, TweenInfo.new(1/Config.HolographicUI.LockDisplay.NeuralPulse.Speed), {
                    Size = Config.HolographicUI.LockDisplay.BaseSize + UDim2.new(0,20,0,20),
                    ImageTransparency = 0.7
                }):Play()
                task.wait(1/Config.HolographicUI.LockDisplay.NeuralPulse.Speed)
                TweenService:Create(lockRing, TweenInfo.new(1/Config.HolographicUI.LockDisplay.NeuralPulse.Speed), {
                    Size = Config.HolographicUI.LockDisplay.BaseSize,
                    ImageTransparency = 0.3
                }):Play()
                task.wait(1/Config.HolographicUI.LockDisplay.NeuralPulse.Speed)
            end
        end)
        
        -- Target Info Panel
        local infoFrame = Instance.new("Frame")
        infoFrame.Size = UDim2.new(1.5, 0, 0.2, 0)
        infoFrame.Position = Config.HolographicUI.LockDisplay.TargetInfo.NameTag.Offset
        infoFrame.BackgroundTransparency = 1
        
        local nameTag = Instance.new("TextLabel")
        nameTag.Size = UDim2.new(1, 0, 0.5, 0)
        nameTag.Font = Enum.Font.GothamBlack
        nameTag.TextStrokeTransparency = 0
        nameTag.TextStrokeColor3 = Color3.new(0,0,0)
        nameTag.TextColor3 = Color3.new(1,1,1)
        nameTag.TextSize = Config.HolographicUI.LockDisplay.TargetInfo.NameTag.FontSize
        nameTag.Parent = infoFrame
        
        local healthBar = Instance.new("Frame")
        healthBar.Size = Config.HolographicUI.LockDisplay.TargetInfo.HealthBar.Size
        healthBar.Position = Config.HolographicUI.LockDisplay.TargetInfo.HealthBar.Offset
        healthBar.BackgroundColor3 = Color3.fromRGB(50,50,50)
        healthBar.BorderSizePixel = 0
        
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.Parent = healthBar
        
        healthBar.Parent = infoFrame
        infoFrame.Parent = lockRing
        lockRing.Parent = gui
        
        self.Elements = {
            Main = gui,
            LockRing = lockRing,
            NameTag = nameTag,
            HealthBar = healthFill
        }
        
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
}

--[[
    HỆ THỐNG XỬ LÝ CHÍNH
]]
local MainSystem = {
    LastInput = tick(),
    
    Initialize = function(self)
        HolographicUI:CreateDisplay()
        self:SetupInput()
        self:StartNeuralTraining()
    end,
    
    SetupInput = function(self)
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.F6 then
                self:ToggleUI()
            end
        end)
    end,
    
    ToggleUI = function(self)
        local currentTransparency = self.Elements.LockRing.ImageTransparency
        local targetValue = currentTransparency > 0.5 and 0.3 or 0.8
        TweenService:Create(self.Elements.LockRing, TweenInfo.new(0.3), {
            ImageTransparency = targetValue
        }):Play()
    end,
    
    StartNeuralTraining = function(self)
        RunService.Heartbeat:Connect(function(dt)
            if TargetProfile.CurrentTarget then
                NeuralCore:TrainingModule(dt)
                TargetProfile:UpdateProfile(TargetProfile.CurrentTarget, dt)
                SmartCamera:UpdateCamera(TargetProfile.CurrentTarget.Position)
                self:UpdateTargetDisplay()
            end
        end)
    end,
    
    UpdateTargetDisplay = function(self)
        local char = TargetProfile.CurrentTarget.Parent
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        self.Elements.NameTag.Text = char.Name
        self.Elements.HealthBar.Size = UDim2.new(humanoid.Health/humanoid.MaxHealth, 0, 1, 0)
    end
}

MainSystem:Initialize()
