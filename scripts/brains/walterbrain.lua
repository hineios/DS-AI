local WalterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WalterBrain:OnStart()
	local times = {
		minwalktime = 2,
	    randwalktime = 3,
	    minwaittime = 0,
	    randwaittime = 1
	}

    local root = PriorityNode(
    {
    	Wander(self.inst, nil, 30, times)
    }, 1)
    

    self.bt = BT(self.inst, root)

end

return WalterBrain