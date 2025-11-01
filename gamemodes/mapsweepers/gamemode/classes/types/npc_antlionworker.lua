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
local class = {}
jcms.class_Add("npc_antlionworker", class)

class.faction = "antlion"
class.mdl = "models/antlion_worker.mdl"
class.footstepSfx = "NPC_Antlion.FootstepHeavy"
class.footstepSfxNoPostfix = true

class.health = 60
class.shield = 0
class.shieldRegen = 0
class.shieldDelay = 64

class.damage = 1
class.hurtMul = 1
class.hurtReduce = 0
class.speedMul = 1.5
class.jumpPower = 300

class.playerColorVector = Vector(1, 1, 0)
class.noFallDamage = true
class.gravity = 0.75

function class.OnSpawn(ply)
	ply:Give("weapon_jcms_playernpc", false)
	ply.jcms_bounty = 50
end

if SERVER then
	
	function class.PrimaryAttack(ply, wep)
		wep:SetNextPrimaryFire(CurTime() + 1.5)

		local origin
		ply:EmitSound("NPC_Antlion.PoisonShoot")

		local headBoneId = ply:LookupBone("Antlion.Head_Bone")
		if headBoneId then
			origin = ply:GetBoneMatrix(headBoneId):GetTranslation()
		else
			origin = ply:WorldSpaceCenter()
		end

		local eyeAngles = ply:EyeAngles()
		eyeAngles.p = eyeAngles.p - 4
		local fwdNormal = eyeAngles:Forward()
		for i=1, 4 do
			local spit = ents.Create("grenade_spit")
			spit:SetOwner(ply)
			spit:SetPos(origin)
			spit:Spawn()

			local mul = 1400 + i*100
			local fwd = fwdNormal * mul
			fwd:Rotate(AngleRand(-i, i))

			spit:SetVelocity(fwd)
		end

		ply:ViewPunch( AngleRand(-2, 2) )
	end

	function class.OnDeath(ply)
		local pos = ply:WorldSpaceCenter()
		ParticleEffect( "antlion_gib_02", pos, angle_zero )
		EmitSound( "NPC_Antlion.PoisonBurstExplode", pos );
		
		local blstDmg = DamageInfo()
		blstDmg:SetAttacker(ply)
		blstDmg:SetInflictor(ply)
		
		blstDmg:SetDamage(50)
		blstDmg:SetReportedPosition(pos)
		blstDmg:SetDamageForce(jcms.vectorOrigin)
		blstDmg:SetDamageType( bit.bor(DMG_POISON, DMG_BLAST_SURFACE, DMG_ACID) )

		util.BlastDamageInfo(blstDmg, pos, 100)
		
		timer.Simple(0.04, function()
			if IsValid(ply) and IsValid(ply:GetRagdollEntity()) then
				ply:GetRagdollEntity():Remove()
			end
		end)
	end

end

if CLIENT then
	
	class.color = Color(255, 200, 83)
	class.colorAlt = Color(41, 255, 112)

	function class.HUDOverride(ply)
		local col = class.color
		local colAlt = class.colorAlt
		local sw, sh = ScrW(), ScrH()

		local weapon = ply:GetActiveWeapon()
		cam.Start2D()
			jcms.hud_npc_DrawTargetIDs(col, colAlt)
			jcms.hud_npc_DrawHealthbars(ply, col, colAlt)
			jcms.hud_npc_DrawCrosshair(ply, weapon, col, colAlt)
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
			
			if speed > 10 then
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
			return ACT_GLIDE
		end
	end
	
	function class.ColorMod(ply, cm)
		jcms.colormod["$pp_colour_addr"] = 0.1
		jcms.colormod["$pp_colour_addg"] = 0.12
		jcms.colormod["$pp_colour_addb"] = 0

		jcms.colormod["$pp_colour_mulr"] = 0
		jcms.colormod["$pp_colour_mulg"] = 0
		jcms.colormod["$pp_colour_mulb"] = 0
		
		jcms.colormod["$pp_colour_contrast"] = 1.13
		jcms.colormod["$pp_colour_brightness"] = -0.01
		
		jcms.colormod[ "$pp_colour_colour" ] = 0.6
	end
	
end

