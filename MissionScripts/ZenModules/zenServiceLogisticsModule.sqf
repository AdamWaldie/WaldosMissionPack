/*
 * Author: WaldoTheWarfighter
 * Purpose: Presents target-first ZEN dialogs for base nodes, quartermasters and cargo handling.
 * Locality / Authority: Curator interface only; edits go to an authenticated server handler.
 * Repeat / JIP: Dialogs are transient; server registries and object state replay to joining clients.
 * Arguments: feature <STRING>; module position <ARRAY>; selected object <OBJECT>.
 * Return Value: <BOOL> whether a dialog or inspection was opened.
 * Current callers: WMP Logistics and Mission Flow ZEN registrations.
 * Example: ["BASE", getPosATL cursorObject, cursorObject] call Waldo_fnc_ZenServiceLogisticsModule;
 * Result: The selected object's current service, quartermaster or ACE Cargo settings open in
 * a labelled curator dialog; applying changes sends an authenticated server request.
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
            } else {"Register an inventory box for ACE transfers and merges, or inspect it. Empty ammo boxes receive WMP inventory capacity; decorative props do not."}],
                [["REGISTER", "INSPECT"], ["Register for transfers", "Inspect registration"], if (_registered) then {1} else {0}]]
        ], {
            params ["_values", "_args"];
            _args params ["_target", "_send"];
            _values params ["_mode"];
            ["SUPPLY_" + _mode, _target, []] call _send;
        }, {}, [_target, _send]] call zen_dialog_fnc_create;
    };
    case "PHYSICAL": {
        private _eligible = [_target] call Waldo_fnc_PhysicalCargoIsEligible;
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
    case "ACE_CARGO": {
        // No ACE setters run while placing this module. Keep the read and dialog
        // times separate so a first-open hitch can be assigned to the UI path.
        private _startedAt = diag_tickTime;
        private _config = configFile >> "CfgVehicles" >> typeOf _target;
        // Read ACE's effective object state. WMP's saved choice may be stale
        // after another module or mission script changes the same object.
        private _choice = [
            _target getVariable ["ace_dragging_canDrag", getNumber (_config >> "ace_dragging_canDrag") > 0],
            _target getVariable ["ace_dragging_canCarry", getNumber (_config >> "ace_dragging_canCarry") > 0],
            _target getVariable ["ace_dragging_ignoreWeightDrag", getNumber (_config >> "ace_dragging_ignoreWeightDrag") > 0],
            _target getVariable ["ace_dragging_ignoreWeightCarry", getNumber (_config >> "ace_dragging_ignoreWeightCarry") > 0]
        ];
        private _configSize = if (isNumber (_config >> "ace_cargo_size")) then {
            getNumber (_config >> "ace_cargo_size")
        } else {-1};
        private _size = _target getVariable ["ace_cargo_size", _configSize];
        private _space = _target getVariable ["ace_cargo_space",
            getNumber (_config >> "ace_cargo_space")];
        if !((_target getVariable ["ace_cargo_loaded", []]) isEqualTo []) then {
            // ACE exposes remaining space once cargo is loaded. WMP's own
            // tracked total is preferable when it is available.
            _space = _target getVariable ["Waldo_CargoAttributes_TotalSpace", _space];
        };
        private _sizeRangeMax = 50 max (ceil _size);
        private _spaceRangeMax = 100 max (ceil _space);
        private _readMs = round ((diag_tickTime - _startedAt) * 1000);
        // ZEN otherwise reuses values saved from the last object edited. Force
        // each row to its live object value so Cancel/reopen resets the form.
        ["Set ACE Cargo and Object Handling", [
            ["CHECKBOX", ["Can drag", "Show ACE Drag and allow this object to be dragged."], _choice param [0, false], true],
            ["CHECKBOX", ["Can carry", "Show ACE Carry and allow this object to be carried."], _choice param [1, false], true],
            ["CHECKBOX", ["Ignore drag weight limit", "Only use when the intended object exceeds ACE's normal drag weight limit."], _choice param [2, false], true],
            ["CHECKBOX", ["Ignore carry weight limit", "Only use when the intended object exceeds ACE's normal carry weight limit."], _choice param [3, false], true],
            ["SLIDER", ["ACE cargo size", "Whole-number size: -1 disables ACE loading; 0 or more enables it. Does not control physical mounting."], [-1, _sizeRangeMax, (round _size) max -1, 0], true],
            ["SLIDER", ["ACE cargo space", "Whole-number capacity: 0 means it cannot hold ACE Cargo. For loaded objects, ACE may expose remaining rather than total space."], [0, _spaceRangeMax, (round _space) max 0, 0], true]
        ], {
            params ["_values", "_args"];
            _args params ["_target", "_send", "_originalChoice", "_originalSize", "_originalSpace"];
            _values params ["_drag", "_carry", "_ignoreDrag", "_ignoreCarry", "_size", "_space"];
            // ZEN sliders may return fractions even with zero display decimals.
            // ACE accepts those fractions, so normalise the submitted values.
            _size = round _size;
            _space = round _space;
            private _setSize = _size isNotEqualTo (round _originalSize);
            private _setSpace = _space isNotEqualTo (round _originalSpace);
            private _setHandling = !([_drag, _carry, _ignoreDrag, _ignoreCarry] isEqualTo _originalChoice);
            if (!_setHandling && {!_setSize} && {!_setSpace}) exitWith {};
            ["ACE_CARGO_SET", _target, [["drag", _drag], ["carry", _carry],
                ["ignoreDragWeight", _ignoreDrag], ["ignoreCarryWeight", _ignoreCarry],
                ["setHandling", _setHandling], ["setSize", _setSize], ["size", _size],
                ["setSpace", _setSpace], ["space", _space]]] call _send;
        }, {}, [_target, _send, _choice, _size, _space]] call zen_dialog_fnc_create;
        diag_log format ["[WMP ZEN ACE CARGO] placement target=%1 readMs=%2 dialogMs=%3",
            typeOf _target, _readMs, round ((diag_tickTime - _startedAt) * 1000) - _readMs];
    };
};
true
