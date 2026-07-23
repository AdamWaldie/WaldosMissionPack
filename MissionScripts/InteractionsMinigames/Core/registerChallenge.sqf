/*
 * Author: Waldo
 * Registers a mini game "challenge" type into the local challenge registry so it can be
 * launched by id through Waldo_fnc_MiniGameChallenge and gated onto any object through
 * Waldo_fnc_MiniGameInteraction. Registration is client-local (challenges are dialogs), and
 * re-registering the same id overwrites the previous entry.
 *
 * A challenge opener is CODE following the contract [_config, _resolve]: it presents the
 * challenge to the local player and calls [_success] on _resolve exactly once when finished.
 *
 * Arguments:
 * _id          - String - unique challenge id (e.g. "wirecut")
 * _opener      - Code   - opener following the [_config, _resolve] contract
 * _displayName - String - human-readable name (optional, default: _id)
 *
 * Return Value:
 * Boolean - true if registered
 *
 * Example:
 * ["wirecut", Waldo_fnc_MiniGameWireCut, "Wire-Cut Defusal"] call Waldo_fnc_MiniGameRegisterChallenge;
 */

params [
    ["_id", "", [""]],
    ["_opener", {}, [{}]],
    ["_displayName", "", [""]]
];

if (_id == "") exitWith { false };
if (_displayName == "") then { _displayName = _id; };

private _registry = missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []];
private _index = -1;
{
    if ((_x select 0) == _id) exitWith { _index = _forEachIndex; };
} forEach _registry;

if (_index >= 0) then {
    _registry set [_index, [_id, _opener, _displayName]];
} else {
    _registry pushBack [_id, _opener, _displayName];
};

missionNamespace setVariable ["Waldo_MG_ChallengeRegistry", _registry];
true
