# Economy — Buy system

Read `core.md` first for the enable flow and authority model.

## What it does

Purchase vehicles with configurable drop points and requirements.

## Setup entry points

```sqf
setPurchaseCatalog     // define purchasable vehicles and requirements
createDropPoint        // where purchased vehicles arrive
```

Or designate an existing Eden-placed object as a purchase terminal:

```sqf
[this] call Waldo_fnc_EcoBuy_registerTerminal;   // on a Land_Laptop_unfolded_F
```

## Object tagging

Purchase terminal: `Land_Laptop_unfolded_F`.

## Function namespace

Callable as `Waldo_fnc_EcoBuy_*`. Full function list isn't enumerated in
`CLAUDE.md` — check script headers under `MissionScripts/EconomySystems/Buy/`
or the wiki for exhaustive param detail beyond the entry points above.
