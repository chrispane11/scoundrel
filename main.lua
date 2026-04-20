-- 1. Create the class table
suit_spr = {
    h = 4, 
    d = 5,
    s = 6,
    c = 7,
}
type_spr = {
    weapon = 8,
    potion = 9,
    monster = 10,
}
red = 8
black = 5
suit_color = {
    h = red, 
    d = red,
    s = black,
    c = black,
}

started = false
cards = {}
health = 20
dungeon = {}
selected_index = 1

weapon_card = nil

cursor_x = 0
cursor_y = 0
cursor_target_x = 0
cursor_target_y = 0

function render_card(card)
    local x, y = card.current_x, card.current_y
    local tl_x, tl_y = center_spr(x, y, 3, 4)
    spr(1, tl_x, tl_y, 3, 4)

    spr(suit_spr[card.suit], tl_x + 2, tl_y + 2 )

    local icon_tl_x, icon_tl_y = center_spr(x, y, 1, 1)
    spr(type_spr[card:type()], icon_tl_x, icon_tl_y)

    print(card.rank, tl_x + 10, tl_y + 4, suit_color[card.suit])

    print(card.value, tl_x + 2, tl_y + 4 * 8 - 8, 13)
end

function render_cursor()
    local card = dungeon[selected_index]
    local tl_x, tl_y = center_spr(cursor_x, cursor_y, 3, 4)
    spr(11, flr(tl_x), flr(tl_y), 3, 4)
end

function draw_card()
    local i = flr(rnd(#cards)) + 1
    local card = cards[i]
    deli(cards, i)
    return card
end

function get_card_slot_position(i)
    return (i - 1) * 26 + 24, 32
end

function equip_weapon(card)
    weapon_card = card
end

function create_dungeon()
    for i = 1,4 do
        local card = draw_card()
        card.current_x = -10
        card.current_y = 140
        card.delay = (i - 1) * 5
        add(dungeon, card)
    end
end

function refresh_dungeon()
    for i = 1,3 do
        local card = draw_card()
        card.current_x = -10
        card.current_y = 140
        card.delay = (i - 1) * 5
        add(dungeon, card)
    end
end

function _init()
    poke(0x5f2c,0x40)
    -- Create the deck (w/o some cards)
    local ranks = {'j', 'q', 'k', 'a'}
    local suits = {'c', 'd', 'h', 's'}
    for v = 2,10 do
        add(ranks, ''..v)
    end

    foreach(suits, function (suit)
        foreach(ranks, function (rank)
            if (suit == 'd' or suit == 'h') and (rank == 'a' or rank == 'j' or rank == 'q' or rank == 'k') then
                return
            end
            add(cards, Card:new(rank, suit))
        end)
    end)
end

states = {
    menu = {
        update = function ()
            print("scoundrel", 32, 64, 0)
        end,
        draw = function ()
            
        end
    },
    'dungeon',
    'dungeon-menu'
}
state = 'menu'

function _update ()
    if (btn(O) and not started) then
        create_dungeon()
        state = 'dungeon'
        started = true
        return
    end 

    if (btnp(L)) then
        if (selected_index - 1 < 1) then
             selected_index = count(dungeon)
        else
            selected_index -= 1
        end
    end

    if (btnp(R)) then
        if (selected_index + 1 > count(dungeon)) then
             selected_index = 1
        else
            selected_index += 1
        end
    end

    local card = dungeon[selected_index] 
    if (card) then
        cursor_target_x = card.current_x
        cursor_target_y = card.current_y
    end

    if (btnp(X) and card) then
        local type = card:type()
        if (type == 'weapon') then
            equip_weapon(card)

            deli(dungeon, selected_index)
            selected_index = 1
        elseif (type == 'potion') then
            health = min(health + card.value, 20)

            -- update dungeon
            deli(dungeon, selected_index)
            selected_index = 1
        else
            local damage = card.value

            --
            deli(dungeon, selected_index)
            selected_index = 1
        end
    end

    local i = 1
    foreach(dungeon, function (card)
        if not card then return end
        if (card.delay > 0) then
            card.delay -= 1
            i += 1
            return
        end
        local target_x, target_y = get_card_slot_position(i)
        card.current_x = lerp(card.current_x, target_x, 0.2)
        card.current_y = lerp(card.current_y, target_y, 0.2)
        i += 1
    end)

    cursor_x = lerp(cursor_x, cursor_target_x, 0.5)
    cursor_y = lerp(cursor_y, cursor_target_y, 0.5)
    -- snap if needed (looks better)
    if (abs(cursor_x - cursor_target_x) < 0.15) then cursor_x = cursor_target_x end
    if (abs(cursor_y - cursor_target_y) < 0.15) then cursor_y = cursor_target_y end

    if (weapon_card) then
        weapon_card.current_x = lerp(weapon_card.current_x, 64, 0.2)
        weapon_card.current_y = lerp(weapon_card.current_y, 100, 0.2)
    end
end


function _draw()
    cls(1)
    if not started then
        print("scoundrel", 32, 64, 0)
        return
    end

    if (count(dungeon) > 0) then
        local i = 1
        foreach(dungeon, render_card)
    end

    if (weapon_card) then
        render_card(weapon_card)
    end

    render_cursor()

    print("HP:"..health, 4, 120, 5)
    print(''..selected_index, 4, 110, 5)
end