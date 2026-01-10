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
ENT.PrintName = "Vanguard Backpack"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Radius = 600
ENT.ChargePerSecond = 5
ENT.ChargeInterval = 0.5

ENT.Damage = 2
ENT.TeslaRadius = 350
ENT.ChainRadius = 250
ENT.ChainSteps = 6
ENT.FireRate = 0.45

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_combine/combine_light002a.mdl")
		self:SetColor(Color(162, 81, 255))
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		
		self:SetMaxHealth(20)
		self:SetHealth(20)
		
		self.soundCharge = CreateSound(self, "ambient/machines/combine_shield_touch_loop1.wav")

		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

		self:SetModelScale(0.75)

		self.nextZap = CurTime()
	end
end

if SERVER then
	function ENT:OnRemove()
		if self.soundCharge then
			self.soundCharge:Stop()
		end
	end	
	
	function ENT:TeslaEffect(target)
		target = target or self

		local tPos = target:WorldSpaceCenter()
		local effectdata = EffectData()
		effectdata:SetStart(tPos)
		effectdata:SetOrigin(tPos)
		effectdata:SetMagnitude(2)
		effectdata:SetNormal(vector_up)
		effectdata:SetScale(5)
		effectdata:SetEntity(target)
		util.Effect("TeslaHitboxes", effectdata)
	end
	
	function ENT:Think()
		local charging = false

		if self:Health() > 0 then 
			local selfCentre = self:WorldSpaceCenter()
			for i, ent in ipairs(ents.FindInSphere(selfCentre, math.max(self.Radius, self.TeslaRadius))) do 
				if ent:IsNPC() and ent:WorldSpaceCenter():DistToSqr(selfCentre) < self.Radius^2 then 
					local maxShield = ent:GetNWInt("jcms_sweeperShield_max", -1)
					if not(maxShield == -1) and (ent:GetNWInt("jcms_sweeperShield", -1) < maxShield) then
						charging = true
						self:ChargeShield(ent)
					end
				elseif ent:IsPlayer() and self.nextZap < CurTime() and ent:WorldSpaceCenter():DistToSqr(selfCentre) < self.TeslaRadius^2 then
					self:Zap(ent)
				end
			end
		else
			util.BlastDamage(self, IsValid(self.jcms_owner) and self.jcms_owner or self, self:WorldSpaceCenter(), 150, 100)

			local pos = self:WorldSpaceCenter()
			local ed = EffectData()
			ed:SetMagnitude(1)
			ed:SetOrigin(pos)
			ed:SetRadius(140)
			ed:SetNormal(self:GetAngles():Up())
			ed:SetFlags(1)
			util.Effect("jcms_blast", ed)
			util.Effect("Explosion", ed)
			self:Remove()
		end

		if self.soundCharge then
			if charging then
				if not self.soundCharge:IsPlaying() then
					self.soundCharge:PlayEx(1, 110)
				else
					self.soundCharge:ChangePitch(110)
				end
				
				local chargePitch = 130
				self.soundCharge:ChangePitch(chargePitch, self.ChargeInterval/2)
			else
				if self.soundCharge:IsPlaying() and self.soundCharge:GetVolume() <= 0 then
					self.soundCharge:Stop()
				else
					self.soundCharge:ChangeVolume(0, 0.25)
					self.soundCharge:ChangePitch(1, 0.25)
				end
			end
		end
		
		if math.random() < 0.25 then 
			self:TeslaEffect()
		end

		self:NextThink(CurTime() + self.ChargeInterval)
		return true
	end

	function ENT:ChargeShield(npc)
		local armour = npc:GetNWInt("jcms_sweeperShield")
		local maxArmour = npc:GetNWInt("jcms_sweeperShield_max")
		local chargeAmount = math.Clamp(maxArmour - armour, 0, self.ChargePerSecond*self.ChargeInterval)


		npc:SetNWInt("jcms_sweeperShield", armour + chargeAmount)
		
		local ed = EffectData()
		ed:SetFlags(0)
		ed:SetOrigin(self:WorldSpaceCenter())
		ed:SetEntity(npc)
		util.Effect("jcms_chargebeam", ed)
	end
	
	function ENT:Zap(target)
		local selfPos = self:GetPos()
		local targetPos = target:GetPos()

		local damageinfo = DamageInfo()
		damageinfo:SetAttacker(self.jcms_owner)
		damageinfo:SetInflictor(self)
		damageinfo:SetDamage(self.Damage)
		damageinfo:SetDamageType( DMG_SHOCK )
		damageinfo:SetReportedPosition(selfPos)
		damageinfo:SetDamagePosition(targetPos)
		target:TakeDamageInfo(damageinfo)
		
		self:TeslaEffect()
		timer.Simple(0.1, function() 
			if IsValid(self) then 
				self:TeslaEffect() 
			end
		end)
		self:TeslaEffect(target)

		self:EmitSound("Weapon_StunStick.Melee_HitWorld")

		local ed = EffectData()
		ed:SetStart(self:WorldSpaceCenter())
		ed:SetOrigin(target:WorldSpaceCenter())
		util.Effect("jcms_tesla", ed)

		local hitBefore = { self = true, ent = true }
		for i=1, self.ChainSteps do
			local bestDist2, bestTarget = self.ChainRadius*self.ChainRadius+1
			local targetPos = target:WorldSpaceCenter()
			
			for j, near in ipairs(ents.FindInSphere(targetPos, self.ChainRadius)) do
				if (not hitBefore[near]) and (near:Health() > 0 and near:Health() <= target:Health() + self.Damage) and jcms.team_GoodTarget(near) then
					local dist2 = targetPos:DistToSqr(near:WorldSpaceCenter())
					if (not bestTarget) or (dist2 < bestDist2) then
						bestTarget = near
						bestDist2 = dist2
					end
				end
			end
			
			local previous = target
			target = bestTarget
			
			if IsValid(target) then
				hitBefore[target] = true
				
				damageinfo:ScaleDamage(1 - 1/self.ChainSteps)
				target:TakeDamageInfo(damageinfo)
				
				self:TeslaEffect(target)
				
				local ed = EffectData()
				ed:SetStart(previous:WorldSpaceCenter())
				ed:SetOrigin(target:WorldSpaceCenter())
				util.Effect("jcms_tesla", ed)
			else
				break
			end
		end

		self.nextZap = CurTime() + self.FireRate
	end
	
	function ENT:OnTakeDamage(dmg)
		local inflictor, attacker = dmg:GetInflictor(), dmg:GetAttacker()
		
		self:SetHealth(self:Health() - dmg:GetDamage())
		return 0
	end
end

--[[
if CLIENT then
	function ENT:Think()
		local ed = EffectData()
		ed:SetEntity(self)
		ed:SetMagnitude(4)
		ed:SetScale(0.25)
		util.Effect("TeslaHitBoxes", ed)

		self:SetNextClientThink(CurTime() + 0.15 + math.Rand(0, 0.1))
		return true 
	end
end
--]]