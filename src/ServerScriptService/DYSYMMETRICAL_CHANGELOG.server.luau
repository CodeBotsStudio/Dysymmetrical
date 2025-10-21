--[[

    ------01/10/2025------
    * Added the shop (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Shop` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added reward notifications (e.g. when buying a character or getting a character from an achievement) (MAKE SURE TO GO INTO `StarterGui` AND `StarterPlayerScritps/UI/Shop` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------06/10/2025------
    * Added spectator & ragdoll collision group (MAKE SURE TO GO INTO `Collision Groups` IN `Window -> 3D -> Collision Groups` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------08/10/2025------
    * Added shift lock fixes and execution animations (MAKE SURE TO GO INTO `StarterPlayerScripts/PlayerModule/CameraModule` AND REPLACE YOUR `SmoothShiftLock` WITH THE ONE IN THE EXAMPLE PLACE CURRENTLY)
    * Rearranged SFX in character configs (check the diff)

    ------09/10/2025------
    * Added Round Player List (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/RoundPlayerList` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    
    ------16/10/2025------
    * Refactored TerrorRadius to not be a util and be embedded to each character instead
    * Added TopbarPlus for the mod panel

    ------18/10/2025------
    * Added Emote WHEEL using trigonometry that I despise (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/EmotePanel` & `ServerScriptService/Managers/SaveManager/PlayerData/Equipped/Emotes` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------19/10/2025------
    * Added Emote purchasing and equipping (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Inventory` & `StarterPlayer/StarterPlayerScripts/UI/Shop` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added some loading screen stuff (MAKE SURE TO GO INTO `ReplicatedFirst/Loading` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------20/10/2025------
    * Added Player list UI (MAKE SURE TO GO INTO `StarterGui/PlayerList`, `StarterPlayer/StarterPlayerScripts/UI/PlayerList` & `StarterPlayer/StarterPlayerScripts/UI/PlayerList/PlayerInfoWindow` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added Hide Money option (MAKE SURE TO GO INTO `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Privacy/HideMoney` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------21/10/2025------
    * Added Money & EXP notifications (MAKE SURE TO GO INTO `StarterGui/MoneyXPRewards` and `StarterPlayer/StarterPlayerScripts/UI/MoneyXPRewards` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added skippable killer intros (MAKE SURE TO GO INTO `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Miscellaneous/DisableKillerIntros` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
]]

script:Destroy()