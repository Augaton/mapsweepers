--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
    Copyright (C) 2025-2026 MerekiDor

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
ENT.PrintName = "Sniper Round"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Speed = 3000
ENT.Damage = 27

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Intercepted")
end

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate.mdl")
	self:DrawShadow(false)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:AddEFlags(EFL_DONTBLOCKLOS)
		if IsValid(self:GetPhysicsObject()) then
			self:GetPhysicsObject():Wake()
			self:GetPhysicsObject():EnableGravity(false)
		end
		self.sniper_trail = util.SpriteTrail(self, 0, Color(0, 190, 255), true, 2, 0, 0.25, 1, "sprites/bluelaser1")
	end

	if CLIENT then
		self:SetRenderBounds(Vector(-16, -16, 16), Vector(16, 16, 16))
	end

	self.ShotFrom = self:GetPos()
end

if SERVER then
	function ENT:SniperShoot(normal, attacker)
		self.Attacker = isentity(attacker) and IsValid(attacker) and attacker or NULL
		self:GetPhysicsObject():SetVelocity(normal * self.Speed)
	end

	function ENT:PhysicsCollide(data, collider)
		self:InflictDamage(data.HitEntity)
	end
	
	function ENT:InflictDamage(hitEntity)
		if self.hasHit then return end
		self.hasHit = true --We can take damage multiple times in one frame due to physics collide.

		local from, to = self.ShotFrom, self:GetPos()
		local norm = to - from
		norm:Normalize()

		local tr = util.TraceLine {
			start = from,
			endpos = to + norm*64,
			filter = { self, self.Attacker }
		}

		if IsValid(hitEntity) then
			local dmgType = bit.bor(DMG_SNIPER, DMG_BULLET)
			local dmg = DamageInfo()

			if IsValid(self.Attacker) then
				dmg:SetAttacker(self.Attacker)
			else
				dmg:SetAttacker(self)
			end
			
			dmg:SetInflictor(self)
			dmg:SetDamage(self.Damage)
			dmg:SetDamageType(dmgType)
			dmg:SetDamagePosition(self:GetPos())
			dmg:SetReportedPosition(self.ShotFrom or self:GetPos())
			hitEntity:DispatchTraceAttack(dmg, tr)
		end
		
		self:EmitSound("ambient/energy/weld2.wav", 130, 200, 1.0)

		self:Remove()
		local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetNormal(tr.Normal)
		util.Effect("MetalSpark", ed)
	end

	function ENT:GravGunOnPickedUp(user)
		self:SetIntercepted(true)

		if IsValid(self.sniper_trail) then
			self.sniper_trail:Remove()
		end

		self.sniper_trail = util.SpriteTrail(self, 0, Color(255, 0, 0), true, 4, 0, 0.5, 2, "sprites/bluelaser1")
	end

	function ENT:GravGunPunt(ply)
		self.Attacker = ply
		self.ShotFrom = ply:EyePos()
		self.Damage = math.max(self.Damage, 300)
		self:SetOwner(ply)
		return true
	end
end

if CLIENT then
	ENT.mat = Material("particle/fire")
	ENT.color_normal = Color(0, 190, 255)
	ENT.color_red1 = Color(255, 0, 0)
	ENT.color_red2 = Color(255, 128, 128)

	function ENT:Draw()
	end

	function ENT:DrawTranslucent()
		render.SetMaterial(self.mat)
		render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
		local red = self:GetIntercepted()
		if red then
			render.DrawSprite(self:GetPos(), 72, 28, self.color_red1 )
			render.DrawSprite(self:GetPos(), 32, 12, self.color_red2 )
		else
			render.DrawSprite(self:GetPos(), 64, 24, self.color_normal )
		end
		render.OverrideBlend(false)
	end
end
