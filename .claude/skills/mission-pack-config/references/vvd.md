# Virtual Vehicle Depot (VVD) — WIP, not recommended for live missions

Always tell the user this is explicitly marked work-in-progress before
configuring it, and suggest **ACE Garage** instead for a fully stable
vehicle-spawning experience unless they specifically need VVD's feature set.

```sqf
[spawnerObject, helipad, types, allowedSides, sideCheck, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
// types: ["Auto"], ["Ground"], ["All"] or specific type strings
// allowedSides: ["ALL"], ["BLUFOR"], ["OPFOR"], ["INDEP"], ["CIV"]
```

## Known limitation

Depot vehicles and their (UAV) crew are created with
`createVehicle`/`createVehicleCrew` on whichever client pressed spawn.
Vehicle removal routes deletion to the vehicle's owning machine via
`Waldo_fnc_VVDPurgeVehicle` specifically because a client-side
`deleteVehicle`/`deleteVehicleCrew` issued from a *different* machine
silently no-ops on the remote object — this owner-routing fixes the
dominant cause of orphaned UAV crew, but a UAV with a player actively
connected via a terminal remains an engine edge case with no guaranteed
teardown.

If the user reports orphaned/duplicate vehicles or crew, this is the first
thing to check — and if VVD is core to their mission design, recommend
thorough testing with their exact mod set before relying on it live.
