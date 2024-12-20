local lg = love.graphics
local lw = love.window
local ls = love.system
local lm = love.mouse
local lt = love.touch
local lk = love.keyboard
if not table.unpack then table.unpack = unpack end

local M = {}
M.width,M.height = 0,0

-- ENUMS
M.state_count = 1
M.room_count  = 1

function M.Vector2(x,y)
    return {x=x or 0, y=y or x or 0}
end

function M.Rectangle(x,y,w,h)
    return {x=x or 0, y=y or x or 0, width = w or 10, height = h or w or 10}
end

function M.Clone_Cat(game, change_player)
    local player = game.players[game.current_player]
    local cat = player:clone()
    
    table.insert(game.players, cat)
    if change_player then game.current_player = #game.players end
    cat.index=#game.players
    cat.room = player.room
end

function M.change_cat(game, index)
    if index>#game.players and index<1 then return end
    game.current_player = index
    game.current_room_index = M[game.players[index].room.tag]
end


function M.New_Game()
    return {
        players = {},
        current_player = 1,

        gui_state_stack = {},
        state = 0,
        width = 0, height = 0,
        scalex = 1, scaley = 1,
        offx = 0, offy = 0,

        rooms = {},
        current_respawn_index = 0,
        current_room_index = 0,

        mouse = {buttons={}, x=0, y=0},
        keyboard = {},
        touches = {},
        guis = {},
    }
end

--[[ @params
    room_data  := {
        respawn_positions: {<Vector2>} = {Vector2(10,10)},
        music_background:love.audio.newSource = nil,
        collision_rects: {<Rectangle>} = {Rectangle(0,200,800,200)},
        mouses: {<Mouse>} = {},
    }
]] -- Mardhi Lh, November 2024

function M.New_Room(tag, room_data)
    assert(tag, "tag (param #1) is nil.")
    assert(M[tag]==nil, "this tag: `"..tostring(tag).."` already exist." )
    M[tag] = M.room_count
    M.room_count = M.room_count+1

    local room = {tag=tag}

    if DEBUG then
        room.show_up_and_down_button = false
        room.hide_up_and_down_button = false
    end

    room.UP_PLATFORM = false
    room.DOWN_PLATFORM = false
    
    room.respawn_positions = room_data.respawn_positions or {M.Vector2(10, 10)}
    room.music_background  = room_data.music_background
    room.collision_rects   = room_data.collision_rects or {M.Rectangle(0,200,800,200)}
    room.mouses = room_data.mouses or {}
    room.on_start    = function(game)end
    room.update      = function(game)end
    room.background_draw = function()end
    room.foreground_draw = function()end
    return room
end

function M.NewGUI(tag)
    assert(tag, "tag (param #1) is nil.")
    assert(M[tag]==nil, "this tag: `"..tostring(tag).."` already exist." )
    M[tag] = M.state_count
    M.state_count = M.state_count+1

    local gui = {tag=tag}
    gui.buttons = {}
    gui.init    = function(game)end
    gui.update  = function(game)end
    gui.draw    = function(game)end
    return gui
end

local function update_game_scale_and_offset(game, width, height)
    if width>height then
        game.scalex,game.scaley = height/game.height,height/game.height
        game.offx = width/2 - game.width * game.scalex/2
        game.offy = 0
    else
        game.scalex,game.scaley = width/game.width,width/game.width
        game.offy = height/2 - game.height*game.scaley/2
        game.offx = 0
    end
end

function M.get_mouse_gui_input(game)
    for _,it in pairs(game.guis[game.state].buttons) do
        for _,btn in pairs(game.mouse.buttons) do
            if  game.mouse.x >= game.offx + it.x*game.scalex and
                game.mouse.x <= game.offx + it.x*game.scalex + it.width*game.scalex and 
                game.mouse.y >= game.offy + it.y*game.scaley and
                game.mouse.y <= game.offy + it.y*game.scaley + it.height*game.scaley then
                it.pressed = btn.pressed
                it.isDown  = btn.isDown
                return true
            end
        end
    end
    return false
end

function M.get_touch_gui_input(game)
    local used = false
    for _,it in pairs(game.guis[game.state].buttons) do
        for _,touch in pairs(game.touches) do
            if  touch.x >= game.offx + it.x*game.scalex and
                touch.x <= game.offx + it.x*game.scalex + it.width*game.scalex and 
                touch.y >= game.offy + it.y*game.scaley and
                touch.y <= game.offy + it.y*game.scaley + it.height*game.scaley then
                it.pressed = touch.pressed
                it.isDown  = touch.isDown
                used = true
            end
        end
    end
    return used
end

function M.update(game, dt)
    update_game_scale_and_offset(game, lg.getWidth(), lg.getHeight())
    game.guis[game.state].update(game, dt)
end

local function draw_bar(game, width, height)
    lg.setColor(0,0,0)
    if width>height then
        lg.rectangle("fill", 0,0, game.offx, height)
        lg.rectangle("fill", game.offx + game.width*game.scalex,0, game.offx, height)
    else
        lg.rectangle("fill", 0,0, width, game.offy)
        lg.rectangle("fill", 0, game.offy + game.height*game.scaley, width, game.offy)
    end
    lg.setColor(1,1,1)
end

local function reset_input(game)
    for it_index,it in pairs(game.keyboard) do
        it.pressed = false
        it.isDown  = lk.isDown(it_index)
    end

    for it_index,it in pairs(game.mouse.buttons) do
        it.pressed = false
        it.isDown  = lm.isDown(it_index)
    end

    local touches  = lt.getTouches()
    for it_index,it in pairs(game.touches) do
        it.pressed = false
    end
    
    for it_index,it in pairs(game.guis[game.state].buttons) do
        it.pressed = false
        it.isDown  = false
    end
end

function M.draw(game)
    lg.push()
        lg.translate(game.offx, game.offy)
        lg.scale(game.scalex, game.scaley)
        
        game.guis[game.state].draw(game)
    lg.pop()
    if DEBUG then
        for _,it in pairs(game.touches) do
            lg.setColor(1,1,1,.5)
            lg.circle("fill", it.x, it.y, 10)
            lg.setColor(1,1,1,1)
        end
    end

    draw_bar(game, lg.getWidth(), lg.getHeight())
    reset_input(game)

    if #game.gui_state_stack>0 then
        local s = table.remove(game.gui_state_stack)
        M.init_gui(game, s.state, table.unpack(s.args))
    end
end

function M.Text_Button(text, x,y,w,h)
    return {text=text, isDown=false, pressed=false, x=x, y=y, width=w, height=h,active=true}
end

function M.Image_Button(images, x,y,w,h)
    return {images=images, isDown=false, pressed=false, x=x, y=y, width=w, height=h,active=true}
end

function M.start(game, width, height, cat)
    game.width,game.height = width,height
    M.width,M.height = width,height
    if ls.getOS()=="Android" or ls.getOS()=="IOS" then
        lw.setMode(game.width, game.height, {resizable=false, fullscreen=true})
    else
        lw.setMode(game.width, game.height, {resizable=true, fullscreen=false})
    end
    table.insert(game.players, cat)
    game.current_player = 1
    cat.index=#game.players
end

function M.add_game_guis(game, ...)
    local rooms_path = {...}
    for _,it in ipairs(rooms_path) do
        local gui = require(it)
        game.guis[M[gui.tag]] = gui
    end
end

function M.add_game_rooms(game, ...)
    local rooms_path = {...}
    for _,it in ipairs(rooms_path) do
        table.insert(game.rooms, require(it))
    end
end

function M.change_gui(game,state,...)
    table.insert(game.gui_state_stack, {state=state, args={...}})
end

function M.init_gui(game, state, ...)
    game.state = state
    game.guis[game.state].init(game, ...)
end

function M.init_menu(game)
    game.state = M.STATE_MENU
    lg.setBackgroundColor(.15, .15, .65)
end

function M.keyboard_pressed(game, key)
    game.keyboard[key] = game.keyboard[key] or {}
    game.keyboard[key].pressed = true
end

function M.mouse_pressed(game, x,y,button,istouch,presses)
    game.mouse.buttons[button] = game.mouse.buttons[button] or {}
    game.mouse.buttons[button].pressed = true
    game.mouse.buttons[button].isDown  = true
    game.mouse.x,game.mouse.y = x,y
end

function M.touch_pressed(game, id,x,y)
    game.touches[id] = game.touches[id] or {}
    game.touches[id].pressed = true
    game.touches[id].isDown  = true
    game.touches[id].x,game.touches[id].y = x,y
end

function M.touch_released(game, id,x,y)
    game.touches[id] = game.touches[id] or {}
    game.touches[id].pressed = false
    game.touches[id].isDown  = false
    game.touches[id].x,game.touches[id].y = -100,-100
end

return M

