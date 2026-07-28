/* Return the valid objects in a typed economy runtime registry. */
params [["_key", ""]];
if (_key == "") exitWith {[]};
+((missionNamespace getVariable [format ["WaldoEcoCore_Runtime_%1", toUpper _key], []]) select {!isNull _x})
