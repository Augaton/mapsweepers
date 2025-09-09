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


-- Data Download {{{

	jcms.missions.datadownload = {
		faction = "combine",

		generate = function(data, missionData)
			-- Defense phase {{{
				missionData.defenseOngoing = false
				missionData.defenseCompleted = false
				missionData.defenseAttempts = 0
				missionData.defenseProgress = 0
			-- }}}

			-- The computer {{{
				-- // Area Weights {{{
					local weightedAreas = {}
					for i, area in ipairs(jcms.mapgen_MainZone()) do --Prioritise outdoor areas, ignore too small ones.
						weightedAreas[area] = #area:GetVisibleAreas()
						if area:GetSizeX() < 350 or area:GetSizeY() < 350 then
							weightedAreas[area] = nil
						elseif not jcms.mapgen_AreaFlat(area) then
							weightedAreas[area] = nil
						end
					end
				-- // }}}

				local computerArea = jcms.util_ChooseByWeight(weightedAreas)
				assert(computerArea, "Can't place down the main computer. This map sucks, find a better one")
				local _, computer = jcms.prefab_TryStamp("datadownload_computer", computerArea)

				computer:SetNWBool("jcms_terminal_locked", false)
				jcms.terminal_ToPurpose(computer)
				
				function computer:jcms_terminal_Callback(cmd, data, ply)
					if data == "prep" and not missionData.defenseOngoing and not missionData.defenseCompleted then
						missionData.defenseOngoing = true
						missionData.defenseProgress = 0
						missionData.defenseAttempts = missionData.defenseAttempts + 1

						self:EmitSound("ambient/alarms/klaxon1.wav", 150, 108, 1)
						util.ScreenShake(self:GetPos(), 3, 50, 1, 2048, true)
						return true, "upload"
					end
				end

				missionData.computer = computer
			-- }}}

			-- // The Pillars {{{
				-- // Prioritise areas near the computer {{{
					--Outside the loop for optimisation
					local computerPos = computerArea:GetCenter()
					local defaultWeightedAreas = {}
					for i, area in ipairs(jcms.mapgen_MainZone()) do
						if area:GetSizeX() < 50 or area:GetSizeY() < 50 then
							defaultWeightedAreas[area] = nil
							continue
						end

						local dist = area:GetCenter():Distance(computerPos) 
						if dist > 350 then --Not too close/on-top of us
							defaultWeightedAreas[area] = 1 / math.sqrt(dist) --Close to the main computer
						end
					end
				-- // }}}

				-- // Generate {{{
					local pillarCount = math.ceil(2 * jcms.runprogress_GetDifficulty() * (2/3))
					local pillars = {}
					local pillarPositions = {} --Optimisation

					-- Note / TODO: We *could* make this like spreadprefabs & try to make them unable to see each-other.
					for i=1, pillarCount do --Generate pillars
						local weightedAreas = {}
						for i, area in ipairs(jcms.mapgen_MainZone()) do --Try to spread pillars out
							weightedAreas[area] = defaultWeightedAreas[area]
							if not weightedAreas[area] then continue end

							local centre = area:GetCenter()
							local closestDist = math.huge
			
							for i, pillarPos in ipairs(pillarPositions) do --Don't spawn too close to others.
								local dist = pillarPos:Distance(centre)
								closestDist = (closestDist < dist and closestDist) or dist
							end
							
							if not(closestDist == math.huge) then  
								weightedAreas[area] = weightedAreas[area] * math.sqrt(closestDist)
							end
						end

						local chosenArea = jcms.util_ChooseByWeight(weightedAreas)
						assert(chosenArea, "Can't place down any computer pillars. This map sucks, find a better one")

						local _, pillar = jcms.prefab_TryStamp("datadownload_pillar", chosenArea)
						table.insert(pillars, pillar)
						table.insert(pillarPositions, chosenArea:GetCenter()) 
					end
				-- // }}}

				missionData.pillars = pillars
				computer.pillars = pillars

				for i, pillar in ipairs(pillars) do
					local chr = string.char(64 + i) --Capital alphabetical chars
					pillar:SetLabelSymbol(chr)
					
					local health = 500 --TODO: We *could* make this reduce based on difficulty.
					pillar:SetMaxHealth(health)
					pillar:SetHealth(health)
				end

			-- // }}}

			jcms.mapgen_PlaceNaturals(jcms.mapgen_AdjustCountForMapSize(24), weightOverride)
			jcms.mapgen_PlaceEncounters()
		end,

		tagEntities = function(director, missionData, tags)
			if IsValid(missionData.computer) then
				tags[missionData.computer] = { name = "#jcms.obj_datadownloadcomputer", moving = false, active = true, landmarkIcon = "computer" }
			end
		end,

		getObjectives = function(missionData)
			local phase = 0 -- Evacuating
			if IsValid(missionData.computer) then
				if missionData.defenseCompleted then
					phase = 0 -- Evac
				elseif missionData.defenseOngoing then
					phase = 2 -- Combat
				else
					phase = 1 -- Preparing for defense
				end
			end
			missionData.phase = phase

			if phase == 1 then
				return {
					{ type = "prepfordefense" },
					{ type = "activatedownload" }
				}
			elseif phase == 2 then
				local objectives = {
					{ type = "surv", style = 1, progress = missionData.timeEstimate or 0 },
				}

				for i, pillar in ipairs(missionData.pillars) do 
					if not IsValid(pillar) then continue end

					local isDisrupted = pillar:GetIsDisrupted()
					table.insert(objectives, { type = isDisrupted and "repairpillarx" or "defendpillarx", format = { pillar:GetLabelSymbol() } })
					table.insert(objectives, { type = "defendpillarx", style = 2, progress = math.ceil(pillar:Health() / pillar:GetMaxHealth() * 100), total = 100 })
				end
				--[[
				local disrupted1 = missionData.pillar1:GetIsDisrupted()
				local disrupted2 = missionData.pillar2:GetIsDisrupted()
				return {
					{ type = disrupted1 and "repairpillarx" or "defendpillarx", format = { "A" } },
					{ type = "defendpillarx", style = 2, progress = math.ceil(missionData.pillar1:Health() / missionData.pillar1:GetMaxHealth() * 100), total = 100 },
					{ type = disrupted2 and "repairpillarx" or "defendpillarx", format = { "B" } },
					{ type = "defendpillarx", style = 2, progress = math.ceil(missionData.pillar2:Health() / missionData.pillar2:GetMaxHealth() * 100), total = 100 }
				}--]]

				return objectives
			else
				missionData.evacuating = true
			
				if not IsValid(missionData.evacEnt) then
					missionData.evacEnt = jcms.mission_DropEvac(jcms.mission_PickEvacLocation(), 20)
				end
				
				return jcms.mission_GenerateEvacObjective()
			end
		end,

		think = function(d)
			local md = d.missionData
			md.timeEstimate = 0
			
			local pillarsShouldBeActive = false

			if md.defenseCompleted then
				md.defenseProgress = 1
			else
				if md.defenseOngoing then
					pillarsShouldBeActive = true

					local totalPillars = 0
					local activePillars = 0
					for i, pillar in ipairs(md.pillars) do 
						if not IsValid(pillar) then continue end

						totalPillars = totalPillars + 1
						if not pillar:GetIsDisrupted() then activePillars = activePillars + 1 end
					end

					if activePillars > 0 then
						--4 Minutes at max power, scaling with difficulty
						--Fewer pillars exponentially slows it.

						local progressPower = (activePillars / totalPillars)^2
						progressPower = progressPower * 1/(240 * jcms.runprogress_GetDifficulty())

						md.defenseProgress = math.Clamp(md.defenseProgress + progressPower, 0, 1)
						md.timeEstimate = math.ceil( (1 - md.defenseProgress) / progressPower )--]]

						if md.defenseProgress >= 1 then
							md.defenseCompleted = true
							md.defenseOngoing = false
						end
					else
						pillarsShouldBeActive = false

						for i, pillar in ipairs(md.pillars) do
							pillar:SetIsDisrupted(false)
							pillar:SetHealth( pillar:GetMaxHealth() )
							pillar:SetHealthFraction(1)
						end

						md.defenseOngoing = false
						md.defenseProgress = 0
					end
				else
					md.defenseProgress = 0
				end

				for i, pillar in ipairs(md.pillars) do 
					pillar:SetIsActive(pillarsShouldBeActive) 
					pillar:SetChargeFraction(md.defenseProgress)
				end
			end
			
			if IsValid(md.computer) then
				if md.computer:GetNWString("jcms_terminal_modeData") == "upload" and not md.defenseOngoing then
					md.computer:SetNWString("jcms_terminal_modeData", "prep")
				end
			end
		end,

		swarmCalcCost = function(director, baseCost)
			local md = director.missionData
			
			if md.evacuating then
				return baseCost
			else
				local phase = md.phase

				if phase == 2 then
					return math.min(5, baseCost / 2) -- Severely reduce spawnrates during prep
				elseif phase == 3 then
					return baseCost > 0 and baseCost + 4 or 0 -- More shit during the defense phase
				end
			end
		end,

		swarmCalcDanger = function(d, swarmCost)
			local phase = d.missionData.phase
			if phase == 2 then
				return math.min(d.swarmDanger, jcms.NPC_DANGER_STRONG) -- No bosses during prep
			elseif phase == 3 then
				return math.max(d.swarmDanger, jcms.NPC_DANGER_STRONG) -- Always strongs during defense
			end
		end,

		swarmCalcBossCount = function(d, swarmCost)
			if d.missionData.phase == 2 then
				return 0 -- No bosses during preparation phase
			end
		end,

		npcTypeQueueCheck = function(d, swarmCost, dangerCap, npcType, npcData, basePassesCheck)
			local phase = d.missionData.phase
			local weightMul

			if phase == 2 then
				-- More snipers during prep.
				weightMul = ({
					["combine_sniper"] = 2.5
				})[npcType]
			elseif phase == 3 then
				-- More hunters, less BS enemies during the defense
				weightMul = ({
					["combine_metrocop"] = 1.66,
					["combine_hunter"] = 2.5,
					["combine_suppressor"] = 0.5,
					["combine_sniper"] = 0.75,
					["combine_gunship"] = 0.5 --This isn't going to do anything because boss-spawns are guaranteed and combine only have one type - J
				})[npcType]
			else
				-- More cops and hunters.
				weightMul = ({
					["combine_metrocop"] = 1.5,
					["combine_hunter"] = 1.75
				})[npcType]
			end

			if weightMul then
				return basePassesCheck, jcms.npc_GetScaledSwarmWeight(npcData) * weightMul
			else
				return basePassesCheck
			end
		end
	}

-- }}}
