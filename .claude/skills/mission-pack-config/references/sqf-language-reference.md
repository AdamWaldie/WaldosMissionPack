# SQF language reference (data types, control flow, scope)

Scope: the SQF language itself — types, control flow, scoping rules,
formatting, and compile mechanics. This is the "what does this syntax mean
and what can I do with this value" file. For *how a mission actually runs*
(execution model, locality, event handlers, `CfgFunctions`), see
`references/arma-scripting-architecture.md`. For *diagnosing a broken
script*, see `references/sqf-debugging.md`. Any WMP-specific variable,
function, or config field still routes to that feature's own
`references/*.md` file first — this file is vanilla SQF only.

## Core data types

### ARRAY

```sqf
private _arr = [1, 2, 3];
_arr select 0;                  // 1 — zero-indexed
_arr pushBack 4;                // appends 4, returns new index — [1,2,3,4]
_arr pushBackUnique 4;          // only appends if not already present
_arr deleteAt 0;                // removes index 0 in place — [2,3,4]
_arr append [5, 6];             // in-place concat — [2,3,4,5,6]
_arr + [7];                     // NON-destructive concat, returns a new array
_arr - [3];                     // returns a new array with all `3`s removed
count _arr;                     // length
_arr find 5;                    // index of first match, -1 if absent
_arr in 5;                      // BOOLEAN membership test — prefer this over `find` when you don't need the index
_arr arrayIntersect [3, 4, 9];  // elements present in both arrays
[3, 1, 2] call BIS_fnc_sortNumbers; // ascending sort helper (or plain `sort`/`[] call BIS_fnc_sortBy` for HashMap-friendly sorts)
{ _x > 2 } count _arr;          // count matching a condition
_arr apply { _x * 2 };          // returns a new array with the code applied to every element
```

`select` also supports a range: `_arr select [1, 2]` (start index, length).
A negative `select` index is invalid in SQF (unlike some languages) — use
`count _arr - 1` for "last element."

### STRING

```sqf
format ["Player %1 has %2 magazines", name player, count magazines player]; // %1/%2 placeholders, 1-indexed
"a" + "b";                       // concatenation — "ab"
toArray "abc";                   // [97, 98, 99] — character codes
toString [97, 98, 99];           // "abc" — inverse of toArray
splitString "a,b,c" ",";         // ["a", "b", "c"]
"hello" select [0, 3];           // substring — "hel" (STRING select also takes [start, length])
toUpper "abc"; toLower "ABC";
```

### NUMBER

No separate int/float type — every number is the same underlying type.
Standard arithmetic operators plus `min`/`max`/`abs`/`round`/`ceil`/`floor`.
Careful with equality on computed values — see "Common gotchas" below.

### BOOLEAN

`true`/`false`. Standard `&&`/`||`/`!`, plus `and`/`or`/`not` as
word-form aliases for the same operators.

### OBJECT

A reference to a unit/vehicle/static object. `objNull` is the canonical
"no object" value — test with `isNull _obj`, not `_obj == objNull`
(both work, but `isNull` is idiomatic and reads clearly). Never assume an
object variable is non-null just because it was assigned once — vehicles/units
can be deleted mid-mission while a script still holds a stale reference.

### GROUP

A reference to a unit group. `grpNull` is the empty-group equivalent of
`objNull`. `units _grp`, `leader _grp`, `groupId _grp` (the callsign),
`createGroup side`.

### SIDE

`west`, `east`, `independent` (also `resistance`, same side), `civilian`,
and `sideUnknown` (used as a sentinel/"don't care" value, e.g.
`Waldo_fnc_RecoveryRegisterWorkshop`'s "serviced side" argument accepts it
to mean "serve all sides," per `vehicle-recovery-rallies.md`).

### CODE

A `{ ... }` block is a first-class value — it can be stored in a variable,
passed as an argument, and `call`ed/`spawn`ed later:

```sqf
private _fnc = { params ["_a", "_b"]; _a + _b };
[1, 2] call _fnc;   // 3
```

This is how every callback-style WMP/ACE/CBA API works (e.g. ACE's
`condition`/`insertCode`/`code` action arguments, CBA's event-handler
callbacks) — the callback is just a CODE value the framework `call`s at the
right moment with a known `_this`/`params` shape.

### HashMap

```sqf
private _hm = createHashMap;
_hm set ["key", "value"];
_hm get "key";                       // "value", or nil if missing
_hm getOrDefault ["key", "fallback"]; // safer — never nil
_hm select "key";                    // newer alias for get, behaves the same
_hm deleteAt "key";
keys _hm; values _hm;                 // arrays of every key / every value
[_hm] call BIS_fnc_arrayFromHashMap; // or `toArray _hm` — pairs as [[k,v], ...]
createHashMapFromArray [["a", 1], ["b", 2]]; // build from [key, value] rows
```

WMP's `MissionConfig\*.sqf` files, most Zeus-module configuration payloads,
and Dynamic AA/AO/hazard/gunship registration calls all use HashMaps as
their argument shape (see `mission-configuration`-adjacent reference files
for real examples) — recognising this pattern is the fastest way to read an
unfamiliar WMP call.

### Config (class definitions, not runtime state)

`configFile >> "CfgSomething" >> "SomeClass"` walks Arma's **config tree** —
the compiled class hierarchy from every loaded `config.cpp`/`CfgPatches`
across the base game and every mod, not mission/runtime state:

```sqf
isClass (configFile >> "CfgPatches" >> "ace_main");             // does this class exist at all
getText (configFile >> "CfgVehicles" >> "B_Soldier_F" >> "displayName");
getNumber (configFile >> "CfgVehicles" >> "B_Soldier_F" >> "scope");
getArray (configFile >> "CfgVehicles" >> "B_Soldier_F" >> "weapons");
configName (configFile >> "CfgVehicles" >> "B_Soldier_F");       // "B_Soldier_F" back out as a string
configProperties [configFile >> "CfgVehicles" >> "B_Soldier_F"]; // enumerate every property entry
```

This is the exact mechanism behind the `CfgPatches` mod-detection guard
pattern already documented in `references/mod-detection.md`
(`isClass(configFile >> "CfgPatches" >> "ace_main")`) — the same
`configFile >> ... >>` chain works for any other config tree
(`CfgVehicles`, `CfgWeapons`, `CfgFactionClasses`, `CfgAmmo`) when
inspecting a classname's properties instead of just checking mod presence.
`description.ext` is itself a config file the mission compiles the same
way — see `arma-scripting-architecture.md`'s "Config architecture basics"
section for how `class CfgFunctions`/`class Header`/`class CfgDebriefing`
relate to this same tree.

## Control flow

```sqf
if (_condition) then { ... } else { ... };          // else is optional
for "_i" from 0 to (count _arr - 1) do { ... };     // classic counting loop
for "_i" from 10 to 0 step -1 do { ... };           // optional step, can count down
while { _condition } do { ... };                     // condition re-evaluated as CODE each iteration
{ ... } forEach _arr;                                // _x = current element, _forEachIndex = its index
switch (_value) do {
    case "a": { ... };
    case "b": { ... };
    default { ... };
};
```

`exitWith { ... }` inside an `if` short-circuits the *enclosing function*
(not just the `if` block) — this is the standard idiom behind every WMP
guard clause documented in `CLAUDE.md`'s "Guard clauses" section
(`if !(isServer) exitWith {};`). Using `exitWith` outside a function context
(e.g. bare in a script run with `execVM`) exits that script instead.

## Scope and declaration

```sqf
private _x = 1;         // explicit private declaration — the recommended default
_y = 1;                 // implicit — actually creates a GLOBAL variable unless
                         // an enclosing `private ["_y"]`/`params` already declared it locally
```

- Every `{ }` code block, `if`/`while`/`for`/`forEach` body, and function
  call introduces its own scope. A `private` variable declared inside one
  of these is **not visible** outside it.
- **Declare before use.** SQF does not hoist declarations — referencing a
  variable before its `private`/`params` line sees whatever that name
  resolves to in an *outer* scope (often nothing, producing "Undefined
  variable," or worse, an unrelated global of the same name that happens to
  exist). This is the classic "used before declared as private" gotcha:
  writing `_y = _x + 1; private _x = 5;` reads `_x` from whatever scope
  it was already visible in (or undefined) before the `private` line runs,
  not the value assigned on the next line.
- `params` both declares and assigns in one step — the preferred way to
  unpack `_this` at the top of a function, documented as WMP's own house
  convention in `CLAUDE.md`'s "Argument parsing" section (see any WMP
  function's own header, e.g. the call patterns in `acre2.md`, for real
  examples of the convention in practice).

## String/array formatting and round-tripping

```sqf
format ["%1 of %2", 3, 10];        // "3 of 10"
str [1, "a", true];                 // "[1,""a"",true]" — turns any value into its literal SQF text form
parseSimpleArray (str [1, 2, 3]);   // [1, 2, 3] — round-trips back to a real array
```

`str`/`parseSimpleArray` is the standard way to pass a complex value through
something that only accepts a STRING (a `setVariable`-published value read
back with `getVariable`, or a persistence layer like WMP's INIDBI2
integration in `persistence.md`).

## Compile mechanics

```sqf
private _code = compile "hint 'hi'";              // turns a STRING into a CODE value
private _code2 = compile preprocessFileLineNumbers "myScript.sqf"; // reads + preprocesses (#include, #define) a file into CODE
```

A `{ ... }` literal in source is already CODE — `compile` is for turning a
*string* (or a file's text, via `preprocessFileLineNumbers`) into CODE at
runtime. `CfgFunctions` (see `arma-scripting-architecture.md`) does this
automatically for every registered function at mission start, which is why
`Waldo_fnc_*` functions don't need a manual `compile` call at the point
they're used.

## Common gotchas (things that compile fine but behave wrong)

- **Floating-point equality.** `0.1 + 0.2 == 0.3` is not guaranteed `true`
  in SQF any more than in most languages using IEEE floats — compare with a
  tolerance (`abs (_a - _b) < 0.001`) instead of `==` for computed
  fractional values (fuel fractions, damage fractions, distances).
- **Array copy-by-reference vs by-value.** `private _b = _a;` makes `_b`
  point at the *same* array as `_a` — mutating `_b` (`pushBack`, `set`,
  `deleteAt`) mutates `_a` too. `private _b = +_a;` (unary `+`) makes a real
  shallow copy. This trips up anyone caching a HashMap's array value or
  passing an array into a function that mutates it in place expecting the
  caller's copy to be unaffected.
- **`forEach`/`for` scoping.** `_x` and `_forEachIndex` are only valid
  *inside* the `forEach` code block — don't expect them to leak out, and
  don't shadow `_x` with your own `private "_x"` inside the block (it's
  already implicitly private to that iteration).
- **`private` inside a loop runs every iteration.** `for "_i" from 0 to 9
  do { private _tmp = _i * 2; ... }` re-declares `_tmp` fresh each pass —
  this is usually what you want, but it means a `private` declared *outside*
  the loop and mutated inside without redeclaring keeps accumulating state
  across iterations, which is sometimes the actual bug when a loop's totals
  look wrong.
