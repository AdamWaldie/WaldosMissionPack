/*
 * Author: WaldoTheWarfighter
 * Purpose: Labels an empty Quartermaster ACE rearm source with its live supply state.
 * Locality / Authority: Interface-local addActions only; ACE owns and replicates supply.
 * Repeat / JIP: Installs once per object on every current/JIP interface. Conditions read
 *   ACE's replicated currentSupply, so depleted/unlimited labels change without polling.
 * Arguments: rearm box <OBJECT>.
 * Return Value: <BOOL> actions installed or already present.
 * Current caller: Waldo_fnc_QuartermasterExtendedSpawn via object-scoped JIP remote execution.
 * Example: [rearmBox] call Waldo_fnc_QuartermasterRearmLabelLocal;
 * Result: Players see whether the ACE rearm source is limited, depleted or unlimited.
 */
params [["_box", objNull, [objNull]]];
if (!hasInterface || {isNull _box}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if !(isNil {_box getVariable "Waldo_QM_RearmInfoActionLocal"}) exitWith {true};
private _limited = _box addAction [
    "<t color='#79C7FF'>Rearm supply: check remaining</t>",
    {
        params ["_box"];
        private _remaining = ceil (_box getVariable ["ace_rearm_currentSupply", 0]);
        ["QUARTERMASTER", format ["%1 ACE rearm supply points remain. Use ACE Rearm on a nearby vehicle or static weapon.", _remaining],
            "INFO", format ["QM_REARM_%1", netId _box], 6] call Waldo_fnc_FeatureNotifyLocal;
    }, nil, 1.5, true, false, "",
    "_this distance _target < 5 && {(missionNamespace getVariable ['ace_rearm_supply', 0]) == 1} && {(_target getVariable ['ace_rearm_currentSupply', 0]) > 0}", 5
];
private _empty = _box addAction [
    "<t color='#F0A47E'>Rearm supply exhausted</t>",
    {
        params ["_box"];
        ["QUARTERMASTER", "This Rearm Box has no ACE supply points left.", "WARNING",
            format ["QM_REARM_%1", netId _box], 6] call Waldo_fnc_FeatureNotifyLocal;
    }, nil, 1.5, true, false, "",
    "_this distance _target < 5 && {(missionNamespace getVariable ['ace_rearm_supply', 0]) == 1} && {(_target getVariable ['ace_rearm_currentSupply', 0]) <= 0}", 5
];
private _unlimited = _box addAction [
    "<t color='#79C7FF'>Rearm supply: unlimited</t>",
    {
        params ["_box"];
        ["QUARTERMASTER", "ACE Rearm is set to unlimited for this mission. This box has no finite supply balance.",
            "INFO", format ["QM_REARM_%1", netId _box], 6] call Waldo_fnc_FeatureNotifyLocal;
    }, nil, 1.5, true, false, "",
    "_this distance _target < 5 && {(missionNamespace getVariable ['ace_rearm_supply', 0]) == 0}", 5
];
_box setVariable ["Waldo_QM_RearmInfoActionLocal", [_limited, _empty, _unlimited]];
true
