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

function Card:render()
    local x, y = self.current_x, self.current_y
    local tl_x, tl_y = center_spr(x, y, 3, 4)

    local spr_n = self.face_down and 64 or 1
    spr(spr_n, tl_x, tl_y, 3, 4)

    if (not self.face_down) then
        spr(suit_spr[self.suit], tl_x + 2, tl_y + 2 )

        local icon_tl_x, icon_tl_y = center_spr(x, y, 1, 1)
        spr(type_spr[self:type()], icon_tl_x, icon_tl_y)

        print(self.rank, tl_x + 10, tl_y + 4, suit_color[self.suit])

        print(self.value, tl_x + 2, tl_y + 4 * 8 - 8, 13)
    end

end
