/*
 * Author: WaldoTheWarfighter
 * Captures carried ACRE radio channel and spatial state by base class plus same-type ordinal so no
 * transient unique-ID classname is persisted.
 *
 * Arguments: None.
 * Return Value: ARRAY - radio state entries [base class, ordinal, channel, spatial].
 *
 * Example: private _state = [] call Waldo_fnc_ACRE2CaptureRadioState;
 * Current caller: Waldo_fnc_PersistenceClientCapture.
 */
if (!hasInterface || {!(isClass (configFile >> 'CfgPatches' >> 'acre_main'))}) exitWith {[]};
private _counts = createHashMap;
private _state = [];
{
    private _base = [_x] call acre_api_fnc_getBaseRadio;
    private _ordinal = _counts getOrDefault [_base, 0];
    _counts set [_base, _ordinal + 1];
    _state pushBack [_base, _ordinal, [_x] call acre_api_fnc_getRadioChannel, [_x] call acre_api_fnc_getRadioSpatial];
} forEach ([player] call acre_api_fnc_getCurrentRadioList);
_state
