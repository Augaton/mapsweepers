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
jcms.class_Add("npc_combinemetropolice", class)

class.faction = "combine"
class.mdl = "models/police.mdl"
class.footstepSfx = "NPC_MetroPolice.RunFootstep"

class.handsModel = "models/weapons/c_arms_combine.mdl"
class.deathSound = "NPC_MetroPolice.Die"

class.health = 50
class.shield = 0
class.shieldRegen = 0
class.shieldDelay = 64

class.damage = 0.2
class.hurtMul = 1
class.hurtReduce = 0
class.speedMul = 0.75

function class.OnSpawn(ply)
	local weapon = ply:Give("weapon_smg1", false)
	weapon:SetNWInt("jcms_npcspecial", 3) -- Manhacks
	ply:GiveAmmo(9999, weapon:GetPrimaryAmmoType())
	ply:Give("weapon_frag", false)

	ply.jcms_bounty = 65
end

if CLIENT then

	class.color = Color(32, 240, 255)
	class.colorAlt = Color(255, 72, 30)
	
	function class.HUDOverride(ply)
		local col = Color(32, 240, 255)
		local colAlt = Color(255, 72, 30)
		local sw, sh = ScrW(), ScrH()

		local weapon = ply:GetActiveWeapon()
		cam.Start2D()
			jcms.hud_npc_DrawTargetIDs(col, colAlt)
			jcms.hud_npc_DrawHealthbars(ply, col, colAlt)
			jcms.hud_npc_DrawCrosshair(ply, weapon, col, colAlt, colAlt)
			jcms.hud_npc_DrawSweeperStatus(col, colAlt)
			jcms.hud_npc_DrawObjectives(col, colAlt)
			jcms.hud_npc_DrawDamage(col, colAlt)
		cam.End2D()
		surface.SetAlphaMultiplier(1)
	end
	
	function class.ColorMod(ply, cm)
		jcms.colormod["$pp_colour_addr"] = 0
		jcms.colormod["$pp_colour_addg"] = 0.02
		jcms.colormod["$pp_colour_addb"] = 0.05

		jcms.colormod["$pp_colour_mulr"] = 0
		jcms.colormod["$pp_colour_mulg"] = 0
		jcms.colormod["$pp_colour_mulb"] = 0
		
		jcms.colormod["$pp_colour_contrast"] = 1.04
		jcms.colormod["$pp_colour_brightness"] = -0.03
		
		jcms.colormod[ "$pp_colour_colour" ] = 1
	end

	function class.TranslateActivity(ply, act)
		if act == 1001 then
			return ACT_JUMP
		end

		if ply:IsOnGround() then
			local myvector = ply:GetVelocity()
			local speed = myvector:Length()

			myvector.z = 0
			myvector:Normalize()
			local myangle = ply:GetAngles()
			ply:SetPoseParameter("move_yaw", math.AngleDifference( myvector:Angle().yaw, myangle.yaw))

			if speed <= 10 then
				if act == 1025 then
					return 378
				end
		
				if act == 1028 then
					return 379
				end
			end

			if speed > 10 then
				if not ply:IsWalking() then
					return ply:Crouching() and 8 or 363
				else
					return ply:Crouching() and 8 or 359
				end
			else
				return ply:Crouching() and 302 or 284
			end
		else
			return ACT_GLIDE
		end
	end
	
end

if SERVER then

	function class.Ability(ply)
		local weapon = ply:GetActiveWeapon()

		if weapon:GetNWInt("jcms_npcspecial", 0) > 0 then
			local manhack = ents.Create("npc_manhack")
			manhack.jcms_owner = ply

			local v = ply:EyeAngles()
			v.p = v.p + math.Rand(-10, 10)
			v.y = v.y + math.Rand(-15, 15)
			v = v:Forward()

			local pos = ply:EyePos()
			v:Mul(38)
			pos:Add(v)

			manhack:SetPos(pos)
			manhack:EmitSound("weapons/slam/throw.wav")
			
			manhack:Spawn()
			jcms.npc_UpdateRelations(manhack)
			jcms.npc_GetRowdy(manhack)

			local phys = manhack:GetPhysicsObject()
			if IsValid(phys) then
				v:Mul(7)
				manhack:SetAngles(ply:EyeAngles())
				manhack:GetPhysicsObject():SetVelocity(v)
			end

			weapon:SetNWInt("jcms_npcspecial", weapon:GetNWInt("jcms_npcspecial", 0) - 1)
			return true
		else
			return false
		end
	end

end

