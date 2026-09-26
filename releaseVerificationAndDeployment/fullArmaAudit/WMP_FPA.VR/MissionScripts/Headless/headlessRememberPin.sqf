/*
 * Author: WaldoTheWarfighter
 * Records previous WMP/ACE exclusion values before a feature pins an entity or group.
 * Locality/authority: server only. No changes to exclusion flags are made here.
 * Repeat/JIP: first baseline is retained and published until a documented release consumes it.
 * Arguments: 0: target <OBJECT or GROUP>, default objNull.
 * Return Value: Boolean, true when a baseline exists.
 * Current callers: HeadlessPinCrew and generated Paradrop jumper setup.
 * Example: [_jumpGroup] call Waldo_fnc_HeadlessRememberPin;
 */
params [["_target", objNull, [objNull, grpNull]]];
if (!isServer || {isNull _target}) exitWith {false};
if (isNil {_target getVariable "Waldo_Headless_PinBefore"}) then {
    private _before = ["Waldo_ServerOwnedFeature", "Waldo_Headless_ExcludeGroup", "acex_headless_blacklist"] apply {
        [_x, !isNil {_target getVariable _x}, _target getVariable [_x, false]]
    };
    _target setVariable ["Waldo_Headless_PinBefore", _before, true];
};
true
