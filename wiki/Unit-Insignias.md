# Unit Insignia Textures

> **Use this page when:** you want to show a WMP insignia texture in the mission or configure a real unit patch.

WMP includes `.paa` images in `UnitInsignias/`. The images are assets. Copying them into a
mission does not register unit insignia classes or apply a patch to a soldier. Eden's
**User Texture** object can display one of these images as a world object. A uniform
patch uses Arma's separate `CfgUnitInsignia` system.

The insignia files may be distributed separately as `WMP_UnitInsignias-vX.X.X.zip` on
the [releases page](https://github.com/AdamWaldie/WaldosMissionPack/releases/latest).
Check that the `.paa` files are present in your mission's `UnitInsignias/` folder
before using a path from the examples below.

## Show a texture on a world object

1. In Eden, place a **User Texture** object.
2. Open that object's Attributes and find its texture path.
3. Enter `UnitInsignias\1-1.paa`, replacing the filename if you chose another image.

This creates an in-world textured object. It does not change any unit's uniform. The
shipped `UnitInsignias/How to make these work.txt` describes this same User Texture
method.

## Put a patch on a unit

Register the texture as a `CfgUnitInsignia` class in your mission's `description.ext`.
Then apply that class to the unit. For example:

```sqf
// description.ext
class CfgUnitInsignia {
    class WMP_1_1 {
        displayName = "1-1";
        author = "WaldoTheWarfighter";
        texture = "UnitInsignias\1-1.paa";
        textureVehicle = "";
    };
};
```

In the unit's Eden Init field:

```sqf
[this, "WMP_1_1"] call BIS_fnc_setUnitInsignia;
```

| Input | Type | What it means |
| --- | --- | --- |
| `UnitInsignias\1-1.paa` | Texture-path String | An image file packed with the mission. |
| `WMP_1_1` | `CfgUnitInsignia` class-name String | The name registered in `description.ext`; pass this name to the function, not the `.paa` path. |
| `this` | Object | The unit whose insignia is set by the Eden Init call. |
| `BIS_fnc_setUnitInsignia` result | Boolean | `true` if Arma applied the registered class. |

Arma's function applies this patch. WMP has no feature toggle for it. The unit model needs an
insignia selection. If a respawn system replaces the unit, check the replacement unit
and reapply the class through that system when needed. Test the texture on a connected
client as well as the host, because mission-defined insignia texture paths can differ
between server and client contexts. See Bohemia's [Unit Insignia guide](https://community.bohemia.net/wiki/Arma_3:_Unit_Insignia)
and [function reference](https://community.bohemia.net/wiki/BIS_fnc_setUnitInsignia).

## Use an insignia in the Virtual Vehicle Depot

The VVD reads registered classes from the add-on `CfgUnitInsignia` catalogue and offers
their textures only where a vehicle has a suitable insignia/decal selection. A loose
`.paa` file in `UnitInsignias/` will not appear in that chooser by itself. This vehicle
texture option is separate from applying a patch to a character.

## If an image does not appear

For a User Texture object, confirm the file is inside the packed mission and check its
relative path. For a unit patch, confirm the `CfgUnitInsignia` class exists, the Init
field passes that class name, and the unit supports insignias. For VVD, check that an
add-on registered the class and that the vehicle exposes a supported texture point.

## See also

- [Virtual Vehicle Depot](Virtual-Vehicle-Depot)
- [Feature Configuration Files](Feature-Configuration-Files)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
