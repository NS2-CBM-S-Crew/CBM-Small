heatAmountleft = 0
idleHeatAmountleft = 0
shieldStatusleft = "off"

function Update(dt)
    UpdateOverHeat(dt, heatAmountleft, idleHeatAmountleft, shieldStatusleft)
end

Script.Load("lua/CommunityBalanceMod/ModularExos/GUI/GUIShield.lua")