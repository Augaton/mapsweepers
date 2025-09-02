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
			-- Password gen {{{
				local password = ""
				for i = 1, 6 do
					password = password .. math.random(0, 9)
				end
				missionData.password = password
			-- }}}
			
			-- Clue gen {{{
				local termCount = math.Clamp(jcms.mapgen_AdjustCountForMapSize(3 + math.ceil(jcms.runprogress_GetDifficulty())) - 2, 3, 16)
				local clues = {}
				local reveals = { 0, 0, 0, 0, 0, 0 }
				for i=1, termCount do
					local weights = {}

					local foundZero = false
					for j,w in ipairs(reveals) do
						if w == 0 then
							foundZero = true
							break
						end
					end

					if foundZero then
						for j, w in ipairs(reveals) do
							if w == 0 then
								weights[j] = 1
							end
						end
					else
						for j, w in ipairs(reveals) do
							weights[j] = 2 / (w*w+1)
						end
					end

					local id1 = jcms.util_ChooseByWeight(weights)
					weights[id1] = 0
					local id2 = jcms.util_ChooseByWeight(weights)

					reveals[id1] = reveals[id1] + 1
					reveals[id2] = reveals[id2] + 1

					local clue = ""
					for j=1, 6 do
						if (j == id1) or (j == id2) then
							clue = clue .. password:sub(j, j)
						else
							clue = clue .. "_"
						end
					end

					clues[i] = clue
				end

				local terminals = jcms.mapgen_SpreadPrefabs("datadownload_passwordclue", termCount, 72, termCount <= 9)
				for i, term in ipairs(terminals) do
					term.jcms_passwordClue = clues[i]
				end

				missionData.terminals = terminals -- Terminal entities containing clues
				missionData.clues = clues -- Actual clues (as in, strings)
			-- }}}

			-- Defense phase {{{
				missionData.defenseOngoing = false
				missionData.defenseCompleted = false
				missionData.defenseAttempts = 0
				missionData.defenseProgress = 0
			-- }}}

			-- The computer {{{
				local spawnedPrefabs = jcms.mapgen_SpreadPrefabs("datadownload_computer", 1, 200, true)
				local computer = spawnedPrefabs[1]
				assert(IsValid(computer), "Can't place down the main computer. This map sucks, find a better one")
				assert(IsValid(computer.pillar1) and IsValid(computer.pillar2), "Can't place down the computer pillars. Maybe your entity limit has been hit?")

				computer.jcms_password = password
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
				missionData.pillar1 = computer.pillar1
				missionData.pillar2 = computer.pillar2

				local adjustedDifficulty = math.max(1, jcms.runprogress_GetDifficulty()) ^ (2/3)
				local health = math.ceil( 500 * adjustedDifficulty )
				missionData.pillar2:SetMaxHealth(health)
				missionData.pillar2:SetHealth(health)
			-- }}}

			jcms.mapgen_PlaceNaturals(jcms.mapgen_AdjustCountForMapSize(24), weightOverride)
			jcms.mapgen_PlaceEncounters()
		end,

		tagEntities = function(director, missionData, tags)
			if IsValid(missionData.computer) then
				tags[missionData.computer] = { name = "#jcms.obj_datadownloadcomputer", moving = false, active = true, landmarkIcon = "computer" }
			end

			if missionData.phase == 1 then
				for i, term in ipairs(missionData.terminals) do
					if IsValid(term) then
						tags[term] = { name = "#jcms.datadownload_terminal", moving = false, active = term:GetNWBool("jcms_terminal_locked") }
					end
				end
			end
		end,

		getObjectives = function(missionData)
			local phase = 0 -- Evacuating
			if IsValid(missionData.computer) and (missionData.defenseAttempts == 0 and missionData.computer:GetNWBool("jcms_terminal_locked")) then
				phase = 1 -- Getting to know the password
			elseif IsValid(missionData.computer) and IsValid(missionData.pillar1) and IsValid(missionData.pillar2) then
				if missionData.defenseCompleted then
					phase = 0 -- Evac
				elseif missionData.defenseOngoing then
					phase = 3 -- Combat
				else
					phase = 2 -- Preparing for defense
				end
			end
			missionData.phase = phase

			if phase == 1 then
				local pw = missionData.password
				local known = { "_", "_", "_", "_", "_", "_" }
				
				for i, term in ipairs(missionData.terminals) do
					local thisIsKnown = false
					if IsValid(term) and term.jcms_passwordClue then
						thisIsKnown = not term:GetNWBool("jcms_terminal_locked")
					else
						thisIsKnown = true
					end

					if thisIsKnown then
						for j=1, 6 do
							local sym = missionData.clues[i]:sub(j, j)
							if tonumber(sym) then
								known[j] = sym
							end
						end
					end
				end

				local knownPieces = 0
				for i, v in ipairs(known) do
					if v ~= "_" then
						knownPieces = knownPieces + 1
					end
				end

				if knownPieces > (missionData.lastKnownPieces or 0) then
					missionData.lastKnownPieces = knownPieces
					local progress = knownPieces / 6
					if progress >= 1 then
						jcms.net_SendTip("all", true, "#jcms.datadownload_completion2", 1)
					else
						jcms.net_SendTip("all", true, "#jcms.datadownload_completion1", progress)
					end
				end

				local knownString = table.concat(known, " ")

				return {
					{ type = "obtainpassword", progress = knownPieces, total = 6, completed = knownPieces >= 6 },
					{ type = "passwordclue", format = { knownString } },
					{ type = "datadownloadgainaccess" }
				}
			elseif phase == 2 then
				if not missionData.computerHasBeenHacked then
					jcms.net_SendTip("all", true, "#jcms.datadownload_completion3", 1)
					missionData.computerHasBeenHacked = true
				end

				return {
					{ type = "prepfordefense" },
					{ type = "activatedownload" }
				}
			elseif phase == 3 then
				local disrupted1 = missionData.pillar1:GetIsDisrupted()
				local disrupted2 = missionData.pillar2:GetIsDisrupted()
				return {
					{ type = "surv", style = 1, progress = missionData.timeEstimate or 0 },
					{ type = disrupted1 and "repairpillarx" or "defendpillarx", format = { "A" } },
					{ type = "defendpillarx", style = 2, progress = math.ceil(missionData.pillar1:Health() / missionData.pillar1:GetMaxHealth() * 100), total = 100 },
					{ type = disrupted2 and "repairpillarx" or "defendpillarx", format = { "B" } },
					{ type = "defendpillarx", style = 2, progress = math.ceil(missionData.pillar2:Health() / missionData.pillar2:GetMaxHealth() * 100), total = 100 }
				}
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
			if IsValid(md.pillar1) and IsValid(md.pillar2) then
				local pillarsShouldBeActive = false

				if md.defenseCompleted then
					md.defenseProgress = 1
				else
					if md.defenseOngoing then
						pillarsShouldBeActive = true

						local activePillars = 0
						if not md.pillar1:GetIsDisrupted() then activePillars = activePillars + 1 end
						if not md.pillar2:GetIsDisrupted() then activePillars = activePillars + 1 end

						if activePillars > 0 then
							-- If both pillars are active, it takes 4 minutes to charge up
							-- If only one pillar is active, it takes 12 minutes instead
							
							local progressPower = (activePillars == 2) and (1 / 240) or (1 / 720)
							md.defenseProgress = math.Clamp(md.defenseProgress + progressPower, 0, 1)

							md.timeEstimate = math.ceil( (1 - md.defenseProgress) / progressPower )

							if md.defenseProgress >= 1 then
								md.defenseCompleted = true
								md.defenseOngoing = false
							end
						else
							pillarsShouldBeActive = false

							md.pillar1:SetIsDisrupted(false)
							md.pillar2:SetIsDisrupted(false)

							md.pillar1:SetHealth( md.pillar1:GetMaxHealth() )
							md.pillar2:SetHealth( md.pillar2:GetMaxHealth() )

							md.pillar1:SetHealthFraction(1)
							md.pillar2:SetHealthFraction(1)

							md.defenseOngoing = false
							md.defenseProgress = 0
						end
					else
						md.defenseProgress = 0
					end
				end

				md.pillar1:SetIsActive(pillarsShouldBeActive)
				md.pillar1:SetChargeFraction(md.defenseProgress)

				md.pillar2:SetIsActive(pillarsShouldBeActive)
				md.pillar2:SetChargeFraction(md.defenseProgress)
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
					["combine_gunship"] = 0.5
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
