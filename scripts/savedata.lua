moddataPrefix = "savegame.mod.thrustertool"

function saveFileInit()
	saveVersion = GetInt(moddataPrefix .. "Version")
	drawThrusterSpriteActive = GetBool(moddataPrefix .. "OldThrusterStyle")
	
	if saveVersion < 1 or saveVersion == nil then
		saveVersion = 1
		SetInt(moddataPrefix .. "Version", saveVersion)
	end
	
	if saveVersion < 2 then
		saveVersion = 2
		SetInt(moddataPrefix .. "Version", saveVersion)
		
		changelogActive = true
	end
	
	if saveVersion < 3 then
		saveVersion = 3
		SetInt(moddataPrefix .. "Version", saveVersion)
		
		drawThrusterSpriteActive = true
		SetBool(moddataPrefix .. "OldThrusterStyle", drawThrusterSpriteActive)
	end
end