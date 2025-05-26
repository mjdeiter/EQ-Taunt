--[[
KeepAggro.Lua v3.9.7 (2025-05-25)
Changelog:
- Documents harmless /declare warning at top of file
- Uses /declare AUTOSHIELD_REQUEST string outer (always, for safety)
- Only fires aggro abilities when truly in combat (using mq.TLO.Me.Combat())
- Keeps all aggro/control logic and robust nil checks
- Compatible with MacroQuest/E3 Lua
]]

local mq = require('mq')

-- Version banner
local SCRIPT_VERSION = "v3.9.7"
local SCRIPT_DATE = "2025-05-25"
mq.cmd(string.format('/echo \\agCredit: \\acAlektra <Lederhosen>\\ax | \\ayKeepAggro.Lua %s (%s)\\ax', SCRIPT_VERSION, SCRIPT_DATE))

-- NOTE:
-- There is no way to check for variable existence in MacroQuest Lua.
-- The line below will produce a harmless warning if AUTOSHIELD_REQUEST is already declared.
-- This warning does not affect functionality and can be safely ignored.
mq.cmd('/declare AUTOSHIELD_REQUEST string outer')

-- Logging function with timestamps
local function log(message, level)
    local prefix = os.date('%Y-%m-%d %H:%M:%S') .. " [KeepAggro] "
    mq.cmdf('/echo %s%s: %s', prefix, level or "INFO", message)
end

-- Ability and item definitions (edit as needed)
local abilities = {
    taunt = "Taunt",
    ae_taunts = { "Area Taunt", "Rampage Taunt" },
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
}

-- Defensive cooldowns/items for low health thresholds
local defensive_triggers = {
    { threshold = 40, action = function() use_item("Forsaken Shieldstorm") end },
    { threshold = 25, action = function() use_ability("Armor of Experience") end },
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

local function safe_pct_aggro()
    local pct = mq.TLO.Me.PctAggro()
    if type(pct) ~= "number" then
        log("safe_pct_aggro(): PctAggro() returned nil or non-number!", "ERROR")
        return 0
    end
    return pct
end

local function is_tanking()
    return safe_pct_aggro() >= 99
end

function lost_aggro()
    local pct_aggro = safe_pct_aggro()
    local tot = mq.TLO.Me.TargetOfTarget()
    local tot_class = (tot and tot.Class and tot.Class.ShortName()) or ""
    return pct_aggro < 100 and not (tot_class:find("WAR") or tot_class:find("PAL") or tot_class:find("SHD"))
end

local function super_close()
    local dist = mq.TLO.Target.Distance()
    return dist and dist < 10 and mq.TLO.Me.CountSongs() < 19 and not mq.TLO.Me.Moving()
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
local function safe_pct_hps()
    local hp = mq.TLO.Me.PctHPs()
    if type(hp) ~= "number" then
        log("safe_pct_hps(): PctHPs() returned nil or non-number!", "ERROR")
        return 100
    end
    return hp
end

local function check_defensive_triggers()
    local hp = safe_pct_hps()
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

-- Bash cooldown logic
local bash_request_cooldown = 4
local last_bash_request = 0

local function request_autoshield(state)
    mq.cmdf('/varset AUTOSHIELD_REQUEST %s', state)
end

-- Main aggro logic loop
while true do
    local status, err = pcall(function()
        local group_members = mq.TLO.Group.Members()
        local target_id = mq.TLO.Target.ID()
        local target_pcthps = mq.TLO.Target.PctHPs()
        local target_beneficial = mq.TLO.Target.Beneficial()
        -- Only act if actually in combat!
        if mq.TLO.Me.Combat() and
            group_members and group_members > 1 and
            target_id and target_pcthps and target_pcthps > 0 and
            not target_beneficial then

            -- Always core aggro tools
            use_ability(abilities.taunt)
            for _, ae in ipairs(abilities.ae_taunts) do
                use_ability(ae)
            end

            -- Bash swap synergy (robust safe math and debug)
            if can_use_ability(abilities.bash) then
                local now = os.time()
                local safe_last_bash_request = last_bash_request

                log("DEBUG: Bash math about to run. now="..tostring(now)..
                    " ("..type(now)..") last_bash_request="..tostring(safe_last_bash_request)..
                    " ("..type(safe_last_bash_request)..")", "DEBUG")

                if type(now) == "number" and type(safe_last_bash_request) == "number" then
                    local diff = now - safe_last_bash_request

                    if not has_shield() then
                        if diff > bash_request_cooldown then
                            log("Requesting shield swap from AutoShield for Bash. (now="..now.." last_bash_request="..safe_last_bash_request.." diff="..diff..")")
                            request_autoshield("shield")
                            last_bash_request = now
                        end
                    elseif has_shield() then
                        use_ability(abilities.bash)
                        log("Requesting offhand swap from AutoShield after Bash.")
                        request_autoshield("offhand")
                        last_bash_request = now
                    end
                else
                    log("BASH ERROR: Cannot perform Bash cooldown math: now="..tostring(now).." ("..type(now)..") last_bash_request="..tostring(safe_last_bash_request).." ("..type(safe_last_bash_request)..")", "ERROR")
                end
            end

            -- Tanking logic
            if is_tanking() then
                if has_shield() then
                    use_ability(abilities.knee_strike)
                    use_ability(abilities.throat_jab)
                end
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
