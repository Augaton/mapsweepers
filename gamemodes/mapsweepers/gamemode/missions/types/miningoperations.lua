--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
	Copyright (C) 2025  MerekiDor

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.

	See the full GNU GPL v3 in the LICENSE file.
	Contact E-Mail: merekidorian@gmail.com
--]]

-- Mining Operations {{{

jcms.missions.miningoperations = {
	faction = "antlion",
	
	generate = function(data, missionData)
		--Place refineries / Difficulty calculations
		local pvpMode = jcms.util_IsPVP()

		local refineries_main = jcms.mapgen_SpreadPrefabs("refinery_main", pvpMode and 2 or 1, 250, true)
		local refineries_secondary = jcms.mapgen_SpreadPrefabs("refinery_secondary", jcms.mapgen_AdjustCountForMapSize(3), 180, false)

		missionData.refineries_main = refineries_main
		missionData.refineries_secondary = refineries_secondary

		local diffMult = jcms.runprogress_GetDifficulty() ^ (2/3)
		missionData.totalToRefine = math.ceil(1500 * diffMult)


		--Pvp Mode
		if pvpMode then
			refineries_main[1]:SetNWInt("jcms_pvpTeam", 1)

			refineries_main[2]:SetColor(Color(241, 212, 14))
			refineries_main[2]:SetNWInt("jcms_pvpTeam", 2)

			local function onRefineMain(ref, ore, miner, bringer, obtain)
				ref.jcms_pvpOreAccumulator = (ref.jcms_pvpOreAccumulator or 0) + obtain

				if ref.jcms_pvpOreAccumulator > missionData.totalToRefine/3 then
					ref.jcms_pvpOreAccumulator = 0
					jcms.director_PvpObjectiveCompletedTeam(ref:GetNWInt("jcms_pvpTeam", -1), ref:GetPos())
				end
			end

			for i, ref in ipairs(refineries_main) do
				ref.OnRefine = onRefineMain
			end
		end


		local function onRefineSecondary(ref, ore, miner, bringer, obtain)
			if not jcms.director_IsSuddenDeath() then
				if miner ~= bringer then
					local half = math.ceil(obtain/2)
					jcms.giveCash(miner, half)
					jcms.giveCash(bringer, half)
				else
					jcms.giveCash(miner, obtain)
				end
			end
		end

		--POIs to avoid for ore spawning
		local vectorsOfInterest = {}
		for i, ref in ipairs(refineries_main) do 
			table.insert(vectorsOfInterest, ref:WorldSpaceCenter())
		end
		for i, ref in ipairs(refineries_secondary) do
			ref.OnRefine = onRefineSecondary
			table.insert(vectorsOfInterest, ref:WorldSpaceCenter())
		end
		
		--Ore spawning
		local spawned = 0
		local areas = navmesh.GetAllNavAreas()
		table.Shuffle(areas)

		for i, area in ipairs( areas ) do
			if area:GetSizeX() > 200 and area:GetSizeY() > 200 then
				local wallspots = jcms.prefab_GetWallSpotsFromArea(area, 48, 500)
				if #wallspots > 0 then
					table.Shuffle(wallspots)

					for j=1, math.random(1, math.min(2, #wallspots)) do
						if spawned <= 32 or math.random() < 32 / spawned then
							local pos = wallspots[j] + Vector(0, 0, -50)

							local minDist2 = math.huge
							for k,voi in ipairs(vectorsOfInterest) do
								local dist2 = voi:DistToSqr(pos)
								minDist2 = math.min(minDist2, dist2)
							end

							local validOres = {}
							for k, oreData in pairs(jcms.oreTypes) do
								if (minDist2 >= oreData.proxMin^2 and minDist2 <= oreData.proxMax^2) then
									validOres[k] = oreData.weight or 1
								end
							end

							if next(validOres) then
								local vein = ents.Create("jcms_orevein")
								vein:SetPos(pos)
								vein:SetAngles(Angle(0, math.random()*360, 0))
								vein:Spawn()
								vein:SetOreType(jcms.util_ChooseByWeight(validOres))
								spawned = spawned + 1
							end
						end
					end
				end
			end
		end
		missionData.totalOres = spawned
		missionData.oreProgress = 0

		--Naturals
		jcms.mapgen_PlaceNaturals( jcms.mapgen_AdjustCountForMapSize(10) )
		jcms.mapgen_PlaceEncounters()
	end,
	
	tagEntities = function(director, missionData, tags)
		for i, refinery  in ipairs(missionData.refineries_main) do 
			if IsValid(refinery) then
				tags[refinery] = { name = "#jcms.refinery", moving = false, active = not missionData.evacuating }
			end
		end

		for i, ref in ipairs(missionData.refineries_secondary) do
			if IsValid(ref) then
				tags[ref] = { name = "#jcms.refinery_secondary", moving = false, active = not missionData.evacuating }
			end
		end
	end,

	getObjectives = function(missionData)
		local totalValid = 0
		local totalComplete = 0
		for i, refinery in ipairs(missionData.refineries_main) do
			if IsValid(refinery) then
				totalValid = totalValid + 1

				if refinery:GetValueInside() >= missionData.totalToRefine then
					totalComplete = totalComplete + 1
				end
			end
		end

		if totalValid > 0 and totalComplete < totalValid then
			local objectives =  {
				{ type = "jantlion" },
				{ type = "mineore" },
				{ type = "bringore" },
			}

			for i, refinery in ipairs(missionData.refineries_main) do 
				table.insert(objectives, 
					{ type = "refineore", progress = refinery:GetValueInside(), total = missionData.totalToRefine , format = { missionData.totalToRefine  } }
				)
			end

			return objectives
		else
			missionData.evacuating = true
		
			if not IsValid(missionData.evacEnt) then
				missionData.evacEnt = jcms.mission_DropEvac(jcms.mission_PickEvacLocation())
			end
			
			return jcms.mission_GenerateEvacObjective()
		end
	end,

	think = function(director, missionData)
		local oresRightNow = 0
		for i, ent in ipairs( ents.FindByClass("jcms_*") ) do
			if not IsValid(ent) then continue end

			local entTbl = ent:GetTable()
			if ent:GetClass() == "jcms_orevein" then
				oresRightNow = oresRightNow + math.Clamp( ent:Health() / ent:GetMaxHealth(), 0, 1 )
			elseif type(entTbl.SpawnMinecart) == "function" and not entTbl.jcms_minecartHandled then
				entTbl.SpawnMinecart(ent)
				entTbl.jcms_minecartHandled = true
			end
		end

		missionData.oreProgress = 1 - oresRightNow / missionData.totalOres
	end,

	swarmCalcCost = function(director, swarmCost)
		return swarmCost + (director.missionData.oreProgress^2)*2 
	end,

	npcTypeQueueCheck = function(director, swarmCost, dangerCap, npcType, npcData, basePassesCheck)
		local md = director.missionData
		if npcType == "antlion_mineralguard" and md.oreProgress > 0 then
			return basePassesCheck, md.oreProgress * 1.43
		else
			return basePassesCheck
		end
	end
}

-- }}}
