/*
 * Author: WaldoTheWarfighter
 * Purpose: Authenticates and applies ZEN base, quartermaster and crate setup to selected objects.
 * Locality / Authority: Server only; owner-bound active curator is required for remote calls.
 * Repeat / JIP: Uses repeat-safe registries; quartermaster setup is JIP-replayed by object key.
 * Arguments: operation <STRING>; selected object <OBJECT>; named pairs <ARRAY>; requester <OBJECT>.
 * Return Value: <BOOL> request accepted. Current caller: Waldo_fnc_ZenServiceLogisticsModule.
 * Example: ["SUPPLY_REGISTER", crate1, [], player] remoteExecCall ["Waldo_fnc_ZenServiceLogisticsServer", 2];
 */
params [["_operation", "", [""]], ["_target", objNull, [objNull]], ["_pairs", [], [[]]], ["_requester", objNull, [objNull]]];
if (!isServer || {isNull _target}) exitWith {false};
private _replyOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _requester};
if (isRemoteExecuted && {isNull _requester || {owner _requester != _replyOwner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {false};
private _settings = createHashMapFromArray _pairs;
private _ok = false;
private _deferred = false;
private _message = "Unsupported operation or feature disabled.";
switch (toUpperANSI _operation) do {
    case "BASE_UPSERT": {
        private _group = _settings getOrDefault ["group", ""];
        private _label = _settings getOrDefault ["label", ""];
        private _services = _settings getOrDefault ["services", []];
        private _transition = _settings getOrDefault ["transition", "STANDARD"];
        if (missionNamespace getVariable ["Waldo_BaseServices_Enable", false]
            && {_group isEqualType ""} && {count _group > 0} && {count _group <= 32}
            && {_label isEqualType ""} && {_label isNotEqualTo ""} && {count _label <= 48}
            && {_services isEqualType []} && {(_services findIf {!(_x in ["SAVE", "HEAL", "SPECTATE", "TELEPORT"])}) < 0}
            && {_transition in ["STANDARD", "QUICK", "TRAVEL", "NIGHT", "DAYLIGHT", "NONE"]}) then {
            [_target, _group, _label, _services, _transition, _replyOwner] spawn {
                params ["_target", "_group", "_label", "_services", "_transition", "_replyOwner"];
                private _applied = [_target, _group, _label, _services, "", _transition]
                    call Waldo_fnc_BaseServicesRegisterNode;
                diag_log format ["[WMP ZEN] BASE_UPSERT applied=%1 target=%2 group=%3", _applied, netId _target, _group];
                if (_replyOwner > 2) then {
                    ["BASE SERVICES", if (_applied) then {format ["%1 registered in %2.", _label, _group]}
                        else {"Base node could not be registered; check the feature flag and target."},
                        if (_applied) then {"SUCCESS"} else {"ERROR"}, "ZEN_BASE_NODE", 7]
                        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
                };
            };
            _deferred = true;
            _ok = true;
        };
    };
    case "BASE_REMOVE": {
        private _group = _settings getOrDefault ["group", ""];
        private _registry = missionNamespace getVariable ["Waldo_BaseServices_Registry", []];
        private _index = _registry findIf {(_x select 0) isEqualTo _group};
        if (_index >= 0) then {
            private _rows = ((_registry select _index) select 1) select {(_x select 0) isNotEqualTo _target};
            if (count _rows < count ((_registry select _index) select 1)) then {
                [_group, _rows, (_registry select _index) select 2, _replyOwner] spawn {
                    params ["_group", "_rows", "_transition", "_replyOwner"];
                    private _applied = [_group, _rows, _transition] call Waldo_fnc_BaseServicesRegister;
                    if (_replyOwner > 2) then {
                        ["BASE SERVICES", if (_applied) then {format ["Node removed from %1.", _group]}
                            else {"Could not remove the base node."},
                            if (_applied) then {"SUCCESS"} else {"ERROR"}, "ZEN_BASE_NODE", 7]
                            remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
                    };
                };
                _deferred = true;
                _ok = true;
            };
        };
    };
    case "QUARTERMASTER": {
        private _bearing = _settings getOrDefault ["bearing", 90];
        private _distance = _settings getOrDefault ["distance", 3];
        private _deploymentControlled = _settings getOrDefault ["deploymentControlled", false];
        private _allowed = _settings getOrDefault ["allowedKinds", []];
        private _kinds = ["Medical", "Ammo", "Supply", "Wheel", "Track", "Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"];
        if (missionNamespace getVariable ["Waldo_Quartermaster_Enable", true]
            && {_bearing isEqualType 0} && {_bearing >= 0} && {_bearing < 360}
            && {_distance isEqualType 0} && {_distance >= 2} && {_distance <= 12}
            && {_deploymentControlled isEqualType false}
            && {_allowed isEqualType []} && {_allowed isNotEqualTo []}
            && {(_allowed findIf {!(_x in _kinds)}) < 0}) then {
            private _enabled = {
                params ["_kind"];
                if (_kind == "Rearm") exitWith {
                    missionNamespace getVariable ["Waldo_QM_Rearm_Enable", false]
                        || {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]}
                        || {missionNamespace getVariable ["Waldo_QM_StaticRearm_Enable", false]}
                };
                missionNamespace getVariable [format ["Waldo_QM_%1_Enable", _kind], false]
            };
            _allowed = _allowed select {[_x] call _enabled};
            if (_allowed isEqualTo []) exitWith {_message = "No selected issue type is enabled in MissionConfig/logisticsConfig.sqf."};
            _target setVariable ["Waldo_QM_AllowedKinds", _allowed, true];
            _target setVariable ["Waldo_QM_ZenSettings", [_bearing, _distance, _deploymentControlled, _allowed], true];
            [_target, _bearing, _distance, _deploymentControlled] call Waldo_fnc_SetupQuarterMaster;
            [_target, _bearing, _distance, _deploymentControlled, _allowed]
                remoteExecCall ["Waldo_fnc_QuartermasterReconfigureLocal", -2, _target];
            _ok = true;
            _message = format ["Quartermaster configured: %1 issue types. %2", count _allowed,
                if (_deploymentControlled) then {"Waiting for its deployment controller."} else {"Ready now."}];
        };
    };
    case "SUPPLY_REGISTER": {
        if !(missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false]) then {
            _message = "Supply transfers are disabled in MissionConfig/logisticsConfig.sqf.";
        } else {
        if (maxLoad _target <= 0) then {
            _message = "Selected object has no Arma inventory capacity; it cannot send or receive supplies.";
        } else {
            [_target, _replyOwner] spawn {
                params ["_target", "_replyOwner"];
                private _applied = [_target] call Waldo_fnc_SupplyTransfersRegister;
                diag_log format ["[WMP ZEN] SUPPLY_REGISTER applied=%1 target=%2", _applied, netId _target];
                if (_replyOwner > 2) then {
                    ["SUPPLY TRANSFERS", if (_applied) then {
                        if (_target isKindOf "LandVehicle" || {_target isKindOf "Air"} || {_target isKindOf "Ship"}) then {
                            "Vehicle logistics registered: transfer in or out, select it as source, and merge through ACE."
                        } else {"Container registered; its ACE logistics actions are available."}
                    } else {"Registration failed; check feature status and inventory capacity."},
                        if (_applied) then {"SUCCESS"} else {"ERROR"}, "ZEN_SUPPLY_REGISTER", 7]
                        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
                };
            };
            _deferred = true;
            _ok = true;
        };
        };
    };
    case "SUPPLY_INSPECT": {
        _ok = true;
        _message = format ["Registered: %1. Inventory capacity: %2. Role: %3.",
            _target in (missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]),
            round maxLoad _target,
            if (_target isKindOf "LandVehicle" || {_target isKindOf "Air"} || {_target isKindOf "Ship"})
                then {"vehicle source and destination"} else {"container source and destination"}];
    };
    case "PHYSICAL_ENABLE": {
        if (missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]
            && {!(_target isKindOf "StaticWeapon" || {_target isKindOf "LandVehicle"}
                || {_target isKindOf "Air"} || {_target isKindOf "Ship"})}) then {
            [_target, _replyOwner] spawn {
                params ["_target", "_replyOwner"];
                private _applied = [_target] call Waldo_fnc_PhysicalCargoRegister;
                diag_log format ["[WMP ZEN] PHYSICAL_ENABLE applied=%1 target=%2", _applied, netId _target];
                if (_replyOwner > 2) then {
                    ["PHYSICAL CARGO", if (_applied) then {"Object is eligible for physical mounting."}
                        else {"Physical mounting could not be enabled for this object."},
                        if (_applied) then {"SUCCESS"} else {"ERROR"}, "ZEN_PHYSICAL_CARGO", 7]
                        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
                };
            };
            _deferred = true;
            _ok = true;
        } else {
            _message = if (_target isKindOf "StaticWeapon") then {
                "Static weapons are excluded: attached guns can destabilise or flip vehicles. ACE Carry/Cargo remains available."
            } else {if (_target isKindOf "LandVehicle" || {_target isKindOf "Air"} || {_target isKindOf "Ship"}) then {
                "Select a carryable prop or crate, not the carrier vehicle."
            } else {"Physical cargo is disabled in MissionConfig/logisticsConfig.sqf."}};
        };
    };
    case "PHYSICAL_DISABLE": {
        if (isNull (_target getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])) then {
            _target setVariable ["Waldo_PhysicalCargo_Eligible", false, true];
            _ok = true;
            _message = "Future physical mounting disabled; native ACE handling remains.";
        } else {_message = "Unmount the cargo before disabling physical mounting."};
    };
    case "PHYSICAL_INSPECT": {
        _ok = true;
        _message = format ["Eligible: %1. Mounted: %2.",
            _target getVariable ["Waldo_PhysicalCargo_Eligible", _target isKindOf "ReammoBox_F"],
            !isNull (_target getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])];
    };
};
diag_log format ["[WMP ZEN] service/logistics operation=%1 target=%2 owner=%3 ok=%4", _operation, netId _target, _replyOwner, _ok];
if (_replyOwner > 2 && {!_deferred}) then {
    [if (_operation find "BASE" == 0) then {"BASE SERVICES"} else {
        if (_operation find "QUARTERMASTER" == 0) then {"QUARTERMASTER"} else {
            if (_operation find "SUPPLY" == 0) then {"SUPPLY TRANSFERS"} else {"PHYSICAL CARGO"}
        }
    }, _message, if (_ok) then {"SUCCESS"} else {"ERROR"}, "ZEN_SERVICE_LOGISTICS", 7]
        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _replyOwner];
};
_ok
