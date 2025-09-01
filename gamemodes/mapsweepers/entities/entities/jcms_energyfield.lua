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

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Energy Shield"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsActive")
	self:NetworkVar("Vector", 0, "Start") --bottom left corner
	self:NetworkVar("Vector", 1, "End") --top right corner
end

if SERVER then 
	function ENT:Initialize()
		self:SetTrigger(true)

	end

	function ENT:ResetMesh() --Recalculate our convex mesh
		local ang = self:GetAngles()
		local fw = ang:Forward()

		local vStart = self:WorldToLocal(self:GetStart())
		local vEnd = self:WorldToLocal(self:GetEnd())

		--local vStart = self:GetStart()
		--local vEnd = self:GetEnd()

		--Other 2 corners
		local sx, sy, sz = vStart:Unpack()
		local ex, ey, ez = vEnd:Unpack()

		local vSE = Vector(sx, sy, ez) -- top left
		local vES = Vector(ex, ey, sz) -- bottom right

		local points = {
			--Bottom Left
			vStart + fw/2,
			vStart - fw/2,

			--Top left
			vSE + fw/2,
			vSE - fw/2,

			--Top Right
			vEnd + fw/2,
			vEnd - fw/2,

			--Bottom right
			vES + fw/2,
			vES - fw/2,
		}

		--[[
		print(fw)
		print(vStart)
		print(vEnd)

		for i, point in ipairs(points) do 
			debugoverlay.Cross(point, 30, 1, Color(255,0,0), true)
		end--]]

		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_CUSTOM )

		self:PhysicsInitConvex( points )

		self:EnableCustomCollisions( true )
	end
end

if CLIENT then 
	ENT.ShieldMat = Material("effects/combineshield/comshieldwall3")

	function ENT:DrawTranslucent()
		self:DestroyShadow()

		--TODO: OPTIMISE. This is currently really really wasteful, it's just easier to test this way

		local vStart = self:GetStart()
		local vEnd = self:GetEnd()

		--Other 2 corners
		local sx, sy, sz = vStart:Unpack()
		local ex, ey, ez = vEnd:Unpack()

		local vSE = Vector(sx, sy, ez) -- top left
		local vES = Vector(ex, ey, sz) -- bottom right

		render.SetMaterial(self.ShieldMat)
		render.DrawQuad( vStart, vSE, vEnd, vES, color_white )

		--TODO: Use 3D2D and drawTexturedRectUV instead. Quad stretches the texture which we don't want.

	end
	--TODO: DrawTranslucent
end
