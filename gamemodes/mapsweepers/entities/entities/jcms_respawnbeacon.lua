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
ENT.PrintName = "Respawn Beacon"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/jcms/jcorp_respawnbeacon.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		
		if jcms.director then
			table.insert(jcms.director.respawnBeacons, self)
		end
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "RespawnTarget")
	self:NetworkVar("Bool", 0, "RespawnBusy")
	
	self:SetRespawnBusy(false)
end

function ENT:UpdateForFaction(faction)
	for i, matname in ipairs(self:GetMaterials()) do
		self:SetSubMaterial(i-1, matname:gsub("jcorp_", tostring(faction) .. "_"))
	end
end

if SERVER then
	function ENT:DoPreRespawnEffect(ply, duration)
		self:SetRespawnTarget(ply)
	end
	
	function ENT:DoPostRespawnEffect(ply)
		local ed = EffectData()
		ed:SetColor(jcms.util_GetColorIntegerPvP(ply))
		ed:SetFlags(0)
		ed:SetEntity(ply)
		util.Effect("jcms_spawneffect", ed)
		jcms.net_SendRespawnEffect(ply)
		self:SetBodygroup(1, 1)
		
		timer.Simple(6, function()
			if IsValid(self) then
				self:Remove()
				
				local ed = EffectData()
				ed:SetMagnitude(0.7)
				ed:SetOrigin(self:GetPos())
				ed:SetRadius(100)
				ed:SetNormal(Vector(0, 0, 1))
				ed:SetFlags(2)
				util.Effect("jcms_blast", ed)
			end
		end)
	end
end

if CLIENT then
	ENT.mat_spark = Material "effects/spark"
	
	function ENT:Draw(flags)
		self:DrawModel()
	end
	
	function ENT:OnRemove()
		if IsValid(self.csmodel) then
			self.csmodel:Remove()
			self.csmodel = nil
		end
	end
	
	function ENT:Think()
		local W = 5
		self.fadein = ((self.fadein or 0)*W + (self:GetRespawnBusy() and 1 or 0))/(W+1)
	end
	
	function ENT:DrawTranslucent(flags)
		if self.fadein and self.fadein > 0.003 then
			local pos, norm = self:GetPos(), Vector(0, 1, 0)
			local red = Color(255, 150, 150)
			local time = CurTime()
			local a = self.fadein
			
			render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_ONE, BLENDFUNC_ADD )
				render.SetMaterial(self.mat_spark)
				local rx, ry = pos.x, pos.y
				
				if not self.sparks then
					self.sparks = {}
					for i=1, 24 do
						table.insert(self.sparks, {
							a = math.random()*math.pi*2,
							size = math.Rand(0.4, 1.4)^2,
							speed = (math.random()<0.3 and -1 or 1)*math.Rand(0.5, 2.3),
							dist = math.Rand(4, 24),
							z = math.Rand(0, 8)^2,
						})
					end
				end
				
				local rx, ry, rz = pos:Unpack()
				local dt = FrameTime()
				for i, spark in ipairs(self.sparks) do
					local cos, sin = math.cos(spark.a), math.sin(spark.a)
					pos.x = rx + cos*spark.dist
					pos.y = ry + sin*spark.dist
					pos.z = rz + spark.z
					
					norm.x = cos
					norm.y = sin
					render.DrawQuadEasy(pos, norm, spark.size*32, spark.size*2*a, red, spark.speed*3+2)
					
					spark.a = spark.a + spark.speed*dt*8
					spark.z = (spark.z + spark.speed*dt*5)%64
				end
			
				local tg = self:GetRespawnTarget() or Entity(1)
				if IsValid(tg) then
					if not IsValid(self.csmodel) then
						self.csmodel = ClientsideModel( tg:GetModel(), RENDERGROUP_TRANSLUCENT )
						self.csmodel:SetNoDraw( true )
						self.csmodel:SetMaterial("models/shiny")
						self.csmodel:SetSequence(math.random() < 0.1 and "taunt_dance_base" or "swim_idle_all")
					end
					
					if IsValid(self.csmodel) then
						local pos = self:GetPos()
						pos.z = pos.z + 12 + 4*a
						
						render.SetColorModulation(100*a, 0, 0)
						self.csmodel:SetPos(pos)
						self.csmodel:SetCycle((time%2.5)/2.5)
						self.csmodel:DrawModel()
					end
				else
					if IsValid(self.csmodel) then
						self.csmodel:Remove()
						self.csmodel = nil
					end
				end
			render.OverrideBlend( false )
		end
	end
end
