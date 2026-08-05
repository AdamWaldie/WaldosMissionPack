/*
 * Author: WaldoTheWarfighter, Val
 * Installs repeat-safe local transport-service controls. Remote pickup requests are player self-
 * actions. Named management controls list the player's exact active services, so a nearby or
 * occupied second transport cannot silently redirect an action intended for the first one.
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
    private _logistics = ["Waldo_Logistics_SelfRoot", "WMP Logistics", "\a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _logistics] call ace_interact_menu_fnc_addActionToObject;
    private _root = ["Waldo_Transport_Root", "Transport Services", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot"], _root] call ace_interact_menu_fnc_addActionToObject;
    private _heli = ["Waldo_Transport_RequestHeli", "Request Helicopter Pickup", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {["REQUEST_PICKUP", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, {
        private _uid = getPlayerUID player;
        missionNamespace getVariable ["Waldo_HeliTransport_Available", false] || {vehicles findIf {_x getVariable ["Waldo_TransportService_Type", ""] == "HELICOPTER" && {_x getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} >= 0}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _heli] call ace_interact_menu_fnc_addActionToObject;
    private _ground = ["Waldo_Transport_RequestGround", "Request Ground Transport", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa", {["REQUEST_PICKUP", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, {
        private _uid = getPlayerUID player;
        missionNamespace getVariable ["Waldo_GroundTransport_Available", false] || {vehicles findIf {_x getVariable ["Waldo_TransportService_Type", ""] == "GROUND" && {_x getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} >= 0}
    }] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _ground] call ace_interact_menu_fnc_addActionToObject;
    private _additionalHeli = ["Waldo_Transport_RequestAdditionalHeli", "Request Additional Helicopter Transport", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {["REQUEST_ADDITIONAL", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_HeliTransport_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _additionalHeli] call ace_interact_menu_fnc_addActionToObject;
    private _additionalGround = ["Waldo_Transport_RequestAdditionalGround", "Request Additional Ground Transport", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa", {["REQUEST_ADDITIONAL", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_GroundTransport_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _additionalGround] call ace_interact_menu_fnc_addActionToObject;
    private _manage = ["Waldo_Transport_Manage", "Manage Active Services", "\a3\ui_f\data\igui\cfg\simpletasks\types\documents_ca.paa", {}, {
        private _uid = getPlayerUID player;
        vehicles findIf {_x getVariable ["Waldo_TransportService_Registered", false] && {player in crew _x || {_uid != "" && {_x getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} || {!isNull getAssignedCuratorLogic player}}} >= 0
    }, {params ["_target", "_player"]; [_player] call Waldo_fnc_TransportManageChildrenLocal}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _manage] call ace_interact_menu_fnc_addActionToObject;
} else {
    player addAction ["<t color='#79C7FF'>Request Helicopter Pickup</t>", {["REQUEST_PICKUP", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -82, false, true, "", "private _uid = getPlayerUID _this; missionNamespace getVariable ['Waldo_HeliTransport_Available',false] || {vehicles findIf {_x getVariable ['Waldo_TransportService_Type',''] == 'HELICOPTER' && {_x getVariable ['Waldo_TransportService_RequesterUID',''] == _uid}} >= 0}"];
    player addAction ["<t color='#79C7FF'>Request Ground Transport</t>", {["REQUEST_PICKUP", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -83, false, true, "", "private _uid = getPlayerUID _this; missionNamespace getVariable ['Waldo_GroundTransport_Available',false] || {vehicles findIf {_x getVariable ['Waldo_TransportService_Type',''] == 'GROUND' && {_x getVariable ['Waldo_TransportService_RequesterUID',''] == _uid}} >= 0}"];
    player addAction ["<t color='#79C7FF'>Request Additional Helicopter Transport</t>", {["REQUEST_ADDITIONAL", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -84, false, true, "", "missionNamespace getVariable ['Waldo_HeliTransport_Available',false]"];
    player addAction ["<t color='#79C7FF'>Request Additional Ground Transport</t>", {["REQUEST_ADDITIONAL", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -85, false, true, "", "missionNamespace getVariable ['Waldo_GroundTransport_Available',false]"];
};
player setVariable ["Waldo_Transport_InteractionsInstalled", true];
true
