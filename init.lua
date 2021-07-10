local modname = minetest.get_current_modname()
local register_craftitem = minetest.register_tool
local register_entity = minetest.register_entity
local add_entity = minetest.add_entity

local mudsling = {}
mudsling.GRAVITY_BASE = 0.987
function say(x)
    return minetest.chat_send_all(type(x) == "string" and x or minetest.serialize(x))
end


local function invertPlayerPhysics(name, state)
    local player = minetest.get_player_by_name(name)
    if(name and type(name) == "string" and player)then
        local val = state and 1 or 0
        local physics_params = player:get_physics_override()
        physics_params.gravity = val
        physics_params.speed = val
        physics_params.jump = val
        player:set_physics_override(physics_params)
    end
end

mudsling.invertPlayerPhysics = invertPlayerPhysics


local function generateAngularVel(name,vec)
    if(name and type(name) == "string")then
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        vec = vec or player:get_look_dir()
        local sdata = minetest.serialize({name = name, vel = vec})
        minetest.add_entity(pos, modname .. ":entity", sdata)
    end
end
mudsling.generateAngularVel = generateAngularVel


local function enforceGravity(obj)
    local vel = obj:get_velocity()
    vel.y = vel.y - mudsling.GRAVITY_BASE
    obj:set_velocity(vel)
end
mudsling.enforceGravity = enforceGravity


local function attenuateVel(obj)
    local vel = obj:get_velocity()
    vel = vector.divide(vel,1.0005)
    obj:set_velocity(vel)
end
mudsling.attenuateVel = attenuateVel


local function setProps(obj,propdef)
    if(obj and obj:get_properties())then
        local props = obj:get_properties()
        
        for k,v in pairs(propdef)do
            if(props[k])then
                props[k] = v
            end
        end
        obj:set_properties(props)
    end
end

mudsling.setProps = setProps


local function getProp(obj, label)
    if(obj and obj:get_properties())then
        return obj:get_properties()[label]
    end
end

mudsling.getProp = getProp


-- TOOLDEF
    local iname = modname .. ":mudsling"
register_craftitem(iname,{
    description = iname,
    groups = {},
    inventory_image = "sling.png",
    range = 6.0,
    on_place = function(itemstack,placer)
        local user = placer
        say(user:get_player_name())
        mudsling.generateAngularVel(user:get_player_name())
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        local placer = user
        say(user:get_player_name())
        mudsling.generateAngularVel(user:get_player_name())
    end
})




-- ENTITYDEF

local entdef = {
    hp_max = 1,
    breath_max = 0,
    zoom_fov = 0.0,
    eye_height = 1.625,
    physical = true,
    collide_with_objects = true,
    weight = 5,
    collisionbox = {-0.5, 0.0, -0.5, 0.5, 1.0, 0.5},
    selectionbox = {-0.5, 0.0, -0.5, 0.5, 1.0, 0.5},
    pointable = false,
    visual = "cube",
    is_visible = false,
    static_save = false,
    on_activate = function(self, staticdata)
        local data = minetest.deserialize(staticdata)
        mudsling.setProps(self.object,{infotext = data.name})
        self.object:set_velocity(vector.multiply(data.vel,-64))
    end,
    on_step = function(self)
        local obj = self.object
        local vel = obj:get_velocity()
        local pos = obj:get_pos()
        local name = mudsling.getProp(obj,"infotext")
        local player = minetest.get_player_by_name(name)
        if(vel.y == 0)then        
            mudsling.invertPlayerPhysics(name,true)
            obj:remove()
        else
        --say(vel)
        mudsling.invertPlayerPhysics(name)
        mudsling.enforceGravity(obj)
        --mudsling.attenuateVel(obj)
        player:move_to(pos)
        end
        
    end
}
register_entity(modname .. ":entity", entdef)
