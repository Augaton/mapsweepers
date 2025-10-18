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

local prefabs = jcms.prefabs

-- // Critical / Always spawns {{{
	prefabs.shop = {
		natural = false,

		check = function(area)
			if not jcms.mapgen_ValidArea(area) then return false end

			local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 128)
			
			if #wallspots > 0 then
				local rng = math.random(#wallspots)
				return true, { pos = wallspots[rng], normal = normals[rng] }
			else
				return false
			end
		end,

		stamp = function(area, data)
			local ent = ents.Create("jcms_shop")
			if not IsValid(ent) then return end

			data.pos = data.pos + data.normal * 14
			ent:SetPos(data.pos)
			ent:DropToFloor()
			ent:SetAngles(data.normal:Angle())
			ent:Spawn()
			return ent
		end
	}
-- // }}}