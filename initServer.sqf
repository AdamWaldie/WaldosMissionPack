/*
If you are utilising the Virtual Logistics Quartermaster (initQuartermaster.sqf & LogiBoxes.sqf) You can set custom boxes for both Medical & Supply boxes.
By default, leaving these unchanged, will provide players with the Default ACE Medical/Vanilla Medical box & Vanilla Supply box. you do not need to change these

You will need to find the classname of the box you are wanting to use, and place it with the quotation marks in where dennoted below;

missionNamespace setVariable ["SupplyBoxClass", "PUTCLASSNAMEHERE", true];

*/

//Supply Box Classname MissionNameSpace Declaration
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F",true];
//Logi_SupplyBoxClass = "B_supplyCrate_F";
//Medical Box Classname MissionNameSpace Declaration
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced",true];
} else {
    missionNamespace setVariable ["Logi_MedicalBoxClass", "C_IDAP_supplyCrate_F",true];
};


/*
PARADROP SCRIPTS

MissionScripts\Paradrop has all the paradrop related functions. Waldos_functions.sqf under Paradrop display the function names.

For basic usage, most "Plane" class assets, and some Helicopters have static line &/or HALO jump capabilities added automatically. The C130J from RHS and its inherritants also have full use of these systems.

You can also tweak the below variables to supply custom parachute classes, as well as change the requirements for HALO & Static Line jumps to be availble to perform. 

This affects both the automatically added vehicles, and those you manually add via:
[this] call Waldo_fnc_VehicleJumpSetup;

*/
//Static Line Variables
//Static Minimum Altitude
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180, true];
//Static Maximum Altitude
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350, true];
//Static Maximum Speed
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310, true];
//Static Line Parachute Class
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true];

//HALO Jump Variables
//HALO Minimum Altitude
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];
//HALO Parachute Class
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute", true];

/*

Mission.sqm based supply system

This searches the Mission.sqm for playable characters on the side defined by the parameter. It grabs their compliment of weapons, ammo, clothing and items, gets uniques and returns a unique 2D Array of the results.

These results are then globaly synced, for use in the ZEN resupply boxes & to create ACE Arsenals with equipment limited to that pre-existing in the mission.sqm

IMPORTANT: YOU MUST EDIT THE LOADOUTS OF PLACED UNITS WITH AN ARSENAL OF SOME DESCRIPTION FOR THIS TO WORK, VANILLA UNIT LOADOUTS WILL NOT SUFFICE!

*/

[] call Waldo_fnc_SideBaseLoadoutSetup;

/*
After-Action tracking

Starts lightweight, event-driven tallying of mission duration and infantry KIA per side so the
ENDEX debrief can show a summary. Adds negligible overhead (a single EntityKilled handler).
*/
[] call Waldo_fnc_AARTrack;

/*
Mission Diagnostics (optional)

Runs a server-side configuration sanity check after the loadout scan: warns about missing
required mods, empty per-side loadout scrapes (vanilla loadouts / binarized mission.sqm),
invalid crate or parachute classnames and bad paradrop thresholds. Output goes to the RPT
log (prefixed [WMP DIAG]) and warnings are echoed to admins via systemChat.

Set the flag below to false to disable it for a shipping mission.
*/
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
if (missionNamespace getVariable ["Waldo_RunDiagnostics", true]) then {
    [] spawn Waldo_fnc_RunDiagnostics;
};

/*
Safestart (optional)

Freezes all players at mission start - weapons safe, no damage dealt or received, confined to a
safe zone, with an on-screen banner. Lift it (go live) from the Zeus "Waldos Mission Modules" menu
or from script with [false] call Waldo_fnc_SafeStart. A timed go-live can be started from Zeus or
with [seconds] call Waldo_fnc_SafeStartTimer.

Confinement defaults to a 75m radius around each player's start position. To use one shared zone,
place a marker and set Waldo_SafeStart_ZoneMarker to its name. Tune or disable below.

Set Waldo_SafeStart_AutoStart to false to start the mission live (no safestart).
*/
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", true, true];
if (missionNamespace getVariable ["Waldo_SafeStart_AutoStart", true]) then {
    [true] call Waldo_fnc_SafeStart;
};

/*
Waldos Economy Systems - editor / script-time setup (optional)

Lets you configure the economy suite (Resource / Research / Build / Buy) from the editor with
no need to open Zeus. These settings are applied once, server-side, at mission start and are
broadcast to all players (JIP / rejoining players inherit them automatically). You can still
fine-tune everything live in the Zeus "Waldos Economy Systems" menu afterwards.

FIRST enable the suite in init.sqf (set Waldo_Economy_Enable = true;), OR drop one of the
"[WMP] Waldos Economy Systems" compositions. THEN, to pre-load a configuration, set any of the
variables below (leave them as-is to configure purely in Zeus).

Option A - load a bundled preset (quickest):
    Waldo_Economy_Preset      - "LOW", "MEDIUM" or "HIGH" (increasing complexity). LOW is a single
                                resource + research; HIGH is a full Factorio-style economy.
    Waldo_Economy_PresetSides - which faction catalogue each side buys from. Default below covers
                                WEST/EAST/INDEP. Catalogue keys: "NATO","CSAT","AAF","SYNDIKAT".

Option B - load a full configuration string you exported earlier from the Zeus "Export" tool
           (this wins over a preset if both are set):
    Waldo_Economy_ConfigString - paste the exported text here.

Option C - hand-author the whole economy (define your own resources / research / buildings /
           purchases and pre-place zones, crates, research centers, terminals and drop points
           at map markers): edit economyConfig.sqf in the mission root. You can also designate
           vanilla objects placed in Eden via their init field, e.g.
               [this] call Waldo_fnc_EcoResearch_registerCenter;     // on a Land_Research_HQ_F
               [this] call Waldo_fnc_EcoBuy_registerTerminal;        // on a Land_Laptop_unfolded_F
               [this] call Waldo_fnc_EcoBuild_registerConstructionVehicle; // on any vehicle

Independent of A/B/C:
    Waldo_Economy_CommitmentMode - true freezes config-catalog refreshes to cut server load
                                   (recommended ON once you have finished configuring).

Examples (uncomment and edit to use):
*/
// missionNamespace setVariable ["Waldo_Economy_Preset", "MEDIUM", true];
// missionNamespace setVariable ["Waldo_Economy_PresetSides", [["WEST","NATO"],["EAST","CSAT"],["GUER","AAF"]], true];
// missionNamespace setVariable ["Waldo_Economy_ConfigString", "", true];
// missionNamespace setVariable ["Waldo_Economy_CommitmentMode", true, true];