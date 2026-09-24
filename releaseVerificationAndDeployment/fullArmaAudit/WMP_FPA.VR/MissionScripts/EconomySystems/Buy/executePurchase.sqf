/*
 * Author: WaldoTheWarfighter
 * Purpose: Debits a validated economy purchase and creates it at its selected
 * drop point. A purchased supply/ammunition crate joins WMP crate logistics.
 * Locality / Authority: Runs on the economy authority; the created object and
 * cargo permissions are published from the server.
 * Repeat / JIP: Each accepted call is a new purchase. ACE drag/carry and
 * optional logistics registration replay to joining clients.
 *
 * Arguments:
 * 0: side key <STRING> (default "NONE")
 * 1: purchase name <STRING> (default "")
 * 2: origin <ARRAY> (default [0, 0, 0])
 * 3: requesting player <OBJECT> (default objNull)
 *
 * Return Value:
 * Nothing; the buyer receives WMP feedback on success or rejection.
 *
 * Example:
 * ["WEST", "Supply Crate", getPosATL player, player] call Waldo_fnc_EcoBuy_executePurchase;
 * Current callers: Economy Buy request handling.
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
        if (_spawned isKindOf "ReammoBox_F") then {
            [_spawned, "CARGO"] spawn Waldo_fnc_LogisticsRegisterSpawned;
        };

        [[_spawned], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        [_caller, format ["%1 purchased - delivered to the drop point.", _purchaseName]] call Waldo_fnc_EcoCore_notifyActor;

