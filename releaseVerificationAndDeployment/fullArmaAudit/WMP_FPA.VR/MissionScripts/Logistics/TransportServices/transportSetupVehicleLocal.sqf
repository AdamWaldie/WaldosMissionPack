/*
 * Author: WaldoTheWarfighter, Val
 * Adds a repeat-safe WMP-blue informational addAction to one registered helicopter or ground
 * taxi. The action identifies the service and explains the complete player request flow; it does
 * not reserve, move or otherwise control the vehicle.
 * Locality and authority: runs locally on every interface client, including JIP. Registration
 * remains server-owned and the public object variables are read-only here.
 *
 * Arguments:
 * 0: service vehicle <OBJECT> - a vehicle registered by Waldo_fnc_TransportRegister.
 *
 * Return Value: <BOOL> - true when the information action exists or was installed.
 *
 * Example:
 * [this] call Waldo_fnc_TransportSetupVehicleLocal;
 * Result: The vehicle gains a blue action identifying its transport role and how to use it.
 * Current caller: Waldo_fnc_TransportRegister through object-keyed JIP remote execution.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]]];
if (!hasInterface || {isNull _vehicle}) exitWith {false};

private _oldAction = _vehicle getVariable ["Waldo_TransportService_InfoActionId", -1];
if (_oldAction >= 0) then {_vehicle removeAction _oldAction};

private _type = _vehicle getVariable ["Waldo_TransportService_Type", "GROUND"];
private _name = _vehicle getVariable ["Waldo_TransportService_Name", "Transport Service"];
private _heli = _type == "HELICOPTER";
private _role = ["Ground Taxi", "Helicopter Transport"] select _heli;
private _title = format ["<t color='#79C7FF'>%1 Service: %2</t>", _role, _name];
private _actionId = _vehicle addAction [
    _title,
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_type", "_name"];
        private _heli = _type == "HELICOPTER";
        private _role = ["GROUND TAXI", "HELICOPTER TRANSPORT"] select _heli;
        private _message = format [
            "%1 is %2. Request it through ACE Self Interact > WMP Interface > Transport Services, choose a pickup point, board when it arrives, then use Select Destination from the same menu.",
            _name,
            toLowerANSI _role
        ];
        [_type, _message, "INFO"] call Waldo_fnc_TransportNotifyLocal;
    },
    [_type, _name],
    -90,
    false,
    true,
    "",
    "_target getVariable ['Waldo_TransportService_Registered', false]",
    8
];
_vehicle setVariable ["Waldo_TransportService_InfoActionId", _actionId];
true
