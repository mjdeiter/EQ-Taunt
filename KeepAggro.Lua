-- Advanced Project Lazarus Warrior Aggro Script
-- Requires: mq = require('mq') (for MacroQuest Lua API)

local mq = require('mq')

-- Logging function with timestamps
local function log(message, level)
    local prefix = os.date('%Y-%m-%d %H:%M:%S') .. " [KeepAggro] "
    mq.cmdf('/echo %s%s: %s', prefix, level or "INFO", message)
end

-- Ability and item definitions (edit as needed)
local abilities = {
    taunt = "Taunt",
    ae_taunts = { "Area Taunt", "Rampage Taunt" }, -- Add any AE taunts here
    battle_leap = "Battle Leap",
    knee_strike = "Knee Strike",
    throat_jab = "Throat Jab",
    bash = "Bash",
    kick = "Kick"
}

-- Add clickies and their optional use condition
local clickies = {
    { name = "Forsaken Sword of the Morning", condition = function() return lost_aggro() end },
    { name = "Forsaken Sword of Skyfire", condition = function() return lost_aggro() end },
    -- Add more clickies here as needed, e.g.:
    -- { name = "Aggro Clicky X", condition = function() return true end },
}

-- Defensive cooldowns/items for low health thresholds
local defensive_triggers = {
    { threshold = 40, action = function() use_item("Forsaken Shieldstorm") end },
    { threshold = 25, action = function() use_ability("Armor of Experience") end },
    -- Add more defensive triggers as needed
}

-- Utility functions
local function has_shield()
    local slot14 = mq.TLO.Me.Inventory(14)
    return slot14() ~= nil and slot14.Type() == "Shield"
end

local function has_offhand()
    local slot14 = mq.TLO.Me.Inventory(14)
    return slot14() ~= nil and slot14.Type() ~= "Shield"
end

local function is_tanking()
    return mq.TLO.Me.PctAggro() >= 99
end

local function not_tanking()
    return mq.TLO.Me.PctAggro() < 100
end

function lost_aggro()
    local pct_aggro = mq.TLO.Me.PctAggro()
    local tot = mq.TLO.Me.TargetOfTarget()
    local tot_class = (tot and tot.Class and tot.Class.ShortName()) or ""
    return pct_aggro < 100 and not (tot_class:find("WAR") or tot_class:find("PAL") or tot_class:find("SHD"))
end

local function super_close()
    return mq.TLO.Target.Distance() and mq.TLO.Target.Distance() < 10 and mq.TLO.Me.CountSongs() < 19 and not mq.TLO.Me.Moving()
end

local function can_use_ability(name)
    local ok, ready = pcall(function() return mq.TLO.Me.AbilityReady(name)() end)
    if not ok then log("Failed to check ability: " .. name, "ERROR"); return false end
    return ready
end

local function use_ability(name)
    if can_use_ability(name) then
        log("Using ability: " .. name)
        mq.cmdf('/doability "%s"', name)
    end
end

local function can_use_item(name)
    local ok, ready = pcall(function() return mq.TLO.FindItem(name)() and mq.TLO.Me.ItemReady(name)() end)
    if not ok then log("Failed to check item: " .. name, "ERROR"); return false end
    return ready
end

function use_item(name)
    if can_use_item(name) then
        log("Using item: " .. name)
        mq.cmdf('/useitem "%s"', name)
    end
end

-- Health-based defensive logic
local function check_defensive_triggers()
    local hp = mq.TLO.Me.PctHPs()
    for _, trigger in ipairs(defensive_triggers) do
        if hp <= trigger.threshold then
            local ok, err = pcall(trigger.action)
            if not ok then
                log("Error executing defensive action at "..trigger.threshold.."%: "..tostring(err), "ERROR")
            else
                log("Triggered defensive action at "..trigger.threshold.."%")
            end
        end
    end
end

-- Main aggro logic loop
while true do
    local status, err = pcall(function()
        if mq.TLO.Group.Members() > 1 and mq.TLO.Target.ID() and mq.TLO.Target.PctHPs() > 0 and not mq.TLO.Target.Beneficial() then
            -- Always core aggro tools
            use_ability(abilities.taunt)
            for _, ae in ipairs(abilities.ae_taunts) do
                use_ability(ae)
            end

            -- Tanking logic
            if is_tanking() then
                if has_shield() then
                    use_ability(abilities.knee_strike)
                    use_ability(abilities.throat_jab)
                end
                use_ability(abilities.bash)
            else
                if has_offhand() then use_ability(abilities.battle_leap) end
                use_ability(abilities.kick)
            end
            -- Proximity logic
            if super_close() then use_ability(abilities.battle_leap) end

            -- Clicky logic
            for _, clicky in ipairs(clickies) do
                local ok, want_to_use = pcall(clicky.condition)
                if not ok then
                    log("Error evaluating clicky condition for " .. clicky.name, "ERROR")
                elseif want_to_use then
                    use_item(clicky.name)
                end
            end

            -- Health-based defense
            check_defensive_triggers()
        end
    end)
    if not status then
        log("Main loop error: "..tostring(err), "ERROR")
    end
    mq.delay(2000)
end
