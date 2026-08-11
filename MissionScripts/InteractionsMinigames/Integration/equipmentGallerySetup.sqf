/*
 * Author: WaldoTheWarfighter
 * Installs a local "Open Field Equipment Gallery" interaction on the given object, opening the
 * developer/tester picker for all ten field-equipment procedures via Waldo_fnc_MiniGameEquipmentGallery.
 * ACE and vanilla routes may coexist because the visible vanilla action is a useful discoverability
 * cue; both routes call the same public gallery function. Safe to call directly from an object's own
 * Eden init field on every machine - it only touches client-local interaction menus.
 *
 * Arguments:
 * 0: target <OBJECT> - Object to receive the action
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this] call Waldo_fnc_MiniGameEquipmentGallerySetup;
 */

params ["_target"];

if (isNull _target) exitWith {};
if !(hasInterface) exitWith {};

// Prevent duplicate actions if the object's init runs more than once on this machine (e.g. JIP replay).
private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _aceReady = _aceLoaded
    && {!(isNil "ace_interact_menu_fnc_createAction")}
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")}
    && {!(isNil "ace_common_fnc_canInteractWith")};

if (_aceLoaded && {!_aceReady}) then {
    if !(_target getVariable ["Waldo_EquipmentGalleryActionPending", false]) then {
        _target setVariable ["Waldo_EquipmentGalleryActionPending", true];
        [_target] spawn {
            params ["_target"];
            waitUntil {uiSleep 0.1; isNull _target || {!(isNil "ace_interact_menu_fnc_createAction")}};
            if (!isNull _target) then {
                _target setVariable ["Waldo_EquipmentGalleryActionPending", false];
                [_target] call Waldo_fnc_MiniGameEquipmentGallerySetup;
            };
        };
    };
    false
};

if (_aceReady && {!(_target getVariable ["Waldo_EquipmentGalleryACEActionInstalled", false])}) then {
    private _action = [
        "Waldo_EquipmentGallery", "Open Field Equipment Gallery",
        "\a3\ui_f\data\igui\cfg\actions\repair_ca.paa",
        {[] call Waldo_fnc_MiniGameEquipmentGallery;},
        {params ["_target", "_player"]; alive _player && {_player distance _target < 6} && {[_player, _target, []] call ace_common_fnc_canInteractWith}}
    ] call ace_interact_menu_fnc_createAction;
    private _path = [_target, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    _target setVariable ["Waldo_EquipmentGalleryACEActionPath", _path];
    _target setVariable ["Waldo_EquipmentGalleryACEActionInstalled", true];
};

if !(_target getVariable ["Waldo_EquipmentGalleryVanillaActionInstalled", false]) then {
    private _id = _target addAction [
        "<t color='#79C7FF'>Open Field Equipment Gallery</t>",
        {[] call Waldo_fnc_MiniGameEquipmentGallery;}, nil, 1.5, true, true, "",
        "alive _this && {_this distance _target < 6}", 6
    ];
    _target setVariable ["Waldo_EquipmentGalleryVanillaActionId", _id];
    _target setVariable ["Waldo_EquipmentGalleryVanillaActionInstalled", _id >= 0];
};

_target setVariable ["Waldo_EquipmentGalleryActionAdded", true];
_target setVariable ["Waldo_EquipmentGalleryInteractionMode", if (_aceReady) then {"ACE+VANILLA"} else {"VANILLA"}];
true
