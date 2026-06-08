-- ====================================================================
-- Script Name: Letterbox Display Enabler 2000
-- Version: 5.0 [CURRENT MASTER]
-- Creator: Ingi Bekk
-- Instagram: @ingibekk
-- Description: Auto-scans for active main displays (1-3) and perfectly 
--              aligns matching sub-displays (8-10) below them.
--              Combines live software scale extraction with the fixed
--              internal rendering grid geometry to eliminate drift.
-- ====================================================================

local function main()
    -- Define relationships: Keys are the Anchors, Values are the Targets
    local display_pairs = {
        [1] = 8,
        [2] = 9,
        [3] = 10
    }

    -- ====================================================================
    -- STEP 1: UNCONDITIONAL CLEAN SWEEP
    -- ====================================================================
    Echo("Performing clean sweep of existing attached displays...")
    for _, target_num in pairs(display_pairs) do
        Cmd(string.format("Delete Display %d /NoPrompt", target_num))
    end
    
    -- Pause to let the engine fully process and flush the deleted windows from memory
    coroutine.yield(0.2)


    -- ====================================================================
    -- STEP 2: ACTIVE SYNC
    -- ====================================================================
    local processed_count = 0

    for anchor_num, target_num in pairs(display_pairs) do
        -- Check if the anchor display is currently open in the engine
        local anchor_display = ObjectList(string.format("Display %d", anchor_num))[1]

        if anchor_display then
            processed_count = processed_count + 1
            Echo(string.format("Anchor Display %d is ON. Instantiating Target Display %d...", anchor_num, target_num))

            -- 1. Force the window to Open cleanly
            Cmd(string.format("Store Display %d", target_num))
            coroutine.yield(0.2) -- Pause to allow the OS to render the fresh floating window container

            -- 2. DYNAMIC SIZE & POSITION CHECKING
            local anchor_x = tonumber(anchor_display:Get("x")) or 0
            local anchor_y = tonumber(anchor_display:Get("y")) or 0
            local anchor_h = tonumber(anchor_display:Get("h")) or 1080 

            -- 3. CRITICAL: LIVE SOFTWARE SCALE EXTRACTION
            -- We pull the scale property as a string and clean it using string.match 
            -- to safely extract only the numeric decimal, avoiding any Lua type crashes.
            local raw_scale_str = tostring(anchor_display:Get("Scale") or "1.0")
            local clean_scale_str = string.match(raw_scale_str, "([%d%.]+)")
            local live_software_scale = tonumber(clean_scale_str) or 1.0

            -- 4. THE MASTER LAYOUT FORMULA
            -- Combines your live window height, your active software scale, 
            -- and compensates for the internal coordinate grid behavior.
            local internal_grid_multiplier = 0.75
            local scaled_visible_height = anchor_h * live_software_scale * internal_grid_multiplier
            
            -- Apply the -2 pixel adjustments verified in your manual tests
            local target_x = anchor_x - 2
            local target_y = anchor_y + scaled_visible_height - 2

            -- 5. Move the target display into position
            Cmd(string.format("Set Display %d Property \"x\" %d", target_num, math.floor(target_x)))
            Cmd(string.format("Set Display %d Property \"y\" %d", target_num, math.floor(target_y)))
            
            Echo(string.format("-> Display %d locked (Scale: %0.2f, Calculated X: %d, Y: %d)", 
                target_num, live_software_scale, math.floor(target_x), math.floor(target_y)))
        end
    end

    Echo(string.format("Sync complete! Successfully aligned %d active workspace display window(s).", processed_count))
end

return main