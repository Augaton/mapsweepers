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
local class = {}
jcms.class_Add("npc_zombine", class)

class.faction = "zombie"
class.mdl = "models/zombie/zombie_soldier.mdl"
class.deathSound = "NPC_FastZombie.Die"
class.footstepSfx = "NPC_CombineS.RunFootstep"

class.health = 175
class.shield = 0
class.shieldRegen = 0
class.shieldDelay = 64

class.damage = 1
class.hurtMul = 0.9
class.hurtReduce = 1
class.speedMul = 1
class.jumpPower = 200
class.walkSpeed = 100
class.runSpeed = 150
class.boostedRunSpeed = 250
class.disallowSprintAttacking = true

class.playerColorVector = Vector(0.6, 0, 0)

function class.OnSpawn(ply)
	local weapon = ply:Give("weapon_jcms_playernpc", false)
	weapon:SetNWInt("jcms_npcspecial", 1)
	ply.jcms_bounty = 40
	ply:SetBodygroup(1, 1)

	local timerId = "jcms_pNPCRegen" .. ply:EntIndex()
	timer.Create(timerId, 1, 0, function()
		if IsValid(ply) and ply:Alive() and ply:GetNWString("jcms_class") == "npc_zombine" then
			if ply:Health() < ply:GetMaxHealth() then
				ply:SetHealth( ply:Health() + 1 )
			end
		else
			timer.Remove(timerId)
		end
	end)
end

function class.PrimaryAttack(ply, wep)
	if ply.zombieFrenzy then return end

	wep.Primary.Automatic = true
	wep:SetNextPrimaryFire(CurTime() + 0.8)

	local tr = util.TraceHull {
		start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * 48,
		mask = MASK_PLAYERSOLID, filter = { ply, wep }, mins = Vector(-8, -8, -12), maxs = Vector(8, 8, 12)
	}

	if (CurTime() - (wep.lastAttackSound or 0) > 2.5) then
		ply:EmitSound("npc/zombine/zombine_charge" .. math.random(1, 2) .. ".wav")
		wep.lastAttackSound = CurTime()
	end

	if tr.Hit then
		ply:ViewPunch( AngleRand(-4, 4) )
		ply:EmitSound("NPC_FastZombie.AttackHit")

		if IsValid(tr.Entity) and tr.Entity:Health() > 0 and not tr.Entity.jcms_canHurtSelfAsNPC then
			local dmg = DamageInfo()
			dmg:SetAttacker(ply)
			dmg:SetInflictor(ply)
			dmg:SetDamageType(DMG_SLASH)
			dmg:SetReportedPosition(ply:GetPos())
			dmg:SetDamagePosition(tr.HitPos)
			dmg:SetDamageForce(tr.Normal * 10000)
			dmg:SetAmmoType(-1)
			dmg:SetDamage(25)

			if tr.Entity.DispatchTraceAttack then 
				tr.Entity:DispatchTraceAttack(dmg, tr, tr.Normal)
			elseif tr.Entity.TakeDamageInfo then
				tr.Entity:TakeDamageInfo(dmg)
			end

			if tr.Entity.TakePhysicsDamage then
				tr.Entity:TakePhysicsDamage(dmg)
			end

			if jcms.team_JCorp(tr.Entity) then
				if ply:Health() < ply:GetMaxHealth() then
					ply:SetHealth( ply:Health() + 1 )
				end
			end
		end

		local start = ply:EyePos()
		start.x = start.x + math.Rand(-8, 8)
		start.y = start.y + math.Rand(-8, 8)
		start.z = start.z + math.Rand(-2, 8)
		util.Decal("Blood", start, tr.HitPos + tr.Normal * 5, ply)
	else
		ply:ViewPunch( AngleRand(-9, 9) )
		ply:EmitSound("NPC_FastZombie.AttackMiss")
	end
end

function class.Ability(ply)
	local weapon = ply:GetActiveWeapon()

	if weapon:GetNWInt("jcms_npcspecial", 0) > 0 then
		local grenade = ents.Create("npc_grenade_frag")
		grenade:SetPos(ply:EyePos())
		grenade:SetOwner(ply)
		grenade:Spawn()
		grenade.jcms_canHurtSelfAsNPC = true
		grenade:GetPhysicsObject():EnableDrag(true)
		grenade:GetPhysicsObject():SetDragCoefficient(100)
		ply:PickupObject(grenade)

		weapon:SetNWInt("jcms_npcspecial", weapon:GetNWInt("jcms_npcspecial", 0) - 1)
		return true
	else
		return false
	end
end

function class.SetupMove(ply, mv, cmd) --Long-Distance-Running (Lifted from Sentinel)
	local sprintDelay = 0.5 --Delay to start speeding up

	if ply:IsSprinting() and not ply.sentinel_isSprinting then
		ply.sentinel_sprintStart = CurTime()
	end
	ply.sentinel_isSprinting = ply:IsSprinting()

	if ply.sentinel_isSprinting then
		local sprintFrac = (CurTime() - ply.sentinel_sprintStart - sprintDelay)/3 --Progress to max
		ply:SetRunSpeed(Lerp( sprintFrac, class.runSpeed, class.boostedRunSpeed))
	else
		ply:SetRunSpeed(class.runSpeed)
	end
end

function class.OnDeath(ply)
	local crab = ents.Create("npc_headcrab")
	if IsValid(crab) then
		ply:SetBodygroup(1, 0)
		crab:SetPos(ply:EyePos())
		crab.jcms_owner = ply
		crab:Spawn()
	end
end

if CLIENT then

	class.color = Color(201, 40, 80)
	class.colorAlt = Color(100, 255, 247)

	function class.HUDOverride(ply)
		local col = Color(201, 40, 80)
		local colAlt = Color(100, 255, 247)
		local sw, sh = ScrW(), ScrH()

		local weapon = ply:GetActiveWeapon()
		cam.Start2D()
			jcms.hud_npc_DrawTargetIDs(col, colAlt)
			jcms.hud_npc_DrawHealthbars(ply, col, colAlt)
			if not ply:IsSprinting() then
				jcms.hud_npc_DrawCrosshairMelee(ply, weapon, col)
			else 
				jcms.draw_Crosshair_SprintBoost(sw/2, sh/2, col)
			end
			jcms.hud_npc_DrawSweeperStatus(col, colAlt)
			jcms.hud_npc_DrawObjectives(col, colAlt)
			jcms.hud_npc_DrawDamage(col, colAlt)
		cam.End2D()
		surface.SetAlphaMultiplier(1)
	end
	
	function class.TranslateActivity(ply, act)
		if ply:IsOnGround() then
			local myvector = ply:GetVelocity()
			local speed = myvector:Length()
			
			if ply:KeyDown(IN_ATTACK) then
				return ACT_MELEE_ATTACK1
			end

			if speed > 40 then
				myvector.z = 0
				myvector:Normalize()
				local myangle = ply:GetAngles()
				
				ply:SetPoseParameter("move_yaw", math.AngleDifference( myvector:Angle().yaw, myangle.yaw))
				if ply:IsSprinting() then
					return ACT_RUN
				else
					return ACT_WALK
				end
			else
				return ACT_IDLE
			end
		else
			ply:SetCycle(1)
			return ACT_RANGE_ATTACK1
		end
	end
	
	function class.ColorMod(ply, cm)
		jcms.colormod["$pp_colour_addr"] = 0.11
		jcms.colormod["$pp_colour_addg"] = 0
		jcms.colormod["$pp_colour_addb"] = 0

		jcms.colormod["$pp_colour_mulr"] = 0
		jcms.colormod["$pp_colour_mulg"] = -0.5
		jcms.colormod["$pp_colour_mulb"] = -0.5
		
		jcms.colormod["$pp_colour_contrast"] = 1.04
		jcms.colormod["$pp_colour_brightness"] = -0.01
		
		jcms.colormod[ "$pp_colour_colour" ] = 0.6
	end
	
end

