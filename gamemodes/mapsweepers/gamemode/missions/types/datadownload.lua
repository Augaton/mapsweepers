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
				missionData.powerMultiplier = 0
			-- }}}

			-- The computer {{{
				-- // Area Weights {{{
					local weightedAreas = {}
					for i, area in ipairs(jcms.mapgen_MainZone()) do --Prioritise outdoor areas, ignore too small ones.
						weightedAreas[area] = #area:GetVisibleAreas()
						if area:GetSizeX() < 250 or area:GetSizeY() < 250 then
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

				computer.jcms_datadownload_cost = 500
				
				function computer:jcms_terminal_Callback(cmd, data, ply)
					if tonumber(data) and not missionData.defenseOngoing and not missionData.defenseCompleted then
						missionData.defenseOngoing = true

						if missionData.defenseAttempts == 0 then
							missionData.defenseProgress = 0
						end
						
						missionData.defenseAttempts = missionData.defenseAttempts + 1

						for i, pillar in ipairs(missionData.pillars) do
							pillar:SetIsDisrupted(false)
							pillar:SetHealth( pillar:GetMaxHealth() )
							pillar:SetHealthFraction(1)
						end

						self:EmitSound("ambient/alarms/klaxon1.wav", 150, 108, 1)
						util.ScreenShake(self:GetPos(), 3, 50, 1, 2048, true)

						if self.soundDownload then
							self.soundDownload:Stop()
							self.soundDownload = nil
						end

						self.soundDownload = CreateSound(self, "ambient/alarms/combine_bank_alarm_loop1.wav")
						self.soundDownload:PlayEx(1, 107)

						if self.soundHum then
							self.soundHum:Stop()
							self.soundHum = nil
						end

						computer.soundHum = CreateSound(computer, "ambient/machines/combine_terminal_loop1.wav")
						computer.soundHum:PlayEx(1, 107)

						jcms.net_SendTip("all", true, "#jcms.datadownload_started", tonumber(missionData.defenseProgress) or 0)
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

				-- // Generate Pillars {{{
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
								weightedAreas[area] = weightedAreas[area] * math.sqrt( math.min(closestDist, 1250) ) --doesn't matter after 1250u
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

				local function getSymbol(i, totalCount)
					if totalCount > 26 then
						local letter = string.char(65 + (i-1)%26)
						local loops = math.floor((i-1)/26)
						return letter..loops
					else
						local letter = string.char(65 + (i-1)%26)
						return letter
					end
				end

				for i, pillar in ipairs(pillars) do
					pillar:SetLabelSymbol( getSymbol(i, #pillars) )
					
					local health = 500 --TODO: We *could* make this reduce based on difficulty.
					pillar:SetMaxHealth(health)
					pillar:SetHealth(health)
				end

			-- // }}}

			jcms.mapgen_PlaceNaturals(jcms.mapgen_AdjustCountForMapSize(24), weightOverride)
			jcms.mapgen_PlaceEncounters()
		end,

		tagEntities = function(director, missionData, tags)
			local tagsActive = missionData.phase > 0
			
			if IsValid(missionData.computer) then
				tags[missionData.computer] = { name = "#jcms.obj_datadownloadcomputer", moving = false, active = tagsActive, landmarkIcon = "computer" }
			end

			for i, pillar in ipairs(missionData.pillars) do
				if IsValid(pillar) then
					tags[pillar] = { name = "^" .. pillar:GetLabelSymbol(), moving = false, active = tagsActive, type = pillar:GetIsDisrupted() and jcms.LOCATOR_WARNING or jcms.LOCATOR_GENERIC }
				end
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

				if not missionData.computerWasLocated then
					for ply, knownTags in pairs(jcms.director.tags_perplayer) do
						if knownTags[missionData.computer] then
							missionData.computerWasLocated = true
							break
						end
					end
				end
			end
			missionData.phase = phase


			if phase == 1 then
				return {
					{ type = "locatecomputer", completed = missionData.computerWasLocated },
					{ type = "prepfordefense" },
					{ type = "activatedownload" },
				}
			elseif phase == 2 then
				local objectives = {
					{ type = "uploadingatspeed", format = { missionData.powerMultiplier }, progress = missionData.defenseProgress*100, total = 100, percent = true },
				}

				for i, pillar in ipairs(missionData.pillars) do 
					if not IsValid(pillar) then continue end

					local isDisrupted = pillar:GetIsDisrupted()
					table.insert(objectives, { type = isDisrupted and "repairpillarx" or "defendpillarx", format = { pillar:GetLabelSymbol() } })
					table.insert(objectives, { type = "defendpillarx", style = 2, progress = math.ceil(pillar:Health() / pillar:GetMaxHealth() * 100), total = 100, completed = isDisrupted })
				end

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
				md.powerMultiplier = 0
			else
				if md.defenseOngoing then
					pillarsShouldBeActive = true

					if #d.npcs < 30 then 
						d.swarmNext = (d.swarmNext or jcms.director_GetMissionTime()) - 1
					end

					for i, npc in ipairs(d.npcs) do
						if not IsValid(npc) or not npc.GetEnemy or IsValid(npc:GetEnemy()) then continue end
						
						local target = md.pillars[math.random(#md.pillars)]
						npc:SetEnemy(target)
						npc:UpdateEnemyMemory(target, target:GetPos())
					end

					local totalPillars = 0
					local activePillars = 0
					for i, pillar in ipairs(md.pillars) do 
						if not IsValid(pillar) then continue end

						totalPillars = totalPillars + 1
						if not pillar:GetIsDisrupted() then activePillars = activePillars + 1 end
					end

					if activePillars > 0 then
						--5 Minutes at max power, scaling with difficulty
						--Fewer pillars exponentially slows it.

						local progressPower = (activePillars / totalPillars)^2

						if md.powerMultiplier ~= 0 and md.powerMultiplier ~= progressPower then
							if progressPower < md.powerMultiplier then
								-- Lost power
								jcms.net_SendTip("all", true, "#jcms.datadownload_destroyed", progressPower)
							else
								-- Gained power (pillars repaired)
								if progressPower >= 1 then
									jcms.net_SendTip("all", true, "#jcms.datadownload_allrepaired", math.min(1, progressPower))
								else
									jcms.net_SendTip("all", true, "#jcms.datadownload_repaired", progressPower)
								end
							end
						end
						
						md.powerMultiplier = progressPower

						progressPower = progressPower * 1/((60*5) * jcms.runprogress_GetDifficulty())

						md.defenseProgress = math.Clamp(md.defenseProgress + progressPower, 0, 1)
						md.timeEstimate = math.ceil( (1 - md.defenseProgress) / progressPower )--]]

						if md.defenseProgress >= 1 then
							md.defenseCompleted = true
							md.defenseOngoing = false
							pillarsShouldBeActive = false
						end
					else
						pillarsShouldBeActive = false

						for i, pillar in ipairs(md.pillars) do
							pillar:SetIsDisrupted(false)
							pillar:SetHealth( pillar:GetMaxHealth() )
							pillar:SetHealthFraction(1)
						end

						md.defenseOngoing = false
					end
				else
					md.powerMultiplier = 0
				end

				for i, pillar in ipairs(md.pillars) do 
					pillar:SetIsActive(pillarsShouldBeActive) 
					pillar:SetChargeFraction(md.defenseProgress)
				end
			end
			
			if IsValid(md.computer) then
				if md.computer:GetNWString("jcms_terminal_modeData") == "upload" and not md.defenseOngoing then
					-- Resetting
					if md.defenseProgress < 1 then
						jcms.net_SendTip("all", true, "#jcms.datadownload_failed", tonumber(md.defenseProgress) or 0)
						md.computer:SetNWString("jcms_terminal_modeData", tostring(md.computer.jcms_datadownload_cost))
					else
						md.computer:SetNWString("jcms_terminal_modeData", "done")
					end

					if md.computer.soundDownload then
						md.computer.soundDownload:Stop()
						md.computer.soundDownload = nil
					end
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
					return baseCost > 0 and baseCost + 4 or 0 -- More shit during the defense phase
				end
			end
		end,

		swarmCalcDanger = function(d, swarmCost)
			local phase = d.missionData.phase
			if phase == 2 then
				return math.max(d.swarmDanger, jcms.NPC_DANGER_STRONG) -- Always strongs during defense
			end
		end,

		--[[
		swarmCalcBossCount = function(d, swarmCost)
			if d.missionData.phase == 1 then
				return 0 -- No bosses during preparation phase
			end
		end,--]]

		npcTypeQueueCheck = function(d, swarmCost, dangerCap, npcType, npcData, basePassesCheck)
			local phase = d.missionData.phase
			local weightMul

			if phase == 1 then
				-- More snipers during prep.
				weightMul = ({
					["combine_sniper"] = 2.5
				})[npcType]
			elseif phase == 2 then
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
