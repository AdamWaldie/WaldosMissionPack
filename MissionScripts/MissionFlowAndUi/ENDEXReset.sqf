/*
 * Author: WaldoTheWarfighter
 * Clears the authoritative ENDEX freeze for rehearsals, audits, and explicit
 * mission-maker recovery. Normal missions may simply leave ENDEX active.
 *
 * Arguments:
 * 0: Apply locally <BOOL> (internal, default: false)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_ENDEXReset;
 */
params [["_applyLocal", false, [false]]];

if (!_applyLocal) exitWith {
    if (!isServer) then {
        [] remoteExecCall ["Waldo_fnc_ENDEXReset", 2];
    } else {
        if !(missionNamespace getVariable ["Waldo_ENDEX_Active", false]) exitWith {
            diag_log "[WMP ENDEX] reset ignored: state already INACTIVE";
        };
        missionNamespace setVariable ["Waldo_ENDEX_Active", false, true];
        [true] remoteExecCall ["Waldo_fnc_ENDEXReset", -2];
        if (hasInterface) then {[true] call Waldo_fnc_ENDEXReset;};
        diag_log "[WMP ENDEX] state=INACTIVE weapons=RELEASED damage=ENABLED";
    };
};
if (!hasInterface) exitWith {};

["ENDEX"] call Waldo_fnc_DismissUiNotification;

if !(isNil "Waldo_PreventWeaponsFireEventHandler") then {
    player removeEventHandler ["Fired", Waldo_PreventWeaponsFireEventHandler];
    Waldo_PreventWeaponsFireEventHandler = nil;
};
private _vehicle = player getVariable ["Waldo_PreventVehicleFire", objNull];
if (!isNull _vehicle) then {
    if !(isNil "Waldo_PreventVehicleFireEventHandler") then {
        _vehicle removeEventHandler ["Fired", Waldo_PreventVehicleFireEventHandler];
    };
    if !(missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
        _vehicle allowDamage (_vehicle getVariable ["Waldo_WMPProtection_DamageBaseline", true]);
        _vehicle setVariable ["Waldo_WMPProtection_DamageBaseline", nil];
    };
};
Waldo_PreventVehicleFireEventHandler = nil;
player setVariable ["Waldo_PreventVehicleFire", nil];
missionNamespace setVariable ["Waldo_ENDEX_VehicleDamageWasAllowed", nil];

if !(missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    player allowDamage (player getVariable ["Waldo_WMPProtection_DamageBaseline", true]);
    player setVariable ["Waldo_WMPProtection_DamageBaseline", nil];
};
["ENDEX"] call Waldo_fnc_ProtectionReleaseSafety;
missionNamespace setVariable ["Waldo_ENDEX_PlayerDamageWasAllowed", nil];

private _message = parseText "<t color='#6CE5A8' size='1.5' shadow='1' align='center'>EXERCISE RESET</t><br/><t align='center'>ENDEX protection removed.</t>";
[_message, 8] call Waldo_fnc_SafeStartNotice;
