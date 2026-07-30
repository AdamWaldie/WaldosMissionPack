/*
 * Author: WaldoTheWarfighter
 * Advances one gunship state machine and enforces fuel, damage, ammunition and service policy.
 *
 * One scheduled server loop is spawned per registered gunship by Waldo_fnc_GunshipRegister. It
 * restores controllers by UID after respawn, drives transit/RTB/service state, uses synchronized
 * serverTime for service progress and initiates automatic service when configured limits are met.
 *
 * Arguments:
 * 0: system ID <STRING>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["SPECTRE_1"] spawn Waldo_fnc_GunshipMonitor;
 */

params ["_id"];
if !(isServer) exitWith {};
while {true} do {
    private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
    if !(_id in keys _registry) exitWith {};
    private _state = _registry get _id;
    if !(_state getOrDefault ["active", false]) exitWith {};
    private _aircraft = _state getOrDefault ["aircraft", objNull];
    private _config = _state get "config";
    if (isNull _aircraft || {!alive _aircraft}) exitWith {
        [_id, "DESTROYED", format ["%1 has been lost.", _config getOrDefault ["callsign", _id]]] call Waldo_fnc_GunshipSetState;
    };

    private _controller = _state getOrDefault ["controller", objNull];
    private _controllerUID = _state getOrDefault ["controllerUID", ""];
    if (!isNull _controller && {isPlayer _controller} && {_controllerUID == ""}) then {
        _controllerUID = getPlayerUID _controller;
        _state set ["controllerUID", _controllerUID];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
    };
    if ((isNull _controller || {!alive _controller}) && {_controllerUID != ""} && {_config getOrDefault ["retainControllerOnRespawn", true]}) then {
        private _replacementIndex = allPlayers findIf {alive _x && {getPlayerUID _x == _controllerUID}};
        if (_replacementIndex >= 0) then {
            _controller = allPlayers select _replacementIndex;
            _state set ["controller", _controller];
            _registry set [_id, _state];
            missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
            [] call Waldo_fnc_GunshipPublishState;
        };
    };
    if ((isNull _controller || {!alive _controller}) && {!(_config getOrDefault ["retainControllerOnRespawn", true])} && {!isNull _controller || {_controllerUID != ""}}) then {
        _state set ["controller", objNull];
        _state set ["controllerUID", ""];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
        [] call Waldo_fnc_GunshipPublishState;
    };

    private _status = _state getOrDefault ["status", "UNAVAILABLE"];
    private _orbit = _state getOrDefault ["orbit", []];
    private _home = _config getOrDefault ["home", []];
    private _arrivalTolerance = (_config getOrDefault ["arrivalTolerance", (_config getOrDefault ["radius", 1500]) + 150]) max 100;
    if (_status == "TRANSIT" && {count _orbit >= 2} && {_aircraft distance2D _orbit <= _arrivalTolerance}) then {
        [_id, "ON_STATION", format ["%1 is on station and available.", _config getOrDefault ["callsign", _id]]] call Waldo_fnc_GunshipSetState;
        _status = "ON_STATION";
    };
    if (_status == "RTB" && {count _home >= 2} && {_aircraft distance2D _home <= _arrivalTolerance}) then {
        private _serviceDuration = ((_config getOrDefault ["serviceDuration", missionNamespace getVariable ["Waldo_Gunship_DefaultServiceDuration", 900]]) max 0);
        _state set ["serviceCompleteAt", serverTime + _serviceDuration];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
        [_id, "SERVICING", format ["%1 is servicing for %2 seconds. Weapon control and tasking are unavailable.", _config getOrDefault ["callsign", _id], round _serviceDuration]] call Waldo_fnc_GunshipSetState;
        _status = "SERVICING";
    };
    if (_status == "SERVICING" && {serverTime >= (_state getOrDefault ["serviceCompleteAt", 1e10])}) then {
        private _maximumCycles = _config getOrDefault ["maximumServiceCycles", -1];
        private _cycles = _state getOrDefault ["serviceCycles", 0];
        if (_maximumCycles >= 0 && {_cycles >= _maximumCycles}) then {
            [_id, "UNAVAILABLE", format ["%1 has exhausted its service allocation.", _config getOrDefault ["callsign", _id]]] call Waldo_fnc_GunshipSetState;
        } else {
            [_aircraft, _config] call Waldo_fnc_GunshipServiceAircraft;
            _state set ["serviceCycles", _cycles + 1];
            _registry set [_id, _state];
            missionNamespace setVariable ["Waldo_Gunship_Registry", _registry];
            [_id, _orbit, "TRANSIT"] call Waldo_fnc_GunshipSetOrbit;
        };
    };

    if (_status in ["ON_STATION", "CONTROLLED", "TRANSIT"]) then {
        private _fuelLow = fuel _aircraft <= (_config getOrDefault ["minimumFuel", 0.25]);
        private _damageHigh = damage _aircraft >= (_config getOrDefault ["maximumDamage", 0.65]);
        private _ammoEntries = magazinesAllTurrets _aircraft;
        private _ammoRemaining = 0;
        {_ammoRemaining = _ammoRemaining + (_x param [2, 0])} forEach _ammoEntries;
        private _ammoLow = (_config getOrDefault ["returnWhenOutOfAmmo", true]) && {_ammoRemaining <= 0};
        if (_fuelLow || {_damageHigh} || {_ammoLow}) then {
            [_id, "SERVICE", [] , objNull] call Waldo_fnc_GunshipServerHandle;
        };
    };
    sleep ((missionNamespace getVariable ["Waldo_Gunship_MonitorInterval", 2]) max 0.5);
};
