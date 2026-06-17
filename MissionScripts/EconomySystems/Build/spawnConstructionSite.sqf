/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - spawnConstructionSite
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_spawnConstructionSite via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [
            ["_pos", [0, 0, 0]],
            ["_dir", 0],
            ["_sideKey", "NONE"],
            ["_buildName", "Build Site"]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {[]};

        private _items = [];
        private _makePos = {
            params ["_origin", "_heading", "_offsetX", "_offsetY", ["_offsetZ", 0]];
            private _rad = _heading * (pi / 180);
            [
                (_origin select 0) + (_offsetX * cos _rad) - (_offsetY * sin _rad),
                (_origin select 1) + (_offsetX * sin _rad) + (_offsetY * cos _rad),
                (_origin select 2) + _offsetZ
            ]
        };

        private _propDefs = [
            ["Land_WoodenCrate_01_stack_x3_F", -3.0, 1.8, 0, 20],
            ["Land_MobileScafolding_01_F", 2.8, 0.6, 0, 90],
            ["Land_BarrelWater_F", -1.2, -2.1, 0, 0],
            ["Land_FieldToilet_F", 3.0, -2.8, 0, 180],
            ["Land_Pallets_F", -2.6, -1.4, 0, 65]
        ];

        {
            private _spawnPos = [_pos, _dir, _x param [1, 0], _x param [2, 0], _x param [3, 0]] call _makePos;
            private _obj = createVehicle [_x param [0, ""], _spawnPos, [], 0, "CAN_COLLIDE"];
            _obj setDir (_dir + (_x param [4, 0]));
            _obj setPosATL _spawnPos;
            _obj allowDamage false;
            _obj enableSimulationGlobal false;
            _obj setVariable ["WaldoEcoBuild_IsConstructionSiteObject", true, true];
            _obj setVariable ["WaldoEcoBuild_BuildOwnerSideKey", _sideKey, true];
            _obj setVariable ["WaldoEcoBuild_BuildDefinitionName", _buildName, true];
            _items pushBack _obj;
        } forEach _propDefs;

        private _workerDefs = [
            [-0.7, 0.3, 0, 180, "Acts_carFixingWheel"],
            [1.3, -0.6, 0, 135, "Acts_TreatingWounded01"]
        ];

        {
            private _spawnPos = [_pos, _dir, _x param [0, 0], _x param [1, 0], _x param [2, 0]] call _makePos;
            private _anim = _x param [4, ""];
            private _worker = createAgent ["C_Man_ConstructionWorker_01_Blue_F", _spawnPos, [], 0, "CAN_COLLIDE"];
            _worker setDir (_dir + (_x param [3, 0]));
            _worker setPosATL _spawnPos;
            _worker allowDamage false;
            removeAllWeapons _worker;
            _worker setBehaviour "CARELESS";
            _worker setCombatMode "BLUE";
            doStop _worker;
            _worker disableAI "ANIM";
            _worker disableAI "AUTOTARGET";
            _worker disableAI "TARGET";
            _worker disableAI "FSM";
            _worker disableAI "PATH";
            _worker disableAI "MOVE";
            _worker switchMove _anim;
            [_worker, _anim] remoteExec ["switchMove", 0, _worker];
            _worker setVariable ["WaldoEcoBuild_IsConstructionSiteObject", true, true];
            _worker setVariable ["WaldoEcoBuild_BuildOwnerSideKey", _sideKey, true];
            _worker setVariable ["WaldoEcoBuild_BuildDefinitionName", _buildName, true];
            _items pushBack _worker;
        } forEach _workerDefs;

        [_items, true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        _items

