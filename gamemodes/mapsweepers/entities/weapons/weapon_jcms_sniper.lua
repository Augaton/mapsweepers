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

SWEP.PrintName = "Sniper Rifle"
SWEP.Author = "Octantis Addons"
SWEP.Purpose = "Map Sweepers"
SWEP.Instructions = "Kill"
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = 4
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "SniperRound"
SWEP.Primary.Damage = 35
SWEP.Primary.NumBullets = 1
SWEP.Primary.Spread = 0.02
SWEP.Primary.Delay = 2.5

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

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"

SWEP.ShootSound = Sound("NPC_Sniper.FireBullet")

-- // Basics, attacking {{{

	function SWEP:SetupDataTables()
		self:NetworkVar("Vector", 0, "SniperNormal")
		self:NetworkVar("Bool", 0, "SniperAiming")

		if SERVER then
			self:SetSniperAiming(false)

			local timerId = "jcms_sniperRifleThink" ..  self:EntIndex()
			local activities = {
				[ACT_RANGE_ATTACK1] = true,
				[ACT_RANGE_ATTACK1_LOW] = true,
				[ACT_RUN_AIM] = true,
				[ACT_WALK_AIM] = true
			}
			timer.Create(timerId, 0.05, 0, function()
				if IsValid(self) then
					local owner = self:GetOwner()
					
					if IsValid(owner) and owner:IsNPC() then
						self:SetSniperNormal(owner:GetAimVector())
						self:SetSniperAiming(activities[ owner:GetActivity() ])
					end
				else
					timer.Remove(timerId)
				end
			end)
		end
	end

	function SWEP:CanPrimaryAttack()
		if self.Weapon:Clip1() <= 0 then
			self:EmitSound("Weapon_Pistol.Empty")
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
			self.Weapon:EmitSound(self.ShootSound)
			self.Weapon:EmitSound("npc/sniper/sniper1.wav", 150)
			self.Weapon:ShootEffects()
			
			local spread = self.Primary.Spread
			if self.Owner:IsNPC() then
				spread = self:GetNPCBulletSpread(self.Owner:GetCurrentWeaponProficiency())
			end

			self:ShootBullet(self.Primary.Damage, self.Primary.NumBullets, math.rad(spread), self.Primary.Ammo, 2, 1)
			self:SetLastShootTime(CurTime())
			self:TakePrimaryAmmo(1)
		end
	end

	function SWEP:ShootBullet(damage, numbullets, aimcone, ammotype, force, tracerX)
		self:ShootEffects()
		local bullet = ents.Create("jcms_sniperround")
		bullet:SetPos( (self.Owner:WorldSpaceCenter() + self.Owner:EyePos())/2 )
		bullet:SetOwner(self.Owner)
		bullet:Spawn()
		bullet.Damage = damage
		bullet.Attacker = self.Owner
		bullet:SniperShoot(self.Owner:GetAimVector(), self.Owner)
		
		local ed = EffectData()
		ed:SetEntity(self)
		ed:SetFlags(5)
		ed:SetAttachment(1)
		util.Effect("MuzzleFlash", ed)
	end

	function SWEP:DrawWorldModel()
		local owner = self.Owner -- Do not use selfTbl, owner does not exist in it
		local selfTbl = self:GetTable()
		if IsValid(owner) and owner:IsNPC() then
			owner.RenderOverride = selfTbl.NPCRifleDraw

			if EyePos():DistToSqr(self:WorldSpaceCenter()) < 1000^2 then
				self:DrawModel()
			end
		else
			self:DrawModel()
		end
	end
	
	function SWEP:CanSecondaryAttack()
		return false
	end
	
	function SWEP:SecondaryAttack()
		return false
	end

-- // }}}

-- // NPCs {{{

	function SWEP:GetNPCBurstSettings()
		return 1, 1, self.Primary.Delay
	end

	function SWEP:GetNPCRestTimes()
		return 1.5, 2.5
	end

	function SWEP:GetNPCBulletSpread(prof)
		local fuckUpChance = math.Remap(prof, WEAPON_PROFICIENCY_POOR, WEAPON_PROFICIENCY_PERFECT, 0.75, 0.03)^2
		if math.random() < fuckUpChance then
			return math.Rand(0.6, 1.3)
		else
			return math.Rand(0, 0.001)
		end
	end

	function SWEP:CanBePickedUpByNPCs()
		return true 
	end

	local spriteMat = Material("particle/fire")
	local spriteMat2 = Material("particle/Particle_Glow_04")
	local spriteLaser = Material("sprites/bluelaser1")

	function SWEP.NPCRifleDraw(npc, flags) --todo: Expensive
		if not IsValid(npc) then return end
		npc:DrawModel(flags)

		local self = npc:GetActiveWeapon()
		local selfTbl = self:GetTable()
		if not(IsValid(self) and IsValid(self.Owner) and self:GetClass() == "weapon_jcms_sniper") then return end 

		local att = self:GetAttachment(self:LookupAttachment("muzzle")) or self:GetAttachment(self:LookupAttachment("1"))

		if not att then
			att = { Pos = npc:EyePos(), Ang = npc:EyeAngles() }
		end

		local normal = att.Ang:Forward()
		--att.Pos = att.Pos + normal
		att.Pos:Add(normal)
		--local dif = EyePos() - att.Pos
		local dif = EyePos()
		dif:Sub(att.Pos)
		local dist = dif:Length()
		dif:Normalize()

		local dot = math.Clamp((dif:Dot(normal)-0.4)/0.6, 0, 1)^4 
		if dot > 0.01 then
			local scale = dist / 1000
			local superDot = math.Remap(dot, 0.6, 1, 0, 1)
			local beamCol = Color(120, 255, 255, 255*superDot)


			render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
				render.SetMaterial(spriteMat)
				render.DrawSprite(att.Pos, Lerp(dot, 0, 256)*scale, Lerp(dot^2, 0, 64)*scale, Color(0, math.Rand(128, 199), 255, math.Rand(128*dot, 255*dot)))
				
				render.SetMaterial(spriteMat2)
				if superDot > 0 then
					render.DrawQuadEasy(att.Pos, normal, math.Rand(32, 48)*scale*superDot*superDot, math.Rand(2, 10)*scale*superDot, Color(64, 200, 255, 180*superDot), math.cos(CurTime())*48)
					render.DrawQuadEasy(att.Pos, normal, math.Rand(48, 64)*scale*superDot*superDot, math.Rand(3, 12)*scale*superDot, beamCol, math.sin(CurTime())*32)
				end
			render.OverrideBlend(false)
				
			if not selfTbl.vNormal then
				selfTbl.vNormal = selfTbl:GetSniperAiming() and selfTbl:GetSniperNormal() or att.Ang:Forward()
			else
				selfTbl.vNormal = LerpVector(0.2, selfTbl.vNormal, selfTbl:GetSniperAiming() and selfTbl:GetSniperNormal() or att.Ang:Forward())
				selfTbl.vNormal:Normalize()
			end

			local tr = util.TraceLine {
				start = att.Pos, endpos = att.Pos + selfTbl.vNormal*16000, mask = MASK_OPAQUE_AND_NPCS
			}

			render.SetMaterial(spriteLaser)
			render.DrawBeam(tr.StartPos, tr.HitPos, superDot*math.Rand(0.5, 0.95)*scale, 0, 1, beamCol)
		end
	end

-- // }}}

-- // Animations and activities {{{

	local actTrans = {
		[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN,
		[ACT_MP_WALK] = ACT_HL2MP_WALK_SHOTGUN,
		[ACT_MP_RUN] = ACT_HL2MP_RUN_SHOTGUN,
		[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		[ACT_MP_JUMP] = ACT_HL2MP_JUMP_CROSSBOW,
		[ACT_MP_AIRWALK] = ACT_HL2MP_JUMP_AR2,
		[ACT_MP_SWIM] = ACT_HL2MP_SWIM_AR2,
		[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_AR2,
		[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_AR2,
		[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_AR2,
		[ACT_MP_SWIM_IDLE] = ACT_HL2MP_SWIM_AR2
	}

	local actTransNPC = {
		[ACT_IDLE] = ACT_IDLE_SMG1_STIMULATED,
		[ACT_IDLE_STIMULATED] = ACT_IDLE_SMG1_STIMULATED,
		[ACT_IDLE_ANGRY] = ACT_IDLE_ANGRY_SMG1,
		[ACT_IDLE_AGITATED] = ACT_IDLE_ANGRY_SMG1,
		[ACT_IDLE_RELAXED] = ACT_IDLE_SMG1_RELAXED,
		[ACT_RANGE_ATTACK1] = ACT_RANGE_ATTACK_AR2,
		[ACT_RANGE_ATTACK1_LOW] = ACT_RANGE_ATTACK_AR2_LOW,
		[ACT_WALK] = ACT_WALK_RIFLE,
		[ACT_WALK_AIM] = ACT_WALK_AIM_RIFLE,
		[ACT_RUN] = ACT_RUN_RIFLE,
		[ACT_RUN_AIM] = ACT_RUN_AIM_RIFLE,
		[ACT_RUN_RELAXED] = ACT_RUN_AIM_RIFLE_STIMULATED,
		[ACT_RUN_AGITATED] = ACT_RUN_AIM_RIFLE_STIMULATED,
		[ACT_RELOAD] = ACT_RELOAD_SMG1,
		[ACT_GESTURE_RANGE_ATTACK1] = ACT_GESTURE_RANGE_ATTACK_AR2
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
