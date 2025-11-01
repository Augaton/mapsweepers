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
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ore Vein"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

if SERVER then
	ENT.ModelsWithHealth = {
		-- big:
		["models/props_wasteland/rockgranite01c.mdl"] = 300,
		--["models/props_foliage/forestrock_cluster02.mdl"] = 450,
		["models/props_wasteland/rockgranite04a.mdl"] = 580,
		--["models/props_wasteland/rockcliff05a.mdl"] = 770,
		--["models/props_wasteland/rockcliff05b.mdl"] = 720,
		--["models/props_wasteland/rockcliff_cluster03c.mdl"] = 650,
		
		-- small:
		["models/props_foliage/rock_forest01.mdl"] = 75,
		["models/props_wasteland/rockgranite02c.mdl"] = 115,
		["models/props_mining/caverocks_cluster02.mdl"] = 178,
		["models/props_wasteland/rockcliff01j.mdl"] = 160,
		["models/props_wasteland/rockgranite01a.mdl"] = 230,
		["models/cliffs/rocks_medium01.mdl"] = 140
	}

	jcms.oreTypes = {
		["mafium"] = {
			color = Color(207, 183, 45),
			material = "models/jcms/ore/mafium",
			value = 1,

			proxMin = 150,
			proxMax = 1500
		},

		["argegeum"] = {
			color = Color(214, 61, 245),
			material = "models/jcms/ore/argegeum",
			value = 3,
			
			proxMin = 1500,
			proxMax = 4000
		},

		["jaycorpium"] = {
			color = Color(145, 22, 49),
			material = "models/jcms/ore/jaycorpium",
			value = 5,

			proxMin = 4000,
			proxMax = 64000
		},

		["ectoplasm"] = {
			color = Color(0, 255, 234),
			material = "models/props_combine/stasisshield_sheet",
			value = 15,

			proxMin = 3000,
			proxMax = 64000,
			weight = 0.007
		},

		["cat"] = {
			color = Color(187, 187, 187),
			material = "matsys_regressiontest/background",
			value = 20,

			proxMin = 1000,
			proxMax = 2000,
			weight = 0.0001
		}
	}

	function ENT:SetOreType(oretype)
		local data = assert(jcms.oreTypes[oretype], "unknown ore type '"..tostring(oretype).."'")
		self.OreValue = data.value
		self.OreColInt = jcms.util_ColorInteger(data.color)
		self.OreName = oretype
		self:SetMaterial(data.material)
	end
	
	function ENT:Initialize()
		self:DrawShadow(false)

		local keys = table.GetKeys(self.ModelsWithHealth)
		local mdl = keys[ math.random(1, #keys) ]
		local health = self.ModelsWithHealth[mdl]

		self:SetModel(mdl)
		self:SetHealth(health)
		self:SetMaxHealth(health)
		self:PhysicsInitStatic(SOLID_VPHYSICS)

		self.OreValue = tonumber(self.OreValue) or 1
		self.OreColInt = tonumber(self.OreColInt) or 0
		self.OreDamageAccum = 0
	end

	function ENT:OnRemove()
		local r = self:BoundingRadius()
		for i=1, math.random(6, 8) do
			local low, high = self:WorldSpaceAABB()
			local v = Vector( math.Rand( low.x, high.x ), math.Rand( low.y, high.y ), math.Rand( low.z, high.z ) )

			local ed = EffectData()
			ed:SetOrigin(v)
			ed:SetColor(self.OreColInt or 0)
			ed:SetRadius(math.Rand(0.6, 1.1)*r + i*30)
			util.Effect("jcms_oremine", ed)
		end
	end

	function ENT:OnTakeDamage(dmg)
		local attacker = dmg:GetAttacker()
		local inflictor = dmg:GetInflictor()
		if IsValid(attacker) and IsValid(inflictor) and attacker:IsPlayer() and jcms.team_JCorp_player(attacker) then
			local damageTaken = 0
			local damageAmount = dmg:GetDamage()
			local doPickSound = false
			if jcms.util_IsStunstick(inflictor) then
				self.OreDamageAccum = self.OreDamageAccum + damageAmount
				damageTaken = damageAmount
				doPickSound = true
			elseif bit.band(dmg:GetDamageType(), DMG_BLAST) > 0 then
				self.OreDamageAccum = self.OreDamageAccum + damageAmount^0.9 + 37
				damageTaken = damageAmount + 5
			end

			local didBreakSound = false
			self:SetHealth( math.min( self:Health() - damageTaken, self:Health() ) ) 

			if self:Health() <= 0 then
				self:EmitSound("ambient/levels/outland/ol01_rock_crash.wav", 120, 110)
				self.OreDamageAccum = self.OreDamageAccum + 110
				self:Remove()
				didBreakSound = true
			end

			local threshold = 50
			local pos = dmg:GetDamagePosition()
			if self.OreDamageAccum >= threshold then
				local reps = 0
				repeat
					local chunk = ents.Create("jcms_orechunk")
					chunk.jcms_miner = attacker
					chunk:SetPos(pos)
					chunk:SetAngles(AngleRand())

					chunk:SetOreType(self.OreName)
					chunk:Spawn()

					local phys = chunk:GetPhysicsObject()
					phys:Wake()
					phys:AddVelocity(VectorRand(-32, 32))

					self.OreDamageAccum = self.OreDamageAccum - threshold
					reps = reps + 1
				until (self.OreDamageAccum < threshold)

				local ed = EffectData()
				ed:SetOrigin(pos)
				ed:SetColor(self.OreColInt or 0)
				ed:SetRadius(math.Rand(50, 64 + reps*2) + math.sqrt(reps)*10 + damageTaken)
				util.Effect("jcms_oremine", ed)

				if not didBreakSound then
					if doPickSound then
						self:EmitSound("weapons/crowbar/crowbar_impact1.wav", 100, math.Rand(120, 125))
					end
					self:EmitSound("Breakable.Concrete")
				end
			else
				if doPickSound or (damageAmount >= 4 and math.random()<0.333) then
					local ed = EffectData()
					ed:SetOrigin(pos)
					ed:SetColor(self.OreColInt or 0)
					ed:SetRadius(doPickSound and (math.Rand(25, 30) + damageTaken) or damageAmount+2)
					util.Effect("jcms_oremine", ed)
				end

				if doPickSound and not didBreakSound then
					self:EmitSound("weapons/crowbar/crowbar_impact1.wav", 100, math.Rand(150, 170))
				end
			end
		end
	end

	function ENT:Think()
		self:SetSaveValue("m_vecAbsVelocity", Vector(0,0,0))

		self:NextThink(CurTime() + 1)
		return true
	end
end

if CLIENT then
	function ENT:Initialize()
		self:DrawShadow(false)
	end
end