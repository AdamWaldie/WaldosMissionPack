/*
 * Author: Waldo
 * Apply preset selections.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _complexityKey <STRING> - complexity key (optional, default: "")
 * 1: _sideSelections <ARRAY> - side selections (optional, default: [])
 * 2: _callerName <STRING> - caller name (optional, default: "Zeus")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_complexityKey, _sideSelections, _callerName] call Waldo_fnc_EcoCore_applyPresetSelections;
 */

    params [
        ["_complexityKey", ""],
        ["_sideSelections", []],
        ["_callerName", "Zeus"]
    ];

    private _complexity = toUpper _complexityKey;
    private _messages = [];
    private _successCount = 0;
    private _requestedSelections = _sideSelections select {(toUpper (_x param [1, "NONE"])) isNotEqualTo "NONE"};

    if ((count _requestedSelections) <= 0) exitWith {[0, "Pick at least one side catalogue before setting a preset."]};

    private _genericAssigned = call Waldo_fnc_EcoCore_getPresetGenericComplexity;
    if (_genericAssigned isNotEqualTo "" && {_genericAssigned isNotEqualTo _complexity}) exitWith {
        [0, format [
            "%1 complexity is already active globally. Purge configurations before applying %2 presets.",
            _genericAssigned,
            _complexity
        ]]
    };

    if (_genericAssigned isEqualTo "") then {
        private _genericEntry = [_complexity, "GENERIC"] call Waldo_fnc_EcoCore_getPresetLibraryEntry;
        if ((count _genericEntry) <= 0) exitWith {
            [0, format ["No embedded generic preset exists for %1.", _complexity]]
        };

        private _genericRaw = [(_genericEntry param [2, ""])] call Waldo_fnc_EcoCore_trimString;
        if (_genericRaw isEqualTo "") exitWith {
            [0, format ["Generic preset file for %1 is still empty.", _complexity]]
        };

        private _genericPayload = [];
        if (isNil { _genericPayload = parseSimpleArray _genericRaw; false }) exitWith {
            [0, format ["Generic preset file for %1 is not valid import text yet.", _complexity]]
        };

        private _preparedGenericPayload = [_genericPayload, ""] call Waldo_fnc_EcoCore_preparePresetPayloadForSide;
        if ((count _preparedGenericPayload) <= 0) exitWith {
            [0, format ["Generic preset file for %1 did not contain a valid unified payload.", _complexity]]
        };

        if !([_preparedGenericPayload, _callerName, false] call Waldo_fnc_EcoCore_importUnifiedSavePayload) exitWith {
            [0, format ["Generic preset file for %1 did not contain a valid unified payload.", _complexity]]
        };

        [_complexity] call Waldo_fnc_EcoCore_setPresetGenericComplexity;
        _messages pushBack format ["Applied %1 generic preset.", _complexity];
    };

    {
        private _sideKey = toUpper (_x param [0, ""]);
        private _catalogKey = toUpper (_x param [1, "NONE"]);

        if (_catalogKey isEqualTo "NONE") then {continue;};

        private _sideLabel = switch (_sideKey) do {
            case "WEST": {"BLUFOR"};
            case "EAST": {"OPFOR"};
            case "GUER": {"INDEP"};
            default {_sideKey};
        };

        private _existing = [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignment;
        if ((count _existing) > 0) then {
            _messages pushBack format [
                "%1 already has preset %2 / %3.",
                _sideLabel,
                _existing param [0, ""],
                _existing param [1, ""]
            ];
            continue;
        };

        private _entry = [_complexity, _catalogKey] call Waldo_fnc_EcoCore_getPresetLibraryEntry;
        if ((count _entry) <= 0) then {
            _messages pushBack format ["No embedded preset exists for %1 %2.", _complexity, _catalogKey];
            continue;
        };

        private _raw = [(_entry param [2, ""])] call Waldo_fnc_EcoCore_trimString;
        if (_raw isEqualTo "") then {
            _messages pushBack format ["Preset file for %1 %2 is still empty.", _complexity, _catalogKey];
            continue;
        };

        private _payload = [];
        if (isNil { _payload = parseSimpleArray _raw; false }) then {
            _messages pushBack format ["Preset file for %1 %2 is not valid import text yet.", _complexity, _catalogKey];
            continue;
        };

        private _preparedPayload = [_payload, _sideKey] call Waldo_fnc_EcoCore_preparePresetPayloadForSide;
        if ((count _preparedPayload) <= 0) then {
            _messages pushBack format ["Preset file for %1 %2 did not contain a valid unified payload.", _complexity, _catalogKey];
            continue;
        };

        if ([_preparedPayload, _callerName, true] call Waldo_fnc_EcoCore_importUnifiedSavePayload) then {
            [_sideKey, _complexity, _catalogKey] call Waldo_fnc_EcoCore_setPresetAssignment;
            _successCount = _successCount + 1;
            _messages pushBack format ["Applied %1 %2 to %3.", _complexity, _catalogKey, _sideLabel];
        } else {
            _messages pushBack format ["Preset file for %1 %2 did not contain a valid unified payload.", _complexity, _catalogKey];
        };
    } forEach _requestedSelections;

    [_successCount, _messages joinString "\n"]
