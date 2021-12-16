--  	Author: Ryan Hagelstrom
--	  	Copyright © 2021
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

local parseNPCPower = nil
--local parseEENPCPower = nil
local bEE = false

function onInit()
	if Session.IsHost then
		parseNPCPower = CombatManager2.parseNPCPower	
		CombatManager2.parseNPCPower = customParseNPCPower

		aExtensions = Extension.getExtensions()
		for _,sExtension in ipairs(aExtensions) do
			tExtension = Extension.getExtensionInfo(sExtension)
			if tExtension.name == "5E (and more) - Equipped Effects FGU"  then
				bEE = true -- Its loaded
--				parseEENPCPower = parseNPCPower
--				parseNPCPower = EquippedEffectsManager.saveparseNPCPower
			end
		end
	end
end

-- Set things back the way they origiinally were
function onClose()
	if Session.IsHost then
		CombatManager2.parseNPCPower = parseNPCPower
	end
end

function customParseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	local nActorLevel = 0
	local aSpellDamage = {}
	local i = 1;
	if bEE == true then
--		parseEENPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	end
	
	local sDisplay = DB.getValue(nodePower, "name", "")
	local sDesc = StringManager.trim(DB.getValue(nodePower, "desc", ""))
	local aWords = StringManager.parseWords(sDesc)
	-- Is this a Cantrip? If not don't care and don't waste cycles
	if sDesc:match("[Ll]evel: 0") then
		local nDiceStringPos = 0
		local sOrig = ""
		local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)
		if sNodeType == "ct" or sNodeType == "npc" then -- Is NPC
			for _,nodeTrait in pairs(DB.getChildren(nodeActor, "traits")) do
				local sTraitName = StringManager.trim(DB.getValue(nodeTrait, "name", ""):lower())
				if sTraitName == "spellcasting" then -- Find the spellcasting trait
					local sSpellDesc = DB.getValue(nodeTrait, "desc", ""):lower();
					nActorLevel = tonumber(sSpellDesc:match("is a%l? (%d+)%l+%-level spellcaster")) or 0-- Get Spellcaster Level
				end
			end
		end
		while aWords[i] do
			if StringManager.isWord(aWords[i], "spell's") and StringManager.isWord(aWords[i+1], "damage") and StringManager.isWord(aWords[i+2], "increases")then
				local j = i+3
				while aWords[j] do
					if StringManager.isWord(aWords[i], "level") then
						table.insert(aSpellDamage, {nLevel = tonumber(aWords[i-1]:match("(%d+)") or ""), sDamage = aWords[i+1]})
					end
					i=j
					j = j+1
				end
			elseif StringManager.isWord(aWords[i], {"target","it", "or"}) and StringManager.isWord(aWords[i+1], {"takes","take"} ) and StringManager.isDiceString(aWords[i+2]) then
				sOrig = aWords[i] .. " " .. aWords[i+1] .. " " .. aWords[i+2]
				nDiceStringPos = i+2
			end
			i = i+1
		end
		--Loop though backwards so we check what tier this NPC is at and set cantrip damage accordingly
		if next(aSpellDamage) ~= nil then
			for j=1, #aSpellDamage do
				if nActorLevel >= aSpellDamage[#aSpellDamage+1 -j].nLevel then
					--after all that, this is where the magic happens
					local sReplace = sOrig:gsub("[d%.%dF%+%-]+$", aSpellDamage[#aSpellDamage+1 -j].sDamage)
					sDesc = sDesc:gsub(sOrig, sReplace)
					DB.setValue(nodePower, "desc", "string", sDesc)
					if bEE == true then
				--		parseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
					end
					break
				end 
			end
		end	
	end
	-- If we have 
	if  bEE == false then
		parseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	end
end