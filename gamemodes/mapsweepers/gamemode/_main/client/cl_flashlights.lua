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

jcms.flashlights = jcms.flashlights or {}
jcms.flashlights_anims = jcms.flashlights_anims or {}
jcms.flashlights_sides = jcms.flashlights_sides or {}
jcms.flashlights_sidesTo = jcms.flashlights_sidesTo or {}
jcms.flashlights_angles = jcms.flashlights_angles or {}
jcms.flashlights_cachedColor = Color(0,0,0)

hook.Add("Think", "jcms_Flashlights", function(ply) --todo: see if I can have this switch to something simple like parenting when <60FPS
	local thres = 0.0001

	for i, ply in player.Iterator() do
		if not ply:IsDormant() and IsValid(ply) and ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE and not IsValid(ply:GetNWEntity("jcms_vehicle")) and not IsValid(ply:GetVehicle()) then
			if not jcms.flashlights[ply] then
				local f = ProjectedTexture()
				jcms.flashlights_anims[ply] = 0
				f:SetColor( color_black )
				f:SetTexture("effects/flashlight/hard")
				f:Update()
				jcms.flashlights[ply] = f
			end

			local f = jcms.flashlights[ply]
			local ep
			if ply ~= jcms.locPly then
				local bm = ply:GetBoneMatrix(6)
				if bm then
					ep = bm:GetTranslation()
				else
					ep = ply:EyePos()
				end
			else
				ep = ply:EyePos()
			end
			
			local ea = ply:EyeAngles()
			local span = 14

			local right = ea:Right()
			right:Mul(span)
			local leftShoulder = ep - right
			
			local fwd = ea:Forward()
			fwd:Mul(32)
			
			local trace = util.TraceLine {
				start = leftShoulder,
				endpos = leftShoulder + fwd,
				mask = MASK_VISIBLE,
				filter = ply
			}

			if trace.Hit or trace.StartSolid then
				jcms.flashlights_sidesTo[ply] = true
			else
				jcms.flashlights_sidesTo[ply] = false
			end

			local W = 3
			local approach = ply:GetNWBool("jcms_flashlight")==true and 1 or 0
			if (jcms.flashlights_sidesTo[ply] ~= jcms.flashlights_sides[ply]) or IsValid(ply:GetVehicle()) then
				approach = 0
			end

			jcms.flashlights_anims[ply] = ((jcms.flashlights_anims[ply] or 0)*W + approach )/( W+1 )

			if jcms.flashlights_anims[ply] < 0.34 then
				jcms.flashlights_sides[ply] = jcms.flashlights_sidesTo[ply]
			end

			if jcms.flashlights_sides[ply] then
				f:SetPos(ep + right) --Right Shoulder
			else
				f:SetPos(leftShoulder)
			end

			local anim = jcms.flashlights_anims[ply]

			--local targetAngle = (jcms.util_ShortEyeTrace(ply, 300, MASK_VISIBLE).HitPos - f:GetPos()):GetNormalized():Angle()
			local targetAngle = (ply:GetEyeTraceNoCursor().HitPos - f:GetPos()):Angle()

			if jcms.flashlights_angles[ply] then
				jcms.flashlights_angles[ply] = LerpAngle(Lerp(anim, 0.8, 0.5), jcms.flashlights_angles[ply], targetAngle)
			else
				jcms.flashlights_angles[ply] = targetAngle
			end

			f:SetAngles(jcms.flashlights_angles[ply])

			local a = TimedCos(1, Lerp(anim, 0, 0.99), Lerp(anim, 0, 1), 0)
			if math.random() < 0.008 then
				a = a * 0.9
			end

			if not ply.__s64hash then
				ply.__s64hash = util.SHA256( ply:SteamID64() )
			end
			
			do -- Setting the colour
				local r,g,b = 255*a, 128*a*a, 128*a*a

				if jcms.playerfactions_players[ ply.__s64hash ] == "rgg" then
					r,g,b = 180*a*a, 64*a*a, 255*a
				elseif jcms.playerfactions_players[ ply.__s64hash ] == "mafia" then
					r,g,b = 250*a*a, 207*a*a, 121*a
				end

				jcms.flashlights_cachedColor:SetUnpacked(r,g,b)
				f:SetColor(jcms.flashlights_cachedColor)
			end

			if anim > thres then
				f:SetFarZ(Lerp(anim, 1320, 1500))
				f:SetNearZ(4)
				f:SetFOV(Lerp(anim, 54, 64))
				f:Update()
			end
		else
			if jcms.flashlights[ply] then
				jcms.flashlights[ply]:Remove()
				jcms.flashlights[ply] = nil 
			end
		end
	end
end)

local mat_light = Material "sprites/light_glow02_add"

hook.Add("PostDrawTranslucentRenderables", "jcms_FlashlightOrbs", function(bDepth, bSkybox, is3DSkyBox)
	if bSkybox or bDepth or is3DSkyBox or jcms.performanceEstimate < 30 then return end

	for i, ply in player.Iterator() do
		local f = jcms.flashlights[ply]

		if f and IsValid(f) then
			local color = f:GetColor()
			local a = jcms.flashlights_anims[ply]
			
			if not ply:ShouldDrawLocalPlayer() then
				continue 
			end
			
			if a > 0.02 then
				local v = f:GetPos()
				local yeah = -jcms.EyeFwd_lowAccuracy:Dot(f:GetAngles():Forward())*a

				render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
					render.SetColorMaterial()
					render.DrawSphere(v, 1*a, 7, 7, color)

					if jcms.EyePos_lowAccuracy:DistToSqr(v) < 570*570 then
						render.SetColorModulation(color.r/255, color.g/255, color.b/255)
						render.DrawSphere(v, TimedCos(3, 1.5, 2, -1)*a, 5, 5, color)
						render.DrawSphere(v, TimedCos(2, 1.5, 2, 1)*a, 7, 7, color)
					end

					render.SetMaterial(mat_light)
					render.SetColorModulation(color.r, color.g, color.b)
					
					render.DrawSprite(v, math.random(50, 64), math.random(32, 36), color)
					
					if jcms.EyePos_lowAccuracy:DistToSqr(v) < 900*900 then
						render.DrawSprite(v, math.random(35, 62), math.random(26, 32), color)
					end

					if yeah > 0 then
						render.DrawSprite(v, 128*yeah, 128*yeah, Color(color.r + yeah*128, color.g + yeah*128, color.b + yeah*128))
					end
					
					render.SetColorModulation(1,1,1)
				render.OverrideBlend(false)
			end
		end
	end
end )
