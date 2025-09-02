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

EFFECT.mat_core = Material "effects/fluttercore_gmod"
EFFECT.mats_blood = {
	Material "decals/blood3",
	Material "decals/blood4",
	Material "decals/blood5", 
	nil -- Blocks the second return of "Material"
}
EFFECT.decal_blood = Material "decals/bloodstain_002"

EFFECT.v_gravity = Vector(0, 0, -720)
EFFECT.v_gravityHeavy = Vector(0, 0, -1440)

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.pos = data:GetOrigin()
	self.size = 20 + data:GetRadius()^0.8
	self.color = jcms.util_ColorFromInteger(data:GetColor())

	self.emitter = ParticleEmitter(self.pos)
	if self.emitter then
		for i=1, math.ceil(self.size/3) do
			local p = self.emitter:Add("effects/fleck_cement"..math.random(1, 2), self.pos)
			if p then
				local vel = VectorRand(-self.size*2, self.size*2)
				vel.z = vel.z + self.size*2
				p:SetVelocity(vel)
				p:SetGravity(self.v_gravity)
				p:SetCollide(true)

				p:SetStartSize(math.Rand(self.size/14, self.size/5))
				p:SetEndSize(0)

				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*10 - 5)

				p:SetDieTime(3 + (math.random()^3)*2)
				if math.random() < 0.33 then
					p:SetColor(self.color:Unpack())
				else
					local b = math.random(32, 48)
					p:SetColor(b, b, b)
				end
			end
		end

		local smokeSize = self.size/4
		for j=1, math.random(2, 3) do
			local p = self.emitter:Add("particle/smokesprites_000" .. (j%5 + 1), self.pos)
			if p then
				local vel = VectorRand(-self.size*2, self.size*2)
				vel.z = vel.z + self.size/3
				p:SetVelocity(vel)
				p:SetAirResistance(170)

				p:SetStartSize(self.size/3)
				p:SetEndSize(self.size)

				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*2 - 1)

				p:SetDieTime(math.Rand(0.3, 0.7) + self.size/50)
				p:SetColor(32, 32, 32)
			end
		end
	end

	self.t = 0
	self.tout = 0.15
end

function EFFECT:Think()
	if self.t < self.tout then
		self.t = self.t + FrameTime()
		return true
	else
		return false
	end
end

function EFFECT:Render()
end