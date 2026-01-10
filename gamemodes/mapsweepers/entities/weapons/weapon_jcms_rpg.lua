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

SWEP.PrintName = "RPG"
SWEP.Author = "Octantis Addons"
SWEP.Purpose = "Map Sweepers"
SWEP.Instructions = "Kill"
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "RPG_Round"
SWEP.Primary.Damage = 90
SWEP.Primary.BlastRadius = 150
SWEP.Primary.Delay = 1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom	= false

SWEP.Slot = 4
SWEP.SlotPos = 2
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands = true

SWEP.ShootSound = "weapons/rpg/rocketfire1.wav"

-- // Attack {{{
	function SWEP:CanPrimaryAttack()
		if self.Weapon:Clip1() <= 0 then
			self:EmitSound("Weapon_Pistol.Empty")
			self:SetNextPrimaryFire(CurTime() + 1)
			return false
		elseif IsValid(self.missile) then -- Don't fire while we already have one.
			self:SetNextPrimaryFire(CurTime() + 1)
			return false
		else
			return true
		end
	end

	function SWEP:PrimaryAttack()
		if not IsValid(self.Weapon) then return end

		if SERVER and self:CanPrimaryAttack() then
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
			self.Weapon:EmitSound(self.ShootSound, 100)

			self:ShootBullet()
			self:TakePrimaryAmmo(1)
		end
	end

	function SWEP:ShootBullet()
		self:ShootEffects()

		local missile = ents.Create("jcms_micromissile")
		local owner = self:GetOwner()

		local originPos = owner:EyePos()
		if owner:IsPlayer() then
			originPos:Add( owner:EyeAngles():Right() * 4 )
		end

		missile:SetPos(originPos)
		missile:SetAngles(owner:GetAimVector():Angle())
		missile:SetOwner(owner)
		missile.Damage = self.Primary.Damage
		missile.Radius = self.Primary.BlastRadius
		missile.Proximity = self.Primary.BlastRadius/4
		
		if owner.jcms_odessaRocketJumped then
			missile.Damage = missile.Damage * 1.5 + 5
		end

		local tPos = (owner:IsNPC() and owner:GetEnemyLastKnownPos()) or owner:GetEyeTrace().HitPos
		missile.Target = tPos
		missile.Damping = 1 
		missile.Speed = 1250
		missile.ActivationTime = CurTime() + 0.05
		missile.jcms_owner = owner

		local col = jcms.factions_GetColor(IsValid(owner) and owner.jcms_faction)
		missile:SetBlinkColor( Vector(col.r/255, col.g/255, col.b/255) )
		missile:Spawn()

		missile:EmitSound("weapons/rpg/rocket1.wav", 100)
		
		missile:CallOnRemove( "jcms_rpg_removeMissile", function()
			missile:StopSound("weapons/rpg/rocket1.wav")
		end)

		missile.Arc = 0.35

		local tr = util.TraceLine({
			start = tPos,
			endpos = tPos + Vector(0,0,32768)
		})
		if not tr.HitSky then --Lower our arc indoors.
			missile.Arc = 0.1
		end

		missile.jcms_isPlayerMissile = false

		self.missile = missile 

		local ed = EffectData()
		ed:SetEntity(self)
		ed:SetFlags(7)
		ed:SetAttachment(1)
		util.Effect("MuzzleFlash", ed)
	end

	function SWEP:CanSecondaryAttack()
		return IsValid(self.missile)
	end
	
	function SWEP:SecondaryAttack()
		if self:CanSecondaryAttack() then
			self:EmitSound("buttons/button3.wav", 75, 150)
			local missile = self.missile
			missile:Detonate()
		else
			self:EmitSound("buttons/button10.wav", 75, 130)
		end
	end
-- // }}}

-- // NPCs {{{
	function SWEP:GetNPCBurstSettings()
		return 99, 99, self.Primary.Delay
	end

	function SWEP:GetNPCRestTimes()
		return 1.5, 2.5
	end
	
	function SWEP:CanBePickedUpByNPCs()
		return true 
	end
-- }}}

-- // Animations and activities {{{

	local actTrans = {
		[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_RPG,
		[ACT_MP_WALK] = ACT_HL2MP_RUN_RPG,
		[ACT_MP_RUN] = ACT_HL2MP_RUN_RPG,
		[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
		[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
		[ACT_MP_JUMP] = ACT_HL2MP_SWIM_RPG,
		[ACT_MP_AIRWALK] = ACT_HL2MP_SWIM_RPG,
		[ACT_MP_SWIM] = ACT_HL2MP_SWIM_RPG,
		[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_RPG,
		[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_RPG,
		[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_RPG,
		[ACT_MP_SWIM_IDLE] = ACT_HL2MP_SWIM_RPG
	}

	local actTransNPC = {
		[ACT_IDLE] = ACT_IDLE_ANGRY_RPG,
		[ACT_IDLE_STIMULATED] = ACT_IDLE_ANGRY_RPG,
		[ACT_IDLE_ANGRY] = ACT_IDLE_ANGRY_RPG,
		[ACT_IDLE_AGITATED] = ACT_IDLE_ANGRY_RPG,
		[ACT_IDLE_RELAXED] = ACT_IDLE_RPG_RELAXED,
		[ACT_RANGE_ATTACK1] = ACT_RANGE_ATTACK_RPG,
		[ACT_RANGE_ATTACK1_LOW] = ACT_RANGE_ATTACK_RPG,
		[ACT_WALK] = ACT_WALK_RPG,
		[ACT_WALK_AIM] = ACT_WALK_RPG,
		[ACT_RUN] = ACT_RUN_RPG,
		[ACT_RUN_AIM] = ACT_RUN_RPG,
		[ACT_RUN_RELAXED] = ACT_RUN_RPG,
		[ACT_RUN_AGITATED] = ACT_RUN_RPG,
		[ACT_RELOAD] = ACT_RELOAD_SMG1,
		[ACT_GESTURE_RANGE_ATTACK1] = ACT_GESTURE_RANGE_ATTACK_ML
	}

	function SWEP:TranslateActivity(act)
		if self:GetOwner():IsNPC() then
			return actTransNPC[act] or actTrans[act] or act
		elseif self:GetOwner():IsPlayer() then
			return actTrans[act] or act
		end
		return -1
	end
-- // }}}