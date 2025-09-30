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
ENT.PrintName = "Download Pillar"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "HealthFraction")
	self:NetworkVar("Float", 1, "ChargeFraction")
	self:NetworkVar("Bool", 0, "IsActive")
	self:NetworkVar("Bool", 1, "IsDisrupted")
	self:NetworkVar("String", 0, "LabelSymbol")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_combine/combine_mortar01a.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		
		self:SetMaxHealth(500)
		self:SetHealth(500)
		 
		self.nextDamageAllowed = 0
		self.nextHealthThreshold = 0.95

		self.bullseyes = {}
		local pos = self:WorldSpaceCenter()
		local ang = self:GetAngles()
		for i=1, 6, 1 do 
			local ent = ents.Create("jcms_bullseye")

			local nPos, nAng = Vector(pos), Angle(ang)
			nAng:RotateAroundAxis(nAng:Up(), 360 / 6 * (i-1))
			nPos:Add(nAng:Forward()*24)
			nPos:Add(nAng:Up()*12)
			
			ent:SetPos(nPos)
			ent:Spawn()
			ent.DamageTarget = self

			ent:AddFlags(FL_NOTARGET)
			table.insert(self.bullseyes, ent)
		end
	end

	if CLIENT then
		self.beamShape = {}
		self.nextBeamShape = 0
	end
end

if SERVER then
	function ENT:OnRemove()
		for i, ent in ipairs(self.bullseyes) do
			if IsValid(ent) then
				ent:Remove()
			end
		end
	end

	function ENT:Think()
		local active = self:Health() > 0 and self:GetIsActive() and not self:GetIsDisrupted()
		
		for i, ent in ipairs(self.bullseyes) do
			if IsValid(ent) then
				if active then
					ent:RemoveFlags( FL_NOTARGET )
				else
					ent:AddFlags( FL_NOTARGET )
				end
			end
		end
	end

	function ENT:OnTakeDamage(dmg)
		if not self:GetIsActive() then
			return 0
		end

		local inflictor, attacker = dmg:GetInflictor(), dmg:GetAttacker()
		if IsValid(inflictor) and jcms.util_IsStunstick(inflictor) and jcms.team_JCorp(attacker) then
			jcms.util_PerformRepairs(self, attacker, 25)

			if self:Health() >= self:GetMaxHealth() then
				self.nextHealthThreshold = 0.5
				self.nextDamageAllowed = CurTime() + 3
				self:SetIsDisrupted(false)
			end

			self:SetHealthFraction( self:Health() / self:GetMaxHealth() )
			return 0
		end


		if jcms.team_JCorp(attacker) then
			dmg:SetDamage( dmg:GetDamage() * 0.5 * jcms.cvar_ffmul:GetFloat() )
		end

		dmg:SetDamage( math.ceil(math.max(dmg:GetDamage() - 1, 0)^0.8) ) 

		if not self.nextDamageAllowed or CurTime() > self.nextDamageAllowed then
			local newHealth = math.Clamp(self:Health() - dmg:GetDamage(), 0, self:Health())

			local limit = self:GetMaxHealth() * self.nextHealthThreshold
			if newHealth < limit then
				newHealth = limit
				self.nextHealthThreshold = self.nextHealthThreshold - 0.25
				self.nextDamageAllowed = CurTime() + 2
			end

			self:SetHealth(newHealth)
			self:SetHealthFraction( self:Health() / self:GetMaxHealth() )
			
			if newHealth == 0 then
				self:SetIsDisrupted(true)
			end
		else
			return 0
		end
	end
end

if CLIENT then
	ENT.mat_beam = Material("trails/laser")
	ENT.mat_glow = Material("particle/fire")
	ENT.mat_lamp = Material("effects/lamp_beam.vmt")

	ENT.labelColour1 = Color(32, 192, 255)
	ENT.labelColour2 = Color(168, 230, 255)

	function ENT:Think()
		if not self:GetIsDisrupted() and CurTime() > self.nextBeamShape then
			table.Empty(self.beamShape)
			local pos = self:GetPos()
			pos.z = pos.z - 50.8
			for i=1, 48 do
				table.insert(self.beamShape, Vector(pos))
			
				if i%2 == 1 then
					pos.z = pos.z + math.random(16, 32)
				else
					local a = math.random()*math.pi*2
					local dist = math.Rand(4, 6)
					local cos, sin = math.cos(a), math.sin(a)
					pos.x = pos.x + cos*dist
					pos.y = pos.y + sin*dist
					pos.z = pos.z + dist
				end
			end

			self.nextBeamShape = CurTime() + math.Rand(0.05, 1)
		end
	end

	function ENT:DrawTranslucent()
		local sym = self:GetLabelSymbol()
		if sym then
			local d = 17
			local pos = self:GetPos()
			local ang = self:GetAngles()
			pos = pos + ang:Up() * 54
			ang:RotateAroundAxis(ang:Forward(), 90)
			ang:RotateAroundAxis(ang:Up(), 180)
			pos:Add(ang:Up() * d)
			
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			for i=1, 2 do
				cam.Start3D2D(pos, ang, 1/4)
					draw.SimpleText(sym, "jcms_hud_huge", math.Rand(-1, 1), math.Rand(-1, 1), self.labelColour1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					draw.SimpleText(sym, "jcms_hud_huge", math.Rand(-3, 3), math.Rand(-2, 2), self.labelColour2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cam.End3D2D()

				if i == 1 then
					ang:RotateAroundAxis(ang:Right(), 180)
					pos:Add(ang:Up() * (d * 2))
				end
			end
			render.OverrideBlend( false )
		end

		if self:GetIsActive() then
			local t = CurTime() + self:EntIndex()*math.pi/7
			if self:GetIsDisrupted() then
				local blip = t%0.5<0.25
				render.SetMaterial(self.mat_lamp)
				local col = Color(blip and 255 or 0, blip and 30 or 255, blip and 32 or 255, 128)
				if not self.beamShape[1] then return end --Lua-error fix

				render.DrawBeam(self.beamShape[1], self.beamShape[#self.beamShape], 64, 0, 1, col)
			else
				render.SetMaterial(self.mat_beam)

				local progress = self:GetChargeFraction()

				local n = #self.beamShape
				local color1 = Color(255, 77+60*progress, 77+60*progress)
				local color2 = Color(64, 235+20*progress, 245)
				
				local encounterVector
				render.StartBeam(n)
				for i, v in ipairs(self.beamShape) do
					render.AddBeam(v, 24, i/n, i/n>progress and color2 or color1)

					if not encounterVector and i/n>progress then
						encounterVector = self.beamShape[i-1] or v
					end
				end
				render.EndBeam()

				render.SetMaterial(self.mat_glow)
				render.DrawSprite(self.beamShape[n], 256, 64, progress >= 0.95 and color1 or color2)
				if encounterVector then
					render.DrawSprite(encounterVector, 128, 32, color1)
				end
			end
		end
	end
end