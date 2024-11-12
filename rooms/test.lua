local lg = love.graphics
local Game = require "game"

local collision_rects = {
    Game.Rectangle(   0, 400, 1000, 200),
    Game.Rectangle(  40, 100,  100, 220),
    Game.Rectangle( 240, 100,  100, 220),
}
local room = Game.New_Room({
    collision_rects=collision_rects,
    respawn_positions={Game.Vector2(0, 360)},
})

function room.on_start(game)
    lg.setBackgroundColor(BG_COLOR)
end

function room.update(game, dt)
    if game.players[game.current_player].rectangle.x < 0 then
        Game.init_gui(game, Game.STATE_ROOM, 1, 2)
    end
end

function room.background_draw()
    lg.setColor(BG_COLOR)
    lg.rectangle("fill", 0, 400, Game.width, 200)
    
    lg.setColor(0,0,0)
    lg.line(0, 400, Game.width, 400)
    
    lg.setColor(1,1,1)
end

function room.foreground_draw(game)
    lg.setColor(BG_COLOR)
    for it_index=2,3 do
        local it = collision_rects[it_index]
        lg.rectangle("fill", it.x, it.y, it.width, it.height)
    end
    
    lg.setColor(0,0,0)
    for it_index=2,3 do
        local it = collision_rects[it_index]
        lg.rectangle("line", it.x, it.y, it.width, it.height)
    end
    
    lg.setColor(1,1,1)
end


return room
