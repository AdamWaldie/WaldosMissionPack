/*
 * Author: WaldoTheWarfighter
 * Resolves a newly networked paradrop aircraft by net ID before installing its local jump actions.
 * Dynamic aircraft can be created and configured by the server before a remote client has received
 * the object. Sending the object itself at that moment becomes objNull on that client and silently
 * loses every action. This local wrapper accepts only serialisable data, waits up to 15 seconds for
 * objectFromNetId, then delegates to the repeat-safe aircraft configurator and reconciles the
 * requested invincibility state. The server attaches this combined replay to the aircraft object,
 * so Arma removes it automatically from the JIP queue when the aircraft is deleted.
 *
 * Locality, authority and repeat/JIP behaviour:
 * Run on every machine. Interface clients reconcile local hold actions and ACE interactions; every
 * machine reconciles the damage handler so the current server, headless-client or player owner can
 * apply allowDamage. The server remains authoritative for the aircraft, route and published
 * configuration. Repeated calls are safe because both local reconcilers remove obsolete handlers.
 *
 * Arguments:
 * 0: aircraft network ID <STRING>
 * 1: configuration pairs <ARRAY> - serialised `[key, value]` rows accepted by
 *    createHashMapFromArray; contains the resolved jump envelope, chute classes and door rule.
 * 2: aircraft invincible <BOOL> (default false) - locally reconciled on the current object owner.
 *
 * Return Value:
 * Boolean - true when a local resolution attempt was scheduled; false without an interface or ID.
 *
 * Current callers:
 * Waldo_fnc_ParadropCreateDropZone and Waldo_fnc_ParadropQuickFlightSetup through one global,
 * aircraft-object-keyed JIP remote execution.
 *
 * Example:
 * [netId _aircraft, [["staticJumpEnabled", true], ["staticMinimumAltitude", 180]]]
 *     call Waldo_fnc_ParadropConfigureAircraftNetworkedLocal;
 */
params [
    ["_aircraftNetId", "", [""]],
    ["_configPairs", [], [[]]],
    ["_invincible", false, [false]]
];
if (_aircraftNetId == "") exitWith {false};

[_aircraftNetId, +_configPairs, _invincible] spawn {
    params ["_aircraftNetId", "_configPairs", "_invincible"];
    private _deadline = diag_tickTime + 15;
    private _aircraft = objectFromNetId _aircraftNetId;
    waitUntil {
        uiSleep 0.1;
        _aircraft = objectFromNetId _aircraftNetId;
        !isNull _aircraft || {diag_tickTime >= _deadline}
    };
    if (isNull _aircraft) exitWith {
        diag_log format ["[WMP PARADROP] Local jump-action setup timed out waiting for aircraft netId=%1 owner=%2.", _aircraftNetId, clientOwner];
    };
    private _config = createHashMapFromArray _configPairs;
    private _configured = if (hasInterface) then {
        [_aircraft, _config] call Waldo_fnc_ParadropConfigureAircraftLocal
    } else {
        true
    };
    [_aircraftNetId, _invincible] call Waldo_fnc_ParadropSetAircraftInvincibilityLocal;
    diag_log format [
        "[WMP PARADROP] Local jump-action setup aircraft=%1 netId=%2 owner=%3 configured=%4 static=%5 halo=%6.",
        typeOf _aircraft, _aircraftNetId, clientOwner, _configured,
        _config getOrDefault ["staticJumpEnabled", false],
        _config getOrDefault ["haloJumpEnabled", false]
    ];
};
true
