local modVersion = "1.0.0"
local modName = "Community Balance Mod - Small"

if g_communityBalanceModConfig then
    Print("ERROR: You are not allowed to use this mod with the Community Balance Mod!")
    Print("Please remove the Community Balance Mod is you want to use the small version.")
    return
end

-- This is a small version of the Community Balance Mod, which is a mod that aims to balance the game by adjusting various parameters and settings.
Print("Loading CBS as base mod...")
Script.Load("lua/CommunityBalanceMod/FileHooks.lua")

--Clear the CBS global variable
--g_communityBalanceModConfig = nil

-- Load the extra settings for small mod
ModLoader.SetupFileHook("lua/Balance.lua", "lua/CommunityBalanceMod-Small/Balance.lua", "post")
ModLoader.SetupFileHook("lua/Globals.lua", "lua/CommunityBalanceMod-Small/Globals.lua", "post")
