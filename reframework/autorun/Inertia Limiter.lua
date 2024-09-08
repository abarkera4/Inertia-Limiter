if reframework:get_game_name() ~= "re4" then
    return
end



--                      // Default values //
local defaults = {
    walk_start_rate = 1.500,  -- (1.00) _WalkSpeedRate

}

local field_mapping = {
    walk_start_rate = "_WalkStartSpeedRate"

}

local character_ids = {
    "ch3a8z0_head", "ch6i0z0_head", "ch6i1z0_head", "ch6i2z0_head", 
    "ch6i3z0_head", "ch3a8z0_MC_head", "ch6i5z0_head"
    -- add more if needed...
}

-- Character ID List
--[[
    -- Ada AO - ch3a8z0_head
    -------- Mercenaries ----------
    -- Leon - ch6i0z0_head
    -- Luis - ch6i1z0_head
    -- Krauser ch6i2z0_head
    -- HUNK - ch6i3z0_head
    -- Ada Mercs - ch3a8z0_MC_head
    -- Wesker - ch6i5z0_head
]]
-- Store the last known values
local last_values = {}

local scene = nil
local has_run_initially = false
local threshold = 0.01

local function retrieve_fields_values()
    local scene_manager = sdk.get_native_singleton("via.SceneManager")
    if not scene_manager then
        return
    end

    local scene = sdk.call_native_func(scene_manager, sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
    if not scene then
        log.warn("Scene not found! Cancelling.")
        return
    end

    local pl_head = scene:call("findGameObject(System.String)", "ch0a0z0_head")

    if not pl_head then
        for _, character_id in ipairs(character_ids) do
            pl_head = scene:call("findGameObject(System.String)", character_id)
            if pl_head then
                break
            end
        end
    end
    
    if not pl_head then
         log.warn("Player Head not found!")
        return
    end

    local player_equip = pl_head:call("getComponent(System.Type)", sdk.typeof("chainsaw.PlayerCommonParameter"))
    if not player_equip then
        log.warn("Player Equip component not found!")
        return
    end

    local common_param = player_equip:get_field("_PlayerCommonParamUserData")
    local assisted_param = player_equip:get_field("_PlayerCommonParamUserData_Assisted")
    local hardcore_param = player_equip:get_field("_PlayerCommonParamUserData_Hardcore")
    local professional_param = player_equip:get_field("_PlayerCommonParamUserData_Professional")

    local function store_initial_values(param)
        for key, field_name in pairs(field_mapping) do
            last_values[field_name] = param:get_field(field_name)
        end
    end

    if common_param then
        store_initial_values(common_param)
    end
    if assisted_param then
        store_initial_values(assisted_param)
    end
    if hardcore_param then
        store_initial_values(hardcore_param)
    end
    if professional_param then
        store_initial_values(professional_param)
    end
end
-- Check if any value has changed by more than the threshold
local function has_values_changed(scene)
    if not scene then return false end

    local pl_head = scene:call("findGameObject(System.String)", "ch0a0z0_head")

    if not pl_head then
        for _, character_id in ipairs(character_ids) do
            pl_head = scene:call("findGameObject(System.String)", character_id)
            if pl_head then
                break
            end
        end
    end
    
    if not pl_head then
         log.warn("Player Head not found!")
        return
    end
    

    local player_equip = pl_head:call("getComponent(System.Type)", sdk.typeof("chainsaw.PlayerCommonParameter"))
    if not player_equip then
        log.warn("Player Equip component not found!")
        return false
    end

    local common_param = player_equip:get_field("_PlayerCommonParamUserData")

    if not common_param then
        log.warn("Common Param data not found!")
        return false
    end

    for key, default_value in pairs(defaults) do
        local field_name = field_mapping[key]
        local current_value = common_param:get_field(field_name)
        if not current_value or not last_values[field_name] or math.abs(last_values[field_name] - current_value) > threshold then
            log.info(string.format("Field %s has changed. Old Value: %s, New Value: %s", field_name, tostring(last_values[field_name]), tostring(current_value)))
            last_values[field_name] = current_value
            return true
        end
    end
    return false
end

local function update_speed()
    local pl_head = scene:call("findGameObject(System.String)", "ch0a0z0_head")

    if not pl_head then
        for _, character_id in ipairs(character_ids) do
            pl_head = scene:call("findGameObject(System.String)", character_id)
            if pl_head then
                break
            end
        end
    end
    
    if not pl_head then
        -- log.warn("Player Head not found!")
        return
    end
    
    local player_equip = pl_head:call("getComponent(System.Type)", sdk.typeof("chainsaw.PlayerCommonParameter"))
    if player_equip then
        local common_param = player_equip:get_field("_PlayerCommonParamUserData")
        local assisted_param = player_equip:get_field("_PlayerCommonParamUserData_Assisted")
        local hardcore_param = player_equip:get_field("_PlayerCommonParamUserData_Hardcore")
        local professional_param = player_equip:get_field("_PlayerCommonParamUserData_Professional")

        local function set_values(param)
            param:set_field("_WalkStartSpeedRate", defaults.walk_speed_rate)            -- (1.100) _WalkSpeedRate

        end

        if common_param then
            set_values(common_param)
        end

        if assisted_param then
            set_values(assisted_param)
        end

        if hardcore_param then
            set_values(hardcore_param)
        end

        if professional_param then
            set_values(professional_param)
        end
    end
end

local function reset_context_variables()
    -- Reset the flag to allow the initial setup to run again for the new context
    has_run_initially = false

    -- Clear last known values to ensure they will be reacquired for the new context
    for key, _ in pairs(last_values) do
        last_values[key] = nil
    end
end

retrieve_fields_values()

re.on_frame(function()
    local scene_manager = sdk.get_native_singleton("via.SceneManager")
    if not scene_manager then
        reset_context_variables()
        return
    end

     scene = sdk.call_native_func(scene_manager, sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
    if not scene then
        reset_context_variables()
        log.warn("Scene not found! Cancelling.")
        return
    end

    local character_manager = sdk.get_managed_singleton(sdk.game_namespace("CharacterManager"))
    local player_context = character_manager:call("getPlayerContextRef")
    if player_context == nil then
        reset_context_variables()
        return
    end

    -- If the function has not run initially or if the values have changed
    if not has_run_initially or has_values_changed(scene) then
        log.info("Combat Run Speeds Updating!")
        update_speed()
        has_run_initially = true
    end
    --local valuesChanged = has_values_changed(scene)
    log.info("Combat Run Speed Initialization is "..tostring(has_run_initially).." And have the values changed: "..tostring(valuesChanged))
end)
