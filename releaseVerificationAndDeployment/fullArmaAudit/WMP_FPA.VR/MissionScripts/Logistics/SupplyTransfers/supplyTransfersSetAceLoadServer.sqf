/*
 * Author: WaldoTheWarfighter
 * Purpose: Switches ACE internal loading for one registered supply container without affecting carry.
 * Locality / Authority: Server validates the requesting player's ownership, range and crate registration.
 * Repeat / JIP: ACE setSize publishes its state and JIP action; the saved positive size stays on the object.
 * Arguments: player <OBJECT>, container <OBJECT>, allow loading <BOOL>.
 * Return Value: <BOOL> accepted. Current caller: ACE crate options in SupplyTransfersSetupLocal.
 * Example: [player, supplyCrate, false] remoteExecCall ["Waldo_fnc_SupplyTransfersSetAceLoadServer", 2];
 * Result: The crate's ACE load eligibility changes while its prior positive size is retained.
 */
params [["_player", objNull, [objNull]], ["_container", objNull, [objNull]], ["_allow", true, [true]]];
if (!isServer || {!(missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false])}
    || {isNil "ace_cargo_fnc_setSize"} || {isNull _player} || {isNull _container}
    || {!alive _player}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
if !(_container in (missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []])
    && {_player distance _container <= 5}) exitWith {false};
private _current = _container getVariable ["ace_cargo_size",
    getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "ace_cargo_size")];
if (_allow) then {
    private _saved = _container getVariable ["Waldo_SupplyTransfers_AceLoadSize", 1];
    [_container, (_saved max 1) min 1000] call ace_cargo_fnc_setSize;
} else {
    if (_current > 0) then {
        _container setVariable ["Waldo_SupplyTransfers_AceLoadSize", _current, true];
    };
    [_container, -1] call ace_cargo_fnc_setSize;
};
true
