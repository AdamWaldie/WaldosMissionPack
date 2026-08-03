/*
 * Author: WaldoTheWarfighter
 * Orchestrates the new ACRE lifecycle. The server publishes one authoritative JIP plan; each
 * interface client waits with a deadline, applies only its local carried radios, Babel and CEOI.
 *
 * Arguments: None.
 * Return Value: BOOL - true when this machine accepted or started its applicable lifecycle stage.
 *
 * Example: [] call Waldo_fnc_ACRE2Init;
 * Current callers: initServer.sqf and initPlayerLocal.sqf.
 */
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {
    missionNamespace setVariable ['Waldo_ACRE2_Available', false];
    false
};
private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', call compile preprocessFileLineNumbers 'MissionConfig\acreConfig.sqf'];
private _validation = [_config] call Waldo_fnc_ACRE2ValidateConfig;
{diag_log format ['[WMP ACRE] CONFIG WARNING: %1', _x]} forEach (_validation param [2, []]);
if !(_validation select 0) exitWith {{diag_log format ['[WMP ACRE] CONFIG ERROR: %1', _x]} forEach (_validation select 1); false};
if !(_config getOrDefault ['enabled', true]) exitWith {
    missionNamespace setVariable ['Waldo_ACRE2_Available', false];
    true
};
missionNamespace setVariable ['Waldo_ACRE2_Available', true];
if (isServer && {isNil {missionNamespace getVariable 'Waldo_ACRE2_Plan'}}) then {
    private _revision = (missionNamespace getVariable ['Waldo_ACRE2_PlanRevision', 0]) + 1;
    private _plan = [_config, _revision] call Waldo_fnc_ACRE2CompilePlan;
    missionNamespace setVariable ['Waldo_ACRE2_PlanRevision', _revision, true];
    missionNamespace setVariable ['Waldo_ACRE2_Plan', _plan, true];
    missionNamespace setVariable ['Waldo_ACRE2_PlanReady', true, true];
};
if (hasInterface && {isNil {uiNamespace getVariable 'Waldo_ACRE2_ClientInitStarted'}}) then {
    uiNamespace setVariable ['Waldo_ACRE2_ClientInitStarted', true];
    [] spawn {
        private _deadline = diag_tickTime + 30;
        waitUntil {
            uiSleep 0.1;
            (([] call acre_api_fnc_isInitialized) && {missionNamespace getVariable ['Waldo_ACRE2_PlanReady', false]}) || {diag_tickTime >= _deadline}
        };
        if !(([] call acre_api_fnc_isInitialized) && {missionNamespace getVariable ['Waldo_ACRE2_PlanReady', false]}) exitWith {
            diag_log '[WMP ACRE] Client initialization timed out; mission startup continues.';
        };
        private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
        if !(missionNamespace getVariable ['Waldo_ACRE2_PresetNamesReady', false]) then {[_config] call Waldo_fnc_ACRE2ApplyPresetNames};
        [true, 'INITIAL'] call Waldo_fnc_ACRE2ApplyPlayerPlan;
        [] call Waldo_fnc_ACRE2ApplyBabel;
        [] call Waldo_fnc_ACRE2BuildCEOI;
        [false] call Waldo_fnc_SaveLoadout;
        private _babel = _config getOrDefault ['babel', createHashMap];
        if (_babel getOrDefault ['followPlayerUnit', true] && {isNil {uiNamespace getVariable 'Waldo_ACRE2_UnitHandler'}}) then {
            private _handler = ['unit', {
                params ['_newUnit'];
                if (_newUnit isEqualTo player) then {
                    [] spawn {
                        uiSleep 0.2;
                        [true, 'UNIT_REPLACEMENT'] call Waldo_fnc_ACRE2ApplyPlayerPlan;
                        [] call Waldo_fnc_ACRE2ApplyBabel;
                        [] call Waldo_fnc_ACRE2BuildCEOI;
                    };
                };
            }, false] call CBA_fnc_addPlayerEventHandler;
            uiNamespace setVariable ['Waldo_ACRE2_UnitHandler', _handler];
        };
        if (isNil {uiNamespace getVariable 'Waldo_ACRE2_GroupHandler'}) then {
            private _groupHandler = ['group', {
                [] spawn {
                    uiSleep 0.1;
                    private _config = missionNamespace getVariable ['Waldo_ACRE2_Config', createHashMap];
                    if (_config getOrDefault ['retuneOnGroupChange', false]) then {
                        [true, 'GROUP_CHANGE'] call Waldo_fnc_ACRE2ApplyPlayerPlan;
                    };
                    [] call Waldo_fnc_ACRE2BuildCEOI;
                };
            }] call CBA_fnc_addPlayerEventHandler;
            uiNamespace setVariable ['Waldo_ACRE2_GroupHandler', _groupHandler];
        };
    };
};
true
