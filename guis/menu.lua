local lg = love.graphics
local lw = love.window
local ls = love.system
local lm = love.mouse
local lt = love.touch
local lk = love.keyboard
local Game = require "game"

local font = lg.newFont("fonts/VictorMono-Medium.otf", 30)
local menu = Game.NewGUI("STATE_MENU")

local highlight = 1
local buttons = {"resume", "title", "quit"}
for i,it in ipairs(buttons) do
    menu.buttons[it] = Game.Text_Button(it, Game.width/2 - 100, 120 + (i-1)*80, 200, 60)
end

function menu.init()
    lg.setBackgroundColor(BG_COLOR)
    highlight = 1
end

function menu.update(game, dt)
    local gui_used = false
    
    if ls.getOS()=="Android" or ls.getOS()=="IOS" then
        gui_used = Game.get_touch_gui_input(game)
    else
        game.mouse.x, game.mouse.y = lm.getX(), lm.getY()
        gui_used = Game.get_mouse_gui_input(game)
    end

    if gui_used then
        if menu.buttons.resume.pressed then
            highlight=1
            game.state = Game.STATE_ROOM
            game.rooms[game.current_room_index].on_start(game)
        end
        if menu.buttons.title.pressed then
            highlight=2
            Game.init_gui(game, Game.STATE_TITLE)
        end
        if menu.buttons.quit.pressed then
            highlight=3
            love.event.quit(0)
        end
    else
        if game.keyboard["up"] and game.keyboard["up"].pressed then
            highlight = highlight-1
        end
        if game.keyboard["down"] and game.keyboard["down"].pressed then
            highlight = highlight+1
        end

        if highlight > #buttons then highlight=1 end
        if highlight < 1 then highlight=#buttons end

        if game.keyboard["return"] and game.keyboard["return"].pressed then
            if buttons[highlight] == "resume" then
                game.state = Game.STATE_ROOM
                game.rooms[game.current_room_index].on_start(game)

            elseif buttons[highlight] == "title" then
                Game.init_gui(game, Game.STATE_TITLE)

            elseif buttons[highlight] == "quit" then
                love.event.quit(0)

            end
        end
    end
end

function menu.draw(game)
    lg.setFont(font)
    for _,it in pairs(menu.buttons) do
        local w,h = font:getWidth(it.text),font:getHeight()
        lg.print(it.text, it.x + it.width/2 - w/2, it.y + it.height/2 - h/2)
        if it.text==buttons[highlight] and not (ls.getOS()=="Android" or ls.getOS()=="IOS") then
            lg.rectangle("line", it.x, it.y, it.width, it.height)
        end
    end
    
    if DEBUG then
    end
end

return menu
