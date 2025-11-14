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
    * Added Money & EXP notifications (MAKE SURE TO GO INTO `StarterGui/MoneyXPRewards`, `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Miscellaneous/ShowRewardNotifications` and `StarterPlayer/StarterPlayerScripts/UI/MoneyXPRewards` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added skippable killer intros (MAKE SURE TO GO INTO `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Miscellaneous/DisableKillerIntros` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Reminder to switch the scale type of the character renders in the player info window to `Crop` for them to show up correctly without caring about image aspect ratios.
    * Added Credits menu (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Credits` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------25/10/2025------
    * Added Multi-Killer support in the same round (do what's said under here)
        * Disable collision between the Killer collision group
        * Add a workspace attribute called "KillersAllowed" and make it have a number value
        * Remember that rounds that start without any survivors and don't have `CanSpawnKiller` set to false will end instantly
    
    ------26/10/2025------
    * Added camera shaking when damaged (MAKE SURE TO GO INTO `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Customization/ScreenShakeEnabled` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added camera desaturation when low on health (MAKE SURE TO GO INTO `ServerScriptService/Managers/SaveManager/PlayerData/Settings/Customization/ScreenDesaturation` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added camera fx when killing someone

    ------29/10/2025------
    * Added spectating (MAKE SURE TO DISABLE `StreamingEnabled` IN `Workspace` OR ELSE THIS WON'T WORK; ALSO MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Spectate` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added a projectile class
    * Added a red vignette when low on health (MAKE SURE TO ENABLE `IgnoreGuiInset` IN `StarterGui/TemporaryUI`)
    * Added custom LMS voicelines depending on the last man standing's character AND skin
    * Added custom kill voicelines depending on the killed player's character AND skin

    ------31/10/2025------
    * Added stun protection (MAKE SURE TO GO INTO `ServerScriptService/Managers/PlayerManager` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    
    ------05/11/2025------
    * Added original sidebar icons & remade some code for them (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Sidebar` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------06/11/2025------
    * Added new sidebar labels and inverted icon support (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Sidebar` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------08/11/2025------
    * Added `More Info` to Shop and Inventory (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Shop` & `StarterPlayer/StarterPlayerScripts/UI/Inventory` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------12/11/2025------
    * Added effect tooltips when checking a `More Info` page (MAKE SURE TO GO INTO `ReplicatedStorage/Classes/Tooltip` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

    ------14/11/2025------
    * Added game changelog (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Changelog`, `ServerScriptService/Managers/SaveManager/PlayerData/Misc/LastSeenLog` & `ReplicatedStorage/PlaceVersion` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added rules menu (TBF) (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/Rules` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)
    * Added smaller sidebar icons (MAKE SURE TO GO INTO `StarterPlayer/StarterPlayerScripts/UI/SideBar` IN THE EXAMPLE PLACE TO GRAB WHAT YOU NEED FOR IT TO WORK)

]]

script:Destroy()