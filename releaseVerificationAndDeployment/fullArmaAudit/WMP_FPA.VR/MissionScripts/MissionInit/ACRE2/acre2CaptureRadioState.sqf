/*
 * Author: WaldoTheWarfighter
 * Captures carried ACRE radio state by base class plus deterministic same-type occurrence so no
 * transient unique-ID classname is persisted. Channel/frequency, ear, volume, audio source and the
 * selected radio are preserved; alternate PTT and speaker mode remain untouched player settings.
 * A captured manual-frequency radio can be restored only when its frequency was last applied by WMP,
 * because ACRE exposes no public frequency read API.
 * Locality and authority: call on the player's interface client; ACRE radio state is client-owned
 * and this function only returns a serialisable snapshot.
 *
 * Arguments: None.
 * Return Value: ARRAY - [schema, radio entries, selected-radio descriptor].
 *
 * Example: private _state = [] call Waldo_fnc_ACRE2CaptureRadioState;
 * Result: `_state` contains supported radio occurrences and selected-radio identity without IDs.
 * Current callers: Waldo_fnc_SaveLoadout and Waldo_fnc_PersistenceClientCapture.
 */
if (!hasInterface || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {[]};
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _counts = createHashMap;
private _state = [];
private _selectedId = [] call acre_api_fnc_getCurrentRadio;
private _selected = [];
private _lastApplication = missionNamespace getVariable ["Waldo_ACRE2_LastApplication", []];
private _lastApplied = if (count _lastApplication >= 5) then {_lastApplication select 4} else {[]};
{
    private _radioId = _x;
    private _base = [_radioId] call acre_api_fnc_getBaseRadio;
    private _ordinal = (_counts getOrDefault [_base, 0]) + 1;
    _counts set [_base, _ordinal];
    private _profiles = [] call Waldo_fnc_ACRE2GetRadioProfiles;
    private _profileIndex = _profiles findIf {toUpper (_x select 0) == toUpper _base};
    private _mode = if (_profileIndex >= 0) then {toUpper ((_profiles select _profileIndex) select 1)} else {"CHANNEL"};
    private _setting = [_radioId] call acre_api_fnc_getRadioChannel;
    private _appliedIndex = _lastApplied findIf {(_x select 0) == _radioId};
    // ACRE exposes the PRC-343's current position as one absolute 1-256 channel. Convert that
    // public value back to WMP's beginner-facing [block, channel] form so player changes to either
    // knob are actually captured instead of reusing the original mission assignment.
    if (_mode == "BLOCK_CHANNEL" && {_setting >= 1}) then {
        private _zeroBased = _setting - 1;
        _setting = [(floor (_zeroBased / 16)) + 1, (_zeroBased mod 16) + 1];
    };
    if (_mode == "FREQUENCY" && {_appliedIndex >= 0}) then {
        private _applied = _lastApplied select _appliedIndex;
        _setting = _applied select 3;
    };
    // ACRE exposes no public frequency read-back. Only persist a frequency when the current WMP
    // application requested it; otherwise omit that occurrence instead of saving a bogus channel.
    if (_mode != "FREQUENCY" || {_appliedIndex >= 0}) then {
    private _audioSource = if (toUpper _base in ["ACRE_PRC148", "ACRE_PRC152", "ACRE_SEM52SL", "ACRE_SEM70"]) then {[_radioId] call acre_api_fnc_getRadioAudioSource} else {""};
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
    };
} forEach _radios;
[2, _state, _selected]
