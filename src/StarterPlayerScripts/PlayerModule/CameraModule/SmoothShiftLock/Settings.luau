return {
	["CHARACTER_SMOOTH_ROTATION"]   = true,                       --// If your character should rotate smoothly or not
	["CHARACTER_ROTATION_SPEED"]    = 3,                          --// How quickly character rotates smoothly
	["OFFSET_TRANSITION_DAMPER"]    = 0.75,                        --// Camera transition spring damper, test it out to see what works for you
	["OFFSET_TRANSITION_IN_SPEED"]  = 15,                         --// How quickly locked camera moves to offset position
	["OFFSET_TRANSITION_OUT_SPEED"] = 25,                         --// How quickly locked camera moves back from offset position
	["LOCKED_CAMERA_OFFSET"]        = Vector3.new(1.75, 0.5, 0), --// Locked camera offset
	["LOCKED_MOUSE_ICON"]           =                             --// Locked mouse icon
		"rbxasset://textures/MouseLockedCursor.png",
	-- ["SHIFT_LOCK_KEYBINDS"]         =                             --// Shift lock keybinds
	-- 	{ Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl }
}
