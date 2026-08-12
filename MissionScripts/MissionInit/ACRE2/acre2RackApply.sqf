/*
 * Author: WaldoTheWarfighter
 * Server-side worker for Waldo_fnc_ACRE2RackSetup: waits (bounded) for ACRE2 to finish initialising
 * a vehicle's radio racks, then applies the requested preset/per-rack mount and channel/frequency
 * assignments. Reuses Waldo_fnc_ACRE2GetRadioProfiles for capability lookups and the same
 * channel/frequency-mode application logic already proven for carried radios
 * (acre2ApplyPlayerPlan.sqf), rather than a separate implementation.
 *
 * Rack readiness is genuinely asynchronous in ACRE2 and requires a connected player - ACRE2
 * delegates the actual rack-initialisation and radio-mount work to a player's machine internally
 * (see acre_api_fnc_addRackToVehicle/mountRackRadio). This worker waits in two deliberately separate,
 * differently-bounded phases rather than one shared timeout: first (up to 300s) for any player to be
 * connected at all - a mission-hosting condition outside WMP's or ACRE2's control, since a dedicated
 * server can auto-start its mission (and fire this object's Eden init field) before its lobby has
 * filled - then (up to 30s) for ACRE2 itself to report the vehicle's racks initialised. The second
 * phase is short because acre_api_fnc_initVehicleRacks is called explicitly here rather than assumed
 * - per ACRE2's own source comment it "must be executed" and is not triggered automatically on
 * vehicle creation; without calling it ourselves, ACRE2 only appears to trigger it once a player
 * actually enters/approaches the vehicle, which can take far longer than any fixed wait or never
 * happen at all for a parked, uncrewed vehicle. A rack's mounted radio can likewise sit as an
 * un-initialised base classname for a period before ACRE2 issues its real unique ID
 * (acre_api_fnc_getMountedRackRadio returns the bare base class until then) - readiness is detected
 * by comparing the plain and base-class-forced reads of that same call, exactly mirroring how
 * carried-radio code already distinguishes a resolved unique ID from a base class via
 * acre_api_fnc_getBaseRadio.
 *
 * ACRE2's per-rack radio STATE (acre_api_fnc_getMountedRackRadio, acre_api_fnc_isRackRadioRemovable,
 * acre_api_fnc_setRadioChannel/getRadioChannel, acre_api_fnc_getCurrentRadioList) is tracked locally
 * on whichever connected client ACRE2 itself delegated the rack's mount/init work to - it is not
 * synced to the server (confirmed against ACRE2's own source: acre_sys_rack_fnc_getState reads a
 * local acre_sys_data_radioData store, not a broadcast variable). Calling these functions directly
 * from the server therefore only works by coincidence on a listen server, where the host process is
 * simultaneously the server and a client and so shares that "local" state; on a genuine dedicated
 * server it throws "[ACRE] (api) WARNING: Non existant rack ID provided" followed by a script error,
 * confirmed live. Every read/write against this state is therefore routed through
 * Waldo_fnc_ACRE2RackClientAction, broadcast to every connected client so whichever one actually holds
 * the state can answer - this file no longer calls those specific ACRE2 functions directly. Only the
 * genuinely server-side ACRE2 calls (acre_api_fnc_setVehicleRacksPreset, acre_api_fnc_initVehicleRacks,
 * acre_api_fnc_mountRackRadio, acre_api_fnc_removeRackFromVehicle, acre_api_fnc_areVehicleRacksInitialized,
 * acre_api_fnc_getVehicleRacks) remain here, matching ACRE2's own "Must be executed on the server"
 * documentation for the write-triggering ones and the vehicle-attached (broadcast) storage the last two
 * read from.
 *
 * FREQUENCY-mode rack radios (PRC-77/SEM70-family) are the one path here that has not been proven
 * against a live engine: no public per-radio frequency-write API exists (the same limitation
 * documented in acre2ApplyPlayerPlan.sqf), so this reuses the batched, ordinal acre_api_fnc_setupRadios
 * call - but computes that radio's occurrence directly from its own already-known unique ID's
 * position in the broad current-radio list, rather than the ambiguous "which physical radio is this"
 * guess the carried-radio path has to guard against when several same-class radios of unknown
 * identity are visible at once. Treat this specific path as the priority item to verify manually.
 *
 * Locality and authority:
 * Server-only, spawned. Clears Waldo_ACRE2_RackSetupRunning and publishes
 * Waldo_ACRE2_RackSetupComplete / Waldo_ACRE2_RackSetupResult on the vehicle when finished, so a
 * later Waldo_fnc_ACRE2RackSetup call (a genuinely different config) can run.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Config <HASHMAP> - see Waldo_fnc_ACRE2RackSetup for the full shape.
 *
 * Return Value: Boolean - true when every requested assignment applied without a reported problem.
 * Example: [_vehicle, _configHash] spawn Waldo_fnc_ACRE2RackApply;
 * Current caller: Waldo_fnc_ACRE2RackSetup.
 */

params [["_vehicle", objNull, [objNull]], ["_config", createHashMap, [createHashMap]]];

private _finish = {
    params ["_success", "_applied", "_total", "_problems"];
    _vehicle setVariable ["Waldo_ACRE2_RackSetupRunning", false, true];
    _vehicle setVariable ["Waldo_ACRE2_RackSetupComplete", true, true];
    _vehicle setVariable ["Waldo_ACRE2_RackSetupResult", [_applied, _total, _problems], true];
    diag_log format ["[WMP ACRE RACK] Vehicle %1 rack setup finished: applied=%2/%3 problems=%4.", _vehicle, _applied, _total, _problems];
    _success
};

if !(isServer) exitWith {[false, 0, 0, ["not-server"]] call _finish};
if (isNull _vehicle) exitWith {[false, 0, 0, ["null-vehicle"]] call _finish};

// ACRE2 delegates the actual rack/radio work to a connected player's machine, so on a dedicated
// server that auto-starts its mission before anyone has joined, calling into ACRE2 immediately from
// an object's own Eden init field can race a lobby that is still filling. This wait is deliberately
// separate from - and much longer than - the 30s ACRE2-readiness wait below: "is any player
// connected yet" is a mission-hosting condition outside WMP's or ACRE2's control and can legitimately
// take minutes, while "did ACRE2 finish initialising once a player exists" is normally a few seconds
// now that this function triggers it explicitly instead of waiting on ACRE2's own trigger.
private _playerDeadline = time + 300;
waitUntil {
    sleep 1;
    (count allPlayers > 0) || {time > _playerDeadline}
};
if (count allPlayers == 0) exitWith {
    [false, 0, 0, ["no-player-connected (nobody joined the server within 300s of this call)"]] call _finish
};

// Broadcasts one rack-state read/write to every connected human player and returns the first
// reported result, since we cannot know in advance which client ACRE2 delegated this rack's live
// state to - see the file header. Targets allPlayers explicitly rather than remoteExec mode 0 (every
// machine) or -2 (every client) - a headless client can never hold ACRE2 rack/radio state (no
// interface, no real ACRE2 session) and allPlayers already excludes them by construction (see
// Waldo_fnc_HeadlessRegisterClient's own identical assumption), so sending this at every connected
// headless client every 0.5s for the whole wait window is pure unnecessary network/script overhead on
// a mission running several of them, with zero chance of ever getting a useful answer back. Re-sends
// every 0.5s so a client that connects/becomes ready mid-wait, or a rack whose state only becomes
// readable partway through (e.g. GET_ID before ACRE2 has issued a unique ID yet), is still caught
// within the timeout. Returns nil on timeout.
private _clientRackQuery = {
    params ["_rackId", "_action", "_args", "_timeoutSeconds"];
    private _requestId = format ["Waldo_ACRE2_RackQuery_%1_%2_%3", _rackId, _action, diag_tickTime];
    private _deadline = time + _timeoutSeconds;
    private _gotResult = false;
    waitUntil {
        sleep 0.5;
        private _targets = allPlayers apply {owner _x};
        if (count _targets > 0) then {
            [_rackId, _action, _args, _requestId] remoteExecCall ["Waldo_fnc_ACRE2RackClientAction", _targets];
        };
        _gotResult = !(isNil {missionNamespace getVariable _requestId});
        _gotResult || {time > _deadline}
    };
    private _result = if (_gotResult) then {missionNamespace getVariable _requestId} else {nil};
    missionNamespace setVariable [_requestId, nil];
    _result
};

private _preset = _config getOrDefault ["preset", ""];
if (_preset != "") then {
    [_vehicle, _preset] call acre_api_fnc_setVehicleRacksPreset;
};

// acre_api_fnc_initVehicleRacks must be called explicitly - ACRE2 does not initialise a vehicle's
// config-defined racks on vehicle creation or on a fixed timer of its own; per ACRE2's own source
// comment, it is driven by ACRE2's own internal triggers (observed in practice to depend on a player
// actually entering/approaching the vehicle, which can take much longer than any fixed wait, or never
// happen at all for a parked, uncrewed vehicle nobody gets in). Requesting it ourselves here removes
// that dependency instead of passively hoping ACRE2 gets to it before the wait below times out. Safe
// to call even if some other path already triggered it - the function itself no-ops once
// areVehicleRacksInitialized is already true.
if !([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) then {
    [_vehicle] call acre_api_fnc_initVehicleRacks;
};

private _deadline = time + 30;
waitUntil {
    sleep 0.5;
    ([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) || {time > _deadline}
};
if !([_vehicle] call acre_api_fnc_areVehicleRacksInitialized) exitWith {
    [false, 0, 0, ["racks-not-initialised (no connected player, or ACRE2 setup failed within 30s)"]] call _finish
};

private _racks = [_vehicle] call acre_api_fnc_getVehicleRacks;
if (_racks isEqualTo []) exitWith {[true, 0, 0, ["no-racks-on-vehicle"]] call _finish};

private _profiles = [] call Waldo_fnc_ACRE2GetRadioProfiles;
private _profileFor = {
    params ["_base"];
    private _i = _profiles findIf {toUpper (_x select 0) == toUpper _base};
    if (_i < 0) then {[]} else {_profiles select _i}
};

// Waits (bounded) for a rack's mounted radio to have a real unique ID rather than a bare base class,
// via _clientRackQuery (see file header for why this cannot be read directly on the server).
// acre_api_fnc_mountRackRadio is itself asynchronous - like acre_api_fnc_initVehicleRacks, it fires a
// CBA targeted event to a connected player's machine and returns immediately, without waiting for
// that event to actually land and process. On a mission with a lot of other systems competing for
// that same player's machine (many CBA event handlers, other spawned workers), the event can
// genuinely take longer than a short window to be handled - confirmed live against a real, heavily
// loaded audit mission where this consistently hit a tighter 20s budget on a rack that had just been
// requested to mount a radio. 45s gives real headroom without materially changing the worst case for
// a rack that is never going to receive an ID at all (an intentionally-untouched empty rack, or one
// where the mount was refused - see the not-removable/no-mount branches above, which already return
// before reaching this wait).
private _waitForRackRadioId = {
    params ["_rackId"];
    private _result = [_rackId, "GET_ID", [], 45] call _clientRackQuery;
    if (isNil "_result") then {""} else {_result}
};

private _applyChannel = {
    params ["_radioId", "_base", "_profile", "_setting"];
    if (_setting isEqualType 0 && {_setting < 0}) exitWith {true}; // sentinel: no channel/frequency requested
    private _mode = toUpper (_profile select 1);
    switch (_mode) do {
        case "BLOCK_CHANNEL"; case "CHANNEL": {
            private _channel = if (_setting isEqualType []) then {(((_setting select 0) - 1) * 16) + (_setting select 1)} else {_setting};
            private _result = [_radioId, "SET_CHANNEL", [_radioId, _channel], 15] call _clientRackQuery;
            if (isNil "_result") exitWith {
                diag_log format ["[WMP ACRE RACK] %1 channel %2 write/read-back timed out - no connected client reported a result.", _radioId, _channel];
                false
            };
            _result params [["_set", false], ["_verified", false]];
            if (!_set || {!_verified}) then {diag_log format ["[WMP ACRE RACK] %1 channel %2 write/read-back failed.", _radioId, _channel];};
            _set && _verified
        };
        case "FREQUENCY": {
            private _divisor = (_profile select 4) select 3;
            private _whole = floor _setting;
            private _freqSetting = [_whole, round ((_setting - _whole) * _divisor)];
            private _result = [_radioId, "SET_FREQUENCY", [_radioId, _base, _freqSetting], 15] call _clientRackQuery;
            if (isNil "_result") exitWith {
                diag_log format ["[WMP ACRE RACK] Could not resolve a safe occurrence for frequency rack radio %1 - no connected client reported a result.", _radioId];
                false
            };
            diag_log format ["[WMP ACRE RACK] %1 frequency %2 requested via setupRadios (accepted=%3, unverified - no public frequency read-back API).", _radioId, _setting, _result];
            _result
        };
        default {
            diag_log format ["[WMP ACRE RACK] %1 has no recognised WMP radio profile mode; channel/frequency not applied.", _radioId];
            false
        };
    };
};

private _applyOne = {
    params ["_rackId", "_setting", "_mountClass"];
    private _currentBaseResult = [_rackId, "GET_BASE", [], 10] call _clientRackQuery;
    private _currentBase = if (isNil "_currentBaseResult") then {""} else {_currentBaseResult};
    private _isRemovable = {
        private _result = [_rackId, "IS_REMOVABLE", [], 10] call _clientRackQuery;
        if (isNil "_result") then {false} else {_result}
    };

    if (_mountClass == "REMOVE_RACK") exitWith {
        if (_currentBase != "" && {!(call _isRemovable)}) exitWith {
            diag_log format ["[WMP ACRE RACK] Rack %1 radio is not removable; REMOVE_RACK refused.", _rackId];
            false
        };
        [_vehicle, _rackId] call acre_api_fnc_removeRackFromVehicle
    };

    if (_mountClass != "" && {toUpper _mountClass != toUpper _currentBase}) then {
        if (_currentBase != "" && {!(call _isRemovable)}) exitWith {
            diag_log format ["[WMP ACRE RACK] Rack %1 currently holds %2, which is not removable; requested replacement %3 refused.", _rackId, _currentBase, _mountClass];
            false
        };
        [_rackId, _mountClass] call acre_api_fnc_mountRackRadio;
    };

    if (_setting isEqualType 0 && {_setting < 0} && {_mountClass == "" || {toUpper _mountClass == toUpper _currentBase}}) exitWith {true}; // nothing further requested and nothing changed

    private _radioId = [_rackId] call _waitForRackRadioId;
    if (_radioId == "") exitWith {
        diag_log format ["[WMP ACRE RACK] Rack %1 on vehicle %2 has not produced a unique radio ID within 45s (empty rack, ACRE2 has not finished issuing it yet, or no connected client currently has visibility into this rack's state).", _rackId, _vehicle];
        false
    };
    private _base = toUpper ([_radioId] call acre_api_fnc_getBaseRadio);
    private _profile = [_base] call _profileFor;
    if (count _profile == 0) exitWith {
        diag_log format ["[WMP ACRE RACK] Rack radio %1 (%2) is not a recognised WMP radio profile; channel/frequency not applied.", _radioId, _base];
        false
    };
    [_radioId, _base, _profile, _setting] call _applyChannel
};

private _assignments = _config getOrDefault ["assignments", []];
private _applied = 0;
private _problems = [];
{
    _x params [["_selector", 0], ["_setting", -1], ["_mountClass", ""]];
    if (_selector isEqualType "" && {toUpper _selector == "ALL"}) then {
        {
            if ([_x, _setting, _mountClass] call _applyOne) then {_applied = _applied + 1;} else {_problems pushBack _x;};
        } forEach _racks;
    } else {
        if (_selector isEqualType 0 && {_selector >= 0} && {_selector < count _racks}) then {
            private _rackId = _racks select _selector;
            if ([_rackId, _setting, _mountClass] call _applyOne) then {_applied = _applied + 1;} else {_problems pushBack _rackId;};
        } else {
            diag_log format ["[WMP ACRE RACK] Rack index %1 out of range for vehicle %2 (%3 rack(s)).", _selector, _vehicle, count _racks];
            _problems pushBack format ["invalid-index-%1", _selector];
        };
    };
} forEach _assignments;

[_problems isEqualTo [], _applied, count _racks, _problems] call _finish
