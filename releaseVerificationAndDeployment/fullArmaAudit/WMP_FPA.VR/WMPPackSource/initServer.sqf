/*
 * Author: WaldoTheWarfighter
 * Starts authoritative WMP systems once on the server. Mission makers normally edit files inside
 * MissionConfig, not this entry point. Put a custom call here only when its function header says
 * that the server owns the world state, spawning, database operation or public-variable broadcast.
 * Player UI and local ACE actions do not belong here.
 *
 * Arguments: None (Arma calls this file automatically on the server).
 * Return Value: Nothing.
 * Current caller: Arma's server mission lifecycle, including hosted and dedicated servers.
 */

/* STARTUP ORDER
 * 1. ACRE compiles and publishes its authoritative communications plan.
 * 2. SERVER feature settings are loaded from MissionConfig.
 * 3. Server-owned features start.
 * 4. Runtime readiness is broadcast last so players and JIP clients see a complete snapshot.
 */
[] call Waldo_fnc_ACRE2Init;
["SERVER"] call Waldo_fnc_LoadFeatureConfigs;
if (missionNamespace getVariable ["Waldo_Jamming_Enable", true]) then {
    [] call Waldo_fnc_JammingInit;
};

[] spawn {
    waitUntil {missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]};
    if (missionNamespace getVariable ["Waldo_Economy_Enable", false]) then {
        // initServer.sqf has now finished assigning mission-maker presets/configuration.
        // Economy applies that authoritative setup before runtime readiness is published.
        [] call Waldo_fnc_EcoInit;
    };
    if (missionNamespace getVariable ["Waldo_Persistence_Enable", false]) then {
        [] call Waldo_fnc_PersistenceInit;
    };
    // Published last: player machines may now reconcile their local defaults with authoritative state.
    missionNamespace setVariable ["Waldo_FeatureRuntimeStateReady", true, true];
};

/*
If you are utilising the Virtual Logistics Quartermaster (initQuartermaster.sqf & LogiBoxes.sqf) You can set custom boxes for both Medical & Supply boxes.
By default, leaving these unchanged, will provide players with the Default ACE Medical/Vanilla Medical box & Vanilla Supply box. you do not need to change these

You will need to find the classname of the box you are wanting to use, and place it with the quotation marks in where dennoted below;

missionNamespace setVariable ["SupplyBoxClass", "PUTCLASSNAMEHERE", true];

*/

/*
PARADROP SCRIPTS

MissionScripts\Paradrop has all the paradrop related functions. Waldos_functions.sqf under Paradrop display the function names.

For basic usage, most "Plane" class assets, and some Helicopters have static line &/or HALO jump capabilities added automatically. The C130J from RHS and its inherritants also have full use of these systems.

Edit `MissionConfig\airOperationsConfig.sqf` for parachute classes and jump requirements. Do not paste
those settings below or create another global activation here.

This affects both the automatically added vehicles, and those you manually add via:
[this] call Waldo_fnc_VehicleJumpSetup;

*/
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

Runs a read-only server and client health check after the loadout scan. RPT lines include
one run ID, machine role, feature area, feature name, severity, and event. Checks distinguish
loaded, active, disabled, unconfigured, unavailable, and error states. A hosted server also
shows warnings through systemChat.

Set `Waldo_RunDiagnostics` in `MissionConfig\missionSystemsConfig.sqf`.
*/
if (missionNamespace getVariable ["Waldo_RunDiagnostics", true]) then {
    [] spawn {
        private _deadline = diag_tickTime + 30;
        waitUntil {
            sleep 0.5;
            (
                missionNamespace getVariable ["Logi_MissionScanComplete", false]
                && {missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]}
            )
            || {diag_tickTime >= _deadline}
        };
        [] call Waldo_fnc_RunDiagnostics;
    };
};

/*
Safestart (optional)

Freezes all players at mission start - weapons safe, no damage dealt or received, confined to a
safe zone, with an on-screen banner. Lift it (go live) from the Zeus "Waldos Mission Modules" menu
or from script with [false] call Waldo_fnc_SafeStart. A timed go-live can be started from Zeus or
with [seconds] call Waldo_fnc_SafeStartTimer.

Confinement defaults to a 75m radius around each player's start position. To use one shared zone,
place a marker and set Waldo_SafeStart_ZoneMarker to its name. Tune or disable below.

Set `Waldo_SafeStart_AutoStart` in `MissionConfig\missionSystemsConfig.sqf` to start live.
*/
if (missionNamespace getVariable ["Waldo_SafeStart_AutoStart", true]) then {
    [true] call Waldo_fnc_SafeStart;
};

/*
Waldos Economy Systems - editor / script-time setup (optional)

Lets you configure the economy suite (Resource / Research / Build / Buy) from the editor with
no need to open Zeus. These settings are applied once, server-side, at mission start and are
broadcast to all players (JIP / rejoining players inherit them automatically). You can still
fine-tune everything live in the Zeus "Waldos Economy Systems" menu afterwards.

Enable and configure the suite in `MissionConfig\economyConfig.sqf`, or use a documented WMP
economy composition. The examples below are custom server-side overrides only; most beginners
should leave them commented and use the configuration file.

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
           at map markers): edit MissionConfig\economyConfig.sqf. You can also designate
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
