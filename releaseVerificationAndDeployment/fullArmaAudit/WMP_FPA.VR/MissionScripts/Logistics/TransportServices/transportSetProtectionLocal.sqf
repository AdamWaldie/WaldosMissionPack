/*
 * Author: WaldoTheWarfighter, Val
 * Applies or releases optional invulnerability for a registered transport and only its original
 * AI service crew. The pre-feature damage permission is restored when protection is released;
 * passenger players are deliberately excluded.
 * Locality and authority: may be sent to every machine, but allowDamage is applied only to local
 * objects. The server monitor repeats this one-shot call after a vehicle or AI locality change.
 *
 * Arguments:
 * 0: registered transport <OBJECT>; 1: protection enabled <BOOL> (default false).
 *
 * Return Value: <BOOL> - true when the local protection pass completed.
 *
 * Example: [this, true] call Waldo_fnc_TransportSetProtectionLocal;
 * Current callers: Waldo_fnc_TransportRegister and locality-change handling in the server monitor.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]], ["_enabled", false, [true]]];
if (isNull _vehicle) exitWith {false};
private _apply = {
    params ["_object", "_enabled"];
    if (isNull _object || {!local _object}) exitWith {};
    if (_enabled) then {
        if (isNil {_object getVariable "Waldo_TransportService_DamageAllowedBaseline"}) then {
            _object setVariable ["Waldo_TransportService_DamageAllowedBaseline", isDamageAllowed _object, true];
        };
        _object setDamage 0;
        _object allowDamage false;
    } else {
        private _baseline = _object getVariable ["Waldo_TransportService_DamageAllowedBaseline", -1];
        if (_baseline isEqualType true) then {_object allowDamage _baseline};
        _object setVariable ["Waldo_TransportService_DamageAllowedBaseline", nil, true];
    };
};
[_vehicle, _enabled] call _apply;
{
    [_x, _enabled] call _apply;
} forEach (_vehicle getVariable ["Waldo_TransportService_BaseCrew", []]);
true
