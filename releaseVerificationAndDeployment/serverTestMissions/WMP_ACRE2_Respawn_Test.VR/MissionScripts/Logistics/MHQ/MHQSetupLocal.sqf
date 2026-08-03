/* Installs the MHQ interaction surface on one interface client. Called globally/JIP by MHQSetup. */
params [
    ["_target", objNull, [objNull]],
    ["_logisticsDirection", 180, [0]],
    ["_logisticsDistance", 4, [0]]
];

if (!hasInterface || {isNull _target}) exitWith {false};
if (_target getVariable ["Waldo_MHQ_LocalActionsInstalled", false]) exitWith {
    // The first local call can arrive before the server's optional configuration.
    // Re-evaluate components on the later object-keyed JIP call without duplicating
    // the already installed deploy/tear-down actions.
    if ((_target getVariable ["Waldo_MHQ_Config", ["", false]]) param [1, false]) then {
        [_target, _logisticsDirection, _logisticsDistance] call Waldo_fnc_SetupQuarterMaster;
    };
    true
};

private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _aceReady = _aceLoaded
    && {!(isNil "ace_interact_menu_fnc_createAction")}
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")}
    && {!(isNil "ace_common_fnc_progressBar")};

// Never expose duplicate vanilla actions in an ACE mission. If setup previously ran before ACE
// became ready, remove those fallback actions before installing the ACE tree.
if (_aceReady) then {
    {
        if (_x >= 0) then {_target removeAction _x;};
    } forEach (_target getVariable ["Waldo_MHQ_VanillaActionIds", []]);
    _target setVariable ["Waldo_MHQ_VanillaActionIds", []];

    private _canOperate = {
        params ["_target", "_player"];
        alive _player
        && {_player distance _target < 6}
        && {abs speed _target < 1}
        && {!(_target getVariable ["Waldo_MHQ_Transition", false])}
        && {[_player, _target, []] call ace_common_fnc_canInteractWith}
    };
    private _category = [
        "Waldo_MHQ_Category", "Command Post",
        "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_view_article_CA.paa",
        {}, {true}
    ] call ace_interact_menu_fnc_createAction;
    private _deploy = [
        "Waldo_MHQ_Deploy", "Set Up Command Post",
        "\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_unloadVehicle_ca.paa",
        {_this call ((_this select 0) getVariable ["Waldo_MHQ_RunOperation", {}]);},
        {[_target, _player] call (_target getVariable ["Waldo_MHQ_CanOperate", {false}]) && {!(_target getVariable ["Waldo_MHQ_Status", false])}},
        {}, "DEPLOY", [0, 0, 0], 6
    ] call ace_interact_menu_fnc_createAction;
    private _tearDown = [
        "Waldo_MHQ_TearDown", "Tear Down Command Post",
        "\a3\data_f_destroyer\data\UI\IGUI\Cfg\holdactions\holdAction_loadVehicle_ca.paa",
        {_this call ((_this select 0) getVariable ["Waldo_MHQ_RunOperation", {}]);},
        {[_target, _player] call (_target getVariable ["Waldo_MHQ_CanOperate", {false}]) && {_target getVariable ["Waldo_MHQ_Status", false]}},
        {}, "TEARDOWN", [0, 0, 0], 6
    ] call ace_interact_menu_fnc_createAction;

    // Store local code on the object so ACE receives its normal [_target,_player,_actionParams]
    // tuple and the operation remains explicit and testable.
    _target setVariable ["Waldo_MHQ_CanOperate", _canOperate];
    _target setVariable ["Waldo_MHQ_RunOperation", {
        params ["_target", "_actor", "_operation"];
        [10, [_target, _actor, _operation], {
            _args params ["_target", "_actor", "_operation"];
            [_target, _actor, _operation] remoteExecCall ["Waldo_fnc_MHQRequestServer", 2];
        }, {
            _args params ["_target", "_actor"];
            ["Command post operation cancelled.", _actor] call Waldo_fnc_DynamicText;
        }, if (_operation == "DEPLOY") then {"Establishing Command Post"} else {"Tearing Down Command Post"}]
            call ace_common_fnc_progressBar;
    }];

    private _categoryPath = [_target, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
    private _deployPath = [_target, 0, ["ACE_MainActions", "Waldo_MHQ_Category"], _deploy] call ace_interact_menu_fnc_addActionToObject;
    private _tearDownPath = [_target, 0, ["ACE_MainActions", "Waldo_MHQ_Category"], _tearDown] call ace_interact_menu_fnc_addActionToObject;
    _target setVariable ["Waldo_MHQ_ACEActionPaths", [_categoryPath, _deployPath, _tearDownPath]];
    _target setVariable ["Waldo_MHQ_ACEActions", [_category, _deploy, _tearDown]];
    _target setVariable ["Waldo_MHQ_ACEActionsInstalled", true];
    _target setVariable ["Waldo_MHQ_VanillaActionsInstalled", false];
} else {
    // The patch being loaded but its functions not being initialized is not a legitimate vanilla
    // fallback state. Retry shortly rather than showing two interaction systems in an ACE mission.
    if (_aceLoaded) exitWith {
        if !(_target getVariable ["Waldo_MHQ_LocalSetupPending", false]) then {
            _target setVariable ["Waldo_MHQ_LocalSetupPending", true];
            [_target, _logisticsDirection, _logisticsDistance] spawn {
                params ["_target", "_direction", "_distance"];
                waitUntil {
                    uiSleep 0.1;
                    isNull _target
                    || {!(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")}}
                };
                if (!isNull _target) then {
                    _target setVariable ["Waldo_MHQ_LocalSetupPending", false];
                    [_target, _direction, _distance] call Waldo_fnc_MHQSetupLocal;
                };
            };
        };
        false
    };

    private _deployId = _target addAction [
        "<t color='#F4C542'>Set Up Command Post</t>",
        {params ["_target", "_actor"]; [_target, _actor, "DEPLOY"] remoteExecCall ["Waldo_fnc_MHQRequestServer", 2];},
        [], 1.5, true, true, "",
        "!(_target getVariable ['Waldo_MHQ_Status',false]) && !(_target getVariable ['Waldo_MHQ_Transition',false]) && {_this distance _target < 6} && {abs speed _target < 1}", 6
    ];
    private _tearDownId = _target addAction [
        "<t color='#F4C542'>Tear Down Command Post</t>",
        {params ["_target", "_actor"]; [_target, _actor, "TEARDOWN"] remoteExecCall ["Waldo_fnc_MHQRequestServer", 2];},
        [], 1.5, true, true, "",
        "(_target getVariable ['Waldo_MHQ_Status',false]) && !(_target getVariable ['Waldo_MHQ_Transition',false]) && {_this distance _target < 6} && {abs speed _target < 1}", 6
    ];
    _target setVariable ["Waldo_MHQ_VanillaActionIds", [_deployId, _tearDownId]];
    _target setVariable ["Waldo_MHQ_ACEActionsInstalled", false];
    _target setVariable ["Waldo_MHQ_VanillaActionsInstalled", true];
};

if ((_target getVariable ["Waldo_MHQ_Config", ["", false]]) param [1, false]) then {
    [_target, _logisticsDirection, _logisticsDistance] call Waldo_fnc_SetupQuarterMaster;
};

_target setVariable ["Waldo_MHQ_InteractionMode", if (_aceReady) then {"ACE"} else {"VANILLA"}];
_target setVariable ["Waldo_MHQ_LocalActionsInstalled", true];
diag_log format ["[WMP MHQ] Local actions installed target=%1 mode=%2 owner=%3", netId _target, _target getVariable ["Waldo_MHQ_InteractionMode", "NONE"], clientOwner];
true
