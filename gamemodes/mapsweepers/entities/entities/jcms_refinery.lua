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
ENT.PrintName = "Refinery"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsOreRefinery")
	self:NetworkVar("Int", 0, "ValueInside")
	self:NetworkVar("Int", 1, "TimesGround")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_lab/scrapyarddumpster_static.mdl")

		if self:GetIsOreRefinery() then --Secondary Refinery
			self:SetModel("models/props_junk/trashdumpster01a.mdl")
		end
        self:PhysicsInitStatic(SOLID_VPHYSICS)
	end

	function ENT:PhysicsCollide(colData, collider)
		local ent = colData.HitEntity
		local mass = tonumber(ent.jcms_oreMass) or 0
		local value = tonumber(ent.jcms_oreValue) or 1
		if mass and mass*value > 0 then
			local obtained = math.max(0, ent:GetWorth())
			self:SetValueInside( self:GetValueInside() + obtained )

			ent.jcms_oreMass = nil
			ent.jcms_oreValue = nil
			ent:Remove()

			local ed = EffectData()
			ed:SetOrigin(ent:WorldSpaceCenter())
			ed:SetColor(ent:GetOreColourInt())
			ed:SetRadius(obtained)
			util.Effect("jcms_oremine", ed)

			if type(self.OnRefine) == "function" then
				local miner = IsValid(ent.jcms_miner) and ent.jcms_miner or nil
				local bringer = IsValid(ent.jcms_lastPickedUp) and ent.jcms_lastPickedUp or nil

				local canRefine = false
				if miner and bringer then
					canRefine = true
				elseif miner and not bringer then
					bringer = miner
					canRefine = true
				elseif not miner and bringer then
					bringer = miner
					canRefine = true
				end

				if canRefine then
					self:OnRefine(ent, miner, bringer, obtained, mass, value)
				end
			end

			self:SetTimesGround(self:GetTimesGround() + 1)
		end
	end

	function ENT:Think()
		self:SetSaveValue("m_vecAbsVelocity", Vector(0,0,0))

		self:NextThink(CurTime() + 1)
		return true
	end
end

if CLIENT then
	function ENT:OnRemove()
		if self.sfxGrind then
			self.sfxGrind:Stop()
			self.sfxGrind = nil
		end
	end

	function ENT:Think()
		local dist2 = jcms.EyePos_lowAccuracy:DistToSqr(self:WorldSpaceCenter())

		if dist2 <= 1000000 then
			if not self.sfxGrind then
				if self:GetIsOreRefinery() then
					self.sfxGrind = CreateSound(self, "vehicles/crane/crane_idle_loop3.wav")
				else
					self.sfxGrind = CreateSound(self, "vehicles/digger_grinder_loop1.wav")
				end
				self.sfxGrind:PlayEx(0, 80)
			end

			self.grindFactor = math.max(0, (self.grindFactor or 0) - FrameTime()*0.4)

			if self.grindFactor > 0 and (not self.nextBoulderSFX or CurTime() > self.nextBoulderSFX) then
				self:EmitSound("Breakable.Concrete")
				self.nextBoulderSFX = CurTime() + math.Rand(0.06, 0.2) 
			end

			local timesGround = self:GetTimesGround()
			if timesGround ~= self.timesGroundCl and timesGround > 0 then
				self.timesGroundCl = timesGround
				self.grindFactor = math.min(self.grindFactor + 0.6, 1)
			end

			local pitch = 80 + self.grindFactor*40
			local vol = math.Clamp(math.Remap(dist2, 1000000, 10000, 0, 1), 0, self:GetIsOreRefinery() and 1 or (0.5+self.grindFactor*0.5))
			self.sfxGrind:ChangePitch(pitch, 0.1)
			self.sfxGrind:ChangeVolume(vol, 0.1)
		else
			if self.sfxGrind then
				self.sfxGrind:Stop()
				self.sfxGrind = nil
			end
		end
	end
end