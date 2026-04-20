L, R, U, D, O, X = 0, 1, 2, 3, 4, 5
function lerp(a, b, t) return a + (b - a) * t end
function vec2(x,y) return { x=x or 0, y=y or 0 } end

function center_spr(x, y, spr_w, spr_h)
    local w, h = spr_w * 8, spr_h * 8
    return x - w / 2, y - h / 2
end
