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
    private _multiple = ["Waldo_Transport_Multiple", "Multiple Transports", "\a3\ui_f\data\igui\cfg\simpletasks\types\meet_ca.paa", {}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root"], _multiple] call ace_interact_menu_fnc_addActionToObject;
    private _allHeliPickup = ["Waldo_Transport_AllHeliPickup", "Request All Available Helicopter Transports", "\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa", {["PICKUP_ALL", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_HeliTransport_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root", "Waldo_Transport_Multiple"], _allHeliPickup] call ace_interact_menu_fnc_addActionToObject;
    private _allGroundPickup = ["Waldo_Transport_AllGroundPickup", "Request All Available Ground Transports", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa", {["PICKUP_ALL", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, {missionNamespace getVariable ["Waldo_GroundTransport_Available", false]}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root", "Waldo_Transport_Multiple"], _allGroundPickup] call ace_interact_menu_fnc_addActionToObject;
    private _allHeliRtb = ["Waldo_Transport_AllHeliRtb", "Return All Controlled Helicopter Transports to Base", "\a3\ui_f\data\igui\cfg\simpletasks\types\land_ca.paa", {["RTB_ALL", "HELICOPTER", [], player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2]}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root", "Waldo_Transport_Multiple"], _allHeliRtb] call ace_interact_menu_fnc_addActionToObject;
    private _allGroundRtb = ["Waldo_Transport_AllGroundRtb", "Return All Controlled Ground Transports to Base", "\a3\ui_f\data\igui\cfg\simpletasks\types\land_ca.paa", {["RTB_ALL", "GROUND", [], player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2]}, {true}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_Logistics_SelfRoot", "Waldo_Transport_Root", "Waldo_Transport_Multiple"], _allGroundRtb] call ace_interact_menu_fnc_addActionToObject;
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
    player addAction ["<t color='#79C7FF'>Request All Available Helicopter Transports</t>", {["PICKUP_ALL", "HELICOPTER", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -86, false, true, "", "missionNamespace getVariable ['Waldo_HeliTransport_Available',false]"];
    player addAction ["<t color='#79C7FF'>Request All Available Ground Transports</t>", {["PICKUP_ALL", "GROUND", objNull] call Waldo_fnc_TransportOpenMapLocal}, [], -87, false, true, "", "missionNamespace getVariable ['Waldo_GroundTransport_Available',false]"];
    player addAction ["<t color='#79C7FF'>Return All Controlled Helicopter Transports to Base</t>", {["RTB_ALL", "HELICOPTER", [], player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2]}, [], -88, false, true];
    player addAction ["<t color='#79C7FF'>Return All Controlled Ground Transports to Base</t>", {["RTB_ALL", "GROUND", [], player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2]}, [], -89, false, true];
};
player setVariable ["Waldo_Transport_InteractionsInstalled", true];
true
