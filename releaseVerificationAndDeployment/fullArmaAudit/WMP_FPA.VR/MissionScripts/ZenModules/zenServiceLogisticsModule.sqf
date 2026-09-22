/*
 * Author: WaldoTheWarfighter
 * Purpose: Presents target-first ZEN dialogs for base nodes, quartermasters and cargo eligibility.
 * Locality / Authority: Curator interface only; edits go to an authenticated server handler.
 * Repeat / JIP: Dialogs are transient; server registries and object state replay to joining clients.
 * Arguments: feature <STRING>; module position <ARRAY>; selected object <OBJECT>.
 * Return Value: <BOOL> whether a dialog or inspection was opened.
 * Current callers: WMP Logistics and Mission Flow ZEN registrations.
 * Example: ["BASE", getPosATL cursorObject, cursorObject] call Waldo_fnc_ZenServiceLogisticsModule;
 */
params [["_feature", "", [""]], ["_modulePos", [], [[]]], ["_target", objNull, [objNull]]];
if (!hasInterface || {isNull _target}) exitWith {
    ["WMP ZEN", "Place this module directly on the object to configure.", "ERROR", "SERVICE_TARGET", 6]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _send = {
    params ["_operation", "_target", "_pairs"];
    [_operation, _target, _pairs, player] remoteExecCall ["Waldo_fnc_ZenServiceLogisticsServer", 2];
};
switch (toUpperANSI _feature) do {
    case "BASE": {
        private _network = [];
        private _existing = [];
        {
            private _found = (_x select 1) findIf {(_x select 0) isEqualTo _target};
            if (_found >= 0) exitWith {_network = _x; _existing = (_x select 1) select _found};
        } forEach (missionNamespace getVariable ["Waldo_BaseServices_Registry", []]);
        private _existingServices = _existing param [2, []];
        private _existingTransition = _existing param [4, ""];
        private _transitions = ["", "STANDARD", "QUICK", "TRAVEL", "NIGHT", "DAYLIGHT", "NONE"];
        private _transitionIndex = _transitions find _existingTransition;
        ["Configure Base Service Node", [
            ["EDIT", ["Base network", "Nodes sharing this name can teleport to each other. Example: MainBase."], [_network param [0, "MainBase"]]],
            ["EDIT", ["Node name", "Shown beside this object and as a teleport destination."],
                [_existing param [1, getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName")]]],
            ["CHECKBOX", ["Save respawn loadout", "Give this object a loadout-save action."], "SAVE" in _existingServices],
            ["CHECKBOX", ["Full heal", "Give this object an ACE full-heal action."], "HEAL" in _existingServices],
            ["CHECKBOX", ["Spectator", "Give this object a spectator-entry action."], "SPECTATE" in _existingServices],
            ["CHECKBOX", ["Teleport", "Make this object a source and destination in its named network."],
                _existing isEqualTo [] || {"TELEPORT" in _existingServices}],
            ["COMBO", ["Transition", "Use Network default to inherit the network transition; Standard is a short black fade."],
                [_transitions, ["Network default", "Standard", "Quick", "Travel", "Night", "Daylight", "None"], _transitionIndex max 0]],
            ["CHECKBOX", ["Remove this node", "Remove this object from the named base instead of updating it."], false]
        ], {
            params ["_values", "_args"];
            _args params ["_target", "_send"];
            _values params ["_group", "_label", "_save", "_heal", "_spectate", "_teleport", "_transition", "_remove"];
            private _services = [];
            if (_save) then {_services pushBack "SAVE"};
            if (_heal) then {_services pushBack "HEAL"};
            if (_spectate) then {_services pushBack "SPECTATE"};
            if (_teleport) then {_services pushBack "TELEPORT"};
            [if (_remove) then {"BASE_REMOVE"} else {"BASE_UPSERT"}, _target,
                [["group", _group], ["label", _label], ["services", _services], ["transition", _transition]]] call _send;
        }, {}, [_target, _send]] call zen_dialog_fnc_create;
    };
    case "QUARTERMASTER": {
        private _initial = _target getVariable ["Waldo_QM_SetupSettings", [90, 2, false]];
        private _current = _target getVariable ["Waldo_QM_ZenSettings", _initial + [[]]];
        private _configured = _current param [3, []];
        private _issues = [
            ["Medical", "Medical box", "Waldo_QM_Medical_Enable"],
            ["Ammo", "Ammo box", "Waldo_QM_Ammo_Enable"],
            ["Supply", "Heavy supply box", "Waldo_QM_Supply_Enable"],
            ["Wheel", "Spare wheel", "Waldo_QM_Wheel_Enable"],
            ["Track", "Spare track", "Waldo_QM_Track_Enable"],
            ["Grenades", "Grenade box", "Waldo_QM_Grenades_Enable"],
            ["Explosives", "Explosives box", "Waldo_QM_Explosives_Enable"],
            ["Rearm", "ACE rearm box", "Waldo_QM_Rearm_Enable"],
            ["FuelBarrel", "ACE fuel barrel", "Waldo_QM_FuelBarrel_Enable"],
            ["FuelJerrycan", "ACE fuel jerrycan", "Waldo_QM_FuelJerrycan_Enable"]
        ];
        private _fields = [
            ["SLIDER", ["Spawn bearing", "Degrees relative to this object: 0 ahead, 90 right."], [0, 359, _current param [0, 90], 0]],
            ["SLIDER", ["Spawn distance", "Metres from this object; make room for the largest enabled crate."], [2, 12, _current param [1, 2], 1]],
            ["CHECKBOX", ["Deployment controlled", "Only select this for an MHQ or another system that explicitly controls the active state. Ordinary points should stay off."], _current param [2, false]]
        ];
        {
            _x params ["_kind", "_label", "_flag"];
            private _available = missionNamespace getVariable [_flag, _kind in ["Medical", "Ammo", "Supply", "Wheel", "Track"]];
            if (_kind == "Rearm") then {
                _available = _available || {missionNamespace getVariable ["Waldo_QM_VehicleRearm_Enable", false]}
                    || {missionNamespace getVariable ["Waldo_QM_StaticRearm_Enable", false]};
            };
            _fields pushBack ["CHECKBOX", [_label, format ["Offer this issue here. Global availability: %1; class and quantity are set in MissionConfig/logisticsConfig.sqf.",
                if (_available) then {"enabled"} else {"disabled"}]],
                _available && {_configured isEqualTo [] || {_kind in _configured}}];
        } forEach _issues;
        ["Set Up Quartermaster", _fields, {
            params ["_values", "_args"];
            _args params ["_target", "_send"];
            _values params ["_bearing", "_distance", "_deploymentControlled"];
            private _kinds = ["Medical", "Ammo", "Supply", "Wheel", "Track", "Grenades", "Explosives", "Rearm", "FuelBarrel", "FuelJerrycan"];
            private _allowed = [];
            {
                if (_values param [_forEachIndex + 3, false]) then {_allowed pushBack _x};
            } forEach _kinds;
            ["QUARTERMASTER", _target, [["bearing", _bearing], ["distance", _distance],
                ["deploymentControlled", _deploymentControlled], ["allowedKinds", _allowed]]] call _send;
        }, {}, [_target, _send]] call zen_dialog_fnc_create;
    };
    case "SUPPLY": {
        private _vehicle = _target isKindOf "LandVehicle" || {_target isKindOf "Air"} || {_target isKindOf "Ship"};
        private _registered = _target in (missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]);
        [if (_vehicle) then {"Configure Vehicle Supply Logistics"} else {"Configure Supply Container"}, [
            ["COMBO", ["Operation", if (_vehicle) then {
                "Register this vehicle for two-way ACE transfers and whole-inventory merge. It needs Arma inventory capacity."
            } else {"Register this box as a supply source, or inspect its current state."}],
                [["REGISTER", "INSPECT"], ["Register for transfers", "Inspect registration"], if (_registered) then {1} else {0}]]
        ], {
            params ["_values", "_args"];
            _args params ["_target", "_send"];
            _values params ["_mode"];
            ["SUPPLY_" + _mode, _target, []] call _send;
        }, {}, [_target, _send]] call zen_dialog_fnc_create;
    };
    case "PHYSICAL": {
        private _eligible = _target getVariable ["Waldo_PhysicalCargo_Eligible", _target isKindOf "ReammoBox_F"];
        ["Physical Cargo Eligibility", [
            ["COMBO", ["Operation", "Allow carried non-weapon objects to mount on vehicles, disable future mounts, or inspect."],
                [["ENABLE", "DISABLE", "INSPECT"], ["Allow physical mounting", "Disallow physical mounting", "Inspect state"],
                    if (_eligible) then {2} else {0}]]
        ], {
            params ["_values", "_args"];
            _args params ["_target", "_send"];
            _values params ["_mode"];
            ["PHYSICAL_" + _mode, _target, []] call _send;
        }, {}, [_target, _send]] call zen_dialog_fnc_create;
    };
};
true
