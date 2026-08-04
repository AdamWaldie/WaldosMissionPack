/*
 * Author: WaldoTheWarfighter
 * Restores saved carried-radio state after ACRE replaces base classes with new unique IDs. It
 * restores channel or WMP-known frequency, ear, volume, supported audio source and selected radio while leaving
 * alternate PTT and speaker mode untouched. The wait is bounded and successful restoration suppresses
 * baseline mission-plan retuning for the same loadout generation. The same function serves ordinary
 * respawn snapshots and optional INIDBI2 persistence snapshots.
 * Locality and authority: spawn on the player's interface client after its filtered loadout is
 * restored. The bounded wait and all radio mutations are local to that player.
 *
 * Arguments:
 * 0: saved radio state <ARRAY>
 * 1: loadout generation <NUMBER>
 *
 * Return Value: BOOL - true when every saved occurrence was restored or its asynchronous frequency
 * request was accepted. ACRE provides no public frequency read-back, so frequency remains unverified.
 *
 * Example: [_radios, _generation] spawn Waldo_fnc_ACRE2ApplyRadioState;
 * Result: matching fresh radio IDs recover the saved state without changing PTT configuration.
 * Current callers: local respawn restoration and Waldo_fnc_PersistenceClientApply.
 */
params [["_savedState", [], [[]]], ["_generation", 0, [0]]];
if (!hasInterface || {count _savedState < 3} || {(_savedState select 0) != 2} || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {false};
private _savedRadios = _savedState select 1;
private _savedSelected = _savedState select 2;
if (count _savedRadios == 0) exitWith {false};
private _deadline = diag_tickTime + 10;
waitUntil {
    uiSleep 0.1;
    private _list = [] call Waldo_fnc_ACRE2GetOrderedRadios;
    private _allOccurrencesReady = {
        private _base = _x select 0;
        private _ordinal = _x select 1;
        ({toUpper ([_x] call acre_api_fnc_getBaseRadio) == toUpper _base} count _list) >= _ordinal
    } count _savedRadios == count _savedRadios;
    (([] call acre_api_fnc_isInitialized) && {_allOccurrencesReady}) || {diag_tickTime >= _deadline}
};
private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
private _counts = createHashMap;
private _success = true;
private _setupSettings = [];
private _selectedId = "";
private _audioSourceClasses = ["ACRE_PRC148", "ACRE_PRC152", "ACRE_SEM52SL", "ACRE_SEM70"];
{
    private _radioId = _x;
    private _base = [_radioId] call acre_api_fnc_getBaseRadio;
    private _ordinal = (_counts getOrDefault [_base, 0]) + 1;
    _counts set [_base, _ordinal];
    private _savedIndex = _savedRadios findIf {(_x select 0) == _base && {(_x select 1) == _ordinal}};
    if (_savedIndex >= 0) then {
        private _saved = _savedRadios select _savedIndex;
        private _mode = _saved select 2;
        private _setting = _saved select 3;
        private _spatial = _saved select 4;
        private _volume = _saved select 5;
        private _audioSource = _saved select 6;
        if (toUpper _mode == "FREQUENCY") then {
            _setupSettings pushBack [_base, _ordinal, _setting];
        } else {
            if (toUpper _mode == "BLOCK_CHANNEL") then {
                _setupSettings pushBack [_base, _ordinal, [_setting select 1, _setting select 0]];
            } else {
                if !([_radioId, _setting] call acre_api_fnc_setRadioChannel) then {_success = false};
                if (([_radioId] call acre_api_fnc_getRadioChannel) != _setting) then {_success = false};
            };
        };
        if !([_radioId, _spatial] call acre_api_fnc_setRadioSpatial) then {_success = false};
        if (_volume >= 0 && {!([_radioId, _volume] call acre_api_fnc_setRadioVolume)}) then {_success = false};
        if (_audioSource != "" && {toUpper _base in _audioSourceClasses} && {!([_radioId, _audioSource] call acre_api_fnc_setRadioAudioSource)}) then {_success = false};
        if (count _savedSelected == 2 && {_base == (_savedSelected select 0)} && {_ordinal == (_savedSelected select 1)}) then {_selectedId = _radioId};
    };
} forEach _radios;
{
    private _base = _x select 0;
    private _ordinal = _x select 1;
    private _matchingCount = {_base == ([_x] call acre_api_fnc_getBaseRadio)} count _radios;
    if (_matchingCount < _ordinal) then {_success = false};
} forEach _savedRadios;
if (count _setupSettings > 0) then {
    private _broadRadios = [] call acre_api_fnc_getCurrentRadioList;
    private _frequencyClasses = _setupSettings apply {toUpper (_x select 0)};
    private _safeFrequencyOrder = true;
    {
        private _base = _x;
        private _broadMatching = _broadRadios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
        private _carriedMatching = _radios select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
        if !(_broadMatching isEqualTo _carriedMatching) then {_safeFrequencyOrder = false};
    } forEach (_frequencyClasses arrayIntersect _frequencyClasses);
    _setupSettings sort true;
    private _setupRequest = _setupSettings apply {[_x select 0, _x select 2]};
    if (!_safeFrequencyOrder || {isNil "acre_api_fnc_setupRadios"} || {!(_setupRequest call acre_api_fnc_setupRadios)}) then {_success = false};
};
if (_selectedId != "" && {!([_selectedId] call acre_api_fnc_setCurrentRadio)}) then {_success = false};
if (_success) then {missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", _generation]};
_success
