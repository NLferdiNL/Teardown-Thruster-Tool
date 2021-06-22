#include "datascripts/color4.lua"
#include "scripts/utils.lua"
#include "scripts/savedata.lua"
#include "scripts/ui.lua"
#include "scripts/menu.lua"
#include "datascripts/inputList.lua"

thrusterClass = {
	parentBody = nil,
	localPosition = nil,
	localNormal = nil,
	localInvertedNormal = nil,
	localSpriteLookPos = nil,
	power = 100,
	toggle = false,
	toggledOn = false,
	toggleInvert = false,
	keyForward = "h",
	keyBackward = "n",
}

local activeThrusters = {}

local thrusterSprite = nil
local toolDown = false

local debugConsoleNeeded = false

local screenCenter = { x = 0, y = 0 }

function init()
	saveFileInit()
	menu_init()
	
	RegisterTool("nlthrustertool", "Thruster Tool", "MOD/vox/thruster.vox")
	SetBool("game.tool.nlthrustertool.enabled", true)
	
	thrusterSprite = LoadSprite("sprites/thruster.png")
end

function tick(dt)
	menu_tick(dt)

	if isMenuOpen() then
		return
	end
	
	toolLogic(dt)
	placementLogic(dt)
	allThrustersHandler(dt)
end

function draw(dt)	
	menu_draw(dt)

	screenCenter.x = UiWidth() / 2
	screenCenter.y = UiHeight() / 2
	drawUI(dt)
end

function toolLogic(dt)
	-- Might reimplement this for fun.
	--[[if InputDown(binds["Fire_All_Thrusters_Forwards"]) then
		fireAllThrusters(false)
	elseif InputDown(binds["Fire_All_Thrusters_Backwards"]) then
		fireAllThrusters(true)
	end]]--
	
	if GetString("game.player.tool") ~= "nlthrustertool" then
		return
	end
	
	if InputPressed("usetool") then
		toolDown = true
	else
		toolDown = false
	end
	
	if InputPressed(binds["Delete_All_Thrusters"]) then
		activeThrusters = {}
	end
	
	if InputPressed(binds["Delete_Last_Thruster"]) and #activeThrusters > 0 then
		activeThrusters[#activeThrusters] = nil
	end
	
	local strengthAdd = 0
	
	if InputDown(binds["New_Thruster_Power_Up"]) then
		strengthAdd = strengthAdd + 1
	end
	
	if InputDown(binds["New_Thruster_Power_Down"]) then
		strengthAdd = strengthAdd - 1
	end
	
	thrusterClass.power = thrusterClass.power + strengthAdd
	
	if thrusterClass.power <= 0 then
		thrusterClass.power = 1
	end
end

function placementLogic(dt)
	if not toolDown then
		return
	end
	
	local newThruster = createThrusterAtLookPos()
	
	if newThruster == nil then
		return
	end
	
	activeThrusters[#activeThrusters + 1] = newThruster
end

-- Object handlers

function allThrustersHandler(dt)
	for i = 1, #activeThrusters do
		local currentThruster = activeThrusters[i]
		
		if currentThruster ~= nil then
			local currForwardKey = currentThruster.keyForward
			local currBackwardKey = currentThruster.keyBackward
			
			if InputDown(currForwardKey) then
				if currentThruster.toggle and InputPressed(currForwardKey) then
					if currentThruster.toggleInvert and currentThruster.toggledOn then
						currentThruster.toggleInvert = false
					else
						currentThruster.toggleInvert = false
						currentThruster.toggledOn = not currentThruster.toggledOn
					end
				else
					fireThruster(currentThruster, false)
				end
			elseif InputDown(currBackwardKey) then
				if currentThruster.toggle and InputPressed(currBackwardKey)  then
					if not currentThruster.toggleInvert and currentThruster.toggledOn then
						currentThruster.toggleInvert = true
					else
						currentThruster.toggleInvert = true
						currentThruster.toggledOn = not currentThruster.toggledOn
					end
				else
					fireThruster(currentThruster, true)
				end
			end
		
			if currentThruster.toggle and currentThruster.toggledOn then
				fireThruster(currentThruster, currentThruster.toggleInvert)
			end
			
			drawThrusterSprite(currentThruster)
	
			thrusterSoundHandler(dt, currentThruster)
		end
	end
end

-- UI Functions (excludes sound specific functions)

function drawUI(dt)
	if debugConsoleNeeded then
		return
	end

	if (#activeThrusters <= 0 and GetString("game.player.tool") ~= "nlthrustertool") or isMenuOpen() then
		return
	end
	
	local infoText = ""--"\n" .. binds["Fire_All_Thrusters_Forwards"]:upper()  .. ": Forwards\n" .. binds["Fire_All_Thrusters_Backwards"]:upper() .. ": Backwards"
	
	local activeToolText = "\nKeys can now be rebound in menu!\n" ..
	"New Thruster Strength: " .. thrusterClass.power .. "\n" .. 
	"New Thruster Forwards Key: " .. binds["New_Thrusters_Forwards_Key"]:upper() .. "\n" .. 
	"New Thruster Backwards Key: " .. binds["New_Thrusters_Backwards_Key"]:upper() .. "\n\n" .. 
	"Following keys only while tool active:\n" .. 
	binds["Delete_All_Thrusters"]:upper() .. ": Erase all thrusters\n" .. 
	binds["Delete_Last_Thruster"]:upper() .. ":Erase last thruster\n" .. 
	binds["New_Thruster_Power_Up"]:upper() .. ": Increase new thruster strength\n" .. 
	binds["New_Thruster_Power_Down"]:upper() .. ": Decrease new thruster strength\n" ..
	binds["Open_Menu"]:upper() .. ": Open Thruster Menu"
	
	if GetString("game.player.tool") == "nlthrustertool" then
		infoText = infoText .. activeToolText
	end
	
	UiPush()
		UiAlign("left bottom")
		UiTranslate(UiWidth() * 0.01, UiHeight() * 0.95)
		UiFont("regular.ttf", 26)
		UiTextShadow(0, 0, 0, 0.5, 2.0)
		UiText("Active thrusters: " .. #activeThrusters .. infoText)
	UiPop()
end

-- Creation Functions
function createThrusterAtLookPos()
	local direction = UiPixelToWorld(screenCenter.x, screenCenter.y)
	
	local origin = GetCameraTransform().pos
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction, 100)
	
	if hit == false then
		return nil
	end
	
	local shapeBody = GetShapeBody(shape)
	
	local bodyTransform = GetBodyTransform(shapeBody)
	
	local worldSpaceNormal = VecAdd(hitPoint, normal)
	
	local newThruster = deepcopy(thrusterClass)
	
	newThruster.keyForward = binds["New_Thrusters_Forwards_Key"]
	newThruster.keyBackward = binds["New_Thrusters_Backwards_Key"]
	newThruster.parentBody = shapeBody
	newThruster.localPosition = TransformToLocalPoint(bodyTransform, hitPoint)
	newThruster.localNormal = TransformToLocalPoint(bodyTransform, worldSpaceNormal)
	
	return newThruster
end

-- World Sound functions

function thrusterSoundHandler(thruster)

end

-- Action functions
function setParticle()
	ParticleReset()
	
	ParticleTile(5)
	ParticleRadius(0.05, 0.2, "smooth")
	ParticleEmissive(1, 0, "smooth")
end

function particleBlue()
	ParticleColor(0, 1, 1, 0, 0, 0)
end

function particleRed()
	ParticleColor(1, 0.6, 0.2, 0, 0, 0)
end

function fireThruster(thruster, invert)
	local bodyTransform = GetBodyTransform(thruster.parentBody)
	
	local worldPos = TransformToParentPoint(bodyTransform, thruster.localPosition)
	
	local worldSpaceNormal = TransformToParentPoint(bodyTransform, thruster.localNormal)
	
	local normalizedNormal = VecDir(worldPos, worldSpaceNormal)
	
	setParticle()
	
	if invert then
		particleBlue()
	else
		particleRed()
	end
	
	SpawnParticle(VecAdd(worldPos, VecScale(normalizedNormal, 0.1)), VecScale(normalizedNormal, 2.5), 1)
	
	if not IsBodyDynamic(thruster.parentBody) then
		return
	end
	
	local strengthVec = nil
	
	if invert then -- Invert means reverse, an inverted normal is forward. I know its confusing.
		strengthVec = VecScale(normalizedNormal, thruster.power)
		--DrawLine(worldPos, VecAdd(worldPos, normalizedNormal), 0, 0, 1, 1)
	else
		local invertNormal = VecInvert(normalizedNormal)
		strengthVec = VecScale(invertNormal, thruster.power)
		--DrawLine(worldPos, VecAdd(worldPos, normalizedNormal), 1, 0, 0, 1)
	end
	
	ApplyBodyImpulse(thruster.parentBody, worldPos, strengthVec)
end

-- Sprite functions

function drawThrusterSprite(thruster)
	if thruster ~= nil then
		local bodyTransform = GetBodyTransform(thruster.parentBody)
	
		local worldPos = TransformToParentPoint(bodyTransform, thruster.localPosition)
		local worldSpaceNormal = TransformToParentPoint(bodyTransform, thruster.localNormal)
		
		local normalizedNormal = VecDir(worldPos, worldSpaceNormal)
		
		--local vecA = worldPos
		--local vecB = worldSpaceNormal
		
		--local middlePoint = Vec((vecA[1] + vecB[1]) / 2, 0, (vecA[3] + vecB[3]) / 2)
		
		--https://math.stackexchange.com/questions/995659/given-two-points-find-another-point-a-perpendicular-distance-away-from-the-midp
		
		--local quatLookAtTarget = VecAdd(worldPos, lookAtOffset)
		
		--local thrusterTransform = Transform(spritePos, QuatLookAt(spritePos, quatLookAtTarget))
		
		--DrawSprite(thrusterSprite, thrusterTransform, 0.3, 0.25, 1, 1, 1, 1, true, false)
		
		DrawLine(worldPos, VecAdd(worldPos, normalizedNormal))
	end
end

-- UI Sound Functions
