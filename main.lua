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

cards = {}
health = 20
dungeon = {}
discards = {}
selected_index = 1
reroll_selected = false

weapon_card = nil
kills = {}

cursor_x = 0
cursor_y = 0
cursor_target_x = 0
cursor_target_y = 0

function render_card(card)
    local x, y = card.current_x, card.current_y
    local tl_x, tl_y = center_spr(x, y, 3, 4)
    spr(card.face_down and 64 or 1, tl_x, tl_y, 3, 4)

    if (not card.face_down) then
        spr(suit_spr[card.suit], tl_x + 2, tl_y + 2 )

        local icon_tl_x, icon_tl_y = center_spr(x, y, 1, 1)
        spr(type_spr[card:type()], icon_tl_x, icon_tl_y)

        print(card.rank, tl_x + 10, tl_y + 4, suit_color[card.suit])

        print(card.value, tl_x + 2, tl_y + 4 * 8 - 8, 13)
    end
end

function render_cursor()
    local card = dungeon[selected_index]
    local tl_x, tl_y = center_spr(cursor_x, cursor_y, 3, 4)
    spr(11, flr(tl_x), flr(tl_y), 3, 4)
end

function draw_card()
    local card = cards[count(cards)]
    card.face_down = false
    deli(cards, count(cards))
    return card
end

function get_card_slot_position(i)
    return (i - 1) * 26 + 24, 32
end

function equip_weapon(card)
    if weapon_card then
        add_to_discard(weapon_card)
        for i,card in ipairs(kills) do
            card.delay = i * 2
            add_to_discard(card)
        end
    end

    weapon_card = card
    kills = {}

end

function create_dungeon()
    for i = 1,4 do
        local card = draw_card()
        card.delay = (i - 1) * 5
        add(dungeon, card)
    end
end

potion_used = false
rerolled_recently = false
function refresh_dungeon()
    for i = 1,3 do
        local card = draw_card()
        card.delay = (i - 1) * 5
        add(dungeon, card, 1)
    end
    potion_used = false
    rerolled_recently = false
end

function add_to_discard(card)
    add(discards, card)
    card.target_x = 110
    card.target_y = 80
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
            local card = Card:new(rank, suit)
            card.current_x = 40
            card.current_y = 100
            card.target_x = 40
            card.target_y = 100
            card.face_down = true
            add(cards, card)
        end)
    end)
    shuffle(cards)
end

function remove_selected_from_dungeon()
    deli(dungeon, selected_index)
    selected_index = selected_index - 1 < 1 and 1 or selected_index - 1
end

function reroll_dungeon()
    for i, card in ipairs(dungeon) do
        card.target_x = 40
        card.target_y = 100
        card.delay = (i - 1) * 2
        card.face_down = true
        add(cards, card, 1)
    end

    dungeon = {}
    create_dungeon()

    reroll_selected = false
    rerolled_recently = true
end

attack_mode_data = {
    is_choosing = false,
    card = nil,
    choice_index = 1,
    choices = {'weapon', 'barehand', 'cancel'}
}

current_state = 'menu'
menu_state = {
    update = function ()
        if btn(O) then
            create_dungeon()
            current_state = 'dungeon'
        end 
    end,
    draw = function ()
        print("scoundrel", 32, 64, 0)
    end
}
dungeon_state = {
    update = function ()
        local card = dungeon[selected_index] 
        if (attack_mode_data.is_choosing) then
            local i = attack_mode_data.choice_index
            if (btnp(⬇️)) then
                attack_mode_data.choice_index = (i + 1 > count(attack_mode_data.choices)) and 1 or i + 1
            elseif (btnp(⬆️)) then
                attack_mode_data.choice_index = (i - 1 < 1) and count(attack_mode_data.choices) or i - 1
            end
            if (btnp(❎)) then
                local choice = attack_mode_data.choices[attack_mode_data.choice_index]
                if (choice == 'weapon') then
                    health -= max(attack_mode_data.card.value - weapon_card.value, 0)
                    add(kills, attack_mode_data.card)

                    remove_selected_from_dungeon()
                elseif (choice == 'barehand') then
                    local damage = card.value
                    health -= damage

                    add_to_discard(card)
                    remove_selected_from_dungeon()
                end
                attack_mode_data.is_choosing = false
            end
        else
            if (btnp(⬅️)) then
                selected_index = (selected_index - 1 < 1) and count(dungeon) or selected_index - 1
            end

            if (btnp(➡️)) then
                selected_index = (selected_index + 1 > count(dungeon)) and 1 or selected_index + 1
            end

            if (btnp(⬇️)) then
                reroll_selected = true
            end
            if (btnp(⬆️)) then
                reroll_selected = false
            end
            reroll_selected = reroll_selected and not rerolled_recently and count(dungeon) == 4

            if (btnp(❎) and card and not reroll_selected) then
                local type = card:type()
                if (type == 'weapon') then
                    equip_weapon(card)

                    remove_selected_from_dungeon()
                elseif (type == 'potion') then
                    if not potion_used then
                        health = min(health + card.value, 20)
                    end

                    -- update dungeon
                    add_to_discard(card)
                    remove_selected_from_dungeon()

                    potion_used = true
                else
                    local can_use_weapon = weapon_card and (count(kills) == 0 or kills[count(kills)].value > card.value)
                    if can_use_weapon then
                        attack_mode_data.is_choosing = true
                        attack_mode_data.card = card
                        attack_mode_data.choice_index = 1
                    else
                        local damage = card.value
                        health -= damage

                        add_to_discard(card)
                        remove_selected_from_dungeon()
                    end

                end
            elseif (btnp(❎) and reroll_selected) then
                reroll_dungeon()
            end

        end

        if (count(dungeon) == 1) then
            refresh_dungeon()
        end

        for i, card in ipairs(dungeon) do
            if not card then return end
            if (card.delay > 0) then
                card.delay -= 1
                i += 1
                return
            end
            local target_x, target_y = get_card_slot_position(i)
            card.current_x = lerp(card.current_x, target_x, 0.2)
            card.current_y = lerp(card.current_y, target_y, 0.2)
        end

        cursor_target_x = card.current_x
        cursor_target_y = card.current_y

        cursor_x = lerp(cursor_x, cursor_target_x, 0.5)
        cursor_y = lerp(cursor_y, cursor_target_y, 0.5)
        -- snap if needed (looks better)
        if (abs(cursor_x - cursor_target_x) < 0.15) then cursor_x = cursor_target_x end
        if (abs(cursor_y - cursor_target_y) < 0.15) then cursor_y = cursor_target_y end

        if (weapon_card) then
            weapon_card.current_x = lerp(weapon_card.current_x, 64, 0.2)
            weapon_card.current_y = lerp(weapon_card.current_y, 100, 0.2)
        end
        for i, kill in ipairs(kills) do
            kill.current_x = lerp(kill.current_x, weapon_card.current_x, 0.2)
            kill.current_y = lerp(kill.current_y, weapon_card.current_y + 10, 0.2)
        end
        foreach(discards, function (card)
            if (card.delay > 0) then
                card.delay -= 1
                return
            end
            card.current_x = lerp(card.current_x, card.target_x, 0.2)
            card.current_y = lerp(card.current_y, card.target_y, 0.2)
        end)
        foreach(cards, function (card)
            if (card.delay > 0) then
                card.delay -= 1
                return
            end
            card.current_x = lerp(card.current_x, card.target_x, 0.2)
            card.current_y = lerp(card.current_y, card.target_y, 0.2)
        end)
    end,
    draw = function ()
        foreach(dungeon, render_card)
        foreach(discards, render_card)
        foreach(cards, render_card)

        if (weapon_card) then
            render_card(weapon_card)
            foreach(kills, render_card)
        end

        if not reroll_selected then
            render_cursor()
        end

        if not rerolled_recently and count(dungeon) == 4 then
            print("Reroll", 100, 54, reroll_selected and 9 or 5)
        end

        if (attack_mode_data.is_choosing) then
            print("Use weapon?", 56, 60, attack_mode_data.choices[attack_mode_data.choice_index] == 'weapon' and 9 or 5)
            print("Use barehand?", 56, 68, attack_mode_data.choices[attack_mode_data.choice_index] == 'barehand' and 9 or 5)
            print("Cancel", 56, 76, attack_mode_data.choices[attack_mode_data.choice_index] == 'cancel' and 9 or 5)
        end

        print("HP:"..health, 4, 120, 5)
    end
}
states = {
    menu = menu_state,
    dungeon = dungeon_state,
}

function _update ()
    states[current_state].update()
end


function _draw()
    cls(1)
    states[current_state].draw()
end