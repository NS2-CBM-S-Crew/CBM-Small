-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ConsoleCommands_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- NS2 Gamerules specific console commands.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")

local gLastPosition

local function JoinTeam(player, teamIndex)

    if player and player:GetTeamNumber() == kTeamReadyRoom then

        if Shared.GetThunderdomeEnabled() then
            Server.Broadcast(player, "Manually joining teams is disabled during Matched Play")
            return
        end

        return GetGamerules():JoinTeam(player, teamIndex)
        
    end
    
    return false
    
end

local function JoinTeamOne(player)
    return JoinTeam(player, kTeam1Index)
end

local function JoinTeamTwo(player)
    return JoinTeam(player, kTeam2Index)
end

local function JoinTeamRandom(player)
    --Note: this just calls into TeamJoin.lua and ends up back here in JoinTeam()
    return JoinRandomTeam(player)
end

local function ReadyRoom(player)

    if player and not player:isa("ReadyRoomPlayer") then

        if Shared.GetThunderdomeEnabled() then
            Server.Broadcast(player, "Manually joining teams is disabled during Matched Play")
            return
        end

        return GetGamerules():JoinTeam(player, kTeamReadyRoom)
        
    end
    
end

local function Spectate(player)
    if Shared.GetThunderdomeEnabled() then
        Server.Broadcast(player, "Manually joining teams is disabled during Matched Play")
        return
    end

    return GetGamerules():JoinTeam(player, kSpectatorIndex)
end

local function OnCommandJoinTeamOne(client)

    local player = client:GetControllingPlayer()
    JoinTeamOne(player)
    
end

local function OnCommandJoinTeamTwo(client)

    local player = client:GetControllingPlayer()
    JoinTeamTwo(player)
    
end

local function OnCommandJoinTeamRandom(client)

    local player = client:GetControllingPlayer()
    JoinTeamRandom(player)
    
end

local function OnCommandReadyRoom(client)

    local player = client:GetControllingPlayer()
    ReadyRoom(player)
    
end

local function OnCommandSpectate(client)

    local player = client:GetControllingPlayer()
    Spectate(player)
    
end

local function OnCommandFilm(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() or Shared.GetDevMode() and not Shared.GetThunderdomeEnabled() then

        Shared.Message("Film mode enabled. Hold crouch for dolly, movement modifier for speed or attack to orbit then press movement keys.")

        local success, newPlayer = Spectate(player)
        
        -- Transform class into FilmSpectator
        newPlayer:Replace(FilmSpectator.kMapName, newPlayer:GetTeamNumber(), false)
        
    end
    
end

--
-- Forces the game to end for testing purposes
--
local function OnCommandEndGame(client)

    local player = client:GetControllingPlayer()

    if Shared.GetCheatsEnabled() and GetGamerules():GetGameStarted() then
        GetGamerules():EndGame(player:GetTeam())
    end
    
end

local function OnCommandTeamResources(client, value)

    value = value and tonumber(value) or kMaxTeamResources
    
    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:GetTeam():SetTeamResources(value)
    end
    
end

local function OnCommandResources(client, value)
    
    value = value and tonumber(value) or kMaxPersonalResources

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:SetResources(value)
    end
    
end

local function OnCommandAutobuild(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetAutobuild(not GetGamerules():GetAutobuild())
        Print("Autobuild now %s", ToString(GetGamerules():GetAutobuild()))
        
        -- Now build any existing structures that aren't built
        for index, constructable in ipairs(GetEntitiesWithMixin("Construct")) do
        
            if not constructable:GetIsBuilt() then
                constructable:SetConstructionComplete()
            end
            
        end
        
    end
    
end

local function OnCommandEnergy(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        -- Give energy to all structures on our team.
        for index, ent in ipairs(GetEntitiesWithMixinForTeam("Energy", player:GetTeamNumber())) do
            ent:SetEnergy(ent:GetMaxEnergy())
        end
        
    end
    
end

local function OnCommandMature(client)

    if Shared.GetCheatsEnabled() then
    
        -- Give energy to all structures on our team.
        for index, ent in ipairs(GetEntitiesWithMixin("Maturity")) do
            ent:SetMature()
        end
        
    end
    
end


local function OnCommandTakeDamage(client, amount, optionalEntId)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        local damage = tonumber(amount)
        if damage == nil then
            damage = 20 + math.random() * 10
        end
        
        local damageEntity
        optionalEntId = optionalEntId and tonumber(optionalEntId)
        if optionalEntId then
            damageEntity = Shared.GetEntity(optionalEntId)
        else
        
            damageEntity = player
            if player:isa("Commander") then
            
                -- Find command structure we're in and do damage to that instead.
                local commandStructures = Shared.GetEntitiesWithClassname("CommandStructure")
                for index, commandStructure in ientitylist(commandStructures) do
                
                    local comm = commandStructure:GetCommander()
                    if comm and comm:GetId() == player:GetId() then
                    
                        damageEntity = commandStructure
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
        if not damageEntity:GetCanTakeDamage() then
            damage = 0
        end
        
        Print("Doing %.2f damage to %s", damage, damageEntity:GetClassName())
        damageEntity:DeductHealth(damage, player, player)
        
    end
    
end

local function OnCommandSetArmorPercent(client, amount)

    if Shared.GetCheatsEnabled() then
        
        local player = client:GetControllingPlayer()
        if player then
            player:SetArmor(player:GetMaxArmor() * amount)
        end
        
    end
    
end

local function OnCommandHeal(client, amount)

    if Shared.GetCheatsEnabled() then
    
        amount = amount and tonumber(amount) or 10
        local player = client:GetControllingPlayer()
        player:AddHealth(amount)
        
    end
    
end

local function OnCommandGiveAmmo(client)

    if client ~= nil and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        local weapon = player:GetActiveWeapon()

        if weapon ~= nil and weapon:isa("ClipWeapon") then
            weapon:GiveAmmo(1)
        end
    
    end
    
end


local function OnCommandNanoShield(client)

    if client ~= nil and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        
        if HasMixin(player, "NanoShieldAble") then
            player:ActivateNanoShield()
        end
        
    end
    
end

local function OnCommandBlight(client, duration)

    if client ~= nil and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()

        if HasMixin(player, "BlightAble") then

            if player:GetIsBlighted() and duration == nil then
                player:RemoveBlight()
            else
                player:SetBlighted( tonumber(duration) )
            end
        else
            Shared.Message("Player is not blightable!")
        end

    end
end

local function OnCommandParasite(client, duration)

    if client ~= nil and Shared.GetCheatsEnabled() then
        
        local player = client:GetControllingPlayer()
        
        if HasMixin(player, "ParasiteAble") then
            
            if player:GetIsParasited() and duration == nil then
                player:RemoveParasite()
            else
                player:SetParasited( nil, tonumber(duration) )
            end    
                
        end
        
    end
    
end


local function OnCommandEnts(client, className)

    -- Allow it to be run on dedicated server
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetTestEnabled() then
    
        local entityCount = Shared.GetEntitiesWithClassname("Entity"):GetSize()
        
        local weaponCount = Shared.GetEntitiesWithClassname("Weapon"):GetSize()
        local playerCount = Shared.GetEntitiesWithClassname("Player"):GetSize()
        local structureCount = #GetEntitiesWithMixin("Construct")
        local team1 = GetGamerules():GetTeam1()
        local team2 = GetGamerules():GetTeam2()
        local playersOnPlayingTeams = team1:GetNumPlayers() + team2:GetNumPlayers()
        local commandStationsOnTeams = team1:GetNumCommandStructures() + team2:GetNumCommandStructures()
        local blipCount = Shared.GetEntitiesWithClassname("Blip"):GetSize()
        local infestCount = Shared.GetEntitiesWithClassname("Infestation"):GetSize()

        if className then
            local numClassEnts = Shared.GetEntitiesWithClassname(className):GetSize()
            Shared.Message(Pluralize(numClassEnts, className))
        else
        
            local formatString = "%d entities (%s, %d playing, %s, %s, %s, %s, %d command structures on teams)."
            Shared.Message( string.format(formatString, 
                            entityCount, 
                            Pluralize(playerCount, "player"), playersOnPlayingTeams, 
                            Pluralize(weaponCount, "weapon"), 
                            Pluralize(structureCount, "structure"), 
                            Pluralize(blipCount, "blip"), 
                            Pluralize(infestCount, "infest"), 
                            commandStationsOnTeams))
        end
    end
    
end

local function OnCommandServerEntities(client, entityType)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetTestEnabled() then
        DumpEntityCounts(entityType)
    end
    
end

local function OnCommandEntityInfo(client, entityId)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetTestEnabled() then
    
        local ent = Shared.GetEntity(tonumber(entityId))
        if not ent then
        
            Shared.Message("No entity matching Id: " .. entityId)
            return
            
        end
        
        local entInfo = GetEntityInfo(ent)
        Shared.Message(entInfo)
        
    end
    
end

local function OnCommandServerEntInfo(client, entityId)

    if client == nil or Shared.GetCheatsEnabled() then
    end
    
end

local function OnCommandDamage(client,multiplier)

    if(Shared.GetCheatsEnabled()) then
        local m = multiplier and tonumber(multiplier) or 1
        GetGamerules():SetDamageMultiplier(m)
        Shared.Message("Damage multipler set to " .. m)
    end
    
end

local function OnCommandHighDamage(client)

    if Shared.GetCheatsEnabled() and GetGamerules():GetDamageMultiplier() < 10 then
    
        GetGamerules():SetDamageMultiplier(10)
        Print("highdamage on (10x damage)")
        
    -- Toggle off
    elseif not Shared.GetCheatsEnabled() or GetGamerules():GetDamageMultiplier() > 1 then
    
        GetGamerules():SetDamageMultiplier(1)
        Print("highdamage off")
        
    end
    
end

local function OnCommandGive(client, itemName)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and itemName ~= nil and itemName ~= "alien") then
        local newItem = player:GiveItem(itemName, nil, true)
        if newItem and newItem.UpdateWeaponSkins then
            newItem:UpdateWeaponSkins( client )
        end
        --player:SetActiveWeapon(itemName)
    end
    
end

local function OnCommandSpawn(client, itemName, teamnum, useLastPos)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and itemName ~= nil and itemName ~= "alien") then
    
        -- trace along players zAxis and spawn the item there
        local startPoint = player:GetEyePos()
        local endPoint = startPoint + player:GetViewCoords().zAxis * 100
        local usePos

        if not teamnum then
            teamnum = player:GetTeamNumber()
        else
            teamnum = tonumber(teamnum)
        end
        
        if useLastPos and gLastPosition then
            usePos = gLastPosition
        else    
        
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            usePos = trace.endPoint
        
        end

        local newItem = CreateEntity(itemName, usePos, teamnum)

        Print("spawned \""..itemName.."\" at Vector("..usePos.x..", "..usePos.y..", "..usePos.z..")")
        
    end
    
end

local function OnCommandSpawnHere(client, itemName, teamnum, useLastPos)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and itemName ~= nil and itemName ~= "alien") then

        local playerPos = player:GetOrigin()
        -- trace along players zAxis and spawn the item there
        local startPoint = player:GetEyePos()
        local endPoint = playerPos + player:GetViewCoords().zAxis

        if not teamnum then
            teamnum = player:GetTeamNumber()
        else
            teamnum = tonumber(teamnum)
        end

        local newItem = CreateEntity(itemName, endPoint, teamnum)

        Print("spawned \""..itemName.."\" at Vector("..endPoint.x..", "..endPoint.y..", "..endPoint.z..")")

    end

end

local function OnCommandTrace(client)

    local player = client:GetControllingPlayer()
    
    -- trace along players zAxis and spawn the item there
    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
    local hitPos = trace.endPoint
    
    Print("Surface: " .. ToString(trace.surface))
    Print("Vector("..hitPos.x..", "..hitPos.y..", "..hitPos.z.."),")
    
end

local function OnCommandShoot(client, projectileName, velocity)

    local player = client:GetControllingPlayer()
    if Shared.GetCheatsEnabled() and projectileName ~= nil then    
    
        velocity = velocity or 15
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
        startPoint = startPointTrace.endPoint
        
        local startVelocity = viewCoords.zAxis * velocity
        
        local projectile = CreateEntity(projectileName, startPoint, player:GetTeamNumber())
        projectile:Setup(player, startVelocity, true, nil, player)    
    
    end

end

local function OnCommandGiveUpgrade(client, techIdString)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        
        if techId ~= nil then
        
            local player = client:GetControllingPlayer()
        
            if not player:GetTechTree():GiveUpgrade(techId) then
            
                if not player:GiveUpgrade(techId) then
                    Print("Error: GiveUpgrade(%s) not researched and not an upgraded", EnumToString(kTechId, techId))
                end
                
            end
            
        else
            Shared.Message("Error: " .. techIdString .. " does not match any Tech Id")
        end
        
    end
    
end

local function OnCommandLogout(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() and GetCommanderLogoutAllowed() then
    
        player:Logout()
    
    end

end

local function OnCommandGotoIdleWorker(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoIdleWorker()
    end
    
end

local function OnCommandGotoPlayerAlert(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoPlayerAlert()
    end
    
end

local function OnCommandSelectAllPlayers(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllPlayers then
        player:SelectAllPlayers()
    end
    
end

local function OnCommandSetFOV(client, fovValue)

    local player = client:GetControllingPlayer()
    if Shared.GetDevMode() then
        player:SetFov(tonumber(fovValue))
    end
    
end

-- Todo: Refactor this mess
local function OnCommandChangeClass(className, teamNumber, extraValues)

    return function(client)
    
        local player = client:GetControllingPlayer()
        
        -- Don't allow to use these commands if you're in the RR
        if player:GetTeamNumber() == kTeam1Index or player:GetTeamNumber() == kTeam2Index then
        
            -- Switch teams if necessary
            if player:GetTeamNumber() ~= teamNumber then
                if Shared.GetCheatsEnabled() and not player:GetIsCommander() then
                
                    -- Remember position and team for calling player for debugging
                    local playerOrigin = player:GetOrigin()
                    local playerViewAngles = player:GetViewAngles()
                    
                    local newTeamNumber = kTeam1Index
                    if player:GetTeamNumber() == kTeam1Index then
                        newTeamNumber = kTeam2Index
                    end
                    
                    local success, newPlayer = GetGamerules():JoinTeam(player, kTeamReadyRoom)
                    success, newPlayer = GetGamerules():JoinTeam(newPlayer, newTeamNumber)
                    
                    newPlayer:SetOrigin(playerOrigin)
                    newPlayer:SetViewAngles(playerViewAngles)
                    
                    player = client:GetControllingPlayer()
                                    
                end
            end
            
            -- Respawn shenanigans
            if Shared.GetCheatsEnabled() then
                local newPlayer = player:Replace(className, player:GetTeamNumber(), nil, nil, extraValues)
                
                -- Always disable 3rd person
                newPlayer:SetDesiredCameraDistance(0)

                -- Turns out if you give weapons to exos the game implodes! Who would've thought!
                if teamNumber == kTeam1Index and (className == "marine" or className == "jetpackmarine") and newPlayer.lastWeaponList then
                    -- Restore weapons in reverse order so the main weapons gets selected on respawn
                    for i = #newPlayer.lastWeaponList, 1, -1 do
                        if newPlayer.lastWeaponList[i] ~= "axe" then
                            newPlayer:GiveItem(newPlayer.lastWeaponList[i])
                        end
                    end
                end
                
                if teamNumber == kTeam2Index and newPlayer.lastUpgradeList then            
                    -- I have no idea if this will break, but I don't care!
                    -- Thug life!
                    -- Ghetto code incoming, you've been warned
                    local upgrades = newPlayer.lastUpgradeList[className] or newPlayer.lastUpgradeList["Skulk"] or {}
                    newPlayer.upgrade1 = upgrades[1] or 1
                    newPlayer.upgrade2 = upgrades[2] or 1
                    newPlayer.upgrade3 = upgrades[3] or 1
                end
                
            end
            
        end
        
    end
    
end

local function OnCommandRespawn(client)

    local player = client:GetControllingPlayer()

    if player.lastClass and player.lastDeathPos and (player:GetTeamNumber() == kTeam1Index or player:GetTeamNumber() == kTeam2Index) and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        local teamNumber = kTeam2Index
        local extraValues

        if player.lastClass == "exo" or player.lastClass == "marine" or player.lastClass == "jetpackmarine" then
            teamNumber = kTeam1Index
            
            if player.lastClass == "exo" then
                extraValues = player.lastExoLayout
            end
        end
        
        local func = OnCommandChangeClass(player.lastClass, teamNumber, extraValues)
        
        func(client)
        
        player = client:GetControllingPlayer()
        player:SetOrigin(player.lastDeathPos)
    end
    
end

local function OnCommandRespawnClear(client)

    local player = client:GetControllingPlayer()
    
    player.lastDeathPos = nil
    player.lastWeaponList = nil
    player.lastClass = nil
    player.lastExoLayout = nil
    
end

-- Switch player from one team to the other, while staying in the same place
local function OnCommandSwitch(client)

    if Shared.GetThunderdomeEnabled() then
        --TODO Add message back to client, notifying this is disabled
        return
    end

    local func
    local player = client:GetControllingPlayer()
    local teamNumber = player:GetTeamNumber()
    
    -- For some reason the player team is swapped here, maybe the old function has been run first?
    if teamNumber == kTeam1Index then
        func = OnCommandChangeClass("skulk", kTeam2Index)
    elseif teamNumber == kTeam2Index then
        func = OnCommandChangeClass("marine", kTeam1Index)
    end
    
    if func ~= nil then
        func(client)
    end
        
    player:SetDesiredCameraDistance(0)
    
end

local function OnCommandSandbox(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then

        MarineTeam.gSandboxMode = not MarineTeam.gSandboxMode
        Print("Setting sandbox mode %s", ConditionalValue(MarineTeam.gSandboxMode, "on", "off"))
        
    end

end

local function OnCommandCommand(client)

    if Shared.GetThunderdomeEnabled() then
        return
    end

    local player = client:GetControllingPlayer()
    if Shared.GetCheatsEnabled() then
    
        local hasComm = player:GetTeam():GetCommander()
        if hasComm then
            return
        end

        -- Find hive/command station on our team and use it
        local ents = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if #ents > 0 then
        
            player:SetOrigin(ents[1]:GetOrigin() + Vector(0, 1, 0))
            player:UseTarget(ents[1], 0)
            ents[1]:UpdateCommanderLogin(true)
            
        end
        
    end
    
end

local function OnCommandCatPack(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and HasMixin(player,"CatPack")) then
        player:ApplyCatPack()
    end
end

local function OnCommandAllTech(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        local newAllTechState = not GetGamerules():GetAllTech()
        GetGamerules():SetAllTech(newAllTechState)
        Print("Setting alltech cheat %s", ConditionalValue(newAllTechState, "on", "off"))
        
    end
    
end

local function OnCommandFastEvolve(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        Embryo.gFastEvolveCheat = not Embryo.gFastEvolveCheat
        Print("Setting fastevolve cheat %s", ConditionalValue(Embryo.gFastEvolveCheat, "on", "off"))
        
    end
    
end

local function OnCommandAllFree(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        Player.kAllFreeCheat = not Player.kAllFreeCheat
        Print("Setting allfree cheat %s", ConditionalValue(Player.kAllFreeCheat, "on", "off"))
        
    end
    
end

local function OnCommandLocation(client)

    local player = client:GetControllingPlayer()
    local locationName = player:GetLocationName()
    if locationName ~= "" then
        Print("You are in \"%s\".", locationName)
    else
        Print("You are nowhere.")
    end
    
end

local function OnCommandCloseMenu(client)
    local player = client:GetControllingPlayer()
    player:CloseMenu()
end

-- Weld all doors shut immediately
local function OnCommandWeldDoors(client)

    if Shared.GetCheatsEnabled() then
    
        for index, door in ientitylist(Shared.GetEntitiesWithClassname("Door")) do 
        
            if door:GetIsAlive() then
                door:SetState(Door.kState.Welded)
            end
            
        end
        
    end
    
end

local function OnCommandGore(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() and player and player:isa("Marine") then
    
        player.interruptAim = true
        player.interruptStartTime = Shared.GetTime()
        
    end
    
end

local function OnCommandPoison(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() and player and player:isa("Marine") then
    
        player:SetPoisoned()
        
    end
    
end

local function OnCommandStun(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() and player and HasMixin(player, "Stun") then
        player:SetStun(kDisruptMarineTime)
    end
    
end

local function OnCommandSpit(client)

    if Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:OnSpitHit()
        end
    end
    
end

local function OnCommandPush(client)

    if Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        if player then
            player:AddPushImpulse(Vector(50,10,0))
        end
    end
    
end

local function OnCommandEnzyme(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player.TriggerEnzyme then
            player:TriggerEnzyme(10)
        end
        
    end
    
end

gMucousDebug = false
local function OnCommandMucousDebug(client)

    if Shared.GetCheatsEnabled() then

        gMucousDebug = not gMucousDebug
        Log("Mucous debug text %s.", ConditionalValue(gMucousDebug, "enabled", "disabled"))
    end
end

local function OnCommandMucous(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "Mucousable") then

            player:SetMucousShield()
            Print("Added mucous to client.")
        end
    end
end

local function OnCommandResearch(client, researchName)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity and HasMixin(trace.entity, "Research") and researchName then

                local techId = StringToEnum(kTechId, researchName)
                if techId then

                    local node = player:GetTechTree():GetTechNode(techId)
                    if node then

                        node:SetResearched(false)
                        node:SetResearching()
                        trace.entity:SetResearching(node, player)
                        player:GetTechTree():SetTechNodeChanged(node, "researching")

                        Print("Started Researching %s", researchName)

                    end

                end

            else
                Print("No target that can research!")
            end

        end

    end

end

local function OnCommandCancelResearch(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity then

                local researchingEntity = nil
                if HasMixin(trace.entity, "Research") and trace.entity:GetIsResearching() then

                    researchingEntity = trace.entity

                elseif trace.entity:isa("Hive") then

                    local evolutionChamber = trace.entity:GetEvolutionChamber()
                    if evolutionChamber and HasMixin(evolutionChamber, "Research") and evolutionChamber:GetIsResearching() then

                        researchingEntity = evolutionChamber
                    end
                end

                if researchingEntity then
                    researchingEntity:CancelResearch()
                    Print("Cancelled target's research.")
                else
                    Print("Target is not researching anything.")
                end
            else
                Print("No target to cancel research.")
            end
        end
    end
end

local function OnCommandMucousOther(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity and HasMixin(trace.entity, "Mucousable") then

                trace.entity:SetMucousShield()
                Print("Added Mucous to target.")
            end
        end
    end
end

local function OnCommandOvershield(client, amount)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "Shieldable") then

            local overshieldAmount = ConditionalValue(amount and tonumber(amount) ~= nil, tonumber(amount), 10)
            player:AddOverShield(overshieldAmount)
            Print("Added %f overshield to client.", overshieldAmount)
        end
    end
end

local function OnCommandOvershieldOther(client, amount)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity and HasMixin(trace.entity, "Shieldable") then

                local overshieldAmount = ConditionalValue(amount and tonumber(amount) ~= nil, tonumber(amount), 10)
                trace.entity:AddOverShield(overshieldAmount)
                Print("Added %f overshield to target.", overshieldAmount)
            end
        end
    end
end

local function OnCommandEmptySecondaryOther(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity and HasMixin(trace.entity, "WeaponOwner") and trace.entity:isa("Marine") then

                local secondaryWeapon = trace.entity:GetWeaponInHUDSlot(2)
                if not secondaryWeapon then
                    Print("empty_secondary_other - %s does not have a secondary weapon!", ToString(trace.entity:GetName()))
                elseif not secondaryWeapon:isa("ClipWeapon") then
                    Print("empty_secondary_other - %s's secondary weapon is not a ClipWeapon!", ToString(trace.entity:GetName()))
                else
                    secondaryWeapon.clip = 0
                    secondaryWeapon.ammo = 0
                    Print("empty_secondary_other - Removed all ammo from %s's secondary weapon!", ToString(trace.entity:GetName()))
                end

            else

                if trace.entity then
                    Print("empty_secondary_other - %s is not a valid entity!", ToString(trace.entity))
                else
                    Print("empty_secondary_other - Could not find an entity!")
                end

            end
        end
    end
end

local function OnCommandEmptyAmmoOther(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))

            if trace.entity and HasMixin(trace.entity, "WeaponOwner") and trace.entity:isa("Marine") then

                for i = 1, 3 do
                    local weapon = trace.entity:GetWeaponInHUDSlot(i)
                    if weapon and weapon:isa("ClipWeapon") then
                        weapon.clip = 0
                        weapon.ammo = 0
                    end
                end

                Print("empty_ammo_other - Removed all ammo from %s's weapons!", ToString(trace.entity:GetName()))

            else

                if trace.entity then
                    Print("empty_ammo_other - %s is not a valid entity!", ToString(trace.entity))
                else
                    Print("empty_ammo_other - Could not find an entity!")
                end

            end
        end
    end
end

local function OnCommandEmptySecondary(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if HasMixin(player, "WeaponOwner") and player:isa("Marine") then

            local secondaryWeapon = player:GetWeaponInHUDSlot(2)
            if not secondaryWeapon then
                Print("empty_secondary - %s does not have a secondary weapon!", ToString(player:GetName()))
            elseif not secondaryWeapon:isa("ClipWeapon") then
                Print("empty_secondary - %s's secondary weapon is not a ClipWeapon!", ToString(player:GetName()))
            else
                secondaryWeapon.clip = 0
                secondaryWeapon.ammo = 0
                Print("empty_secondary - Removed all ammo from %s's secondary weapon!", ToString(player:GetName()))
            end

        end
    end
end

local function OnCommandUmbra(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "Umbra") then
            player:SetHasUmbra(true, 5)
        end
        
    end
    
end

local function OnCommandOrderSelf(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetOrderSelf(not GetGamerules():GetOrderSelf())
        Print("Order self is now %s.", ToString(GetGamerules():GetOrderSelf()))
    end
    
end

local function techIdStringToTechId(techIdString)

    local techId = tonumber(techIdString)
    
    if type(techId) ~= "number" then
        techId = StringToEnum(kTechId, techIdString)
    end        
    
    return techId
    
end

-- Create structure, weapon, etc. near player.
local function OnCommandCreate(client, techIdString, number, teamNum)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        local attachClass = LookupTechData(techId, kStructureAttachClass)
        
        number = number or 1
        
        if techId ~= nil then
        
            for i = 1, number do
            
                local success = false
                -- Persistence is the path to victory.
                for index = 1, 200 do
                
                    local player = client:GetControllingPlayer()
                    local teamNumber = tonumber(teamNum) or player:GetTeamNumber()
                    if techId == kTechId.Scan then
                        teamNumber = GetEnemyTeamNumber(teamNumber)
                    end
                    local position
                    
                    if attachClass then
                    
                        local attachEntity = GetNearestFreeAttachEntity(techId, player:GetOrigin(), 1000)
                        if attachEntity then
                            position = attachEntity:GetOrigin()
                        end
                        
                    else
                    
                        --[[local modelName = LookupTechData(techId, kTechDataModel)
                        local modelIndex = Shared.GetModelIndex(modelName)
                        local model = Shared.GetModel(modelIndex)
                        local minExtents, maxExtents = model:GetExtents()
                        Print(modelName .. " bounding box min: " .. ToString(minExtents) .. " max: " .. ToString(maxExtents))
                        local extents = maxExtents
                        DebugBox(player:GetOrigin(), player:GetOrigin(), maxExtents - minExtents, 1000, 1, 0, 0, 1)
                        DebugBox(player:GetOrigin(), player:GetOrigin(), minExtents, 1000, 0, 1, 0, 1)
                        DebugBox(player:GetOrigin(), player:GetOrigin(), maxExtents, 1000, 0, 0, 1, 1)--]]
                        --position = GetRandomSpawnForCapsule(extents.y, extents.x, player:GetOrigin() + Vector(0, 0.5, 0), 2, 10)
                        --position = position - Vector(0, extents.y, 0)
                        
                        position = CalculateRandomSpawn(nil, player:GetOrigin() + Vector(0, 2, 0), techId, true, 2, 10, 3)
                        
                    end
                    
                    if position then
                    
                        success = true
                        CreateEntityForTeam(techId, position, teamNumber, player)
                        break
                        
                    end
                    
                end
                
                if not success then
                    Print("Create %s: Couldn't find space for entity", EnumToString(kTechId, techId))
                end
                
            end
            
        else
            Print("Usage: create (techId name)")
        end
        
    end
    
end

local function OnCommandRandomDebug(s)

    if Shared.GetCheatsEnabled() then
    
        local newState = not gRandomDebugEnabled
        Print("OnCommandRandomDebug() now %s", ToString(newState))
        gRandomDebugEnabled = newState

    end
    
end

local function OnCommandDistressBeacon(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()  
        local ent = GetNearest(player:GetOrigin(), "Observatory", player:GetTeamNumber())
        if ent and ent.TriggerDistressBeacon then
        
            ent:TriggerDistressBeacon()
            
        end
        
    end

end

local function OnCommandSetGameEffect(client, gameEffectString, trueFalseString)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        local gameEffectBitMask = kGameEffect[gameEffectString]
        if gameEffectBitMask ~= nil then
        
            Print("OnCommandSetGameEffect(%s) => %s", gameEffectString, ToString(gameEffectBitMask))
            
            local state = true
            if trueFalseString and ((trueFalseString == "false") or (trueFalseString == "0")) then
                state = false
            end
            
            player:SetGameEffectMask(gameEffectBitMask, state)
            
        else
            Print("Couldn't find bitmask in %s for %s", ToString(kGameEffect), gameEffectString)
        end        
        
    end
    
end

local function OnCommandChangeGCSettingServer(client, settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing server GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

local function OnCommandEject(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        if player and player.Eject then
        
            player:Eject()        
            
        end
        
    end
    
end


local function GetClosestCyst(player)
    local origin = player:GetOrigin()
    -- get closest cyst inside 5m
    local targets = GetEntitiesWithinRange("Cyst", origin, 5)
    local target, range
    for _,t in ipairs(targets) do
        local r = (t:GetOrigin() - origin):GetLength() 
        if target == nil or range > r then
            target, range = t, r
        end
    end
    return target
end

local function OnCommandCyst(client, cmd)

    if client ~= nil and (Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        local cyst = GetClosestCyst(client:GetControllingPlayer())
        if cyst == nil then
            Print("Have to be within 5m of a Cyst for the command to work")
        else
            if cmd == "track" then
                if cyst == nil then
                    Log("%s has no track", cyst)
                else
                    Log("track %s", cyst)
                    cyst:Debug()
                end
            elseif cmd == "reconnect" then
                TrackYZ.kTrace,TrackYZ.kTraceTrack,TrackYZ.logTable["log"] = true,true,true
                Log("Try reconnect %s", cyst)
                cyst:TryToFindABetterParent()
                TrackYZ.kTrace,TrackYZ.kTraceTrack,TrackYZ.logTable["log"] = false,false,false
            else
                Print("Usage: cyst track - show track to parent") 
            end
        end
    end
end

--
-- Show debug info for the closest entity that has a self.targetSelector
--
local function OnCommandTarget(client, cmd)

    if client ~= nil and (Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        local player = client:GetControllingPlayer()
        local origin = player:GetOrigin()
        local structs = GetEntitiesWithinRange("ScriptActor", origin, 5)
        local sel, selRange
        for _, struct in ipairs(structs) do
            if struct.targetSelector or HasMixin(struct, "AiAttacks") then
                local r = (origin - struct:GetOrigin()):GetLength()
                if not sel or r < selRange then
                    sel,selRange = struct,r
                end
            end
        end
        Log("debug %s", sel)
        if sel then   
            if HasMixin(sel, "AiAttacks") then
                sel:AiAttacksDebug(cmd)
            else                 
                sel.targetSelector:Debug(cmd)
            end
        end
    end
end

local function OnCommandHasTech(client, cmd)

    if client ~= nil and Shared.GetCheatsEnabled() then
    
        if type(cmd) == "string" then

            local techId = StringToEnum(kTechId, cmd)
            if techId == nil then
                Print("Couldn't find tech id \"%s\" (should be something like ShotgunTech)", ToString(cmd))
                return
            end
        
            local player = client:GetControllingPlayer()
            if player then
            
                local techTree = player:GetTechTree()                
                if techTree then
                    local hasText = ConditionalValue(techTree:GetHasTech(techId), "has", "doesn't have")
                    Print("Your team %s \"%s\" tech.", hasText, cmd)
                end
                
            end
            
        else
            Print("Pass case-sensitive upgrade name.")
        end
            
    end
    
end

local function OnCommandEggSpawnTimes(client, cmd)

    if Shared.GetCheatsEnabled() then
    
        Print("Printing out egg spawn times:")

        for playerIndex = 1, 16 do
        
            local s = string.format("%d players: ", playerIndex)
            
            for eggIndex = 1, kAlienEggsPerHive do        
                s = s .. string.format("%d eggs = %.2f  ", eggIndex, CalcEggSpawnTime(playerIndex, eggIndex))
            end
            
            Print(s)
            
        end
        
    end
    
end

local function OnCommandTestOrder(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()

        if player and HasMixin(player, "Orders") then

            local eyePos = player:GetEyePos()
            local endPos = eyePos + player:GetViewAngles():GetCoords().zAxis * 50
            local trace = Shared.TraceRay(eyePos, endPos, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            local target = trace.endPoint

            player:GiveOrder(kTechId.Move, 0, target)
        
        end
        
    end    

end

local function FindNearestAIUnit(player)
    -- find where player is looking
    local eyePos = player:GetEyePos()
    local endPos = eyePos + player:GetViewAngles():GetCoords().zAxis * 50
    local trace = Shared.TraceRay(eyePos, endPos, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
    local target = trace.endPoint
        
    local ents = Shared.GetEntitiesWithClassname("ScriptActor")
    
    local selected
    local selectedRange = 0
    
    for i,entity in ientitylist(ents) do
    
        if entity:isa("Whip") or entity:isa("Drifter") or entity:isa("MAC") or entity:isa("ARC") then
        
            local r = (entity:GetOrigin() - target):GetLength()           
            if not selected or r < selectedRange then
            
                selected = entity 
                selectedRange = r
                
            end
            
        end
        
    end
    
    return trace, selected, selectedRange

end
    
-- call for the nearest AI unit to come to your location. Useful when testing pathing/animation
local function OnCommandFollowAndWeld(client)
    
    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()

        local trace, selected, selectedRange = FindNearestAIUnit(player)
    
        if selected then
        
            local target = trace.entity or player
        
            Log("%s ordered to follow and weld %s", selected, target)
            selected:GiveOrder(kTechId.FollowAndWeld, player:GetId())
            
        else
            Shared.Message("No AI entitity available")
        end
        
    end
    
end

-- Gives the requesting player an attack order at the current look target. For solo testing
local function OnCommandOrderAttackSelf(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "Orders") then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.Default, PhysicsMask.All, EntityFilterOne(player))

            if trace.entity and GetAreEnemies(player, trace.entity) then

                player:GiveOrder(kTechId.Attack, trace.entity:GetId(), trace.entity:GetOrigin())
                Print("Gave Attack Order to self.")
            else
                Print("No entity found for attack order command.")
            end

        end

    end

end

-- Gives the requesting player an attack order at the current look target. For solo testing
local function OnCommandOrderMoveSelf(client)

    if Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "Orders") then

            local startPoint = player:GetEyePos()
            local viewAngles = player:GetViewAngles()
            local fowardCoords = viewAngles:GetCoords()
            local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 45), CollisionRep.Default, PhysicsMask.All, EntityFilterOne(player))

            player:GiveOrder(kTechId.Move, trace.entity and trace.entity:GetId() or nil, trace.entity and trace.entity:GetOrigin() or trace.endPoint)
            Print("Gave Move Order to self.")

        end

    end

end

-- call for the nearest AI unit to come to your location. Useful when testing pathing/animation
local function OnCommandGoThere(client)
    
    if Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        
        local selected = FindNearestAIUnit(player)
    
        if selected then
        
            Shared.Message(string.format("Giving order to %s-%s", selected:GetClassName(), selected:GetId()))
            selected:GiveOrder(kTechId.Move, player:GetId(), target)
            -- Override the target Id to be invalidId so the AI unit doesn't follow the player.
            selected:GetCurrentOrder():Initialize(kTechId.Move, Entity.invalidId, target, 0)
            
        else
            Shared.Message("No AI entitity available")
        end
        
    end
    
end

local function OnCommandRupture(client, classname)

    if Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            if player and player:isa("Marine") then            
                player:SetRuptured()            
            end
        
    end
    
end

local function OnCommandCommanderPing(client, classname)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:GetTeam() then
        
            -- trace along crosshair
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * 100
            
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            
            player:GetTeam():SetCommanderPing(trace.endPoint)
            
        end
        
    end
    
end

local function OnCommandThreat(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player then
        
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * 100
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            CreatePheromone(kTechId.ThreatMarker, trace.endPoint, 2)
            
        end
        
    end
    
end

local function OnCommandFire(client)

    if Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        if player then
            player:SetOnFire(nil, nil)
        end
    end
    
end

local function OnCommandDeployARCs()

    if Shared.GetCheatsEnabled() then
    
        for index, arc in ientitylist(Shared.GetEntitiesWithClassname("ARC")) do        
            arc.deployMode = ARC.kDeployMode.Deploying        
        end
        
    end
    
end

local function OnCommandUndeployARCs()

    if Shared.GetCheatsEnabled() then
    
        for index, arc in ientitylist(Shared.GetEntitiesWithClassname("ARC")) do        
            arc.deployMode = ARC.kDeployMode.Undeploying        
        end
        
    end
    
end

local function OnCommandDebugCommander(client, vm)

    if Shared.GetCheatsEnabled() then    
        BuildUtility_SetDebug(vm)        
    end
    
end

local function OnCommandRespawnTeam(client, teamNum)

    if Shared.GetCheatsEnabled() then
    
        teamNum = tonumber(teamNum)
        if teamNum == 1 then
            GetGamerules():GetTeam1():ReplaceRespawnAllPlayers()
        elseif teamNum == 2 then
            GetGamerules():GetTeam2():ReplaceRespawnAllPlayers()
        end
        
    end
    
end

local function OnCommandGreenEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("green", "male")
        end
        
    end
    
end

local function OnCommandBlackEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("special", "male")
        end
        
    end
    
end

local function OnCommandMakeSpecialEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("deluxe", "male")
        end
        
    end
    
end

local function OnCommandGreenEditionFemale(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("green", "female")
        end
        
    end
    
end

local function OnCommandBlackEditionFemale(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("special", "female")
        end
        
    end
    
end

local function OnCommandMakeSpecialEditionFemale(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then
            player:SetVariant("deluxe", "female")
        end
        
    end
    
end

local function OnCommandMake(client, sex, variant)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and HasMixin(player, "PlayerVariant") then
            player:SetVariant(variant, sex)
        end
        
    end
    
end

local function OnCommandHell(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player then
            
            for _, flammable in ipairs(GetEntitiesWithMixin("Fire")) do                
                flammable:SetOnFire(player, player)            
            end
    
        end
        
    end  

end

local function OnCommandStoreLastPosition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player then            
            gLastPosition = player:GetOrigin()
            Print("stored position %s", ToString(gLastPosition))
        end
        
    end  

end

local function OnCommandEvolveLastUpgrades(client)

    local player = client:GetControllingPlayer()
    if player and player:isa("Alien") and player:GetIsAlive() and not player:isa("Embryo") then

        local class = player:GetClassName()
        local upgrades = player.lastUpgradeList or {}
        upgrades = upgrades[class] or upgrades["Skulk"] or {}
        if upgrades and #upgrades > 0 then
            if player.autopickedUpgrades then
                player:ClearUpgrades()
            end

            player:ProcessBuyAction(upgrades)
        end
    
    end

end

local function OnCommandRequestStructure(client)

    local player = client:GetControllingPlayer()

    if Shared.GetCheatsEnabled() then
        player:GetTeam():TriggerAlert(kTechId.MarineAlertNeedStructure, player)
    end

end

--
-- hack; turn dev mode on, do a trace, turn dev mode off and dump the trace you got back
--
local function OnCommandDevTrace(client, box)
    
     Log("box %s", box)

    if Server and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        if player then
        
            -- trace to a surface and draw the decal
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * 100
            local trace
            Shared.ConsoleCommand("dev 1")
            if box then
                trace = Shared.TraceBox(Vector(0.1,0.1,0.1), startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterOne(player))
            else
                trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterOne(player))
            end
            Shared.ConsoleCommand("dev 0")
            
            if trace.fraction ~= 1 then
            
                DebugLine(startPoint, trace.endPoint, 5, 1, 0, 0, 1)            
                Log("%s: frac %s, ent %s, surf %s", player, trace.fraction, trace.entity, trace.surface)
            
            end
        
        end
    
    end

end

local function OnCommandRailgunBotToggle(client)

    if Shared.GetCheatsEnabled() then

        MarineBrain.kRailgunExoEnabled = not MarineBrain.kRailgunExoEnabled
        Print("Marine bot Railgun Exo purchase allowed: %s", MarineBrain.kRailgunExoEnabled)
        return

    end

    -- Default to enabling it
    MarineBrain.kRailgunExoEnabled = true
    Print("Marine bot Railgun Exo purchase allowed: true (default)")

end

gDebugGrenades = false
local function OnCommandDebugGrenades(client)
    if not Shared.GetTestsEnabled() then
        Log("Command requires Tests enabled")
        return
    end

    gDebugGrenades = not gDebugGrenades
    SetDebugGrenadeDamageRadius(gDebugGrenades)
    Server.SendNetworkMessage("DebugGrenades", { enabled = gDebugGrenades }, true)
end

-- %%% New CBM Functions %%% --
local function OnCommandStorm(client)
    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player.TriggerStorm then
            player:TriggerStorm(9.5)
        end
        
    end
end

Event.Hook("Console_storm", OnCommandStorm)        

Event.Hook("Console_devtrace", OnCommandDevTrace)

-- GC commands
Event.Hook("Console_changegcsettingserver", OnCommandChangeGCSettingServer)

-- NS2 game mode console commands
Event.Hook("Console_jointeamone", OnCommandJoinTeamOne)
Event.Hook("Console_jointeamtwo", OnCommandJoinTeamTwo)
Event.Hook("Console_jointeamthree", OnCommandJoinTeamRandom)
Event.Hook("Console_readyroom", OnCommandReadyRoom)
Event.Hook("Console_spectate", OnCommandSpectate)
Event.Hook("Console_film", OnCommandFilm)

-- Shortcuts because we type them so much
Event.Hook("Console_j1", OnCommandJoinTeamOne)
Event.Hook("Console_j2", OnCommandJoinTeamTwo)
Event.Hook("Console_j3", OnCommandJoinTeamRandom)
Event.Hook("Console_rr", OnCommandReadyRoom)

Event.Hook("Console_endgame", OnCommandEndGame)
Event.Hook("Console_logout", OnCommandLogout)
Event.Hook("Console_gotoidleworker", OnCommandGotoIdleWorker)
Event.Hook("Console_gotoplayeralert", OnCommandGotoPlayerAlert)
Event.Hook("Console_selectallplayers", OnCommandSelectAllPlayers)

-- Cheats
Event.Hook("Console_tres", OnCommandTeamResources)
Event.Hook("Console_pres", OnCommandResources)
Event.Hook("Console_allfree", OnCommandAllFree)
Event.Hook("Console_autobuild", OnCommandAutobuild)
Event.Hook("Console_energy", OnCommandEnergy)
Event.Hook("Console_mature", OnCommandMature)
Event.Hook("Console_takedamage", OnCommandTakeDamage)
Event.Hook("Console_setarmorpercent", OnCommandSetArmorPercent)
Event.Hook("Console_heal", OnCommandHeal)
Event.Hook("Console_giveammo", OnCommandGiveAmmo)
Event.Hook("Console_nanoshield", OnCommandNanoShield)
Event.Hook("Console_blight", OnCommandBlight)
Event.Hook("Console_parasite", OnCommandParasite)
Event.Hook("Console_respawn_team", OnCommandRespawnTeam)

Event.Hook("Console_ents", OnCommandEnts)
Event.Hook("Console_sents", OnCommandServerEntities)
Event.Hook("Console_entinfo", OnCommandEntityInfo)

Event.Hook("Console_switch", OnCommandSwitch)
Event.Hook("Console_damage", OnCommandDamage)
Event.Hook("Console_highdamage", OnCommandHighDamage)
Event.Hook("Console_give", OnCommandGive)
Event.Hook("Console_spawn", OnCommandSpawn)
Event.Hook("Console_spawnhere", OnCommandSpawnHere)
Event.Hook("Console_storeposition", OnCommandStoreLastPosition)
Event.Hook("Console_shoot", OnCommandShoot)
Event.Hook("Console_giveupgrade", OnCommandGiveUpgrade)
Event.Hook("Console_setfov", OnCommandSetFOV)

-- For testing lifeforms
Event.Hook("Console_skulk", OnCommandChangeClass("skulk", kTeam2Index))
Event.Hook("Console_gorge", OnCommandChangeClass("gorge", kTeam2Index))
Event.Hook("Console_lerk", OnCommandChangeClass("lerk", kTeam2Index))
Event.Hook("Console_fade", OnCommandChangeClass("fade", kTeam2Index))
Event.Hook("Console_onos", OnCommandChangeClass("onos", kTeam2Index))
Event.Hook("Console_marine", OnCommandChangeClass("marine", kTeam1Index))
Event.Hook("Console_jetpack", OnCommandChangeClass("jetpackmarine", kTeam1Index))
Event.Hook("Console_exo", OnCommandChangeClass("exo", kTeam1Index, { layout = "MinigunMinigun" }))
Event.Hook("Console_dualminigun", OnCommandChangeClass("exo", kTeam1Index, { layout = "MinigunMinigun" }))
Event.Hook("Console_dualrailgun", OnCommandChangeClass("exo", kTeam1Index, { layout = "RailgunRailgun" }))

Event.Hook("Console_respawn", OnCommandRespawn)
Event.Hook("Console_respawn_clear", OnCommandRespawnClear)

Event.Hook("Console_sandbox", OnCommandSandbox)

Event.Hook("Console_command", OnCommandCommand)
Event.Hook("Console_catpack", OnCommandCatPack)
Event.Hook("Console_alltech", OnCommandAllTech)
Event.Hook("Console_fastevolve", OnCommandFastEvolve)
Event.Hook("Console_location", OnCommandLocation)
Event.Hook("Console_gore", OnCommandGore)
Event.Hook("Console_poison", OnCommandPoison)
Event.Hook("Console_stun", OnCommandStun)
Event.Hook("Console_spit", OnCommandSpit)
Event.Hook("Console_push", OnCommandPush)
Event.Hook("Console_enzyme", OnCommandEnzyme)
Event.Hook("Console_mucousdebug", OnCommandMucousDebug)
Event.Hook("Console_research", OnCommandResearch)
Event.Hook("Console_cancelresearch", OnCommandCancelResearch)
Event.Hook("Console_mucous", OnCommandMucous)
Event.Hook("Console_mucousother", OnCommandMucousOther)
Event.Hook("Console_empty_secondary_other", OnCommandEmptySecondaryOther)
Event.Hook("Console_empty_ammo_other", OnCommandEmptyAmmoOther)
Event.Hook("Console_empty_secondary", OnCommandEmptySecondary)
Event.Hook("Console_overshield", OnCommandOvershield)
Event.Hook("Console_overshieldother", OnCommandOvershieldOther)
Event.Hook("Console_umbra", OnCommandUmbra)
Event.Hook("Console_deployarcs", OnCommandDeployARCs)
Event.Hook("Console_undeployarcs", OnCommandUndeployARCs)

Event.Hook("Console_closemenu", OnCommandCloseMenu)
Event.Hook("Console_welddoors", OnCommandWeldDoors)
Event.Hook("Console_orderself", OnCommandOrderSelf)

Event.Hook("Console_create",OnCommandCreate)
Event.Hook("Console_random_debug", OnCommandRandomDebug)
Event.Hook("Console_beacon", OnCommandDistressBeacon)
Event.Hook("Console_setgameeffect", OnCommandSetGameEffect)

Event.Hook("Console_eject", OnCommandEject)
Event.Hook("Console_cyst", OnCommandCyst)
Event.Hook("Console_target", OnCommandTarget)
Event.Hook("Console_hastech", OnCommandHasTech)
Event.Hook("Console_eggspawntimes", OnCommandEggSpawnTimes)
Event.Hook("Console_gothere", OnCommandGoThere)
Event.Hook("Console_attackorderself", OnCommandOrderAttackSelf)
Event.Hook("Console_moveorderself", OnCommandOrderMoveSelf)
Event.Hook("Console_follow", OnCommandFollowAndWeld)
Event.Hook("Console_testorder", OnCommandTestOrder)

Event.Hook("Console_marinebot_railguntoggle", OnCommandRailgunBotToggle)

Event.Hook("Console_rupture", OnCommandRupture)
Event.Hook("Console_commanderping", OnCommandCommanderPing)
Event.Hook("Console_threat", OnCommandThreat)
Event.Hook("Console_fire", OnCommandFire)
Event.Hook("Console_makegreen", OnCommandGreenEdition)
Event.Hook("Console_makeblack", OnCommandBlackEdition)
Event.Hook("Console_makespecial", OnCommandMakeSpecialEdition)
Event.Hook("Console_makegreenfemale", OnCommandGreenEditionFemale)
Event.Hook("Console_makeblackfemale", OnCommandBlackEditionFemale)
Event.Hook("Console_makespecialfemale", OnCommandMakeSpecialEditionFemale)
Event.Hook("Console_make", OnCommandMake)
Event.Hook("Console_requeststructure", OnCommandRequestStructure)

Event.Hook("Console_sv_debug_grenades", OnCommandDebugGrenades)

Event.Hook("Console_evolvelastupgrades", OnCommandEvolveLastUpgrades)

Event.Hook("Console_debugcommander", OnCommandDebugCommander)
Event.Hook("Console_hell", OnCommandHell)
Event.Hook("Console_trace", OnCommandTrace)

Event.Hook("Console_dlc", function(client)
    if Shared.GetCheatsEnabled() then
        GetHasDLC = function(pid, client)
            return true
            end
    end
end)
