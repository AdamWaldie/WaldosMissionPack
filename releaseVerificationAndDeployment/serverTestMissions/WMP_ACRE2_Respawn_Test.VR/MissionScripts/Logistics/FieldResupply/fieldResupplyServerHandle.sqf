/*
 * Author: WaldoTheWarfighter
 * Validates and executes every Field Resupply operation on the server.
 *
 * The handler is the sole writer for hub stock and carrier stock. A deployed crate is a normal
 * populated supply crate (Waldo_fnc_SupplyCratePopulate, scoped to the servicing hub's side) with
 * real physical cargo - taking supplies from it is ordinary ACE Cargo/Gear interaction against that
 * cargo, not a server-brokered logical grant, so this handler has no TAKE case. Remote callers may
 * act only through the unit they own. Carrier operations require a configured carrier and the same
 * backpack/on-foot conditions shown by local actions. Empty placement and salvage edge cases fail
 * safely.
 *
 * Locality and authority:
 * Runs only on the server. It verifies that remote callers own the supplied player unit, publishes
 * resulting stock state, and asks object owners/clients only for their local side effects.
 *
 * Arguments:
 * 0: unit <OBJECT> - requesting player unit.
 * 1: operation <STRING> - REFILL, DEPLOY or SALVAGE.
 * 2: arguments <ARRAY> - REFILL expects hub at index 0; SALVAGE expects crate at index 0.
 *
 * Return Value:
 * Boolean - true when the requested state change completed; otherwise false.
 *
 * Example:
 * [player, "DEPLOY", []] remoteExecCall ["Waldo_fnc_FieldResupplyServerHandle", 2];
 * Result: one populated crate is safely deployed, or the request is rejected without consuming stock.
 *
 * Current callers: carrier self-actions, registered hub actions and deployed-crate actions.
 */

params [["_unit", objNull, [objNull]], ["_operation", "", [""]], ["_arguments", [], [[]]]];
if !(isServer) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FieldResupply_Enable", false]) exitWith {false};
if (isNull _unit || {!alive _unit} || {remoteExecutedOwner > 0 && {owner _unit != remoteExecutedOwner}}) exitWith {false};

private _notify = {
    params ["_text", ["_state", "INFO"]];
    ["FIELD RESUPPLY", _text, _state, "FIELD_RESUPPLY"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
};
private _isCarrier = {_unit getVariable ["Waldo_FieldResupply_MaxCrates", 0] > 0};
private _hasPack = {backpack _unit != ""};
// Normalises one getXCargo-style [names[], counts[]] pair into a sorted, comparable string list -
// used to snapshot a crate's real cargo at DEPLOY and detect "has anything been taken or added"
// at SALVAGE without caring about the engine's internal cargo ordering.
private _snapshotCargoPair = {
    params ["_names", "_counts"];
    private _pairs = [];
    for "_i" from 0 to ((count _names) - 1) do {
        _pairs pushBack format ["%1:%2", _names select _i, _counts select _i];
    };
    _pairs sort true;
    _pairs
};
private _snapshotCrateCargo = {
    params ["_crate"];
    [
        [(getWeaponCargo _crate) select 0, (getWeaponCargo _crate) select 1] call _snapshotCargoPair,
        [(getMagazineCargo _crate) select 0, (getMagazineCargo _crate) select 1] call _snapshotCargoPair,
        [(getItemCargo _crate) select 0, (getItemCargo _crate) select 1] call _snapshotCargoPair,
        [(getBackpackCargo _crate) select 0, (getBackpackCargo _crate) select 1] call _snapshotCargoPair
    ]
};

switch (toUpperANSI _operation) do {
    case "REFILL": {
        private _hub = _arguments param [0, objNull, [objNull]];
        if (isNull _hub || {!(_hub getVariable ["Waldo_FieldResupply_Hub", false])} || {_unit distance _hub > 5}) exitWith {
            ["No registered supply hub is within reach.", "WARNING"] call _notify;
            false
        };
        if !(call _isCarrier) exitWith {["You are not assigned as a Field Resupply carrier.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to carry field-resupply crates.", "WARNING"] call _notify; false};
        private _hubSide = _hub getVariable ["Waldo_FieldResupply_Side", sideUnknown];
        if (_hubSide != sideUnknown && {_hubSide getFriend (side group _unit) < 0.6}) exitWith {
            ["This supply hub will not service your side.", "WARNING"] call _notify;
            false
        };
        private _stock = _hub getVariable ["Waldo_FieldResupply_Stock", -1];
        if (_stock == 0) exitWith {["This supply hub is empty.", "WARNING"] call _notify; false};
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        private _current = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        private _needed = (_maximum - _current) max 0;
        if (_needed <= 0) exitWith {["Your Field Resupply carrier is already full.", "INFO"] call _notify; false};
        private _issued = if (_stock < 0) then {_needed} else {_needed min _stock};
        if (_issued <= 0) exitWith {["This supply hub cannot issue another crate.", "WARNING"] call _notify; false};
        _unit setVariable ["Waldo_FieldResupply_Crates", _current + _issued, true];
        if (_stock >= 0) then {_hub setVariable ["Waldo_FieldResupply_Stock", _stock - _issued, true]};
        // DEPLOY has no hub reference of its own - it can run anywhere the carrier is standing, long
        // after leaving this hub - so stamp the servicing side here, at the one point a hub and
        // carrier are actually both in hand. A hub serving "ALL" (sideUnknown) has no fixed side to
        // populate from, so fall back to the carrier's own side rather than leaving DEPLOY ambiguous.
        private _carrierSide = if (_hubSide == sideUnknown) then {side group _unit} else {_hubSide};
        _unit setVariable ["Waldo_FieldResupply_CarrierSide", _carrierSide];
        [format ["Carrier refilled with %1 crate(s); now carrying %2 of %3.", _issued, _current + _issued, _maximum], "SUCCESS"] call _notify;
        true
    };

    case "DEPLOY": {
        if !(call _isCarrier) exitWith {["You are not assigned as a Field Resupply carrier.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to deploy field resupply.", "WARNING"] call _notify; false};
        if (vehicle _unit != _unit) exitWith {["Leave the vehicle before deploying field resupply.", "WARNING"] call _notify; false};
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_carried <= 0) exitWith {["No field-resupply crates remain in your carrier.", "WARNING"] call _notify; false};
        private _class = missionNamespace getVariable ["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"];
        if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {
            [format ["Configured crate class %1 is unavailable.", _class], "ERROR"] call _notify;
            false
        };
        private _origin = _unit modelToWorld [0, 1.8, 0];
        private _position = _origin findEmptyPosition [0.5, 5, _class];
        if (count _position == 0) exitWith {
            ["There is no clear space in front of you for the resupply crate.", "WARNING"] call _notify;
            false
        };
        // DEPLOY populates from the servicing hub's own side (stamped on the carrier at REFILL, or
        // the carrier's own side if never refilled from a hub), not the deploying player's personal
        // inventory - a scanned loadout pool can genuinely be empty (e.g. a side with no playable
        // units placed), which Waldo_fnc_SupplyCratePopulate cannot itself detect before spawning a
        // crate. Check first so a mis-scoped hub fails with a clear reason instead of a silently
        // empty crate.
        private _carrierSide = _unit getVariable ["Waldo_FieldResupply_CarrierSide", side group _unit];
        private _loadoutArray = [_carrierSide] call Waldo_fnc_GetSideLoadoutArray;
        if (count _loadoutArray == 0) exitWith {
            [format ["No scanned loadouts are available for %1 - place playable units on that side, or check the hub's serviced side.", str _carrierSide], "WARNING"] call _notify;
            false
        };
        private _crate = createVehicle [_class, _position, [], 0, "NONE"];
        if (isNull _crate) exitWith {["The resupply crate could not be created.", "ERROR"] call _notify; false};
        _crate setDir (getDir _unit);
        _crate setPosATL _position;
        _crate allowDamage false;
        private _sizeScalar = (missionNamespace getVariable ["Waldo_FieldResupply_CrateSizeScalar", 1]) max 0.1;
        private _includeGear = missionNamespace getVariable ["Waldo_FieldResupply_IncludeWeaponsAttachments", false];
        private _includeLaunchers = missionNamespace getVariable ["Waldo_FieldResupply_IncludeLaunchers", false];
        [_crate, _sizeScalar, _carrierSide, _includeGear, _includeLaunchers] call Waldo_fnc_SupplyCratePopulate;
        _crate setVariable ["Waldo_FieldResupply_Deployed", true, true];
        // Server-only - only this same handler's own SALVAGE case ever reads it back, so it does not
        // need to be broadcast.
        _crate setVariable ["Waldo_FieldResupply_CargoSnapshot", [_crate] call _snapshotCrateCargo];
        _unit setVariable ["Waldo_FieldResupply_Crates", _carried - 1, true];
        // Kept exactly as-is: Waldo_fnc_SupplyCratePopulate's own Waldo_fnc_SetCargoAttributes call
        // already made this crate draggable/carryable with default offsets, so these run after it to
        // restore field-resupply's own tuned drag/carry anchor points.
        if !(isNil "ace_dragging_fnc_setDraggable") then {[_crate, true, [0, 0, 0], 0] call ace_dragging_fnc_setDraggable};
        if !(isNil "ace_dragging_fnc_setCarryable") then {[_crate, true, [0, 2, 1], 0] call ace_dragging_fnc_setCarryable};
        // Target 0 (all machines), matching FieldResupplyRegisterHub's own equivalent call - not -2
        // ("all clients", which excludes owner 2). On a listen server the host's own client shares
        // owner 2 with the server, so -2 silently skipped installing the crate's local actions on
        // exactly the machine most mission makers test from; FieldResupplySetupCrateLocal already
        // guards with hasInterface, so target 0 stays a safe no-op on a pure dedicated server.
        [_crate] remoteExecCall ["Waldo_fnc_FieldResupplySetupCrateLocal", 0, format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        [format ["Field resupply deployed; %1 portable crate(s) remain. Open Gear or Cargo to draw supplies.", _carried - 1], "SUCCESS"] call _notify;
        true
    };

    case "SALVAGE": {
        private _crate = _arguments param [0, objNull, [objNull]];
        if (isNull _crate || {!(_crate getVariable ["Waldo_FieldResupply_Deployed", false])} || {_unit distance _crate > 5}) exitWith {
            ["No deployed Field Resupply crate is within reach.", "WARNING"] call _notify;
            false
        };
        if !(call _isCarrier) exitWith {["Only an assigned Field Resupply carrier can salvage this crate.", "WARNING"] call _notify; false};
        if !(call _hasPack) exitWith {["A backpack is required to salvage a field-resupply crate.", "WARNING"] call _notify; false};
        // Recoverable only if nobody has taken from or added to the crate since it was populated -
        // there is no charge counter left to compare against, so this compares the crate's actual
        // cargo against the snapshot captured right after DEPLOY populated it.
        private _originalCargo = _crate getVariable ["Waldo_FieldResupply_CargoSnapshot", []];
        private _currentCargo = [_crate] call _snapshotCrateCargo;
        private _recoverable = _currentCargo isEqualTo _originalCargo;
        private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
        private _carried = _unit getVariable ["Waldo_FieldResupply_Crates", 0];
        if (_recoverable && {_carried >= _maximum}) exitWith {["Carrier capacity is full.", "WARNING"] call _notify; false};
        // Cancel the crate's persistent JIP-replay entry before deleting it - the JIP id is the
        // 3rd remoteExecCall argument, not the 2nd (target); passing it as target previously called
        // a no-op function at a garbage destination and left the JIP entry (and its now-dangling
        // crate object reference) stored for any future joining player.
        [] remoteExecCall ["", 0, format ["Waldo_FieldResupply_Crate_%1", netId _crate]];
        deleteVehicle _crate;
        if (_recoverable) then {
            _unit setVariable ["Waldo_FieldResupply_Crates", _carried + 1, true];
            [format ["Unused crate salvaged; now carrying %1 of %2.", _carried + 1, _maximum], "SUCCESS"] call _notify;
        } else {
            ["Opened crate removed; no portable crate was recovered.", "INFO"] call _notify;
        };
        true
    };

    default {false};
}
