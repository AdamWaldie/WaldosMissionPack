_Associated Files: UnitInsignias\_

WMP includes a set of pre-made unit insignia textures (`.paa` files) in the `UnitInsignias/` folder. These can be applied to player characters in Eden using Arma 3's built-in **User Texture** object.

Insignia files ship as a separate download (`WMP_UnitInsignias-vX.X.X.zip`) from the [releases page](https://github.com/AdamWaldie/WaldosMissionPack/releases/latest).

---

## Setup in Eden

1. In Eden, search for **"User texture"** in the asset search bar and place one near the unit you want to apply the insignia to.
2. Open the User Texture object's **Attributes** and scroll to the bottom.
3. In the texture path field, type the path to the insignia file:

```
UnitInsignias\1-1.paa
```

Replace `1-1.paa` with the filename of the insignia you want to use. Available files are in the `UnitInsignias/` folder of the mission.

---

## Adding Custom Insignias

To use your own unit insignia:

1. Create a `.paa` image (Arma 3's native texture format — convert from PNG using **TexView 2** in the Arma 3 Tools on Steam, or **GIMP with the `.pal` plugin**).
2. Place the `.paa` file in the `UnitInsignias/` folder.
3. Reference it in the User Texture attributes as shown above.

Recommended resolution: 512×512 or 256×256. The texture is applied as an insignia patch on the unit's uniform sleeve.

---

## VVD Insignia Integration

The [Virtual Vehicle Depot](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Virtual-Vehicle-Depot) garage interface also supports applying unit insignias to spawned vehicles where the vehicle model supports it.
