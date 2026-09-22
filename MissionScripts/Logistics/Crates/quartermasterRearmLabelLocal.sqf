/*
 * Author: WaldoTheWarfighter
 * Purpose: Labels an otherwise empty ACE rearm-source box with a readable object action.
 * Locality / Authority: Runs on interface clients; it never changes ACE rearm supply.
 * Repeat / JIP: One local action per object; the server broadcasts it with an object JIP key.
 * Arguments: rearm box <OBJECT>; supply count <NUMBER>.
 * Return Value: <BOOL> action installed or already present.
 * Current caller: Waldo_fnc_QuartermasterExtendedSpawn.
 * Example: [rearmBox, 1200] call Waldo_fnc_QuartermasterRearmLabelLocal;
 */
params [["_box", objNull, [objNull]], ["_supply", 1200, [0]]];
if (!hasInterface || {isNull _box}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if !(isNil {_box getVariable "Waldo_QM_RearmInfoActionLocal"}) exitWith {true};
private _actionId = _box addAction [
    "<t color='#79C7FF'>ACE Rearm Source</t>",
    {
        params ["_box", "_player", "_actionId", "_supply"];
        ["QUARTERMASTER", format ["This empty box contains %1 finite ACE rearm supply units. Use ACE Rearm on a nearby vehicle or static weapon.", _supply],
            "INFO", format ["QM_REARM_%1", netId _box], 6] call Waldo_fnc_FeatureNotifyLocal;
    }, _supply, 1.5, true, false, "", "_this distance _target < 5", 5
];
_box setVariable ["Waldo_QM_RearmInfoActionLocal", _actionId];
true
