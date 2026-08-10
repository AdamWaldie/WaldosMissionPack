/*
 * Author: WaldoTheWarfighter
 * Configures ACRE2 vehicle radio racks (AN/VRC-64, VRC-103, VRC-110, VRC-111, SEM90 and any
 * mission-added rack) from a single object-init call, the same idiom as Waldo_fnc_Jammer: give it a
 * vehicle and it self-forwards to the server, which owns the actual (bounded, retried) setup work.
 * WMP's existing carried-radio channel/frequency-mode logic and capability catalogue
 * (Waldo_fnc_ACRE2GetRadioProfiles) are reused rather than duplicated - a rack radio receives its
 * unique ID from the exact same ACRE2 radio-ID system a carried radio does, once mounted.
 *
 * Re-callable to change a vehicle's radio loadout later in the mission (a different config from what
 * is currently applied is not a duplicate - it runs, and replaces/removes radios as requested). Only
 * an exact repeat of the last-applied config is treated as a no-op, so an object's own Eden init
 * field firing on every machine at mission start does not repeat the work per connected client.
 *
 * Deliberately does not touch MissionScripts\MissionInit\ACRE2\acre2ApplyPlayerPlan.sqf or
 * acre2GetOrderedRadios.sqf: those intentionally filter carried-radio scanning down to
 * uniform/vest/backpack/assignedItems and explicitly exclude rack radios (see their own doc
 * comments) - this is a parallel, vehicle-scoped path, not a change to that carried-radio path.
 *
 * Locality and authority:
 * Server-authoritative. Calling on a client (or from an object's own Eden init field on a client)
 * forwards to the server via remoteExec, exactly like Waldo_fnc_Jammer - safe to call unconditionally
 * from an object init field on every machine. A config identical to the last one actually applied is
 * a no-op unless force is set; while a previous call's worker is still running, a new call is
 * refused (log only) rather than started concurrently against it - call again once
 * Waldo_ACRE2_RackSetupRunning clears. The actual mount/initialise-rack work ACRE2 performs is itself
 * delegated internally by ACRE2 to a connected player's machine (see
 * acre_api_fnc_addRackToVehicle/mountRackRadio) - this function does not need its own
 * object-locality redispatch on top of that.
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle whose already-defined racks (via CfgVehicles/CfgAcreRacks, or
 *    added earlier with acre_api_fnc_addRackToVehicle) should be configured.
 * 1: Config <HASHMAP or ARRAY of [key, value] pairs> - optional settings:
 *    preset <STRING> - an ACRE2 preset name (acre_api_fnc_setVehicleRacksPreset) applied before the
 *      vehicle's racks initialise. This is the simplest path: ACRE2 applies that preset's channels to
 *      every rack radio automatically as it mounts. Only takes effect before first initialisation -
 *      changing it on an already-initialised vehicle has no effect; use per-rack assignments instead.
 *    assignments <ARRAY> - explicit per-rack rows, each
 *      [rackIndex <NUMBER, 0-based into acre_api_fnc_getVehicleRacks order> or "ALL",
 *       setting <NUMBER channel, [block, channel] for PRC-343-style radios, or decimal MHz frequency;
 *         -1 (default) applies no channel/frequency - useful with mountRadioClass alone>,
 *       mountRadioClass <STRING, optional>:
 *         - a base radio classname (e.g. "ACRE_PRC117F") mounts that radio, REPLACING whatever the
 *           rack currently holds (ACRE2's own mount call overwrites the previous occupant - there is
 *           no separate confirmation step). Refused, with a diagnostic and that rack left untouched,
 *           when acre_api_fnc_isRackRadioRemovable reports the current occupant is not removable.
 *         - "REMOVE_RACK" rips the entire physical rack (hardware and radio) off the vehicle via
 *           acre_api_fnc_removeRackFromVehicle, gated by the same isRackRadioRemovable check. This is
 *           the confirmed-available removal path; no public API to unmount only the radio and leave
 *           an empty rack in place was found in ACRE2's source, so removal always takes the rack with
 *           it - reflect this in mission design (e.g. a spare empty rack the mission author already
 *           placed) if a mission needs an intentionally-empty slot.
 *         - blank (default): leave whatever is currently mounted alone.
 *    A mission using only `preset` does not need `assignments` at all.
 * 2: Force <BOOL> (default false) - reapplies even when the config is identical to what is already
 *    applied to this vehicle.
 *
 * Return Value:
 * Boolean - true when setup was accepted and (re)started server-side.
 *
 * Example:
 * // Simplest - apply a named ACRE2 preset to every rack on this vehicle:
 * [this, ["preset", "vrc110_default"]] call Waldo_fnc_ACRE2RackSetup;
 * // Explicit: rack 0 gets channel 5, rack 1 gets Block 2/Channel 3, mounting a PRC-117F into rack 1 first:
 * [this, ["assignments", [[0, 5], [1, [2, 3], "ACRE_PRC117F"]]]] call Waldo_fnc_ACRE2RackSetup;
 * // Later in the mission - re-equip rack 0 with a different radio type, ripping rack 1 out entirely:
 * [this, ["assignments", [[0, 12, "ACRE_PRC152"], [1, -1, "REMOVE_RACK"]]]] call Waldo_fnc_ACRE2RackSetup;
 *
 * Current callers: mission-maker Eden object init fields on rack-equipped vehicles; re-callable from
 * any later script/Zeus action that needs to change a vehicle's radio loadout.
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_config", [], [[], createHashMap]],
    ["_force", false, [true]]
];

if (isNull _vehicle) exitWith {
    diag_log "[WMP ACRE RACK] Waldo_fnc_ACRE2RackSetup called with a null vehicle - ignored.";
    false
};

private _configPairs = _config;
if (_configPairs isEqualType createHashMap) then {
    private _pairs = [];
    {_pairs pushBack [_x, _configPairs get _x];} forEach keys _configPairs;
    _configPairs = _pairs;
};
// A single bare [key, value] pair (e.g. ["preset", "x"], the simplest documented call shape) is
// indistinguishable in form from a list of pairs unless normalised - the same ambiguity
// Waldo_fnc_Jammer's own _bands parameter has, solved the same way.
if (_configPairs isEqualType [] && {count _configPairs == 2} && {(_configPairs select 0) isEqualType ""}) then {
    _configPairs = [_configPairs];
};

if !(isServer) exitWith {
    [_vehicle, _configPairs, _force] remoteExec ["Waldo_fnc_ACRE2RackSetup", 2];
    false
};

if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
    diag_log "[WMP ACRE RACK] ACRE2 is not loaded; rack setup skipped.";
    false
};

private _signature = str _configPairs;
if (!_force && {(_vehicle getVariable ["Waldo_ACRE2_RackSetupSignature", ""]) == _signature}) exitWith {
    false
};
if (_vehicle getVariable ["Waldo_ACRE2_RackSetupRunning", false]) exitWith {
    diag_log format ["[WMP ACRE RACK] Vehicle %1 rack setup already running; call again once it finishes to change the loadout.", _vehicle];
    false
};

_vehicle setVariable ["Waldo_ACRE2_RackSetupRunning", true, true];
_vehicle setVariable ["Waldo_ACRE2_RackSetupComplete", false, true]; // stale true from an earlier
    // run would otherwise make diagnostics see this run as already-settled while it is still in flight
_vehicle setVariable ["Waldo_ACRE2_RackSetupSignature", _signature, true];
private _configHash = createHashMapFromArray _configPairs;
[_vehicle, _configHash] spawn Waldo_fnc_ACRE2RackApply;
true
