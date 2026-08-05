/*
 * Author: WaldoTheWarfighter, Val
 * Installs repeat-safe local transport-service controls. Remote pickup requests are player self-
 * actions; destination and RTB controls become available only while inside the reserved service
 * vehicle. ACE Interact is preferred and vanilla actions preserve the essential path otherwise.
 * Locality and authority: interface-client only; actions submit requests but never reserve or move assets.
 *
 * Arguments: None.
 * Return Value: Boolean - true when installed or already present.
 * Example: [] call Waldo_fnc_TransportInteractionInitLocal;
 * Current callers: object-keyed JIP registration from Waldo_fnc_TransportRegister and respawn init.
 */
if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_Transport_InteractionsInstalled", false]) exitWith {true};
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    [] call Waldo_fnc_SetupUiCleanupAction;
    private _root = ["Waldo_Transport_Root", "Transport Services", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _root] call ace_interact_menu_fnc_addActionToObject;
    private _heli = ["Waldo_Transport_RequestHeli", "Request Helicopter Pickup", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {["REQUEST_PICKUP", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_HeliTransport_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Transport_Root"], _heli] call ace_interact_menu_fnc_addActionToObject;
    private _ground = ["Waldo_Transport_RequestGround", "Request Ground Taxi", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa", {["REQUEST_PICKUP", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_GroundTaxi_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Transport_Root"], _ground] call ace_interact_menu_fnc_addActionToObject;
    private _destination = ["Waldo_Transport_Destination", "Select Destination", "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa", {
        private _service = vehicle player;
        ["SET_DESTINATION", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service] call Waldo_fnc_TransportOpenMapLocal;
    }, {
        private _service = vehicle player;
        _service != player && {_service getVariable ["Waldo_TransportService_Registered", false]} && {_service getVariable ["Waldo_TransportService_State", ""] == "BOARDING"}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Transport_Root"], _destination] call ace_interact_menu_fnc_addActionToObject;
    private _rtb = ["Waldo_Transport_RTB", "Return Service to Base", "\a3\ui_f_oldman\data\igui\cfg\holdactions\meet_ca.paa", {
        private _service = vehicle player;
        ["RTB", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service, [], player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    }, {private _service = vehicle player; _service != player && {_service getVariable ["Waldo_TransportService_Registered", false]}}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot", "Waldo_Transport_Root"], _rtb] call ace_interact_menu_fnc_addActionToObject;
} else {
    player addAction ["<t color='#79C7FF'>Request Helicopter Pickup</t>", {["REQUEST_PICKUP", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -82, false, true, "", "missionNamespace getVariable ['Waldo_HeliTransport_Available',false]"];
    player addAction ["<t color='#79C7FF'>Request Ground Taxi</t>", {["REQUEST_PICKUP", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -83, false, true, "", "missionNamespace getVariable ['Waldo_GroundTaxi_Available',false]"];
};
player setVariable ["Waldo_Transport_InteractionsInstalled", true];
true
