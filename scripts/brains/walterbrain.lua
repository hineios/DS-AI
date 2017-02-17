local WalterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function WalterBrain:OnStart()
    local root = PriorityNode(
    {
    	Wander(self.inst, nil, 30)
    }, 1)
    

    self.bt = BT(self.inst, root)

end

return WalterBrain