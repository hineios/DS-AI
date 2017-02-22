-- local Vector3 = GLOBAL.Vector3
-- local dlcEnabled = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
-- local SEASONS = GLOBAL.SEASONS


-- Debug Helpers
GLOBAL.CHEATS_ENABLED = true
GLOBAL.require 'debugkeys' 
GLOBAL.require 'debughelpers'


local ArtificalWilsonEnabled = false
-- AddBrainPostInit("artificalwilson", ArtificalWilson)
-- AddBrainPostInit("walterbrain", WalterBrain)

-- Since the final brain a creature gets doesn't quite look like the brain
-- specified in code, use this utility to print a brain to the console and
-- to log.txt.
local function DumpBT(bnode, indent)
	local s = ""
	for i=1,indent do
		s = s.."|   "
	end
	s = s..bnode.name
	print(s)
	if bnode.children then
		for i,childnode in ipairs(bnode.children) do
			DumpBT(childnode, indent+1)
		end
	end
end


local function SetSelfAI()
	print("Enabling Artifical Wilson")
	
	--GLOBAL.ThePlayer:RemoveComponent("playercontroller")

	-- GLOBAL.ThePlayer:AddComponent("follower")
	-- GLOBAL.ThePlayer:AddComponent("homeseeker")
	GLOBAL.ThePlayer:AddTag("ArtificalWilson")
	
	local brain = GLOBAL.require "brains/walterbrain"
	GLOBAL.ThePlayer:SetBrain(brain)
	GLOBAL.ThePlayer:RestartBrain()
	-- DumpBT(GLOBAL.ThePlayer.brain.bt.root, 0)
	
	ArtificalWilsonEnabled = true
	
	--GLOBAL.ThePlayer:ListenForEvent("attacked", OnAttacked)
end

local function SetSelfNormal()
	print("Disabling Artifical Wilson")
	
	local brain = GLOBAL.require "brains/wilsonbrain"
	GLOBAL.ThePlayer:SetBrain(brain)
	GLOBAL.ThePlayer:RestartBrain()
	--DumpBT(GLOBAL.ThePlayer.brain.bt.root, 0)

	GLOBAL.ThePlayer:RemoveTag("ArtificalWilson")
	-- GLOBAL.ThePlayer:RemoveComponent("follower")
	-- GLOBAL.ThePlayer:RemoveComponent("homeseeker")
	
	ArtificalWilsonEnabled = false
end

--[[
-- TODO Maybe port this?
GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_P, function()
	local TheInput = GLOBAL.TheInput
	if not GLOBAL.IsPaused() and TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and not TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
		setSelfAI()
	elseif not GLOBAL.IsPaused() and TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
		setSelfNormal()
	end
end)
]]

--[[
-- TODO Finish spawning an Artificial Wilson
local function MakeClickableHearth(self, owner)
	local HealthBadge = self

local function spawnAI(sim)

	sim.SpawnWilson = function(inst)
		wilson = GLOBAL.c_spawn("wilson")
		pos = Vector3(GLOBAL.ThePlayer.Transform:GetWorldPosition())
		if wilson and pos then
			wilson:AddComponent("follower")
			wilson:AddComponent("homeseeker")
			wilson:AddComponent("inventory")
			wilson:AddTag("ArtificalWilson")
			
			local brain = GLOBAL.require "brains/artificalwilson"
			wilson:SetBrain(brain)
			wilson:RestartBrain()
			wilson.Transform:SetPosition(pos:Get())
		end
	end
	
	local function OnAttacked(inst, data)
		inst.components.combat:SetTarget(data.attacker)
	end
	
	
	
	sim.SetSelfAI = setSelfAI
	sim.SetSelfNormal = setSelfNormal
	
	
	sim.Crash = function(inst) local a = inst.components.crashGame.yay end

end

AddComponentPostInit("clock", spawnAI)

end
]]--


local function MakeClickableBrain(self, owner)

    local BrainBadge = self
	
    BrainBadge:SetClickable(true)

	local x = 0
	local darker = true
	local function BrainPulse(self)
		if not darker then
			x = x+.1
			if x >=1 then
				darker = true
				x = 1
			end
		else 
			x = x-.1
			if x <=.5 then
				darker = false
				x = .5
			end
		end

		BrainBadge.anim:GetAnimState():SetMultColour(x,x,x,1)
		self.BrainPulse = self:DoTaskInTime(.15, BrainPulse)
	end
	
	BrainBadge.OnMouseButton = function(self,button,down,x,y)	
		if down == true then
			if ArtificalWilsonEnabled then
				self.owner.BrainPulse:Cancel()
				BrainBadge.anim:GetAnimState():SetMultColour(1,1,1,1)
				SetSelfNormal()
			else
				BrainPulse(self.owner)
				SetSelfAI()
			end
		end
	end
end

AddClassPostConstruct("widgets/sanitybadge", MakeClickableBrain)

local function MakeClickableStomach(self, owner)

	local StomachBadge = self

	StomachBadge:SetClickable(true)
	StomachBadge.OnMouseButton = function(self,button,down,x,y)
		if down == true then
			GLOBAL.c_give("log",20)
			GLOBAL.c_give("twigs",20)
			GLOBAL.c_give("cutgrass",20)
			GLOBAL.c_give("flint",20)
			GLOBAL.c_give("goldnugget",20)
			GLOBAL.c_give("rocks",20)
			GLOBAL.c_give("charcoal",6)
			GLOBAL.c_give("berries",10)
			GLOBAL.c_give("carrot",10)
			GLOBAL.c_give("acorn_cooked",4)
			GLOBAL.c_give("monstermeat",4)
			GLOBAL.c_give("smallmeat",4)
			GLOBAL.c_give("fish",4)
			GLOBAL.c_give("green_cap",4)
		end
	end
end

AddClassPostConstruct("widgets/hungerbadge", MakeClickableStomach)

-- ---------------------------------------------------------------------------------
-- -- LOCOMOTOR MOD
-- -- TODO: Make an equivalent non RoG onupdate function and check if DLC enabled
-- --       to load the right one. Will probabl crash the game if you try to load
-- --       this w/out expansion


-- local distsq = GLOBAL.distsq

-- -- 99% taken directly from locomotor component.
-- local function RoGOnUpdate(self,dt)

--     -- Import the local variables (or copy them)
--     local PATHFIND_PERIOD = 1
--     local PATHFIND_MAX_RANGE = 40
--     local STATUS_CALCULATING = 0
--     local STATUS_FOUNDPATH = 1
--     local STATUS_NOPATH = 2
--     local NO_ISLAND = 127
--     local ARRIVE_STEP = .15

--     self.OnUpdate = function(self,dt)
--         if not self.inst:IsValid() then
--             self:ResetPath()
--             self.inst:StopUpdatingComponent(self)   
--             return
--         end
        
--         if self.enablegroundspeedmultiplier then
--             self.creep_check_timeout = self.creep_check_timeout - dt
--             if self.creep_check_timeout < 0 then
--                 self:UpdateGroundSpeedMultiplier()
--                 self.creep_check_timeout = .5
--             end
--         end
        
        
--         if self.dest then
--             if not self.dest:IsValid() or (self.bufferedaction and not self.bufferedaction:IsValid()) then
--                 self:Clear()
--                 return
--             end
            
--             if self.inst.components.health and self.inst.components.health:IsDead() then
--                 self:Clear()
--                 return
--             end
            
--             local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
--             local mypos_x, mypos_y, mypos_z= self.inst.Transform:GetWorldPosition()
--             local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)
    
--             local run_dist = self:GetRunSpeed()*dt*.5
--             if dsq <= math.max(run_dist*run_dist, self.arrive_dist*self.arrive_dist) then
--                 self.inst:PushEvent("onreachdestination", {target=self.dest.inst, pos=Point(destpos_x, destpos_y, destpos_z)})
--                 if self.atdestfn then
--                     self.atdestfn(self.inst)
--                 end
    
--                 if self.bufferedaction and self.bufferedaction ~= self.inst.bufferedaction then
                
--                     if self.bufferedaction.target and self.bufferedaction.target.Transform then
--                         self.inst:FacePoint(self.bufferedaction.target.Transform:GetWorldPosition())
--                     end
--                     self.inst:PushBufferedAction(self.bufferedaction)
--                 end
--                 self:Stop()
--                 self:Clear()
--             else
--                 --Print(VERBOSITY.DEBUG, "LOCOMOTING")
--                 if self:WaitingForPathSearch() then
--                     local pathstatus = GetWorld().Pathfinder:GetSearchStatus(self.path.handle)
--                     --Print(VERBOSITY.DEBUG, "HAS PATH SEARCH", pathstatus)
--                     --print("HAS PATH SEARCH " .. tostring(pathstatus))
--                     if pathstatus ~= STATUS_CALCULATING then
--                         --Print(VERBOSITY.DEBUG, "PATH CALCULATION complete", pathstatus)
--                         print("PATH CALC COMPLETE " .. tostring(pathstatus))
--                         print("STATUS_FOUNDPATH = " .. tostring(STATUS_FOUNDPATH))
--                         if pathstatus == STATUS_FOUNDPATH then
--                             --Print(VERBOSITY.DEBUG, "PATH FOUND")
--                             print("PATH FOUND")
--                             local foundpath = GetWorld().Pathfinder:GetSearchResult(self.path.handle)
--                             if foundpath then
--                                 --Print(VERBOSITY.DEBUG, string.format("PATH %d steps ", #foundpath.steps))
--                                 print(string.format("PATH %d steps ", #foundpath.steps))
    
--                                 if #foundpath.steps > 2 then
--                                     self.path.steps = foundpath.steps
--                                     self.path.currentstep = 2
    
--                                     -- for k,v in ipairs(foundpath.steps) do
--                                     --     Print(VERBOSITY.DEBUG, string.format("%d, %s", k, tostring(Point(v.x, v.y, v.z))))
--                                     -- end
    
--                                 else
--                                     --Print(VERBOSITY.DEBUG, "DISCARDING straight line path")
--                                     self.path.steps = nil
--                                     self.path.currentstep = nil
--                                 end
--                             else
--                                 print("EMPTY PATH")
--                                 GetWorld().Pathfinder:KillSearch(self.path.handle)
--                                 self.path.handle = nil
--                                 self.inst:PushEvent("noPathFound", {inst=self.inst, target=self.dest.inst, pos=Point(destpos_x, destpos_y, destpos_z)})
                                
--                             end
--                         else
--                             if pathstatus == nil then
--                                 print(string.format("LOST PATH SEARCH %u. Maybe it timed out?", self.path.handle))
--                             else
--                                 print("NO PATH")
--                                 GetWorld().Pathfinder:KillSearch(self.path.handle)
--                                 self.path.handle = nil
--                                 self.inst:PushEvent("noPathFound", {inst=self.inst, target=self.dest.inst, pos=Point(destpos_x, destpos_y, destpos_z)})
                                
--                             end
--                         end
    
--                         if self.path and self.path.handle then
--                             GetWorld().Pathfinder:KillSearch(self.path.handle)
--                             self.path.handle = nil
--                         end
--                     end
--                 end
    
--                 if not self.inst.sg or self.inst.sg:HasStateTag("canrotate") then
--                     --Print(VERBOSITY.DEBUG, "CANROTATE")
--                     local facepos_x, facepos_y, facepos_z = destpos_x, destpos_y, destpos_z
    
--                     if self.path and self.path.steps and self.path.currentstep < #self.path.steps then
--                         --Print(VERBOSITY.DEBUG, "FOLLOW PATH")
--                         --print("FOLLOW PATH")
--                         local step = self.path.steps[self.path.currentstep]
--                         local steppos_x, steppos_y, steppos_z = step.x, step.y, step.z
    
--                         --Print(VERBOSITY.DEBUG, string.format("CURRENT STEP %d/%d - %s", self.path.currentstep, #self.path.steps, tostring(steppos)))
                        
    
--                         local step_distsq = distsq(mypos_x, mypos_z, steppos_x, steppos_z)
--                         if step_distsq <= (self.arrive_step_dist)*(self.arrive_step_dist) then
--                             self.path.currentstep = self.path.currentstep + 1
    
--                             if self.path.currentstep < #self.path.steps then
--                                 step = self.path.steps[self.path.currentstep]
--                                 steppos_x, steppos_y, steppos_z = step.x, step.y, step.z
    
                                
--                             else
                                
--                                 steppos_x, steppos_y, steppos_z = destpos_x, destpos_y, destpos_z
--                             end
--                         end
--                         facepos_x, facepos_y, facepos_z = steppos_x, steppos_y, steppos_z
--                     end
    
--                     local x,y,z = self.inst.Physics:GetMotorVel()
--                     if x < 0 then
--                         local angle = self.inst:GetAngleToPoint(facepos_x, facepos_y, facepos_z)
--                         self.inst.Transform:SetRotation(180 + angle)
--                     else
--                         self.inst:FacePoint(facepos_x, facepos_y, facepos_z)
--                     end
    
--                 end
                
--                 self.wantstomoveforward = self.wantstomoveforward or not self:WaitingForPathSearch()
--             end
--         end
        
--         local is_moving = self.inst.sg and self.inst.sg:HasStateTag("moving")
--         local is_running = self.inst.sg and self.inst.sg:HasStateTag("running")
--         local should_locomote = (not is_moving ~= not self.wantstomoveforward) or (is_moving and (not is_running ~= not self.wantstorun)) -- 'not' is being used on this line as a cast-to-boolean operator
--         if not self.inst:IsInLimbo() and should_locomote then
--             self.inst:PushEvent("locomote")
--         elseif not self.wantstomoveforward and not self:WaitingForPathSearch() then
--             self:ResetPath()
--             self.inst:StopUpdatingComponent(self)
--         end
        
--         local cur_speed = self.inst.Physics:GetMotorSpeed()
--         if cur_speed > 0 then
            
--             local speed_mult = self:GetSpeedMultiplier()
--             local desired_speed = self.isrunning and self.runspeed or self.walkspeed
--             if self.dest and self.dest:IsValid() then
--                 local destpos_x, destpos_y, destpos_z = self.dest:GetPoint()
--                 local mypos_x, mypos_y, mypos_z = self.inst.Transform:GetWorldPosition()
--                 local dsq = distsq(destpos_x, destpos_z, mypos_x, mypos_z)
--                 if dsq <= .25 then
--                     speed_mult = math.max(.33, math.sqrt(dsq))
--                 end
--             end
            
--             self.inst.Physics:SetMotorVel((desired_speed + self.bonusspeed) * speed_mult, 0, 0)
--         end
--     end

-- end


-- AddComponentPostInit("locomotor",RoGOnUpdate)


-- local function ReallyFull(self)

--     self.IsTotallyFull = function()
--         local invFull = self:IsFull()
--         local overFull = true
--         if self.overflow then
--             if self.overflow.components.container then
--                 --print("Is my " .. self.overflow.prefab .. " full?")
--                 overFull = self.overflow.components.container:IsFull()
--             end
--         end    
--         return not not invFull and not not overFull
--     end

-- end

-- AddComponentPostInit("inventory", ReallyFull)

-- -- New components that have OnLoad need to be loaded early!
-- local function AddNewComponents(player)
--    player:AddComponent("prioritizer")
--    player:AddComponent("cartographer")
--    player:AddComponent("chef")
--    --player:AddTag("debugPrint")
-- end

-- AddPlayerPostInit(AddNewComponents)
