
-- TODO: localize user input in the game state
-- TODO: Create a clone of cat by decrease his life


local lg = love.graphics
local la = love.audio
local lk = love.keyboard
local lm = love.mouse
local Game = require "game"

local CAT_MAX_SPEED = 10
local CAT_ACCELERATOR = 2
local CAT_SPEED_EPSILON = 5
local CAT_GROUND_FRICTION = 25
local CAT_MAX_JUMP_HEIGHT = 150
local CAT_MIN_JUMP_HEIGHT = 120

local meong = la.newSource("sounds/meong.wav", "static")
meong:setPitch(1.3)

local cat_mt = {}
cat_mt.__index = cat_mt

function cat_mt.draw(self)
    local frame = self.animations[self.current_animation].frames[math.floor(self.current_frame)]
    
    if frame then
        lg.setColor(1,1,1)
    	local posx = self.rectangle.x + frame:getWidth()*2-(frame:getWidth()*2*self.last_facing)
        if self.sliding then
            posx = self.rectangle.x + frame:getWidth()
        end
        lg.draw(
            frame,
            posx,self.rectangle.y + frame:getHeight()*2, -- px, py
            self.rotation,                               -- rotation
            2 - (4*self.last_facing), 2,                 -- sx, sy
            frame:getWidth()*2/2, frame:getHeight()*2/2  -- ax, ay
        )
    end
end

function cat_mt.standing_on_platform(self)
    local x,y,w,h = self.rectangle.x,self.rectangle.y,self.rectangle.width,self.rectangle.height
    for i,rect in ipairs(self.room.collision_rects) do
        if x+w/2 >= rect.x and x+w/2 <= rect.x+rect.width then
            if y+h >= rect.y and y <= rect.y+rect.height then
                self.rectangle.y = rect.y-h
                return true,i
            end
        end
    end
    return false,0
end

function cat_mt.apply_force(self,x,y,dt)
    self.vel.x = self.vel.x + x * CAT_ACCELERATOR * dt
    self.vel.y = self.vel.y + y * CAT_ACCELERATOR * dt
    
    if self.vel.x>0 and self.vel.x >  CAT_MAX_SPEED then self.vel.x = CAT_MAX_SPEED end
    if self.vel.x<0 and self.vel.x < -CAT_MAX_SPEED then self.vel.x =-CAT_MAX_SPEED end
    if self.vel.y>0 and self.vel.y >  CAT_MAX_SPEED then self.vel.y = CAT_MAX_SPEED end
    
    if DEBUG then
        if self.vel.y > -CAT_SPEED_EPSILON/2 and self.vel.y < CAT_SPEED_EPSILON/2 then
            self.last_jump_height = self.rectangle.y
        end
    end
end

local function get_boundary(rect)
    return rect.x, rect.y, rect.width, rect.height
end

local function resolve_wall_ground_per_collison(self, it_index, it, index)
    local x,y,w,h = get_boundary(self.rectangle)

    if it_index==index then return false end
    if y+h < it.y or y > it.y+it.height then return false end
    
    if x+w > it.x and x < it.x + it.width/2 then
        self.rectangle.x = it.x-w
        self.vel.x = 0
        return true
    elseif x < it.x+it.width and x > it.x+it.width/2 then
        self.rectangle.x = it.x+it.width
        self.vel.x = 0
        return true 
    end
end

function cat_mt.resolve_wall_ground(self, index)
    for it_index,rect in ipairs(self.room.collision_rects) do
        if resolve_wall_ground_per_collison(self, it_index, rect, index) then break end
    end
end

function cat_mt.resolve_wall_air(self)
    local x,y,w,h = get_boundary(self.rectangle)

    for i,rect in ipairs(self.room.collision_rects) do
        if y+h > rect.y and y < rect.y+rect.height then
            if self.vel.x > 0 and x+w >= rect.x and x < rect.x+rect.width/2 then
                if self.vel.y > 0 and self.vel.x > 0 then self.sliding = true end
                self.rectangle.x = rect.x-w
                self.sliding = true
                self.vel.x = 0
                break

            elseif self.vel.x < 0 and x <= rect.x+rect.width and x > rect.x+rect.width/2 then
                if self.vel.y > 0 and self.vel.x < 0 then self.sliding = true end
                self.rectangle.x = rect.x+rect.width
                self.sliding = true
                self.vel.x = 0
                break
            end
        end
    end
end

function cat_mt.apply_gravity(self, dt)
    if self.sliding then self:apply_force(0,35, dt)
    else self:apply_force(0,50, dt) end
end

function cat_mt.jump(self, dt, back_jump)
    self.begin_jump_height = self.rectangle.y
    
    if self.sliding then
        self.sliding = false
        self.vel.y, self.vel.x = 0,0
    end
    
    if self.vel.x == 0 then self:apply_force(back_jump or 0,-650, dt)
    else self:apply_force(back_jump or 0, -520, dt) end
    
    if not SILENT then meong:play() end
end

function cat_mt.update_while_jump(self, dt)
    local max_height = CAT_MAX_JUMP_HEIGHT
    if self.vel.x ~= 0 then max_height = CAT_MIN_JUMP_HEIGHT end
    if self.begin_jump_height - self.rectangle.y >= max_height then
        self.vel.y = 0
    end
end

function cat_mt.update(self, dt)
    if not self.room then return end
    local standing, collision_box_index =  self:standing_on_platform()

    if not self.animation_paused then 
        self.current_frame = self.current_frame+self.animations[self.current_animation].fps*dt
    end
    
    if self.current_frame>=#self.animations[self.current_animation].frames+1 then
        self.current_frame=1
    end

    if standing then
        self.vel.y = 0
        self.rotation = 0
        self.sliding = false
        
        self:resolve_wall_ground(collision_box_index)
        
        if self.JUMP then self:jump(dt) end
        
        if self.MOVE_LEFT then
            self:apply_force(-10, 0, dt) 
            self.last_facing = 0
        elseif self.MOVE_RIGHT then
            self:apply_force( 10, 0, dt)
            self.last_facing = 1 
        else
            if self.vel.x <= -CAT_SPEED_EPSILON or self.vel.x >=  CAT_SPEED_EPSILON then
                self.vel.x = self.vel.x + CAT_GROUND_FRICTION * (1 - 2 * self.last_facing) * dt
            end
            
            if self.vel.x <=  CAT_SPEED_EPSILON and self.vel.x >= -CAT_SPEED_EPSILON then
                self.vel.x = 0
            end
        end
        if self.vel.x <= -CAT_MAX_SPEED or self.vel.x >= CAT_MAX_SPEED then
            self.current_animation = "run"
            self.animation_paused = false
        end
        if self.vel.x < CAT_MAX_SPEED and self.vel.x > -CAT_MAX_SPEED then
            self.current_animation = "walk"
            self.animation_paused = false
        end
        if self.vel.x == 0 then 
            self.current_animation = "idle"
            self.animation_paused = true
        end
    else
        self.animation_paused = true
        self.current_animation = "run"
        self.current_frame = 3
        
        if self.vel.x <= -CAT_SPEED_EPSILON or self.vel.x >=  CAT_SPEED_EPSILON then
            self.vel.x = self.vel.x + CAT_GROUND_FRICTION * (1 - 2 * self.last_facing) * dt*.5
        end

        if self.sliding then
            self.current_animation = "run"
            self.current_frame = 1

            if self.vel.y < 0 then
                self.rotation =-90 * (1-2 * self.last_facing) * math.pi/360
            elseif self.vel.y > 0 then
                self.rotation = 90 * (1-2 * self.last_facing) * math.pi/360
            end
            
            if self.JUMP then self:jump(dt, 100 * (1-2*self.last_facing)) end
        else
            if self.vel.x > 0 then self.last_facing = 1
            elseif self.vel.x < 0 then self.last_facing = 0 end
            
            if self.vel.y < 0 then
                self.rotation = 60 * (1-2 * self.last_facing) * math.pi/360
            elseif self.vel.y > 0 then
                self.rotation =-60 * (1-2 * self.last_facing) * math.pi/360
            end
        end

        if self.vel.y < 0 then
            self:update_while_jump(dt)
        else
            self:apply_gravity(dt)
        end
        self:resolve_wall_air()
    end
    self.rectangle.x = self.rectangle.x + self.vel.x
    self.rectangle.y = self.rectangle.y + self.vel.y
end

function New_Cat(game, anim_path)
    local anims = {}
    for it_index,it in pairs(anim_path) do
        anims[it_index] = {fps = it.fps, frames = {}}
        for _,img_path in ipairs(it.frames) do
            local img = lg.newImage(img_path)
            img:setFilter("nearest", "nearest")
            table.insert(anims[it_index].frames, img)
        end
    end
    
    local cat = {
        rectangle=Game.Rectangle(0,0,64,64),
        begin_jump_height=0,
        vel=Game.Vector2(0,0),
        sliding=false,index=0,

        life=9,health=10,
        
        animations = anims,
        current_animation = "idle",
        current_frame = 1,
        last_facing = 0,
        rotation = 0,

        MOVE_RIGHT = false,
        MOVE_LEFT  = false,
        JUMP       = false,

        game=game,
        room=nil,
    }

    if DEBUG then
        cat.last_jump_height = 0
    end
    
    setmetatable(cat, cat_mt)
    return cat
end


function cat_mt.clone(self)
    local cat = New_Cat(self.game, {})
    cat.animations = self.animations
    cat.rectangle = Game.Rectangle(get_boundary(self.rectangle))
    cat.last_facing = self.last_facing
    return cat
end

return New_Cat
