/*
 * Author: WaldoTheWarfighter
 * Restores persisted carried-radio state after ACRE replaces base classes with new unique IDs.
 * The wait is bounded and the successful generation suppresses baseline mission-plan retuning.
 *
 * Arguments:
 * 0: saved radio state <ARRAY>
 * 1: loadout generation <NUMBER>
 *
 * Return Value: BOOL - true when all matching radio states were restored.
 *
 * Example: [_radios, _generation] spawn Waldo_fnc_ACRE2ApplyRadioState;
 * Current caller: Waldo_fnc_PersistenceClientApply.
 */
params [['_savedRadios', [], [[]]], ['_generation', 0, [0]]];
if (!hasInterface || {count _savedRadios == 0} || {!(isClass (configFile >> 'CfgPatches' >> 'acre_main'))}) exitWith {false};
private _deadline = diag_tickTime + 10;
waitUntil {
    uiSleep 0.1;
    private _list = [player] call acre_api_fnc_getCurrentRadioList;
    (([] call acre_api_fnc_isInitialized) && {count _list >= count _savedRadios}) || {diag_tickTime >= _deadline}
};
private _counts = createHashMap;
private _success = true;
{
    private _radioId = _x;
    private _base = [_radioId] call acre_api_fnc_getBaseRadio;
    private _ordinal = _counts getOrDefault [_base, 0];
    _counts set [_base, _ordinal + 1];
    private _savedIndex = _savedRadios findIf {(_x select 0) == _base && {(_x select 1) == _ordinal}};
    if (_savedIndex >= 0) then {
        private _saved = _savedRadios select _savedIndex;
        if !([_radioId, _saved select 2] call acre_api_fnc_setRadioChannel) then {_success = false};
        if !([_radioId, _saved select 3] call acre_api_fnc_setRadioSpatial) then {_success = false};
    };
} forEach ([player] call acre_api_fnc_getCurrentRadioList);
if (_success) then {missionNamespace setVariable ['Waldo_ACRE2_PersistenceRadioGeneration', _generation]};
_success
