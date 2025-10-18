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
ENT.PrintName = "Ore Crate"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.CrateType = 1
ENT.CrateTypes = {
	[1] = {
		model = "models/Items/item_item_crate.mdl",
		capacity = 150,
		mass = 50,
		
		attachOffset = Vector(0,0,0),
		attachAngle = Angle(0,0,0)
	},
	[2] = {
		model = "models/props_c17/FurnitureFridge001a.mdl",
		capacity = 300,
		mass = 150,

		attachOffset = Vector(0,0,10),
		attachAngle = Angle(90,0,0)
	},
	[3] = {
		model = "models/props_wasteland/controlroom_storagecloset001a.mdl",
		capacity = 450,
		mass = 250,
		
		attachOffset = Vector(0,0,0),
		attachAngle = Angle(90,0,0)
	},
}

ENT.EjectionCooldown = 1 --How long until we can eat again after ejecting
ENT.AttachCooldown = 1 --How long until we can attach after being grabbed off a vehicle

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "MaxCapacity")
	self:NetworkVar("Int", 1, "HeldCapacity")
end

if SERVER then
	--TODO: Magnetism?

	function ENT:Initialize()
		local crateType = self.CrateTypes[self.CrateType]
		self:SetModel(crateType.model)
		self:SetMaterial("models/props_combine/metal_combinebridge001")
		self:UpdateForFaction("jcorp") --TODO
		self:PhysicsInit(SOLID_VPHYSICS)

		self:SetMaxCapacity(crateType.capacity)
		self:GetPhysicsObject():SetMass(crateType.mass)

		self.lastEjected = 0
		self.lastVehicleAttached = 0

		self.crate_contents = {}
		--[[Structure:
			[i] = {type="oreType", model="modelName"} 
		--]]

		self.jcms_attachedToVehicle = false
	end
	
	function ENT:UpdateForFaction(faction)
		if faction == "rgg" then
			self:SetColor( Color(162, 81, 255) )
		elseif faction == "mafia" then
			self:SetColor( Color(241, 212, 14) )
		else
			self:SetColor( Color(255, 32, 32) )
		end
	end

	--GM:OnPlayerPhysicsDrop( Player ply, Entity ent, boolean thrown )
	--TODO: We can currently pick up a crate as soon as we drop it and that's suboptimal.

	function ENT:Use( activator, caller, useType, value )
		if self:IsPlayerHolding() then return end
		activator:PickupObject(self)

		if self.jcms_attachedToVehicle then
			--TODO: SFX
			--TODO: Gravity Gun as well if that's possible.

			self.lastVehicleAttached = CurTime()
			
			local crateType = self.CrateTypes[self.CrateType]
			self:GetPhysicsObject():SetMass(crateType.mass)

			if IsValid(self.jcms_attachedVehicle) then
				self.jcms_attachedVehicle.jcms_attachedCrates[self.jcms_attachedSlot] = nil 

				self.jcms_attachedSlot = nil
				self.jcms_attachedVehicle = NULL
			end
		end

		constraint.RemoveConstraints( self, "Weld" )
		self.jcms_attachedToVehicle = false
	end

	function ENT:PhysicsCollide( data, physObj )
		--Is the target an ore and do we have space for it?
		local hitEnt = data.HitEntity

		if self.lastEjected + self.EjectionCooldown < CurTime() and hitEnt:GetClass() == "jcms_orechunk" and self:GetHeldCapacity() + hitEnt:GetPhysicsObject():GetMass() < self:GetMaxCapacity() and not hitEnt.jcms_physAte then
			self:Eat(hitEnt)
		elseif self.lastVehicleAttached + self.AttachCooldown < CurTime() and hitEnt.jcms_attachedCrates and self:FindAttachSlot(hitEnt) then
			self:ForcePlayerDrop()
			self:AttachToVehicle(hitEnt, self:FindAttachSlot(hitEnt))
		end
	end
	
	function ENT:OnTakeDamage(dmg)
		local attacker, inflictor = dmg:GetAttacker(), dmg:GetInflictor()

		if IsValid(inflictor) and jcms.util_IsStunstick(inflictor) and jcms.team_JCorp(attacker) and self:GetHeldCapacity() > 0 then
			self:Vomit()
		end
	end

	function ENT:Eat( target )
		--TODO: SFX

		target.jcms_physAte = true --We can get multiple physcollide calls at once, we don't want to eat the same object twice.

		local targetData = {
			type = target:GetOreName(),
			model = target:GetModel()
		}
		table.insert(self.crate_contents, targetData)

		--Add mass to capacity.
		self:SetHeldCapacity(self:GetHeldCapacity() + target.jcms_oreMass) --Actual physics object gets its mass fucked with while we're holding it for some reason
		target:Remove()
	end

	function ENT:Vomit()
		--TODO: SFX

		self.lastEjected = CurTime()

		for i, oreData in ipairs(self.crate_contents) do 
			local ore = ents.Create("jcms_orechunk")
			ore:SetPos(self:WorldSpaceCenter())

			ore:SetModel(oreData.model)
			ore:SetOreType(oreData.type)

			ore:Spawn()
			ore:GetPhysicsObject():Wake()
		end

		self.crate_contents = {}
		self:SetHeldCapacity(0)
	end


	function ENT:AttachToVehicle(target, slot)
		--TODO: SFX

		local vec = target.jcms_miningCrateAttaches[slot]
		local crateType = self.CrateTypes[self.CrateType]
		local angAdd, posAdd = crateType.attachAngle, crateType.attachOffset

		self:SetParent(target)
		self:SetPos(vec + posAdd)
		self:SetParent()

		self:SetAngles(target:GetAngles() + angAdd)
		
		timer.Simple(0, function()
			constraint.Weld(target, self, 0, 0, 0, true, true)
		end)

		self:GetPhysicsObject():SetMass(25) --Vehicles can't park properly if we're too heavy


		self.jcms_attachedToVehicle = true
		self.jcms_attachedVehicle = target
		self.jcms_attachedSlot = slot

		target.jcms_attachedCrates[slot] = self
	end

	function ENT:FindAttachSlot(target)
		local i = 1

		while target.jcms_miningCrateAttaches[i] do
			if not IsValid(target.jcms_attachedCrates[i]) then
				return i
			end
			i = i + 1
		end
	end
end

