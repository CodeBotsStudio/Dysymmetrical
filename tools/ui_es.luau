local map = {
	["AFK mode is on. You won't be put in new matches while it's on. It can be turned off from the top of the settings menu."] = "El modo AFK está activado. No entrarás en partidas nuevas mientras siga así. Se quita arriba del todo en Ajustes.",
	["Achievement granted!"] = "¡Logro conseguido!",
	["Achievements"] = "Logros",
	["Achievements (0/0 Unlocked)"] = "Logros (0/0 desbloqueados)",
	["Cancel"] = "Cancelar",
	["Category"] = "Categoría",
	["Changelog"] = "Novedades",
	["Character"] = "Personaje",
	["Command Panel"] = "Panel de comandos",
	["Credits"] = "Créditos",
	["Current value: false"] = "Valor actual: false",
	["DEAD"] = "MUERTO",
	["Emote"] = "Gesto",
	["Emotes"] = "Gestos",
	["Equip"] = "Equipar",
	["Granted 0$ and 0 EXP for something."] = "Has ganado 0$ y 0 EXP por algo.",
	["Initializing"] = "Iniciando",
	["Killer Wins"] = "Victorias de asesino",
	["Killers"] = "Asesinos",
	["Money"] = "Dinero",
	["More Info"] = "Más información",
	["Owned"] = "Tuyo",
	["Purchase"] = "Comprar",
	["Reward: ???????????"] = "Recompensa: ???????????",
	["Round begins in..."] = "La ronda empieza en...",
	["Rules"] = "Normas",
	["Section"] = "Sección",
	["Skins"] = "Aspectos",
	["Survivor Wins"] = "Victorias de superviviente",
	["Survivors"] = "Supervivientes",
	["The killer is..."] = "El asesino es...",
	["Time Played"] = "Tiempo jugado",
	["Toggle"] = "Cambiar",
	["Unequip"] = "Quitar",
	["Using:"] = "Usando:",
	["X Skins"] = "X aspectos",
	["you won a match yayyy"] = "¡has ganado una partida!",
}
local n = 0
for _, root in { game.StarterGui, game.ReplicatedStorage, game.StarterPlayer } do
	for _, d in root:GetDescendants() do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local es = map[(d.Text:gsub("%c", " "))]
			if es then
				d.Text = es
				n += 1
			end
		end
	end
end
return n .. " textos traducidos"
