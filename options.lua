#include "scripts/savedata.lua"
#include "scripts/textbox.lua"
#include "scripts/ui.lua"

local modname = "Thruster Tool"

function init()
	saveFileInit()
end

function draw()
	UiPush()
		UiTranslate(UiWidth(), UiHeight())
		UiTranslate(-50, 3 * -50)
		UiAlign("right bottom")
	
		UiFont("regular.ttf", 26)
		
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		
		if UiTextButton("Reset to default", 200, 50) then
			drawThrusterSpriteActive = true
		end
		
		UiTranslate(0, 60)
		
		if UiTextButton("Save and exit", 200, 50) then
			SetBool(moddataPrefix .. "OldThrusterStyle", drawThrusterSpriteActive)
			Menu()
		end
		
		UiTranslate(0, 60)
		
		if UiTextButton("Cancel", 200, 50) then
			Menu()
		end
	UiPop()
	
	UiPush()
		UiWordWrap(400)
	
		UiTranslate(UiCenter(), 50)
		UiAlign("center middle")
	
		UiFont("bold.ttf", 48)
		UiTranslate(0, 50)
		UiText(modname)
	
		UiTranslate(0, 100)
		
		UiFont("regular.ttf", 26)
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		
		drawToggle("New thruster style: ", drawThrusterSpriteActive, function (i) drawThrusterSpriteActive = i end)
		
	UiPop()
end

function tick()
	textboxClass_tick()
end