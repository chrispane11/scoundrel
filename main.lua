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

function render_card_callback(card) card:render() end

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
        card.delay = (i - 1) * 3
        add(dungeon, card)
    end
end

function refresh_dungeon()
    for i = 1,min(3, count(cards)) do
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

function remove_selected_from_dungeon()
    deli(dungeon, selected_index)
    selected_index = selected_index - 1 < 1 and 1 or selected_index - 1
end

function reroll_dungeon()
    for i, card in ipairs(dungeon) do
        card.target_x = 20
        card.target_y = 90
        card.delay = (i - 1) * 2
        card.face_down = true
        add(cards, card, 1)
    end

    dungeon = {}
    create_dungeon()

    reroll_selected = false
    rerolled_recently = true
end

bg_offset = 0
function draw_background()
    local sx, sy = get_coords_for_sspr(67)
    for y = 0, 4 do
        for x = 0, 4 do
            sspr(sx, sy, 32, 32, x * 32 - bg_offset % 32, y * 32 - bg_offset % 32)
        end
    end
end


attack_mode_data = {
    is_choosing = false,
    card = nil,
    choice_index = 1,
    choices = {'weapon', 'barehand', 'cancel'}
}

attack_mode_choice_state = {
    update = function ()
        local i = attack_mode_data.choice_index
        local card = dungeon[selected_index]
        if (btnp(➡️)) then
            attack_mode_data.choice_index = (i + 1 > count(attack_mode_data.choices)) and 1 or i + 1
        elseif (btnp(⬅️)) then
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

            pop_state()
        end
    end,
    draw = function ()
        local choice = attack_mode_data.choices[attack_mode_data.choice_index]

        local offset_map = { -14, 0, 14 }

        local offset = offset_map[attack_mode_data.choice_index]
        local tl_x, tl_y = center_spr(64, 64, 1, 1)

        local backdrop_tl_x, backdrop_tl_y = tl_x - 14 - 2, tl_y - 2
        local backdrop_br_x, backdrop_br_y = tl_x + 21 + 2, tl_y + 9

        rectfill(backdrop_tl_x, backdrop_tl_y, backdrop_br_x, backdrop_br_y, 3)
        rectfill(tl_x + offset - 3,
            tl_y - 3,
            tl_x + offset + 10, 
            tl_y + 8 + 2, 11)
        spr(8, tl_x - 14, tl_y)
        spr(24, tl_x, tl_y)
        spr(25, tl_x + 14, tl_y)

        rect(tl_x + offset - 3,
            tl_y - 3,
            tl_x + offset + 10, 
            tl_y + 8 + 2, 9)
    end
}
game_finished_state = {
    init = function ()
        game_finished_type = nil
        transition_started = false
        fade_timer = 0
        fade_table = {
            -- step 1: dim
            {0,0,1,1,2,1,5,6,2,4,9,3,1,1,2,4},
            -- step 2: dark
            {0,0,0,0,1,0,1,5,0,2,2,1,0,0,1,2},
            -- step 3: very dark
            {0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
            -- step 4: blackout
            {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
        }
    end,
    update = function ()
        if (btnp(❎) and not transition_started) then
            transition_started = true
            fade_timer = 20
        end
        if (transition_started) then
            if (fade_timer > 0) then
                fade_timer -= 1
            end
            if (fade_timer == 0) then
                states = {}
                push_state(menu_state)
            end
        end
    end,
    draw = function ()
        local w = 64
        local h = 40
        local x0 = 64 - w/2
        local y0 = 64 - h/2
        local x1 = x0 + w - 1
        local y1 = y0 + h - 1
        
        rrectfill(x0, y0, w, h, 3, 9)
        rrect(x0, y0, w, h, 3, 10)
        local text = game_finished_type == 'win' and "you win!" or "game over"
        print_centered(text, (y0 + y1 - 15) / 2, 7)
        print_centered("press x", (y0 + y1 + 10) / 2, 7)
        if (transition_started) then
            local step = 4
            if (fade_timer <= 20 and fade_timer >= 16) then
                step = 1
            elseif (fade_timer <= 15 and fade_timer >= 11) then
                step = 2
            elseif (fade_timer <= 10 and fade_timer >= 6) then
                step = 3
            end
            local ramp = fade_table[step]
            for i = 0,15 do -- pico color indexes start at 0
                pal(i, ramp[i + 1], 1)
            end
        end
    end
}

menu_state = {
    init = function ()
        music(-1)
        title = {
            128,
            130,
            132,
            134,
            136,
            138,
            140,
            142,
            160,
        }
        
    end,
    update = function ()
        if btn(🅾️) or btn(❎) or btn(⬆️) or btn(⬇️) or btn(⬅️) or btn(➡️) then
            pop_state()
            push_state(dungeon_state)
        end 
    end,
    draw = function ()

        for i, spr_n in ipairs(title) do
            local x, y = get_coords_for_sspr(spr_n)
            sspr(
                x,
                y,
                16,
                16,
                6 + (i - 1) * 12,
                32 + flr(sin((t() + i)/6) * 4)
            )
        end

        print_centered("press any key to begin", 84, 7)
    end
}
dungeon_state = {
    init = function ()

        music(0, 2000)

        local ranks = {'j', 'q', 'k', 'a'}
        local suits = {'c', 'd', 'h', 's'}
        for v = 2,10 do
            add(ranks, ''..v)
        end

        cards = {}
        health = 20
        dungeon = {}
        discards = {}
        selected_index = 1
        reroll_selected = false

        weapon_card = nil
        kills = {}

        potion_used = false
        rerolled_recently = false

        cursor_x = -10
        cursor_y = 120
        cursor_target_x = 0
        cursor_target_y = 0
        foreach(suits, function (suit)
            foreach(ranks, function (rank)
                if (suit == 'd' or suit == 'h') and (rank == 'a' or rank == 'j' or rank == 'q' or rank == 'k') then
                    return
                end
                local card = Card:new(rank, suit)
                card.current_x = 20
                card.current_y = 90
                card.target_x = 20
                card.target_y = 90
                card.face_down = true
                add(cards, card)
            end)
        end)
        shuffle(cards)
        create_dungeon()
    end,
    update = function ()
        local card = dungeon[selected_index] 
        if (btnp(⬅️)) then
            selected_index = (selected_index - 1 < 1) and count(dungeon) or selected_index - 1
            sfx(2)
        end

        if (btnp(➡️)) then
            selected_index = (selected_index + 1 > count(dungeon)) and 1 or selected_index + 1
            sfx(2)
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

                sfx(3)

                potion_used = true
            else
                local can_use_weapon = weapon_card and (count(kills) == 0 or kills[count(kills)].value > card.value)
                if can_use_weapon then
                    attack_mode_data.is_choosing = true
                    attack_mode_data.card = card
                    attack_mode_data.choice_index = 1
                    push_state(attack_mode_choice_state)
                else
                    local damage = card.value
                    health = max(0, health - damage)

                    add_to_discard(card)
                    remove_selected_from_dungeon()
                end

            end
        elseif (btnp(❎) and reroll_selected) then
            reroll_dungeon()
        end

        if (health <= 0) then
            game_finished_type = "loss"
            push_state(game_finished_state)
            return
        elseif (count(dungeon) == 0) then
            game_finished_type = "win"
            push_state(game_finished_state)
            return
        end


        if (count(dungeon) == 1 and count(cards) > 0) then
            refresh_dungeon()
        end

        for i, card in ipairs(dungeon) do
            if not card then return end
            if (card.delay > 0) then
                card.delay -= 1
            else
                local target_x, target_y = get_card_slot_position(i)
                card.current_x = lerp(card.current_x, target_x, 0.2)
                card.current_y = lerp(card.current_y, target_y, 0.2)
            end
        end

        if (card) then
            cursor_target_x = card.current_x
            cursor_target_y = card.current_y
        end

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
        foreach(discards, function (card) card:update() end)
        foreach(cards, function (card) card:update() end)
    end,
    draw = function ()
        foreach(dungeon, render_card_callback)
        foreach(discards, render_card_callback)
        foreach(cards, render_card_callback)

        if (weapon_card) then
            weapon_card:render()
            foreach(kills, render_card_callback)
        end

        if not reroll_selected then
            render_cursor()
        end

        if not rerolled_recently and count(dungeon) == 4 then
            rectfill(98, 52, 124, 60, 8)
            print("reroll", 100, 54, reroll_selected and 9 or 5)
        end

        print("hp:"..health, 4, 112, 8)
        rect(4, 120, 4 + 20, 124, 5)
        rectfill(4, 120, 4 + health, 124, 8)
    end
}
states = {}

function push_state(s)
  if s.init then s.init() end
  add(states, s)
end

function pop_state()
  deli(states, #states)
end


function _init()
    push_state(menu_state)
end


function _update ()
    local current = states[#states]
    -- bg_offset += 0.15
    if current and current.update then current.update() end
end

function _draw()
    cls(1)
    pal()
    draw_background()

    for s in all(states) do
        if s.draw then s.draw() end
    end
end