-- wall hop by (Dutj)
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.Size = UDim2.new(0, 200, 0, 140)
frame.Position = UDim2.new(0.5, -100, 0.5, -70)
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = false

local frameWidth = frame.Size.X.Offset
local buttonWidth = 60
local totalButtonWidth = buttonWidth * 3
local totalSpacing = frameWidth - totalButtonWidth
local spacing = totalSpacing / 4

local additionButtonX = spacing + buttonWidth + spacing
local offButtonX = spacing + buttonWidth + spacing + buttonWidth + spacing

local onButton = Instance.new("TextButton")
onButton.Parent = frame
onButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
onButton.Size = UDim2.new(0, buttonWidth, 0, 30)
onButton.Position = UDim2.new(0, onButtonX, 0, 20)
onButton.Text = "On"
onButton.TextScaled = true

local additionButton = Instance.new("TextButton")
additionButton.Parent = frame
additionButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
additionButton.Size = UDim2.new(0, buttonWidth, 0, 30)
additionButton.Position = UDim2.new(0, additionButtonX, 0, 20)
additionButton.Text = "Addition"
additionButton.TextScaled = true
local additionToggle = false
local additionalFrame = nil
local jumpButtonInAddition = nil

local offButton = Instance.new("TextButton")
offButton.Parent = frame
offButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
offButton.Size = UDim2.new(0, buttonWidth, 0, 30)
offButton.Position = UDim2.new(0, offButtonX, 0, 20)
offButton.Text = "Off"
offButton.TextScaled = true

local destroyButton = Instance.new("TextButton")
destroyButton.Parent = frame
destroyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Size = UDim2.new(0, 160, 0, 30)
destroyButton.Position = UDim2.new(0, 20, 0, 60)
destroyButton.Text = "Destroy"
destroyButton.TextScaled = true

local autoButton = Instance.new("TextButton")
autoButton.Parent = frame
autoButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Start Red (Off)
autoButton.Size = UDim2.new(0, 160, 0, 30)
autoButton.Position = UDim2.new(0, 20, 0, 100)
autoButton.Text = "Auto"
autoButton.TextScaled = true
local autoToggle = false -- State variable for Auto button

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Size = UDim2.new(0, 200, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, -30)
statusLabel.Text = "WallHop V4: Off"
statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
statusLabel.TextScaled = true

local plusButton = Instance.new("TextButton")
plusButton.Parent = frame
plusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Start Red (Off)
plusButton.Size = UDim2.new(0, 30, 0, 30)
plusButton.Position = UDim2.new(0, -35, 0, -30)
plusButton.Text = "+"
plusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
plusButton.TextScaled = true
local plusButtonToggle = false
local plusFrame = nil -- Holds GUI 3
local selectButtonInPlusFrame = nil
local selectModeActive = false
local colorListLabelInPlusFrame = nil
local mouseClickConnection = nil
local selectedBrickColor = nil 

local wallhopToggle = false
local InfiniteJumpEnabled = true 
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
local jumpConnection = nil
local autoJumpConnection = nil 

local function getWallRaycastResult()
    local character = player.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    raycastParams.FilterDescendantsInstances = {character}
    local detectionDistance = 2
    local closestHit = nil
    local minDistance = detectionDistance + 1
    local hrpCF = humanoidRootPart.CFrame

    for i = 0, 7 do
        local angle = math.rad(i * 45)
        local direction = (hrpCF * CFrame.Angles(0, angle, 0)).LookVector
        local ray = Workspace:Raycast(humanoidRootPart.Position, direction * detectionDistance, raycastParams)
        if ray and ray.Instance and ray.Distance < minDistance then
            minDistance = ray.Distance
            closestHit = ray
        end
    end

    local blockCastSize = Vector3.new(1.5, 1, 0.5)
    local blockCastOffset = CFrame.new(0, -1, -0.5)
    local blockCastOriginCF = hrpCF * blockCastOffset
    local blockCastDirection = hrpCF.LookVector
    local blockCastDistance = 1.5
    local blockResult = Workspace:Blockcast(blockCastOriginCF, blockCastSize, blockCastDirection * blockCastDistance, raycastParams)

    if blockResult and blockResult.Instance and blockResult.Distance < minDistance then
         minDistance = blockResult.Distance
         closestHit = blockResult
    end

    return closestHit
end

local function executeWallJump(wallRayResult, jumpType)
    
    if jumpType ~= "Button" and not InfiniteJumpEnabled then
      
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local camera = Workspace.CurrentCamera

    if not (humanoid and rootPart and camera and humanoid:GetState() ~= Enum.HumanoidStateType.Dead and wallRayResult) then
    
        return
    end

    if jumpType ~= "Button" then
        InfiniteJumpEnabled = false 
    end

    local maxInfluenceAngleRight = math.rad(20)
    local maxInfluenceAngleLeft  = math.rad(-100)

    local wallNormal = wallRayResult.Normal
    local baseDirectionAwayFromWall = Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit
    if baseDirectionAwayFromWall.Magnitude < 0.1 then
         local dirToHit = (wallRayResult.Position - rootPart.Position) * Vector3.new(1,0,1)
         baseDirectionAwayFromWall = -dirToHit.Unit
         if baseDirectionAwayFromWall.Magnitude < 0.1 then
             baseDirectionAwayFromWall = -rootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
             if baseDirectionAwayFromWall.Magnitude > 0.1 then baseDirectionAwayFromWall = baseDirectionAwayFromWall.Unit end
             if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end
         end
    end
    baseDirectionAwayFromWall = Vector3.new(baseDirectionAwayFromWall.X, 0, baseDirectionAwayFromWall.Z).Unit
    if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall = Vector3.new(0,0,1) end

    local cameraLook = camera.CFrame.LookVector
    local horizontalCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
    if horizontalCameraLook.Magnitude < 0.1 then horizontalCameraLook = baseDirectionAwayFromWall end

    local dot = math.clamp(baseDirectionAwayFromWall:Dot(horizontalCameraLook), -1, 1)
    local angleBetween = math.acos(dot)
    local cross = baseDirectionAwayFromWall:Cross(horizontalCameraLook)
    local rotationSign = -math.sign(cross.Y)
    if rotationSign == 0 then angleBetween = 0 end

    local actualInfluenceAngle
    if rotationSign == 1 then
        actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleRight)
    elseif rotationSign == -1 then
        actualInfluenceAngle = math.min(angleBetween, maxInfluenceAngleLeft)
    else
        actualInfluenceAngle = 0
    end

    local adjustmentRotation = CFrame.Angles(0, actualInfluenceAngle * rotationSign, 0)
    local initialTargetLookDirection = adjustmentRotation * baseDirectionAwayFromWall

    rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + initialTargetLookDirection)
    RunService.Heartbeat:Wait()

    local didJump = false
    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
         humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
         didJump = true
         print("Performed jump away from wall (".. (jumpType or "Unknown") .. ").")

         rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, -1, 0)
         task.wait(0.15)
         rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 1, 0)
         print("Applied cosmetic rotation flick (-1/+1 radians) (".. (jumpType or "Unknown") .. ").")
    end

    if didJump then
         local directionTowardsWall = -baseDirectionAwayFromWall
         task.wait(0.05)
         rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + directionTowardsWall)
         print("Rotated back towards wall after jump (".. (jumpType or "Unknown") .. ").")
    end

    if jumpType ~= "Button" then
        task.wait(0.1)
        InfiniteJumpEnabled = true
    end
end

local function performFaceWallJump()
    local wallRayResult = getWallRaycastResult()
    if wallRayResult then
        executeWallJump(wallRayResult, "Button") 
    else
        print("No nearby wall found for wall jump (Button).")
    end
end

onButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "WallHop V4: On"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    wallhopToggle = true
end)

offButton.MouseButton1Click:Connect(function()
    statusLabel.Text = "WallHop V4: Off"
    statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    wallhopToggle = false
end)

additionButton.MouseButton1Click:Connect(function()
    additionToggle = not additionToggle
    if additionToggle then
        if not additionalFrame then
            additionButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            additionalFrame = Instance.new("Frame")
            additionalFrame.Name = "AdditionalWallHopFrame"
            additionalFrame.Parent = frame
            additionalFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            additionalFrame.Size = UDim2.new(0, 200, 0, 100)
            additionalFrame.Position = UDim2.new(0, 0, 1, 0)
            additionalFrame.Active = false; additionalFrame.Draggable = false; additionalFrame.BorderSizePixel = 1

            jumpButtonInAddition = Instance.new("TextButton")
            jumpButtonInAddition.Name = "FaceWallJumpButton"; jumpButtonInAddition.Parent = additionalFrame
            jumpButtonInAddition.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            jumpButtonInAddition.Size = UDim2.new(0.8, 0, 0.4, 0)
            jumpButtonInAddition.Position = UDim2.new(0.1, 0, 0.3, 0)
            jumpButtonInAddition.Text = "Jump"; jumpButtonInAddition.TextColor3 = Color3.fromRGB(255,255,255)
            jumpButtonInAddition.TextScaled = true; jumpButtonInAddition.Active = true
            jumpButtonInAddition.MouseButton1Click:Connect(performFaceWallJump)
        end
    else
        if additionalFrame then
            additionButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            additionalFrame:Destroy(); additionalFrame = nil; jumpButtonInAddition = nil
        end
    end
end)

autoButton.MouseButton1Click:Connect(function()
    local desiredState = not autoToggle

    if desiredState == true then
        if selectedBrickColor then
            autoToggle = true
            autoButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            print("Auto toggled ON")
        else
            autoToggle = false
            autoButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            print("Auto toggle FAILED: No color selected in GUI 3 yet.")
            local currentStatusText = statusLabel.Text -- Store current text
            local currentStatusColor = statusLabel.TextColor3 -- Store current color
            statusLabel.Text = "Auto requires color selection!"
            statusLabel.TextColor3 = Color3.fromRGB(255,100,0)
            task.wait(2)
            statusLabel.Text = currentStatusText -- Revert status label
            statusLabel.TextColor3 = currentStatusColor
        end
    else
        autoToggle = false
        autoButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        print("Auto toggled OFF")
    end
end)

plusButton.MouseButton1Click:Connect(function()
    plusButtonToggle = not plusButtonToggle

    if plusButtonToggle then
        plusButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

        if not plusFrame then
            print("Plus Button: Creating GUI 3")
            plusFrame = Instance.new("Frame")
            plusFrame.Name = "PlusFrame"; plusFrame.Parent = frame
            plusFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            plusFrame.Size = UDim2.new(0, 200, 0, 100); plusFrame.Position = UDim2.new(0, -205, 0, 0)
            plusFrame.Active = false; plusFrame.Draggable = false; plusFrame.BorderSizePixel = 1
            plusFrame.Visible = true

            selectButtonInPlusFrame = Instance.new("TextButton")
            selectButtonInPlusFrame.Name = "SelectPlatformButton"; selectButtonInPlusFrame.Parent = plusFrame
            selectButtonInPlusFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            selectButtonInPlusFrame.Size = UDim2.new(0, 80, 0, 30); selectButtonInPlusFrame.Position = UDim2.new(0, 10, 0, 10)
            selectButtonInPlusFrame.Text = "Select"; selectButtonInPlusFrame.TextScaled = true; selectButtonInPlusFrame.TextColor3 = Color3.fromRGB(255, 255, 255)

            colorListLabelInPlusFrame = Instance.new("TextLabel")
            colorListLabelInPlusFrame.Name = "ColorDisplayLabel"; colorListLabelInPlusFrame.Parent = plusFrame
            colorListLabelInPlusFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200); colorListLabelInPlusFrame.BackgroundTransparency = 0
            colorListLabelInPlusFrame.Size = UDim2.new(0, 180, 0, 50); colorListLabelInPlusFrame.Position = UDim2.new(0, 10, 0, 45)
            colorListLabelInPlusFrame.Text = "Click a part to detect color"; colorListLabelInPlusFrame.TextColor3 = Color3.new(1, 1, 1)
            colorListLabelInPlusFrame.TextScaled = true; colorListLabelInPlusFrame.BorderSizePixel = 1; colorListLabelInPlusFrame.BorderColor3 = Color3.new(0,0,0)

            selectButtonInPlusFrame.MouseButton1Click:Connect(function()
                selectModeActive = not selectModeActive

                if selectModeActive then
                    selectButtonInPlusFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    colorListLabelInPlusFrame.Text = "Click any part in the world"
                    print("Select Mode Activated")

                    if mouseClickConnection then mouseClickConnection:Disconnect(); mouseClickConnection = nil end

                    mouseClickConnection = mouse.Button1Down:Connect(function()
                        local target = mouse.Target
                        if target and target:IsA("BasePart") then
                            local part = target
                            local bColor = part.BrickColor
                            local colorValue = part.Color

                            selectedBrickColor = bColor
                            print("Stored selected BrickColor:", selectedBrickColor.Name)

                            colorListLabelInPlusFrame.Text = "Color: " .. bColor.Name
                            colorListLabelInPlusFrame.TextColor3 = colorValue
                            print("Detected Part:", part.Name, "Color:", bColor.Name)

                        else
                            print("Clicked invalid target or empty space.")
                        end
                    end)
                else
                    selectButtonInPlusFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    print("Select Mode Deactivated")
                    if mouseClickConnection then mouseClickConnection:Disconnect(); mouseClickConnection = nil end
                end
            end)
        else
            print("Plus Button: Showing existing GUI 3")
            plusFrame.Visible = true
        end

    else
        plusButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        if plusFrame then
            print("Plus Button: Hiding GUI 3")
            plusFrame.Visible = false
            if selectModeActive then
                selectModeActive = false
                if selectButtonInPlusFrame then selectButtonInPlusFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
                if mouseClickConnection then mouseClickConnection:Disconnect(); mouseClickConnection = nil end
            end
        end
    end
end)

autoJumpConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if not autoToggle then return end
    
    if not selectedBrickColor then return end
    if not wallhopToggle then return end 

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not (humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead) then return end

    local wallRayResult = getWallRaycastResult()

    if wallRayResult and wallRayResult.Instance then
        local hitPart = wallRayResult.Instance
        if hitPart:IsA("BasePart") and hitPart.BrickColor == selectedBrickColor then
             executeWallJump(wallRayResult, "Auto")
        end
    end
end)

destroyButton.MouseButton1Click:Connect(function()
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    if autoJumpConnection then autoJumpConnection:Disconnect(); autoJumpConnection = nil end
    if mouseClickConnection then mouseClickConnection:Disconnect(); mouseClickConnection = nil end

    if additionalFrame and additionalFrame.Parent then additionalFrame:Destroy() end
    if plusFrame and plusFrame.Parent then plusFrame:Destroy() end

    wallhopToggle = false; autoToggle = false; plusButtonToggle = false; additionToggle = false; selectModeActive = false
    selectedBrickColor = nil

    if screenGui and screenGui.Parent then screenGui:Destroy() end

    additionalFrame = nil; jumpButtonInAddition = nil;
    plusFrame = nil; selectButtonInPlusFrame = nil; colorListLabelInPlusFrame = nil;
    plusButton = nil; frame = nil; screenGui = nil; mouseClickConnection = nil; autoJumpConnection = nil
    print("GUI Destroyed.")
end)

jumpConnection = UserInputService.JumpRequest:Connect(function()
    if not wallhopToggle then return end 

    local wallRayResult = getWallRaycastResult()
    if wallRayResult then
        executeWallJump(wallRayResult, "Manual")
    end
end)

local toggleVisible = true

local function toggleMenu()
	toggleVisible = not toggleVisible
	if frame then
		frame.Visible = toggleVisible
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.M then
		toggleMenu()
	end
end)

local phoneBtn = Instance.new("TextButton")
phoneBtn.Parent = screenGui
phoneBtn.Size = UDim2.new(0, 60, 0, 30)
phoneBtn.Position = UDim2.new(1, -70, 0, 20)
phoneBtn.Text = "Menu"
phoneBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phoneBtn.TextColor3 = Color3.new(1, 1, 1)
phoneBtn.Font = Enum.Font.SourceSans
phoneBtn.TextSize = 14
phoneBtn.MouseButton1Click:Connect(toggleMenu)
