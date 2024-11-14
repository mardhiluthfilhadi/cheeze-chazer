local lg = love.graphics
local Game = require "game"

local collision_rects = {
    Game.Rectangle(  40, 100, 100, 220),
    Game.Rectangle( 240, 100, 100, 220),
    Game.Rectangle( 700, 450, 500, 600),
    Game.Rectangle(   0, 400, 700, 600),
}

local room = Game.New_Room("TEST", {
    collision_rects=collision_rects,
    respawn_positions={Game.Vector2(0, 360)},
})

function room.on_start(game)
    lg.setBackgroundColor(BG_COLOR)
end

local life_mode = false

function room.update(game, dt)
    if game.players[game.current_player].rectangle.x < 0 then
        Game.init_gui(game, Game.STATE_ROOM, Game.START, 2)
    end
    life_mode = game.players[game.current_player].rectangle.x > 700
        
    if life_mode then
        if game.keyboard["up"] and game.keyboard["up"].isDown then
            room.collision_rects[3].y = room.collision_rects[3].y-30*dt
        elseif game.keyboard["down"] and game.keyboard["down"].isDown then
            room.collision_rects[3].y = room.collision_rects[3].y+30*dt
        end
        local py = room.collision_rects[3].y - game.players[game.current_player].rectangle.height
        game.players[game.current_player].rectangle.y = py
    end
end

function room.background_draw()
    lg.setColor(BG_COLOR)
    lg.rectangle("fill", 0, 400, Game.width, 200)
    
    lg.setColor(0,0,0)
    lg.line(0, 400, 700, 400)
    lg.line(700, room.collision_rects[3].y, 700, 400)
    lg.line(700, room.collision_rects[3].y, 800, room.collision_rects[3].y)
    
    lg.setColor(1,1,1)
end

function room.foreground_draw(game)
    lg.setColor(BG_COLOR)
    for it_index=1,2 do
        local it = collision_rects[it_index]
        lg.rectangle("fill", it.x, it.y, it.width, it.height)
    end
    
    lg.setColor(0,0,0)
    for it_index=1,2 do
        local it = collision_rects[it_index]
        lg.rectangle("line", it.x, it.y, it.width, it.height)
    end
    
    lg.setColor(1,1,1)
end


return room
