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

AddCSLuaFile()

for i, side in ipairs { "jcorp", "mafia" } do
	for j, class in ipairs { "recon", "infantry", "sentinel", "engineer" } do
		local name = side .. "_" .. class

		player_manager.AddValidModel(name, "models/player/jcms/" .. name .. ".mdl")
		player_manager.AddValidHands(name, "models/weapons/jcms/c_arms_jcms_" .. side .. ".mdl")
	end
end
