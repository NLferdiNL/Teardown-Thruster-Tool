#include "datascripts/inputList.lua"
#include "datascripts/color4.lua"
#include "scripts/ui.lua"
#include "scripts/textbox.lua"
#include "scripts/utils.lua"

binds = {
	New_Thrusters_Forwards_Key = "h", 
	New_Thrusters_Backwards_Key = "n", 
	Delete_All_Thrusters = "p", 
	Delete_Last_Thruster = "z",
	New_Thruster_Power_Up = "+",
	New_Thruster_Power_Down = "-",
	New_Thruster_Toggle = "g",
	Open_Menu = "m", -- Only one that can't be changed!
}

local bindBackup = deepcopy(binds)

local bindOrder = {
	"New_Thrusters_Forwards_Key", 
	"New_Thrusters_Backwards_Key", 
	"New_Thruster_Power_Up",
	"New_Thruster_Power_Down",
	"New_Thruster_Toggle",
	"Delete_All_Thrusters", 
	"Delete_Last_Thruster",
}
		
local bindNames = {
	New_Thrusters_Forwards_Key = "New Thrusters Forwards Key", 
	New_Thrusters_Backwards_Key = "New Thrusters Backwards Key", 
	Delete_All_Thrusters = "Delete All Thrusters", 
	Delete_Last_Thruster = "Delete Last Thruster",
	New_Thruster_Power_Up = "New Thruster Power Up",
	New_Thruster_Power_Down = "New Thruster Power Down",
	New_Thruster_Toggle = "New Thruster Toggle",
	Open_Menu = "Open Menu",
}

local menuOpened = false
local rebinding = nil

local erasingBinds = 0

local menuWidth = 0.25
local menuHeight = 0.6

local powerTextBox = nil

local changelogText = "Keys can now be rebound.\n" ..
					  "(Currently not saved cross session.)\n\n" ..
					  "Made editing thruster power easier using this menu.\n" ..
					  "Old plus and minus buttons will remain an option too.\n\n"..
					  "Fix textboxes breaking the mod."

function menu_init()
	
end

function menu_tick(dt)
	if InputPressed(binds["Open_Menu"]) and GetString("game.player.tool") == "nlthrustertool" then
		menuOpened = not menuOpened
		
		if not menuOpened then
			rebinding = nil
			erasingBinds = 0
			thrusterClass.power = tonumber(powerTextBox.value)
		end
	end
	
	if rebinding ~= nil then
		local lastKeyPressed = getKeyPressed()
		
		if lastKeyPressed ~= nil then
			binds[rebinding] = lastKeyPressed
			rebinding = nil
		end
	end
	
	textboxClass_tick()
	
	if erasingBinds > 0 then
		erasingBinds = erasingBinds - dt
	end
end

function menu_draw(dt)
	local textBox01, newBox01 = textboxClass_getTextBox(1)

	if newBox01 then
		textBox01.name = "New Thruster Strength"
		textBox01.value = thrusterClass.power .. ""
		textBox01.numbersOnly = true
		textBox01.limitsActive = true
		textBox01.numberMin = 1
		textBox01.numberMax = 10000000
		
		powerTextBox = textBox01
	end
	
	if powerTextBox == nil and textBox01 ~= nil then
		powerTextBox = textBox01
	end

	if not isMenuOpen() then
		return
	end
	
	UiMakeInteractive()
	
	if changelogActive then
		UiPush()
			UiBlur(0.75)
			UiAlign("left top")
			
			UiTranslate(UiWidth() * 0.01, UiWidth() * 0.01)
			UiImageBox("ui/hud/infobox.png", UiWidth() * 0.15, UiHeight() * 0.4, 10, 10)
			
			UiWordWrap(UiWidth() * 0.15)
			
			UiFont("bold.ttf", 30)
			
			UiTranslate(0, 10)
			
			UiText("Thruster Changelog:")
			
			UiFont("regular.ttf", 26)
			
			UiTranslate(0, 50)
			
			UiText(changelogText)
		UiPop()
	end
	
	UiPush()
		if not changelogActive then
			UiBlur(0.75)
		end
		
		UiAlign("center middle")
		UiTranslate(UiWidth() * 0.5, UiHeight() * 0.5)
		UiImageBox("ui/hud/infobox.png", UiWidth() * menuWidth, UiHeight() * menuHeight, 10, 10)
		
		UiWordWrap(UiWidth() * menuWidth)
		
		UiTranslate(0, -UiHeight() * menuWidth)
		
		UiFont("bold.ttf", 48)
		
		UiTranslate(0, 10)
		
		UiText("Thruster Settings")
		
		UiFont("regular.ttf", 26)
	
		UiPush()
			UiTranslate(-UiWidth() * (menuWidth / 2), 50)
			for i = 1, #bindOrder do
				local id = bindOrder[i]
				local key = binds[id]
				drawRebindable(id, key)
				UiTranslate(0, 50)
			end
		UiPop()
		
		UiTranslate(0, 50 * (#bindOrder + 1))
		
		UiPush()
			UiTranslate(100, 0)
			textboxClass_render(textBox01)
		UiPop()
		
		UiTranslate(0, 50)
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			local statusText = "Disabled"
			
			if thrusterClass.toggle then
				statusText = "Enabled"
			end
			
			if UiTextButton("New Thrusters Toggle: " .. statusText , 400, 40) then
				thrusterClass.toggle = not thrusterClass.toggle
			end
			
			UiTranslate(0, 50)
			
			if erasingBinds > 0 then
				UiPush()
				c_UiColor(Color4.Red)
				if UiTextButton("Are you sure?" , 400, 40) then
					binds = deepcopy(bindBackup)
					erasingBinds = 0
				end
				UiPop()
			else
				if UiTextButton("Reset binds to defaults" , 400, 40) then
					erasingBinds = 5
				end
			end
			
			UiTranslate(-105, 50)
			
			if UiTextButton("Close" , 195, 40) then
				menuOpened = false
				rebinding = nil
			end
			
			UiTranslate(210, 0)
			
			local showText = "Show"
			
			if changelogActive then
				showText = "Hide"
			end
			
			if UiTextButton(showText .. " changelog" , 195, 40) then
				changelogActive = not changelogActive
			end
		UiPop()
	UiPop()
end

function drawRebindable(id, key)
	UiPush()
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	
		UiTranslate(UiWidth() * menuWidth / 1.5, 0)
	
		UiAlign("right middle")
		UiText(bindNames[id] .. "")
		
		UiTranslate(UiWidth() * menuWidth * 0.1, 0)
		
		UiAlign("left middle")
		
		if rebinding == id then
			c_UiColor(Color4.Green)
		else
			c_UiColor(Color4.Yellow)
		end
		
		if UiTextButton(key, 40, 40) then
			rebinding = id
		end
	UiPop()
end

function isMenuOpen()
	return menuOpened
end

function setMenuOpen(val)
	menuOpened = val
end