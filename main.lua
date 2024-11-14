
DEBUG = false 
BYPASS_TITLE = true
BEGIN_ROOM = 1
SILENT = true

BG_COLOR = {0xff/0xff, 0xc9/0xff, 0x39/0xff}
local Game_Manager = require "game"
local New_Cat = require "cat"

local cat_anim = {
    idle = {
        fps = 6,
        frames = {
            "images/cat/idle/1.png",
            "images/cat/idle/2.png",
        }
    },
    walk = {
        fps = 12,
        frames = {
            "images/cat/walk/1.png",
            "images/cat/walk/2.png",
            "images/cat/walk/3.png",
            "images/cat/walk/4.png",
        }
    },
    run = {
        fps = 12,
        frames = {
            "images/cat/run/1.png",
            "images/cat/run/2.png",
            "images/cat/run/3.png",
            "images/cat/run/4.png",
        }
    }
}

local game = Game_Manager.New_Game()

function love.load()
    Game_Manager.start(game, 800, 600, New_Cat(game, cat_anim))
    Game_Manager.add_game_rooms(game, "rooms.start", "rooms.test")
    Game_Manager.add_game_guis (game, "guis.room", "guis.title", "guis.menu")
    
    if BYPASS_TITLE then
        Game_Manager.init_gui(game, Game_Manager.STATE_ROOM, BEGIN_ROOM)
    else
        Game_Manager.init_gui(game, Game_Manager.STATE_TITLE)
    end
end

function love.update(dt)
    Game_Manager.update(game, dt)
end

function love.draw()
    Game_Manager.draw(game)
end

function love.keypressed(key,...)
    if key=="escape" then love.event.quit() end
    Game_Manager.keyboard_pressed(game,key,...)
end

function love.mousepressed(...)
    Game_Manager.mouse_pressed(game, ...)
end

function love.touchpressed(...)
    Game_Manager.touch_pressed(game, ...)
end

