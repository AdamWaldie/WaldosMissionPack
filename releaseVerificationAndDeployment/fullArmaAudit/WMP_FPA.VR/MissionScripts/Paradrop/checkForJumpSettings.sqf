 /*
 This functions provides a means to check the vehicle (via ACE Interact) for Which jump settings are enabled, 
 and the requirements for their use. This is displayeed for the user

 Arguments:
 0: The Object

 Example:
 [variableName] call Waldo_fnc_JumpSettingsCheck;
 
 */

params ["_vehicle"];

//Check for, and exit if not present: ACE3
if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitWith {};

//Get Jump Variables
private _hasStaticJump = _vehicle getVariable ["Waldo_Static_Jump",[]];
private _hasHaloJump = _vehicle getVariable ["Waldo_Halo_Jump",[]];

private _statement = {
    params ["_target", "_player", "_args"];
    _args params ["_hasStaticJump", "_hasHaloJump"];

    if !(count _hasStaticJump == 0) then {
        [
            [],
            ["Static Line Jump", 1.2, [0, 1, 0, 1]],
            ["This aircraft is equipped with static"],
            ["line jump equipment!"],
            [""],
            [format ["Max Safe speed: <t color='#00fe37'>%1 KPH</t>", ((_hasStaticJump select 3) - 10)]],
            [format ["Altitude: <t color='#00fe37'>%1 to %2 METERS AGL</t>", _hasStaticJump select 1, _hasStaticJump select 2]],
            ["Door or ramp needs to be open."],
            [""],
            [""]
        ] call CBA_fnc_notify;
    };
    if !(count _hasHaloJump == 0) then {
        [
            [],
            ["HALO jump", 1.2, [0, 1, 0, 1]],
            ["This aircraft is equipped for high"],
            ["altitude low opening (HALO) jumping."],
            [""],
            [format ["Minimum altitude: <t color='#00fe37'>%1 METERS AGL</t>", _hasHaloJump select 1]],
            ["Door or ramp needs to be open."],
            [""],
            [""]
        ] call CBA_fnc_notify;
    };
};

private _checkLabel = "Check Jump Settings";

Waldo_PARA_Category = ["Waldo_PARA_Category" ,"Para Interactions", "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa", {true}, {true}] call ace_interact_menu_fnc_createAction;

_action = ["Waldo_Jump_Settings", _checkLabel, "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_takeOff1_ca.paa", _statement, {true}, {}, [_hasStaticJump, _hasHaloJump]] call ace_interact_menu_fnc_createAction;
[_vehicle, 1, ["ACE_SelfActions","Waldo_PARA_Category"], _action] call ace_interact_menu_fnc_addActionToObject;
