/*
 * Author: WaldoTheWarfighter
 * Restores saved carried-radio state after ACRE replaces base classes with new unique IDs. It
 * restores channel or WMP-known frequency, ear, volume, supported audio source and selected radio while leaving
 * alternate PTT and speaker mode untouched. The wait is bounded and successful restoration suppresses
 * baseline mission-plan retuning for the same loadout generation. The same function serves ordinary
 * respawn snapshots and optional INIDBI2 persistence snapshots.
 * If ACRE fails to recreate one saved carried radio during that bounded wait, the function repairs
 * only the missing base-radio occurrence (never an `_ID_n` classname), then gives ACRE one final
 * bounded conversion window. This protects ordinary respawn and persistence from silently losing a
 * PRC-152/343/etc. without repeatedly changing radios during normal play.
 * Locality and authority: spawn on the player's interface client after its filtered loadout is
 * restored. The bounded waits, inventory repair and all radio mutations are local to that player.
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
private _allSavedOccurrencesReady = {
    private _list = [] call Waldo_fnc_ACRE2GetOrderedRadios;
    {
        private _base = _x select 0;
        private _ordinal = _x select 1;
        ({toUpper ([_x] call acre_api_fnc_getBaseRadio) == toUpper _base} count _list) >= _ordinal
    } count _savedRadios == count _savedRadios
};
waitUntil {
    uiSleep 0.1;
    (([] call acre_api_fnc_isInitialized) && {call _allSavedOccurrencesReady}) || {diag_tickTime >= _deadline}
};
// ACRE occasionally finishes initialization without replacing every base radio restored by the
// respawn loadout. Count physical inventory as well as unique IDs before repairing so a slow base
// radio is never duplicated. Only a genuine shortage receives another base-class item.
if !(call _allSavedOccurrencesReady) then {
    private _expectedCounts = createHashMap;
    {
        private _base = toUpper (_x select 0);
        _expectedCounts set [_base, (_expectedCounts getOrDefault [_base, 0]) max (_x select 1)];
    } forEach _savedRadios;
    private _inventory = (items player) + (assignedItems player);
    private _repairs = [];
    {
        private _baseUpper = _x;
        private _base = _baseUpper;
        private _configIndex = _savedRadios findIf {toUpper (_x select 0) == _baseUpper};
        if (_configIndex >= 0) then {_base = (_savedRadios select _configIndex) select 0};
        private _uniquePrefix = _baseUpper + "_ID_";
        private _present = {
            private _itemUpper = toUpper _x;
            _itemUpper == _baseUpper || {_itemUpper find _uniquePrefix == 0}
        } count _inventory;
        private _missing = (_expectedCounts get _baseUpper) - _present;
        for "_missingIndex" from 1 to (_missing max 0) do {
            if (player canAdd _base) then {
                player addItem _base;
                _repairs pushBack _base;
            } else {
                diag_log format ["[WMP ACRE] Respawn radio repair could not add %1: player inventory has no capacity.", _base];
            };
        };
    } forEach keys _expectedCounts;
    diag_log format [
        "[WMP ACRE] Respawn radio readiness retry generation=%1 expected=%2 repairedBaseClasses=%3 inventory=%4.",
        _generation, _expectedCounts, _repairs, _inventory
    ];
    private _repairDeadline = diag_tickTime + 10;
    waitUntil {
        uiSleep 0.1;
        (([] call acre_api_fnc_isInitialized) && {call _allSavedOccurrencesReady}) || {diag_tickTime >= _repairDeadline}
    };
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
                // PRC-343 state is saved as beginner-facing [block, channel], while ACRE's direct
                // channel API exposes one absolute 1-256 position. Restore the actual unique ID
                // synchronously so success cannot be reported before ACRE's asynchronous
                // setupRadios helper has done any work.
                private _absoluteChannel = (((_setting select 0) - 1) * 16) + (_setting select 1);
                if !([_radioId, _absoluteChannel] call acre_api_fnc_setRadioChannel) then {_success = false};
                if (([_radioId] call acre_api_fnc_getRadioChannel) != _absoluteChannel) then {_success = false};
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
if (_success) then {
    missionNamespace setVariable ["Waldo_ACRE2_RestoredRadioGeneration", _generation];
} else {
    diag_log format ["[WMP ACRE] Saved radio restoration failed generation=%1 saved=%2 actual=%3.", _generation, _savedRadios, _radios];
};
_success
