local lg = love.graphics
local lw = love.window
local ls = love.system
local lm = love.mouse
local lt = love.touch
local lk = love.keyboard
local Game = require "game"

local font = lg.newFont("fonts/VictorMono-Medium.otf", 30)
local debug_font = lg.newFont("fonts/VictorMono-Medium.otf", 16)

local room = Game.NewGUI("STATE_ROOM")
room.buttons.menu = Game.Text_Button("menu", Game.width - 120, 40, 100, 80)

if ls.getOS()=="Android" or ls.getOS()=="IOS" or DEBUG then
    room.buttons.right = Game.Text_Button("right", 130, Game.height - 140, 100, 80)
    room.buttons.left  = Game.Text_Button("left", 20, Game.height - 140, 100, 80)
    room.buttons.jump  = Game.Text_Button("jump", Game.width - 120, Game.height - 140, 100, 80)
    if DEBUG then
        room.buttons.up = Game.Text_Button("up", Game.width - 120, Game.height - 340, 100, 80)
        room.buttons.down = Game.Text_Button("down", Game.width - 120, Game.height - 250, 100, 80)
        room.buttons.up.active = false
        room.buttons.down.active = false
    end
end

function room.init(game, room_index, respawn_index)
    local r = game.rooms[room_index]
    assert(r ~= nil, "There is no room with index: "..room_index)
    game.current_room_index = room_index
    game.current_respawn_index = 1
    local respawn_pos = r.respawn_positions[respawn_index or 1]
    r.on_start(game) 

    local player = game.players[game.current_player]
    player.rectangle.x,player.rectangle.y = respawn_pos.x,respawn_pos.y
    player.room = r
end

function room.update(game, dt)
    if game.players[1].life == 0 then
        love.event.quit(1)
    end
    local gui_used = false

    if ls.getOS()=="Android" or ls.getOS()=="IOS" then
        gui_used = Game.get_touch_gui_input(game)
    else
        game.mouse.x, game.mouse.y = lm.getX(), lm.getY()
        gui_used = Game.get_mouse_gui_input(game)
    end

    local r = game.rooms[game.current_room_index]
    if gui_used then
        if room.buttons.menu.pressed then
            Game.change_gui(game, Game.STATE_MENU)
        end
        if ls.getOS()=="Android" or ls.getOS()=="IOS" or DEBUG then
            game.players[game.current_player].JUMP = room.buttons.jump.pressed
            game.players[game.current_player].MOVE_LEFT = room.buttons.left.isDown
            game.players[game.current_player].MOVE_RIGHT = room.buttons.right.isDown
            if DEBUG and r.show_up_and_down_button then
                r.UP_PLATFORM = room.buttons.up.isDown
                r.DOWN_PLATFORM = room.buttons.down.isDown
            end
        end
    else
        if game.keyboard["left"] and game.keyboard["left"].isDown then
            game.players[game.current_player].MOVE_LEFT = true
        elseif game.keyboard["right"] and game.keyboard["right"].isDown then
            game.players[game.current_player].MOVE_RIGHT = true
        else
            game.players[game.current_player].MOVE_RIGHT = false
            game.players[game.current_player].MOVE_LEFT  = false
        end
        if game.keyboard["m"] and game.keyboard["m"].pressed then
            Game.change_gui(game, Game.STATE_MENU)
        end
        if game.keyboard["c"] and game.keyboard["c"].pressed then
            Game.Clone_Cat(game, true)
        end

        for i=1, #game.players do
            if game.keyboard[tostring(i)] and game.keyboard[tostring(i)].pressed then
                Game.change_cat(game, i)
            end
        end

        game.players[game.current_player].JUMP = game.keyboard["space"] and game.keyboard["space"].pressed
    end

    for _,it in ipairs(game.players) do
        if it.room == game.rooms[game.current_room_index] then
            it:update(dt)
        end
    end
    
    if r then r.update(game, dt) end
    if DEBUG and r.show_up_and_down_button then
        room.buttons.up.active = true
        room.buttons.down.active = true
    elseif DEBUG and r.hide_up_and_down_button then
        room.buttons.up.active = false
        room.buttons.down.active = false
    end

    if #game.players > 1 then
        game.players[1].health = game.players[1].health-(#game.players-1)*dt
        if  game.players[1].health < .5 then
            game.players[1].life = game.players[1].life - 1
            game.players[1].health = 10
        end
    end
end

function room.draw(game)
    local r = game.rooms[game.current_room_index]

    if r then r.background_draw() end
    for _,it in ipairs(game.players) do
        if it.room == r then it:draw() end
    end
    if r then r.foreground_draw() end
    
    lg.setFont(font)
    for _,it in pairs(room.buttons) do
        if it.active then
            local w,h = font:getWidth(it.text),font:getHeight()
            lg.print(it.text, it.x + it.width/2 - w/2, it.y + it.height/2 - h/2)
        end
    end
 
    if DEBUG then
        if r then
            for _,rect in ipairs(r.collision_rects) do
                lg.setColor(.9, .3, .1, .2)
                lg.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
                lg.setColor(1,1,1,1)
                lg.rectangle("line", rect.x, rect.y, rect.width, rect.height)
            end
        end

        local cat = game.players[1]
        for i=1, cat.life-1 do
            lg.rectangle("line", 10+(i-1)*30, 10, 25, 25)
        end
        lg.rectangle("line", 10+(cat.life-1)*30, 10, 25*cat.health/10, 25)

        local it = game.players[game.current_player]
        lg.setFont(debug_font)
        lg.setColor(0,0,0)
        
        lg.print(
            "Player index: ".. game.current_player ..
            "\n-velocity: { ".. it.vel.x ..", ".. it.vel.y .." }"..
            "\n-last_jump_power: ".. it.last_jump_height,
            it.rectangle.x, it.rectangle.y - 70
        )
    end
end

return room
