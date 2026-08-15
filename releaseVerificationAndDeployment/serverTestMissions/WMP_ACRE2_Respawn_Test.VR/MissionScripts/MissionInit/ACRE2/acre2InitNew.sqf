/*
 * Author: WaldoTheWarfighter
 * Orchestrates ACRE lifecycle ownership. The server publishes one complete plan value
 * for JIP. The plan seeds each player's initial radio state once. Later player saves own their
 * respawn state; player-object replacement and group changes refresh Babel/CEOI without retuning.
 * Authoritative defaults never live in multiplayer init.sqf.
 * Locality and authority: called by server and player-local lifecycle files. The server compiles
 * and publishes the plan; each interface client applies only its own initial radios/Babel/CEOI.
 *
 * Arguments: None.
 * Return Value: BOOL - true when this machine accepted or started its applicable lifecycle stage.
 *
 * Example: [] call Waldo_fnc_ACRE2Init;
 * Result: the applicable server or player-local ACRE lifecycle stage starts once, when available.
 * Current callers: initServer.sqf and initPlayerLocal.sqf.
 */
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {missionNamespace setVariable ["Waldo_ACRE2_Available", false]; false};
private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf"];
private _validation = [_config] call Waldo_fnc_ACRE2ValidateConfig;
{diag_log format ["[WMP ACRE] CONFIG WARNING: %1", _x]} forEach (_validation param [2, []]);
if !(_validation select 0) exitWith {{diag_log format ["[WMP ACRE] CONFIG ERROR: %1", _x]} forEach (_validation select 1); false};
if !(_config getOrDefault ["enabled", true]) exitWith {missionNamespace setVariable ["Waldo_ACRE2_Available", false]; true};
missionNamespace setVariable ["Waldo_ACRE2_Available", true];
if (isServer && {isNil {missionNamespace getVariable "Waldo_ACRE2_Plan"}}) then {
    private _revision = (missionNamespace getVariable ["Waldo_ACRE2_PlanRevision", 0]) + 1;
    private _plan = [_config, _revision] call Waldo_fnc_ACRE2CompilePlan;
    missionNamespace setVariable ["Waldo_ACRE2_PlanRevision", _revision];
    // One public value is the readiness sentinel and payload, avoiding separate JIP arrival order.
    missionNamespace setVariable ["Waldo_ACRE2_Plan", _plan, true];
};
if (hasInterface && {isNil {missionNamespace getVariable "Waldo_ACRE2_ClientInitStarted"}}) then {
    missionNamespace setVariable ["Waldo_ACRE2_ClientInitStarted", true];
    // Actively pre-empt a unit's Eden "ACRE Radio Setup" attribute rather than letting it win a race
    // against ACRE's own initialization and cleaning up afterwards. ACRE applies that attribute
    // (acre_sys_radio_setup) as one of the last steps of its own per-unit init, gated behind ACRE
    // becoming fully ready - which can legitimately take anywhere from a few seconds to minutes on a
    // heavy modset. This runs here, at the very start of WMP's own client-side ACRE lifecycle (called
    // from initPlayerLocal.sqf near mission start), so it lands well before ACRE's own init reaches
    // that step in every observed case. Clearing does not touch acreConfig.sqf's own plan in any way;
    // it only stops the competing Eden-authored setup from ever being read. Waldo_fnc_SchedulePlayerRefresh's
    // readinessTimeoutSeconds wait/retry (MissionConfig\acreConfig.sqf) remains as the fallback for the
    // (unverified against a live ACRE install) case where ACRE reads this variable earlier than WMP can
    // clear it, or re-derives it from mission.sqm on its own schedule. ACRE passes this STRING to
    // parseSimpleArray, so its empty value must be the serialized array "[]"; an empty string throws
    // during ACRE's XEH_postInit and can prevent the carried-radio lifecycle from completing.
    if (!isNull player) then {player setVariable ["acre_sys_radio_setup", "[]", true]};
    ["INITIAL", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    private _babel = _config getOrDefault ["babel", createHashMap];
    if (_babel getOrDefault ["followPlayerUnit", true]) then {
        private _unitHandler = ["unit", {
            params ["_newUnit"];
            // Respawn's class handler requests radio setup after restoring the saved loadout. Other
            // player-object replacements refresh Babel/CEOI only and never retune radios mid-game.
            if (_newUnit isEqualTo player) then {["UNIT_REPLACEMENT", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh};
        }, false] call CBA_fnc_addPlayerEventHandler;
        missionNamespace setVariable ["Waldo_ACRE2_UnitHandler", _unitHandler];
    };
    private _groupHandler = ["group", {["GROUP_CHANGE", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh}] call CBA_fnc_addPlayerEventHandler;
    missionNamespace setVariable ["Waldo_ACRE2_GroupHandler", _groupHandler];
};
true
