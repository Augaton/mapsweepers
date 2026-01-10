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

--[[
	Sink the NPC's model into the ground, to the given depth, over the given duration.

	(It'd be fairly easy to modify this to make an unburrow effect too, recycle this if we ever need that).
--]]

function EFFECT:Init( data )
	self.entity = data:GetEntity()
	self.duration = data:GetScale()
	self.endTime = CurTime() + self.duration --Scale used for duration
	self.depth = data:GetMagnitude()

	self.burrowOffs = Vector(0,0,-self.depth)
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if not IsValid(selfTbl.entity) then return false end

	selfTbl.entity:SetNoDraw(true)
	if selfTbl.endTime < CurTime() and IsValid(selfTbl.entity) then 
		selfTbl.entity:SetNoDraw(false)
		return false
	end
	return true
end

function EFFECT:Render()
	local selfTbl = self:GetTable()

	local frac = 1 - (selfTbl.endTime - CurTime()) / selfTbl.duration
	local pos = selfTbl.entity:GetPos()

	local renderPos = LerpVector(frac, pos, pos + selfTbl.burrowOffs) + VectorRand(-1, 1)

	selfTbl.entity:SetPos(renderPos)
	selfTbl.entity:DrawModel()
	
	selfTbl.entity:SetPos(pos)
end
