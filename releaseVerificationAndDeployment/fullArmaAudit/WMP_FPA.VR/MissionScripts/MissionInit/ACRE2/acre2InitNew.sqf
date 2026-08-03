/*
 * Author: WaldoTheWarfighter
 * Orchestrates schema-three ACRE lifecycle ownership. The server publishes one complete plan value
 * for JIP. Interface clients debounce initial join, player-object replacement and group changes into
 * the readiness-aware refresh helper; authoritative defaults never live in multiplayer init.sqf.
 *
 * Arguments: None.
 * Return Value: BOOL - true when this machine accepted or started its applicable lifecycle stage.
 *
 * Example: [] call Waldo_fnc_ACRE2Init;
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
if (hasInterface && {isNil {uiNamespace getVariable "Waldo_ACRE2_ClientInitStarted"}}) then {
    uiNamespace setVariable ["Waldo_ACRE2_ClientInitStarted", true];
    ["INITIAL", true] call Waldo_fnc_ACRE2SchedulePlayerRefresh;
    private _babel = _config getOrDefault ["babel", createHashMap];
    if (_babel getOrDefault ["followPlayerUnit", true]) then {
        private _unitHandler = ["unit", {
            params ["_newUnit"];
            // Respawn's class handler requests radio setup after restoring the saved loadout. Other
            // player-object replacements refresh Babel/CEOI only and never retune radios mid-game.
            if (_newUnit isEqualTo player) then {["UNIT_REPLACEMENT", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh};
        }, false] call CBA_fnc_addPlayerEventHandler;
        uiNamespace setVariable ["Waldo_ACRE2_UnitHandler", _unitHandler];
    };
    private _groupHandler = ["group", {["GROUP_CHANGE", false] call Waldo_fnc_ACRE2SchedulePlayerRefresh}] call CBA_fnc_addPlayerEventHandler;
    uiNamespace setVariable ["Waldo_ACRE2_GroupHandler", _groupHandler];
};
true
