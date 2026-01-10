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
jcms.class_Add("npc_combineelite", class)

class.faction = "combine"
class.mdl = "models/combine_super_soldier.mdl"
class.footstepSfx = "NPC_CombineS.RunFootstep"

class.handsModel = "models/weapons/c_arms_combine.mdl"
class.deathSound = "NPC_CombineS.DissolveScream"

class.health = 75
class.shield = 45
class.shieldRegen = 5
class.shieldDelay = 1.5

class.damage = 0.2
class.hurtMul = 1
class.hurtReduce = 1
class.speedMul = 0.75

function class.OnSpawn(ply)
	local weapon = ply:Give("weapon_ar2", false)
	ply:GiveAmmo(9999, weapon:GetPrimaryAmmoType())
	ply:GiveAmmo(1, weapon:GetSecondaryAmmoType())

	ply:Give("weapon_frag", false)
	ply.jcms_bounty = 100
end

if CLIENT then

	class.color = Color(255, 64, 64)
	class.colorAlt = Color(32, 240, 255)

	function class.HUDOverride(ply)
		local col = Color(255, 64, 64)
		local colAlt = Color(32, 240, 255)
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

			if speed > 10 then
				
				if not ply:IsWalking() then
					return ply:Crouching() and 364 or 363
				else
					return ply:Crouching() and 360 or 359
				end
			else
				return ply:Crouching() and 300 or 279
			end
		else
			return ACT_GLIDE
		end
	end
	
	function class.ColorMod(ply, cm)
		jcms.colormod["$pp_colour_addr"] = 0.11
		jcms.colormod["$pp_colour_addg"] = 0.01
		jcms.colormod["$pp_colour_addb"] = 0

		jcms.colormod["$pp_colour_mulr"] = 0.1
		jcms.colormod["$pp_colour_mulg"] = 0
		jcms.colormod["$pp_colour_mulb"] = 0
		
		jcms.colormod["$pp_colour_contrast"] = 1.15
		jcms.colormod["$pp_colour_brightness"] = -0.07
		
		jcms.colormod[ "$pp_colour_colour" ] = 0.9
	end
	
end

