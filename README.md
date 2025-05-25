EQ-Taunt: Advanced Warrior Aggro Script
A Lua script for EverQuest Warriors, designed to maximize aggro control and automate defensive cooldowns using the MacroQuest (MQ) Lua API.

Features
Automated Aggro Tools: Uses Taunt, AE taunts (customizable), and situational abilities (Battle Leap, Knee Strike, Throat Jab, Bash, Kick) based on your current tanking state and equipment.
Dynamic Clicky Usage: Automatically activates aggro items (“clickies”) when you lose aggro.
Defensive Cooldowns: Triggers shields, abilities, or items based on configurable low-health thresholds.
Flexible Logic: Detects group/tank status, proximity, and gear (shield/offhand) to optimize ability usage.
Detailed Logging: Script logs actions and errors with timestamps for easy troubleshooting.
Requirements
MacroQuest: This script requires MacroQuest with Lua scripting enabled.
EverQuest Warrior: Script logic is tailored for Warrior class abilities and typical itemization.
Lua: Standard with MacroQuest.
Setup & Installation
Install MacroQuest and ensure the Lua module is active.
Copy the Script: Save the script as eq_taunt.lua (or your preferred name) in your MQ lua scripts directory.
Edit for Your Character:
Edit abilities, ae_taunts, and clickies in the script to match your Warrior’s spell/disc/item setup.
Adjust defensive_triggers thresholds and actions as appropriate for your gear and playstyle.
Usage
In-game, target a mob and ensure you’re grouped.
Start the script via MacroQuest:
Code
/lua run eq_taunt
The script will loop automatically, handling aggro and defensive logic.
Customization
Adding Abilities/Items:
Update the abilities and clickies tables with ability names or item names as they appear in-game.
Change Defensive Behavior:
Edit the defensive_triggers table to add/remove thresholds and actions.
Tweak Logic:
Modify functions for more advanced conditions (e.g., target types, custom clicky logic).
Example: Adding a New Aggro Clicky
Lua
-- Add in the 'clickies' table:
{ name = "Your New Aggro Item", condition = function() return lost_aggro() end },
Troubleshooting
Errors are logged in-game using /echo with timestamps.
Make sure all ability/item names are spelled exactly as in-game.
If the script isn’t acting as expected, check the MQ console for log outputs.
License
MIT License. See LICENSE for details.

Feel free to copy/paste and edit this README as needed for your repo! Let me know if you want to include specific ability/item examples or further customization tips.


