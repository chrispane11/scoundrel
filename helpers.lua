function lerp(a, b, t) return a + (b - a) * t end
function vec2(x,y) return { x=x or 0, y=y or 0 } end

function shuffle(t)
  for i = #t, 2, -1 do
    local j = flr(rnd(i)) + 1
    t[i], t[j] = t[j], t[i] -- swap elements
  end
end


function center_spr(x, y, spr_w, spr_h)
    local w, h = spr_w * 8, spr_h * 8
    return x - w / 2, y - h / 2
end

-- function _init()
--   states = {}
--   -- Push the initial state
--   push_state(state_menu)
-- end

-- function _update()
--   local current = states[#states]
--   if current and current.update then current.update() end
-- end

-- function _draw()
--   -- Optionally draw all states for transparency, or just the top
--   for s in all(states) do
--     if s.draw then s.draw() end
--   end
-- end

-- function push_state(s)
--   if s.init then s.init() end
--   add(states, s)
-- end

-- function pop_state()
--   deli(states, #states)
-- end
