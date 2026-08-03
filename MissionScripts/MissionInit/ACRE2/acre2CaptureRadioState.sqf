/*
 * Author: WaldoTheWarfighter
 * Captures carried ACRE radio state by base class plus deterministic same-type occurrence so no
 * transient unique-ID classname is persisted. Channel/frequency, ear, volume, audio source and the
 * selected radio are preserved; alternate PTT and speaker mode remain untouched player settings.
 * A captured manual-frequency radio can be restored only when its frequency was last applied by WMP,
 * because ACRE exposes no public frequency read API.
 *
 * Arguments: None.
 * Return Value: ARRAY - [schema, radio entries, selected-radio descriptor].
 *
 * Example: private _state = [] call Waldo_fnc_ACRE2CaptureRadioState;
 * Current caller: Waldo_fnc_PersistenceClientCapture.
 */
if (!hasInterface || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {[]};
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _counts = createHashMap;
private _state = [];
private _selectedId = [] call acre_api_fnc_getCurrentRadio;
private _selected = [];
private _lastApplication = uiNamespace getVariable ["Waldo_ACRE2_LastApplication", []];
private _lastApplied = if (count _lastApplication >= 5) then {_lastApplication select 4} else {[]};
{
    private _radioId = _x;
    private _base = [_radioId] call acre_api_fnc_getBaseRadio;
    private _ordinal = (_counts getOrDefault [_base, 0]) + 1;
    _counts set [_base, _ordinal];
    private _mode = "CHANNEL";
    private _setting = [_radioId] call acre_api_fnc_getRadioChannel;
    private _appliedIndex = _lastApplied findIf {(_x select 0) == _radioId};
    if (_appliedIndex >= 0) then {
        private _applied = _lastApplied select _appliedIndex;
        private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
        private _profileIndex = (_config getOrDefault ["radioProfiles", []]) findIf {toUpper (_x select 0) == toUpper _base};
        if (_profileIndex >= 0) then {
            _mode = toUpper (((_config get "radioProfiles") select _profileIndex) select 1);
            _setting = _applied select 3;
        };
    };
    private _audioSource = [_radioId] call acre_api_fnc_getRadioAudioSource;
    if (isNil "_audioSource" || {!(_audioSource isEqualType "")}) then {_audioSource = ""};
    private _volume = [_radioId] call acre_api_fnc_getRadioVolume;
    if (isNil "_volume" || {!(_volume isEqualType 0)}) then {_volume = -1};
    _state pushBack [
        _base, _ordinal, _mode, _setting,
        [_radioId] call acre_api_fnc_getRadioSpatial,
        _volume,
        _audioSource
    ];
    if (_radioId == _selectedId) then {_selected = [_base, _ordinal]};
} forEach _radios;
[2, _state, _selected]
