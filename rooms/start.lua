local lg = love.graphics
local Game = require "game"

local collision_rects = {
    Game.Rectangle(-800, 300,8000, 600),
    Game.Rectangle( 400, 250,1200,  50),
    Game.Rectangle(-100, -30,1000,  30),
    Game.Rectangle(-100,   0, 100, 300),
}

local respawn_positions = {
    Game.Vector2(200, 20),
    Game.Vector2(Game.width-64, 180),
}

local fix_y,y,c,dir,font = 200,200, 0, 1, lg.newFont("fonts/VictorMono-Medium.otf", 110)
local room = Game.New_Room({
    collision_rects=collision_rects,
    respawn_positions=respawn_positions,
})

function room.on_start(game)
    lg.setBackgroundColor(BG_COLOR)
end

function room.update(game, dt)
    local sin = math.sin(c)
    if sin == -1 then dir=dir*-1 end
    
    y = fix_y + 100*sin
    c = c + .05*dir
    
    if game.players[game.current_player].rectangle.x > game.width then
        Game.init_gui(game, Game.STATE_ROOM, 2)
    end
end

function room.background_draw()
    lg.setFont(font)
    lg.print("START ROOM", 100, y)

    lg.setColor(BG_COLOR)
    lg.rectangle("fill",
        0,
        collision_rects[1].y,
        collision_rects[2].x,
        600)

    lg.rectangle("fill",
        collision_rects[2].x,
        collision_rects[2].y,
        Game.width-collision_rects[2].x,
        600)
    
    lg.setColor(0,0,0)
    lg.line(
        collision_rects[1].x,
        collision_rects[1].y,
        collision_rects[2].x,
        collision_rects[1].y)
    
    lg.line(
        collision_rects[2].x,
        collision_rects[2].y,
        collision_rects[2].x,
        collision_rects[1].y)

    lg.line(
        collision_rects[2].x,
        collision_rects[2].y,
        collision_rects[2].x+collision_rects[1].width,
        collision_rects[2].y)

    lg.setColor(1,1,1)
end


return room
