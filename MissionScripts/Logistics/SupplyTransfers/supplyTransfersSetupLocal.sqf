/*
 * Author: WaldoTheWarfighter
 * Purpose: Installs crate logistics and registered vehicles' two-way transfer/merge ACE actions.
 * Locality / Authority: Interface-local; requests are validated and committed on the server.
 * Repeat / JIP: Reconciles current registry, removing obsolete local ACE paths before replacement.
 * Arguments: registry snapshot <ARRAY> (empty; supplied by server on replay).
 * Return Value: <BOOL> setup attempted.
 * Current callers: initPlayerLocal.sqf and Waldo_fnc_SupplyTransfersRegister broadcast.
 * Example: [missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]]
 *     remoteExecCall ["Waldo_fnc_SupplyTransfersSetupLocal", 0];
 */
params [["_snapshot", [], [[]]]];
if (!hasInterface || {!(missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false])}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if (isRemoteExecuted) then {
    // The ordered RPC payload is the action snapshot; do not wait for a separate publicVariable.
    missionNamespace setVariable ["Waldo_SupplyTransfers_Registry", _snapshot];
};
if (!isRemoteExecuted && {!isServer}) then {
    [player] remoteExecCall ["Waldo_fnc_SupplyTransfersRequestStateServer", 2];
};
if (isNil "ace_interact_menu_fnc_createAction" || {isNil "ace_interact_menu_fnc_removeActionFromObject"}) exitWith {false};
private _previous = missionNamespace getVariable ["Waldo_SupplyTransfers_LocalPaths", []];
private _desired = if (isRemoteExecuted) then {_snapshot} else {
    missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]
};
private _installed = [];
{
    private _object = _x;
    if (!isNull _object) then {
        private _oldIndex = _previous findIf {(_x select 0) isEqualTo _object};
        if (_oldIndex >= 0) then {
            _installed pushBack (_previous select _oldIndex);
        } else {
        private _paths = [];
        private _isVehicle = _object isKindOf "LandVehicle" || {_object isKindOf "Air"} || {_object isKindOf "Ship"};
        private _supplyPath = [];
        if (_isVehicle) then {
            private _root = ["WMP_SUPPLY_VEHICLE", "Vehicle logistics",
                "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", {},
                {_player distance _target <= 6}] call ace_interact_menu_fnc_createAction;
            _paths pushBack ([_object, 0, ["ACE_MainActions"], _root]
                call ace_interact_menu_fnc_addActionToObject);
            _supplyPath = ["ACE_MainActions", "WMP_SUPPLY_VEHICLE"];
        } else {
        private _root = ["WMP_SUPPLY_ROOT", "Crate logistics",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", {},
            {_player distance _target <= 6}] call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToObject);
        private _supplies = ["WMP_SUPPLY_CONTENTS", "Supplies",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa", {}, {true}]
            call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_SUPPLY_ROOT"], _supplies]
            call ace_interact_menu_fnc_addActionToObject);
        private _handling = ["WMP_SUPPLY_HANDLING", "Container handling",
            "\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa", {}, {true}]
            call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_SUPPLY_ROOT"], _handling]
            call ace_interact_menu_fnc_addActionToObject);
        _supplyPath = ["ACE_MainActions", "WMP_SUPPLY_ROOT", "WMP_SUPPLY_CONTENTS"];
        if (!isNil "ace_cargo_fnc_setSize") then {
            private _loadOn = ["WMP_SUPPLY_ACE_ON", "Enable ACE loading",
                "\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
                {[_player, _target, true] remoteExecCall ["Waldo_fnc_SupplyTransfersSetAceLoadServer", 2]},
                {_player distance _target <= 5 && {!(_target getVariable ["ace_cargo_canLoad", true])}}]
                call ace_interact_menu_fnc_createAction;
            _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_SUPPLY_ROOT", "WMP_SUPPLY_HANDLING"], _loadOn] call ace_interact_menu_fnc_addActionToObject);
            private _loadOff = ["WMP_SUPPLY_ACE_OFF", "Disable ACE loading",
                "\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
                {[_player, _target, false] remoteExecCall ["Waldo_fnc_SupplyTransfersSetAceLoadServer", 2]},
                {_player distance _target <= 5 && {_target getVariable ["ace_cargo_canLoad", true]}}]
                call ace_interact_menu_fnc_createAction;
            _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_SUPPLY_ROOT", "WMP_SUPPLY_HANDLING"], _loadOff] call ace_interact_menu_fnc_addActionToObject);
        };
        // No inventory recursion while ACE evaluates crate actions. The server alone
        // checks emptiness and returns a visible result if removal is rejected.
        private _remove = ["WMP_SUPPLY_DELETE", "Remove empty container",
            "\a3\ui_f\data\IGUI\Cfg\Actions\ico_off_ca.paa",
            {[_player, _target, objNull, "DELETE", [], 1]
                remoteExecCall ["Waldo_fnc_SupplyTransfersRequestWithFeedbackServer", 2]},
            {_player distance _target <= 5}] call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_SUPPLY_ROOT", "WMP_SUPPLY_HANDLING"], _remove] call ace_interact_menu_fnc_addActionToObject);
        };
        // Crates and vehicles share the same inventory workflow. Only ACE loading and
        // empty-container removal above are crate-specific presentation/actions.
        private _moveLabel = if (_isVehicle) then {"Transfer from this vehicle..."} else {"Transfer from this box..."};
        private _selectLabel = if (_isVehicle) then {"Select this vehicle as supply source"}
            else {"Select this box for merge / vehicle transfer"};
        private _mergeLabel = if (_isVehicle) then {"Merge selected source into this vehicle"}
            else {"Merge selected source into this box"};
        private _icon = "\a3\ui_f\data\igui\cfg\simpletasks\types\rearm_ca.paa";
        private _move = ["WMP_SUPPLY_MOVE", _moveLabel, _icon,
            {[_target] call Waldo_fnc_SupplyTransfersOpenLocal},
            {_player distance _target <= 6}] call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, _supplyPath, _move] call ace_interact_menu_fnc_addActionToObject);
        private _source = ["WMP_SUPPLY_SOURCE", _selectLabel, _icon,
            {
                missionNamespace setVariable ["Waldo_SupplyTransfers_SelectedSource", _target];
                private _name = _target getVariable ["Waldo_QM_IssueName", ""];
                if (_name isEqualTo "") then {
                    _name = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
                };
                if (_name isEqualTo "") then {_name = typeOf _target};
                ["MERGE SOURCE SELECTED",
                    format ["%1 selected. Transfer from here, or use Merge on a destination box or vehicle.", _name],
                    "SUCCESS", 8, "BOTTOM_RIGHT", "SUPPLY_MERGE_SOURCE"] call Waldo_fnc_ShowUiNotification;
            }, {_player distance _target <= 6}] call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, _supplyPath, _source] call ace_interact_menu_fnc_addActionToObject);
        private _merge = ["WMP_SUPPLY_MERGE", _mergeLabel, _icon,
            {
                private _source = missionNamespace getVariable ["Waldo_SupplyTransfers_SelectedSource", objNull];
                private _range = (missionNamespace getVariable ["Waldo_SupplyTransfers_Range", 20]) max 2 min 50;
                if (isNull _source || {_source isEqualTo _target}
                    || {!(_source in (missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]))}
                    || {_source distance _target > _range}) exitWith {
                    ["SUPPLY MERGE", "Select a different registered source within transfer range first.",
                        "INFO", "SUPPLY_MERGE_SOURCE", 7] call Waldo_fnc_FeatureNotifyLocal;
                };
                [_player, _source, _target, "ALL", [], 1]
                    remoteExecCall ["Waldo_fnc_SupplyTransfersRequestWithFeedbackServer", 2];
            }, {_player distance _target <= 6}] call ace_interact_menu_fnc_createAction;
        _paths pushBack ([_object, 0, _supplyPath, _merge] call ace_interact_menu_fnc_addActionToObject);
        _installed pushBack [_object, _paths];
        };
    };
} forEach _desired;
{
    _x params ["_object", "_paths"];
    if (!isNull _object && {!(_object in _desired)}) then {
        private _oldPaths = +_paths;
        reverse _oldPaths;
        {[_object, 0, _x] call ace_interact_menu_fnc_removeActionFromObject} forEach _oldPaths;
    };
} forEach _previous;
missionNamespace setVariable ["Waldo_SupplyTransfers_LocalPaths", _installed];
true
