/*
 * Author: Waldo
 * Execute purchase.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _purchaseName <STRING> - purchase name (optional, default: "")
 * 2: _origin <ARRAY> - origin (optional, default: [0, 0, 0])
 * 3: _caller <OBJECT> - caller (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _purchaseName, _origin, _caller] call Waldo_fnc_EcoBuy_executePurchase;
 */

        params [["_sideKey", "NONE"], ["_purchaseName", ""], ["_origin", [0, 0, 0]], ["_caller", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_purchaseName isEqualTo "") exitWith {};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_caller] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {};

        private _entry = (call Waldo_fnc_EcoBuy_getPurchaseCatalog) select {
            (toLower (_x param [0, ""])) isEqualTo (toLower _purchaseName)
        } param [0, []];
        if ((count _entry) <= 0) exitWith {};
        if ([_entry, call Waldo_fnc_EcoBuy_getPurchaseCatalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_canSideUsePurchase) exitWith {};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_arePurchaseRequirementsMetForSide) exitWith {
            [_caller, format ["%1: requirements not met.", _purchaseName]] call Waldo_fnc_EcoCore_notifyActor;
        };
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_canAffordPurchaseForSide) exitWith {
            [_caller, format ["%1: not enough resources.", _purchaseName]] call Waldo_fnc_EcoCore_notifyActor;
        };

        private _className = _entry param [4, ""];
        if (_className isEqualTo "" || {!(isClass (configFile >> "CfgVehicles" >> _className))}) exitWith {};

        private _dropRow = [(_entry param [5, "Ground"]), _origin, _className, _sideKey] call Waldo_fnc_EcoBuy_findAvailableDropPoint;
        if ((count _dropRow) <= 0) exitWith {
            [_caller, format ["%1: no available drop point in range.", _purchaseName]] call Waldo_fnc_EcoCore_notifyActor;
        };

        {
            [_sideKey, _x param [0, ""], -(_x param [1, 0]), _purchaseName] call Waldo_fnc_EcoResource_addSideResourceAmount;
        } forEach (_entry param [2, []]);

        private _pos = _dropRow param [2, [0, 0, 0]];
        private _dir = _dropRow param [3, 0];
        private _spawned = createVehicle [_className, _pos, [], 0, "CAN_COLLIDE"];
        _spawned setDir _dir;
        _spawned setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];

        [[_spawned], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        [_caller, format ["%1 purchased - delivered to the drop point.", _purchaseName]] call Waldo_fnc_EcoCore_notifyActor;

