/*
 * Author: WaldoTheWarfighter
 * Purpose: Serialises validated item moves, whole-crate merges and empty-crate removal.
 * Locality / Authority: Server only; remote owner must match the requesting player.
 * Repeat / JIP: One request is atomic within an unscheduled server invocation; no durable action state.
 * Arguments: player <OBJECT>, source <OBJECT>, destination <OBJECT>, category <STRING>,
 * expected row <ARRAY>, quantity <NUMBER> (1), interacted object <OBJECT> (objNull).
 * BATCH expects [[category,row,quantity],...]. The interacted object must be the source
 * or a registered destination vehicle, never an arbitrary nearby proxy.
 * Category ALL merges; DELETE removes an empty source.
 * Return Value: <BOOL> committed. Current caller: ACE supply-transfer action.
 * Example: [player, boxA, boxB, "ALL", [], 1] remoteExecCall ["Waldo_fnc_SupplyTransfersRequestServer", 2];
 */
params [["_player", objNull, [objNull]], ["_source", objNull, [objNull]],
    ["_destination", objNull, [objNull]], ["_category", "", [""]],
    ["_expected", [], [[]]], ["_quantity", 1, [0]], ["_interaction", objNull, [objNull]]];
private _reject = {
    params ["_reason"];
    diag_log format ["[WMP SUPPLY TRANSFER REJECTED] reason=%1 category=%2 source=%3 destination=%4 player=%5",
        _reason, _category, _source, _destination, _player];
    false
};
if (!isServer || {!(missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false])}) exitWith {false};
if (isNull _player || {isNull _source} || {!alive _player}) exitWith {["invalid requester/source"] call _reject};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {["requester owner mismatch"] call _reject};
private _registry = missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []];
if !(_source in _registry) exitWith {["source not registered"] call _reject};
private _range = (missionNamespace getVariable ["Waldo_SupplyTransfers_Range", 20]) max 2 min 50;
if (_category == "ALL" && {isNull _destination}) exitWith {["merge destination missing"] call _reject};
private _vehicleReceive = _category == "BATCH" && {_destination in _registry}
    && {(_destination isKindOf "LandVehicle") || {_destination isKindOf "Air"} || {_destination isKindOf "Ship"}};
private _interactionObject = if (isNull _interaction) then {
    if (_category == "ALL") then {_destination} else {_source}
} else {_interaction};
if !(_interactionObject isEqualTo _source || {_interactionObject isEqualTo _destination
    && {(_category == "ALL") || {_vehicleReceive}}}) exitWith {["invalid interaction origin"] call _reject};
if (_player distance _interactionObject > 6) exitWith {["interaction beyond 6 m"] call _reject};
private _src = [_source] call Waldo_fnc_SupplyTransfersSnapshot;
if (_src isEqualTo []) exitWith {["source snapshot invalid"] call _reject};
if (_category == "DELETE") exitWith {
    if (_source isKindOf "LandVehicle" || {_source isKindOf "Air"} || {_source isKindOf "Ship"}) exitWith {
        ["vehicle removal is not a crate action"] call _reject
    };
    if ((_src findIf {_x isNotEqualTo []}) >= 0) exitWith {false};
    if (!isNull (_source getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) then {
        [_source] call Waldo_fnc_PhysicalCargoClearServer;
    };
    _registry = _registry - [_source];
    missionNamespace setVariable ["Waldo_SupplyTransfers_Registry", _registry, true];
    [_registry] remoteExecCall ["Waldo_fnc_SupplyTransfersSetupLocal", 0];
    deleteVehicle _source;
    true
};
private _vehicleDestination = !isNull _destination && {
    (_destination isKindOf "LandVehicle" || {_destination isKindOf "Air"} || {_destination isKindOf "Ship"})
    && {alive _destination} && {maxLoad _destination > 0}
};
if (isNull _destination || {_source isEqualTo _destination}
    || {!(_destination in _registry) && {!_vehicleDestination}}
    || {_source distance _destination > _range}) exitWith {
    [format ["destination/range invalid; actorDistance=%1 boxDistance=%2 limit=%3 registered=%4 vehicle=%5",
        _player distance _source, _source distance _destination, _range,
        _destination in _registry, _vehicleDestination]] call _reject
};
private _dst = [_destination] call Waldo_fnc_SupplyTransfersSnapshot;
if (_dst isEqualTo []) exitWith {["destination snapshot invalid"] call _reject};
private _newSrc = _src apply {+_x};
private _newDst = _dst apply {+_x};
private _selectionValid = true;
if (_category == "ALL") then {
    // Arma coalesces duplicate direct-item classes when cargo is rebuilt. Match
    // that canonical representation before the exact post-write comparison.
    private _mergedItems = +(_dst select 0);
    {
        _x params ["_class", "_count"];
        private _match = _mergedItems findIf {(_x select 0) isEqualTo _class};
        if (_match < 0) then {
            _mergedItems pushBack [_class, _count];
        } else {
            private _row = +(_mergedItems select _match);
            _row set [1, (_row select 1) + _count];
            _mergedItems set [_match, _row];
        };
    } forEach (_src select 0);
    _newDst set [0, _mergedItems];
    _newSrc set [0, []];
    for "_i" from 1 to 3 do {
        _newDst set [_i, +(_dst select _i) + (_src select _i)];
        _newSrc set [_i, []];
    };
} else {
    private _moves = if (_category == "BATCH") then {_expected} else {[[ _category, _expected, _quantity ]]};
    if !(_moves isEqualType [] && {count _moves > 0} && {count _moves <= 100}) then {
        _selectionValid = false;
    } else {
        {
            if (_selectionValid) then {
                if !(_x isEqualType [] && {count _x == 3}) then {
                    _selectionValid = false;
                } else {
                    _x params ["_moveCategory", "_moveRow", "_moveQuantity"];
                    private _index = ["ITEM", "WEAPON", "MAGAZINE", "BACKPACK"] find _moveCategory;
                    if (_index < 0 || {!(_moveRow isEqualType [])} || {count _moveRow < 2}
                        || {!(_moveQuantity isEqualType 0)} || {_moveQuantity < 1}
                        || {_moveQuantity != floor _moveQuantity} || {_moveQuantity > 1000}) then {
                        _selectionValid = false;
                    } else {
                        private _rows = +(_newSrc select _index);
                        private _rowIndex = _rows find _moveRow;
                        if (_rowIndex < 0) then {
                            _selectionValid = false;
                        } else {
                            private _dstRows = +(_newDst select _index);
                            if (_index == 0) then {
                                private _row = +(_rows select _rowIndex);
                                if (_moveQuantity > (_row select 1)) then {
                                    _selectionValid = false;
                                } else {
                                    _row set [1, (_row select 1) - _moveQuantity];
                                    if ((_row select 1) == 0) then {
                                        _rows deleteAt _rowIndex;
                                    } else {
                                        _rows set [_rowIndex, _row];
                                    };
                                    private _match = _dstRows findIf {(_x select 0) isEqualTo (_moveRow select 0)};
                                    if (_match < 0) then {
                                        _dstRows pushBack [(_moveRow select 0), _moveQuantity];
                                    } else {
                                        private _dstRow = +(_dstRows select _match);
                                        _dstRow set [1, (_dstRow select 1) + _moveQuantity];
                                        _dstRows set [_match, _dstRow];
                                    };
                                };
                            } else {
                                for "_copy" from 1 to _moveQuantity do {
                                    private _match = _rows find _moveRow;
                                    if (_match < 0) exitWith {_selectionValid = false};
                                    _rows deleteAt _match;
                                    _dstRows pushBack _moveRow;
                                };
                            };
                            if (_selectionValid) then {
                                _newSrc set [_index, _rows];
                                _newDst set [_index, _dstRows];
                            };
                        };
                    };
                };
            };
        } forEach _moves;
    };
};
if (!_selectionValid) exitWith {["selection/quantity stale"] call _reject};
// A conservative capacity gate before either inventory is touched. Global cargo-add commands may
// ignore the engine capacity, so the post-write exact snapshot check below is also mandatory.
if (maxLoad _destination > 0 && {loadAbs _destination + loadAbs _source > maxLoad _destination}
    && {_category == "ALL"}) exitWith {
    [format ["preflight capacity; sourceLoad=%1 destLoad=%2 max=%3", loadAbs _source,
        loadAbs _destination, maxLoad _destination]] call _reject
};
if !([_destination, _newDst] call Waldo_fnc_SupplyTransfersApplySnapshot) exitWith {
    [_destination, _dst] call Waldo_fnc_SupplyTransfersApplySnapshot;
    ["destination snapshot rebuild mismatch"] call _reject
};
if (maxLoad _destination > 0 && {loadAbs _destination > maxLoad _destination}) exitWith {
    [_destination, _dst] call Waldo_fnc_SupplyTransfersApplySnapshot;
    [format ["postwrite capacity; max=%1", maxLoad _destination]] call _reject
};
if !([_source, _newSrc] call Waldo_fnc_SupplyTransfersApplySnapshot) exitWith {
    [_destination, _dst] call Waldo_fnc_SupplyTransfersApplySnapshot;
    [_source, _src] call Waldo_fnc_SupplyTransfersApplySnapshot;
    ["source snapshot rebuild mismatch"] call _reject
};
diag_log format ["[WMP SUPPLY TRANSFER COMMITTED] category=%1 lines=%2 source=%3 destination=%4 player=%5",
    _category, if (_category == "BATCH") then {count _expected} else {1},
    _source, _destination, _player];
true
