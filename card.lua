Card = {}
Card.__index = Card

value_map = {
    j = 11,
    q = 12,
    k = 13, 
    a = 14
}

function Card:new(rank, suit)
    local instance = setmetatable({}, self)
    instance.rank = rank
    instance.suit = suit
    instance.value = tonum(value_map[rank] or rank)

    instance.current_x = 0
    instance.current_y = 0
    instance.target_x = 0
    instance.target_y = 0
    instance.delay = 0
    return instance
end

function Card:type()
    local types = {
        d = 'weapon',
        h = 'potion',
    }
    return types[self.suit] or 'monster'
end

function Card:update()
    if (self.delay > 0) then
        self.delay -= 1
        return
    end
    self.current_x = lerp(self.current_x, self.target_x, 0.2)
    self.current_y = lerp(self.current_y, self.target_y, 0.2)
end

-- Usage
-- local myAcc = Account:new(100)
-- myAcc:deposit(50)
-- print(myAcc.balance) -- Output: 150
