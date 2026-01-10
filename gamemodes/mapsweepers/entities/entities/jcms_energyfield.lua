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

		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_CUSTOM )

		self:PhysicsInitBox( vStart - fw, vEnd + fw)

		self:EnableCustomCollisions( true )
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		--todo custom physics check flag
	end
end

if CLIENT then 
	ENT.ShieldMat = Material("effects/combineshield/comshieldwall3")
	--TODO: Maybe we could tile by using CreateMaterial for each entity, and scaling its matrices?

	function ENT:DrawTranslucent()
		self:DestroyShadow()

		--TODO: OPTIMISE. This is currently really really wasteful, it's just easier to test this way

		local vStart = self:GetStart()
		local vEnd = self:GetEnd()

		self:SetRenderBoundsWS( vStart - self:GetAngles():Forward(), vEnd + self:GetAngles():Forward())

		local diff = self:WorldToLocal(vEnd) - self:WorldToLocal(vStart)
		local ang = self:GetAngles()

		--Other 2 corners
		local sx, sy, sz = vStart:Unpack()
		local ex, ey, ez = vEnd:Unpack()

		local vSE = Vector(sx, sy, ez) -- top left
		local vES = Vector(ex, ey, sz) -- bottom right

		render.SetMaterial(self.ShieldMat)
		render.DrawQuad( vStart, vSE, vEnd, vES, color_white )

		render.DrawQuad( vEnd, vSE, vStart, vES, color_white )
		

		--[[
		cam.Start3D2D(vStart, Angle(180,180,90), 1)
			surface.SetMaterial(self.ShieldMat)
			
			surface.DrawTexturedRectUV( 0, 0, diff.x, diff.z, 0, 0, diff.x/25, diff.z/25 )

			--surface.DrawRect(0,0,1000,1000)
		cam.End3D2D()
		--]]

	end
end
