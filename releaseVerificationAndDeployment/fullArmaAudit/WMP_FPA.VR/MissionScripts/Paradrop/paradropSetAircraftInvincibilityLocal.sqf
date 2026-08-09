/*
 * Author: WaldoTheWarfighter
 * Applies or removes WMP paradrop-aircraft invincibility on the machine that currently owns the
 * aircraft, and reapplies it whenever the aircraft changes locality.
 *
 * Locality and repeat/JIP behaviour:
 * The server publishes the requested state and invokes this function on every machine with a named
 * JIP key. Each machine installs at most one local Local event handler. Only the current aircraft
 * owner executes allowDamage; when ownership moves to a server, headless client or player client,
 * the new owner immediately reapplies the stored state. Passing false removes WMP's handler and
 * restores ordinary engine damage on the owner. This protects against normal engine damage only;
 * scripted setDamage/setHit calls can still damage the aircraft.
 *
 * Arguments:
 * 0: aircraft net ID <STRING> - network ID of the paradrop aircraft.
 * 1: invincible <BOOL> - true prevents normal damage; false restores normal damage (default false).
 *
 * Return Value:
 * Boolean - true when reconciliation was scheduled; false when the net ID is empty.
 *
 * Current callers:
 * Waldo_fnc_ParadropCreateDropZone, Waldo_fnc_ParadropQuickFlightSetup and
 * Waldo_fnc_ParadropRemoveDropZone.
 *
 * Example:
 * [netId _aircraft, true] remoteExec ["Waldo_fnc_ParadropSetAircraftInvincibilityLocal", 0,
 *     "WMP_Paradrop_Damage_DZ_ALPHA"];
 */
params [["_netId", "", [""]], ["_invincible", false, [false]]];
if (_netId == "") exitWith {false};

[_netId, _invincible] spawn {
    params ["_netId", "_invincible"];
    private _deadline = diag_tickTime + 30;
    private _aircraft = objNull;
    waitUntil {
        uiSleep 0.1;
        _aircraft = objectFromNetId _netId;
        !isNull _aircraft || {diag_tickTime >= _deadline}
    };
    if (isNull _aircraft) exitWith {};

    private _oldHandler = _aircraft getVariable ["Waldo_Paradrop_InvincibilityLocalEH", -1];
    if (_oldHandler >= 0) then {
        _aircraft removeEventHandler ["Local", _oldHandler];
        _aircraft setVariable ["Waldo_Paradrop_InvincibilityLocalEH", -1];
    };

    _aircraft setVariable ["Waldo_Paradrop_AircraftInvincibleLocal", _invincible];
    if (_invincible) then {
        private _handler = _aircraft addEventHandler ["Local", {
            params ["_entity", "_isLocal"];
            if (_isLocal) then {
                _entity allowDamage !(_entity getVariable ["Waldo_Paradrop_AircraftInvincibleLocal", false]);
            };
        }];
        _aircraft setVariable ["Waldo_Paradrop_InvincibilityLocalEH", _handler];
    };

    if (local _aircraft) then {_aircraft allowDamage !_invincible};
};
true
