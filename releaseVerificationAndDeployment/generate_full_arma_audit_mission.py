#!/usr/bin/env python3
"""Generate the checked-in, unbinarized WMP full-pack Arma audit mission.

This is the canonical repository-to-mission generator. It deliberately writes an
Eden-format mission.sqm whose playable-unit inventories are the data consumed by
Waldo_fnc_MissionSQMLookup. It also inventories every registered public function
and assigns it to one physical subsystem station.
"""

from __future__ import annotations

import json
import math
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
MISSION = AUDIT / "WMP_FPA.VR"
FUNCTION = re.compile(
    r'class\s+([A-Za-z0-9_]+)\s*\{\s*file\s*=\s*"([^"]+\.sqf)"', re.IGNORECASE
)
RUNTIME_FUNCTION = re.compile(r"\b(Waldo_[A-Za-z0-9_]+_fnc_[A-Za-z0-9_]+)\s*=\s*\{")
VR_GROUND_ASL = 5.32


def fixture(name: str, classname: str, x: float, y: float, z: float = 0, direction: float = 0, simulation: bool = False) -> dict:
    return {
        "name": name,
        "class": classname,
        "pos": (x, y, z),
        "dir": direction,
        "simulation": simulation,
    }


STATIONS = [
    ("control", "AUDIT CONTROL", (-7, 2), "Navigation, resets, diagnostics and audit modes."),
    ("mission-init", "MISSION INITIALISATION", (18, 42), "Briefing, radios, vehicles and player setup."),
    ("mission-flow", "MISSION FLOW", (0, 39), "SafeStart, ENDEX/AAR, tasks, diagnostics and 3D markers."),
    ("ai", "AI / CONVOY", (28, 44), "AI tuning, convoy and mission-maker helpers."),
    ("loadouts", "LOADOUTS / CRATES", (-20, 40), "MissionSQM scrape, save points, supply and medical crates."),
    ("mhq", "MOBILE HQ", (-73, 45), "Complete MHQ deployment with every optional component."),
    ("vvd", "VEHICLE DEPOT", (-112, 39), "Isolated Virtual Vehicle Depot spawn and purge lane."),
    ("paradrop", "PARADROP", (-36, 68), "HALO, static-line and aircraft boarding paths."),
    ("economy-core", "ECONOMY CONTROL", (-82, 12), "Preset, persistence, diagnostics and setup export."),
    ("economy-resource", "ECONOMY RESOURCES", (-68, -4), "Zones, deposits, crates, collection and storage."),
    ("economy-research", "ECONOMY RESEARCH", (-78, 24), "Research centre, prerequisites and progression."),
    ("economy-build", "ECONOMY CONSTRUCTION", (-42, 20), "Construction vehicles, bases, placement and upgrades."),
    ("economy-buy", "ECONOMY PURCHASES", (-42, -14), "Purchase terminal, drop point and vehicle delivery."),
    ("economy-command", "GROUND COMMAND", (-86, -16), "Command, RADAR and commitment systems."),
    ("electronic-warfare", "ELECTRONIC WARFARE", (-8, -102), "Jamming, trackers, EMP and radio integration."),
    ("party", "PARTY TABLES", (0, 22), "All twelve table games and multiplayer lobby flows."),
    ("interaction-core", "FIELD PROCEDURES", (72, 66), "All ten interaction procedures and state integration."),
    ("zen", "ZEUS MODULES", (14, 54), "All WMP and Economy ZEN modules."),
    ("third-party", "THIRD-PARTY INTEGRATIONS", (34, 78), "Optional attributed integrations; opt-in only."),
    ("corpse-traps", "CORPSE TRAPS - QUARANTINED", (52, 78), "Present in the pack, excluded from automatic activation."),
    ("persistence", "PERSISTENCE", (150, 80), "Dependency gate, object registration, save-now and unavailable-state feedback."),
    ("treatment-feedback", "TREATMENT FEEDBACK", (175, 80), "Real ACE patient treatment and WMP notification feedback."),
    ("hazards", "HAZARDOUS ENVIRONMENTS", (200, 80), "Repeatable exposure zone, protection and runtime removal."),
    ("tree-felling", "TREE FELLING", (225, 80), "Cutting-tool validation, progress, replacement, yield and regrowth."),
    ("emergency-dismount", "EMERGENCY DISMOUNT", (250, 80), "Overturn detection, protected extraction and repeat reset."),
    ("accessibility", "ACCESSIBILITY PID", (150, 40), "Eligible-player friendly identification, LOS and toggle behavior."),
    ("breaching", "EXPLOSIVE BREACHING", (175, 40), "Configured wall, accumulated strength, replacement and reset."),
    ("object-transforms", "OBJECT TRANSFORMS", (200, 40), "Scale, reset, copy and transform helpers on physical props."),
    ("ai-rebalance", "AI REBALANCE", (225, 40), "Named profiles, live AI skill changes and restoration."),
    ("field-resupply", "FIELD RESUPPLY", (250, 40), "Finite hub stock, carrier crates, deployment, refill and salvage."),
    ("tactical-display", "TACTICAL DISPLAY", (150, 0), "Authenticated local tactical map with friendly and known-enemy filtering."),
    ("dynamic-aa", "DYNAMIC ANTI-AIR", (175, 0), "Named radar system, pooled assets, altitude detection and teardown."),
    ("gunship", "AIRBORNE GUNSHIP", (200, 0), "Registration, assignment, orbit, service and removal lifecycle."),
    ("vehicle-recovery", "VEHICLE RECOVERY", (225, 0), "Damage-gated packaging, carrier handling and keyed workshop restoration."),
    ("rally", "SQUAD RALLY", (250, 0), "Leader deployment, group respawn, regroup, expiry and removal."),
    ("nested-loadouts", "NESTED LOADOUT SCRAPE", (275, 0), "Playable inventories inside nested Eden folders feeding crate and arsenal pools."),
    ("dynamic-paradrop", "DYNAMIC PARADROP", (300, 40), "Server-owned DZ route, timed jumpers, operational markers and teardown."),
    ("ai-helicopter-landing", "AI HELICOPTER LANDING", (325, 40), "AI-only event-driven exact landing, canopy clearance, flare and go-around behavior."),
    ("ui-theme-qa", "UI THEME QA", (325, 0), "Live DEFAULT, WW2, VIETNAM and SCIFI visual-theme switching."),
    ("dynamic-ao", "DYNAMIC AO", (350, 0), "Runtime faction scan, randomized AO creation, tracked anchors and complete cleanup."),
]


FIXTURES = [
    fixture("qa_control_table", "Land_CampingTable_F", 0, 2),
    fixture("qa_control_console", "Land_Laptop_unfolded_F", 0, 2, 0.82, 180),
    fixture("qa_party_table_1", "Land_CampingTable_small_F", -7, 28, direction=180),
    fixture("qa_party_table_2", "Land_CampingTable_small_F", 7, 28, direction=180),
    fixture("qa_live_bomb", "Land_Device_assembled_F", 80, -94),
    fixture("qa_economy_crate", "Land_PlasticCase_01_medium_F", -61, -3),
    fixture("qa_economy_research", "Land_Research_HQ_F", -63, 12),
    fixture("qa_economy_construction", "B_Truck_01_box_F", -48, 16, direction=90),
    fixture("qa_economy_base", "Land_RepairDepot_01_green_F", -38, 10, direction=270),
    fixture("qa_economy_table", "Land_CampingTable_F", -48, -5, direction=90),
    fixture("qa_economy_terminal", "Land_Laptop_unfolded_F", -48, -5, 0.82, 90),
    fixture("qa_mhq", "B_Truck_01_covered_F", -62, 45, direction=90),
    fixture("qa_mhq_table", "Land_CampingTable_F", -62, 33),
    fixture("qa_mhq_chair", "Land_CampingChair_V2_F", -56, 33, direction=180),
    fixture("qa_mhq_tent", "Land_TentA_F", -74, 33, direction=90),
    fixture("qa_mhq_crate", "Box_NATO_Equip_F", -68, 21),
    fixture("qa_mhq_antenna", "Land_TTowerSmall_1_F", -80, 45),
    fixture("qa_mhq_light", "Land_PortableLight_double_F", -50, 45, direction=225),
    fixture("qa_vvd_pad", "Land_JumpTarget_F", -105, 48),
    fixture("qa_vvd_table", "Land_CampingTable_F", -105, 34),
    fixture("qa_vvd_laptop", "Land_Laptop_unfolded_F", -105, 34, 0.82),
    fixture("qa_drop_aircraft", "B_Heli_Transport_01_F", -30, 55, 55, 180),
    fixture("qa_drop_flag", "FlagPole_F", -35, 38),
    fixture("qa_loadout_save", "Box_NATO_Equip_F", 2, 45),
    fixture("qa_supply_crate", "B_supplyCrate_F", -14, 48),
    fixture("qa_medical_crate", "ACE_medicalSupplyCrate_advanced", -26, 48),
    fixture("qa_core_console", "Land_Laptop_unfolded_F", 10, 45, direction=180),
    fixture("qa_convoy_1", "B_MRAP_01_F", 28, 54),
    fixture("qa_convoy_2", "B_MRAP_01_F", 28, 70),
    fixture("qa_ew_jammer", "Land_TTowerSmall_1_F", 0, -102),
    fixture("qa_ew_tracked", "O_MRAP_02_F", -18, -102, direction=90),
    fixture("qa_ew_immune", "B_MRAP_01_F", 18, -102, direction=270),
    fixture("qa_persistence_object", "Box_NATO_Equip_F", 150, 87),
    fixture("qa_hazard_emitter", "Land_Device_assembled_F", 200, 88),
    fixture("qa_tree", "Land_TreeBin_F", 225, 87),
    fixture("qa_dismount_vehicle", "B_MRAP_01_F", 250, 88, direction=90),
    fixture("qa_breach_wall", "Land_City2_8m_F", 175, 47, direction=90),
    fixture("qa_tactical_console", "Land_MapBoard_F", 150, 7, direction=180),
    fixture("qa_scale_small", "Land_CampingChair_V2_F", 193, 47),
    fixture("qa_scale_source", "Land_CampingChair_V2_F", 200, 47),
    fixture("qa_scale_target", "Land_CampingChair_V2_F", 207, 47),
    fixture("qa_resupply_hub", "B_supplyCrate_F", 250, 47),
    fixture("qa_recovery_workshop", "Land_RepairDepot_01_green_F", 225, 14),
    fixture("qa_recovery_vehicle", "B_MRAP_01_F", 217, 7, direction=90),
    # The V-44 has a broad physics envelope. Keep it clear of the workshop,
    # damaged vehicle, station sign and adjacent feature stations at activation.
    fixture("qa_recovery_carrier", "B_MRAP_01_F", 225, -28),
    fixture("qa_loadout_arsenal", "B_supplyCrate_F", 275, 7),
    fixture("qa_ai_helicopter_landing_pad", "Land_HelipadCircle_F", 325, 70),
]

CHALLENGES = [
    "wirecut", "minesweeper", "keypad", "lockpick", "circuit",
    "repair", "radiotune", "pressure", "sequence", "commandinput",
]
CHALLENGE_CLASSES = {
    "wirecut": "Land_Device_assembled_F",
    "minesweeper": "Land_Laptop_unfolded_F",
    "keypad": "Land_Laptop_03_sand_F",
    "lockpick": "Land_MetalCase_01_small_F",
    "circuit": "Land_PortableServer_01_sand_F",
    "repair": "Land_ToolTrolley_02_F",
    # Land_Radio_F was removed from current Arma 3. This vanilla field server
    # remains visually appropriate and is already exercised elsewhere here.
    "radiotune": "Land_PortableServer_01_sand_F",
    "pressure": "Land_Pipes_small_F",
    "sequence": "Land_Computer_01_sand_F",
    "commandinput": "Land_Laptop_03_sand_F",
}
DIFFICULTIES = ["easy", "standard", "hard", "expert"]
for row, challenge in enumerate(CHALLENGES):
    for column, difficulty in enumerate(DIFFICULTIES):
        object_class = CHALLENGE_CLASSES[challenge]
        FIXTURES.append(fixture(
            f"qa_interaction_{challenge}_{difficulty}", object_class,
            80 + column * 14, 60 - row * 14, direction=270,
        ))

for index, (station_id, _title, (x, y), _description) in enumerate(STATIONS):
    variable_id = station_id.replace("-", "_")
    FIXTURES.append(fixture(f"qa_sign_{variable_id}", "Land_InfoStand_V2_F", x, y))


LOADOUTS = [
    {
        "name": "qa_player_1", "role": "Audit Commander", "type": "B_Soldier_SL_F",
        "primary": "arifle_MX_GL_Hamr_pointer_F", "primary_mag": "30Rnd_65x39_caseless_mag",
        "handgun": "hgun_P07_F", "handgun_mag": "16Rnd_9x21_Mag", "binocular": "Rangefinder",
        "uniform": "U_B_CombatUniform_mcam_vest", "vest": "V_PlateCarrierGL_rgr",
        "backpack": "B_AssaultPack_mcamo", "headgear": "H_HelmetB_desert",
        "optics": "optic_Hamr", "muzzle": "muzzle_snds_H", "flashlight": "acc_pointer_IR",
        "items": ["ACE_MapTools", "ACE_microDAGR", "ACE_CableTie"],
    },
    {
        "name": "qa_player_2", "role": "Audit Medic", "type": "B_medic_F",
        "primary": "arifle_MXC_Black_F", "primary_mag": "30Rnd_65x39_caseless_black_mag",
        "handgun": "hgun_P07_F", "handgun_mag": "16Rnd_9x21_Mag", "binocular": "Binocular",
        "uniform": "U_B_CombatUniform_mcam", "vest": "V_PlateCarrier1_rgr",
        "backpack": "B_Kitbag_rgr", "headgear": "H_HelmetB_light",
        "optics": "optic_Holosight_blk_F", "muzzle": "", "flashlight": "acc_flashlight",
        "items": ["ACE_fieldDressing", "ACE_tourniquet", "ACE_epinephrine", "ACE_morphine"],
    },
    {
        "name": "qa_player_3", "role": "Audit Anti-Tank", "type": "B_soldier_AT_F",
        "primary": "arifle_MX_Black_F", "primary_mag": "30Rnd_65x39_caseless_black_mag",
        "secondary": "launch_NLAW_F", "secondary_mag": "NLAW_F",
        "handgun": "hgun_P07_F", "handgun_mag": "16Rnd_9x21_Mag", "binocular": "Binocular",
        "uniform": "U_B_CombatUniform_mcam", "vest": "V_PlateCarrier2_rgr",
        "backpack": "B_Carryall_mcamo", "headgear": "H_HelmetB",
        "optics": "optic_Arco_blk_F", "muzzle": "", "flashlight": "acc_pointer_IR",
        "items": ["ACE_RangeCard", "ACE_SpareBarrel"],
    },
    {
        "name": "qa_player_4", "role": "Audit Engineer EOD", "type": "B_engineer_F",
        "primary": "arifle_MX_SW_Black_F", "primary_mag": "100Rnd_65x39_caseless_black_mag",
        "handgun": "hgun_ACPC2_F", "handgun_mag": "9Rnd_45ACP_Mag", "binocular": "Binocular",
        "uniform": "U_B_CombatUniform_mcam_tshirt", "vest": "V_Chestrig_rgr",
        "backpack": "B_Kitbag_mcamo", "headgear": "H_HelmetB_Enh_tna_F",
        "optics": "optic_ERCO_blk_F", "muzzle": "", "flashlight": "acc_flashlight",
        "items": ["ToolKit", "MineDetector", "ACE_Clacker", "ACE_DefusalKit", "ACE_EntrenchingTool"],
    },
    {
        "name": "qa_player_5", "role": "Audit Marksman", "type": "B_soldier_M_F",
        "primary": "srifle_DMR_03_F", "primary_mag": "20Rnd_762x51_Mag",
        "handgun": "hgun_Pistol_heavy_01_F", "handgun_mag": "11Rnd_45ACP_Mag", "binocular": "Laserdesignator",
        "uniform": "U_B_CombatUniform_mcam", "vest": "V_PlateCarrier1_blk",
        "backpack": "B_AssaultPack_blk", "headgear": "H_Booniehat_mcamo",
        "optics": "optic_AMS", "muzzle": "muzzle_snds_B", "flashlight": "acc_pointer_IR",
        "items": ["ACE_Kestrel4500", "ACE_ATragMX", "ACE_DAGR"],
    },
]


def n(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else f"{value:.4f}".rstrip("0").rstrip(".")


def cargo_block(name: str, values: list[str], magazine: bool = False) -> str:
    rows = []
    for index, value in enumerate(values):
        ammo = "\n                                    ammoLeft=1;" if magazine else ""
        rows.append(
            f'                                class Item{index} {{name="{value}"; count=1;{ammo}\n                                }};'
        )
    return f"""                            class {name}
                            {{
                                items={len(rows)};
{chr(10).join(rows)}
                            }};"""


def weapon_block(slot: str, weapon: str, magazine: str, loadout: dict) -> str:
    optional = ""
    if slot == "primaryWeapon":
        for field in ("optics", "muzzle", "flashlight"):
            value = loadout.get(field, "")
            if value:
                optional += f'                            {field}="{value}";\n'
    return f"""                        class {slot}
                        {{
                            name="{weapon}";
{optional}                            class primaryMuzzleMag {{name="{magazine}"; ammoLeft=1;}};
                        }};"""


def unit_block(index: int, loadout: dict) -> str:
    secondary = ""
    if loadout.get("secondary"):
        secondary = "\n" + weapon_block("secondaryWeapon", loadout["secondary"], loadout["secondary_mag"], loadout)
    magazines = [loadout["primary_mag"], loadout["primary_mag"], loadout["handgun_mag"], "SmokeShell"]
    inventory = f"""                    class Inventory
                    {{
{weapon_block('primaryWeapon', loadout['primary'], loadout['primary_mag'], loadout)}
{weapon_block('handgun', loadout['handgun'], loadout['handgun_mag'], loadout)}{secondary}
                        class binocular {{name="{loadout['binocular']}";}};
                        class uniform
                        {{
                            typeName="{loadout['uniform']}";
                            isBackpack=0;
{cargo_block('MagazineCargo', magazines, True)}
{cargo_block('ItemCargo', loadout['items'])}
                        }};
                        class vest {{typeName="{loadout['vest']}"; isBackpack=0;}};
                        class backpack {{typeName="{loadout['backpack']}"; isBackpack=1;}};
                        map="ItemMap";
                        compass="ItemCompass";
                        watch="ItemWatch";
                        radio="ItemRadio";
                        gps="ItemGPS";
                        hmd="NVGoggles";
                        headgear="{loadout['headgear']}";
                    }};"""
    player_flag = "                    isPlayer=1;\n" if index == 0 else "                    isPlayable=1;\n"
    return f"""            class Item{index}
            {{
                dataType="Object";
                class PositionInfo {{position[]={{{index * 2},{VR_GROUND_ASL},0}}; angles[]={{0,0,0}};}};
                side="West";
                flags=7;
                class Attributes
                {{
                    rank="{('CAPTAIN' if index == 0 else 'PRIVATE')}";
                    name="{loadout['name']}";
                    description="{loadout['role']}@WMP Audit";
{player_flag}{inventory}
                }};
                id={10 + index};
                type="{loadout['type']}";
            }};"""


def object_block(item_index: int, object_id: int, item: dict) -> str:
    x, y, z = item["pos"]
    angle = math.radians(item["dir"])
    # Every pre-staged fixture begins inert. featureRangeServer.sqf deliberately
    # enables only the systems selected for a live test after pack startup.
    init = "this allowDamage false; this enableSimulationGlobal false;"
    return f"""        class Item{item_index}
        {{
            dataType="Object";
            class PositionInfo {{position[]={{{n(x)},{n(VR_GROUND_ASL + z)},{n(y)}}}; angles[]={{0,{n(angle)},0}};}};
            side="Empty";
            flags=5;
            class Attributes {{name="{item['name']}"; init="{init}";}};
            id={object_id};
            type="{item['class']}";
        }};"""


def build_sqm() -> str:
    entities = []
    units = "\n".join(unit_block(index, loadout) for index, loadout in enumerate(LOADOUTS))
    entities.append(f"""        class Item0
        {{
            dataType="Group";
            side="West";
            class Entities
            {{
                items={len(LOADOUTS)};
{units}
            }};
            class Attributes {{}};
            id=1;
        }};""")
    entities.append("""        class Item1
        {
            dataType="Logic";
            class PositionInfo {position[]={0,5.32,5};};
            name="qa_curator";
            id=2;
            type="ModuleCurator_F";
            class CustomAttributes
            {
                class Attribute0
                {
                    property="ModuleCurator_F_Addons";
                    expression="_this setVariable ['Addons',_value,true];";
                    class Value {class data {class type {type[]={"SCALAR"};}; value=3;};};
                };
                nAttributes=1;
            };
        };""")
    for offset, item in enumerate(FIXTURES, start=2):
        entities.append(object_block(offset, 100 + offset, item))
    return f'''version=54;
binarizationWanted=0;
sourceName="FullArmaAudit.VR";
class EditorData {{moveGridStep=1; angleGridStep=0.2617994; scaleGridStep=1; autoGroupingDist=10; toggles=1; class ItemIDProvider {{nextID={200 + len(FIXTURES)};}}; class LayerIndexProvider {{nextID=1;}}; class Camera {{pos[]={{0,120,0}}; dir[]={{0,-1,0}}; up[]={{0,0,1}}; aside[]={{1,0,0}};}};}};
class Mission
{{
    addOns[]={{"A3_Characters_F_BLUFOR","A3_Characters_F_OPFOR","A3_Map_VR","A3_Structures_F","A3_Soft_F","A3_Air_F","A3_Modules_F_Curator","cba_main","ace_main"}};
    addOnsAuto[]={{"A3_Characters_F_BLUFOR","A3_Map_VR","A3_Structures_F","A3_Soft_F","A3_Modules_F_Curator","cba_main","ace_main"}};
    randomSeed=210032;
    class Intel {{briefingName="WMP FULL PACK AUDIT"; overviewText="Self-contained WMP development testbed."; year=2035; month=7; day=26; hour=12; minute=0; startWeather=0; forecastWeather=0;}};
    class Entities
    {{
        items={len(entities)};
{chr(10).join(entities)}
    }};
}};
'''


def station_for(path: str) -> str:
    normalized = path.replace("\\", "/").lower()
    rules = [
        ("persistence/", "persistence"), ("medicalsystems/treatmentfeedback", "treatment-feedback"),
        ("environmentalsystems/hazardousenvironments", "hazards"),
        ("environmentalsystems/treefelling", "tree-felling"),
        ("missioninit/vehicleactionssetup/emergencydismount", "emergency-dismount"),
        ("missionflowandui/accessibility", "accessibility"),
        ("combatsystems/breaching", "breaching"),
        ("missionmakerresourcescripts/objecttransforms", "object-transforms"),
        ("aiscripting/airebalance", "ai-rebalance"), ("aiscripting/aiapplyprofile", "ai-rebalance"),
        ("logistics/fieldresupply", "field-resupply"),
        ("missionflowandui/tacticaldisplay", "tactical-display"),
        ("combatsystems/dynamicaa", "dynamic-aa"),
        ("combatsystems/airbornegunship", "gunship"),
        ("logistics/vehiclerecovery", "vehicle-recovery"),
        ("respawn/rallypoint", "rally"),
        ("paradrop/paradropcreatedropzone", "dynamic-paradrop"),
        ("paradrop/paradropremovedropzone", "dynamic-paradrop"),
        ("paradrop/paradropdropzonezen", "dynamic-paradrop"),
        ("logistics/logihelpers/missionfilelookup", "nested-loadouts"),
        ("corpsetrap", "corpse-traps"), ("thirdpartyscripts", "third-party"),
        ("interactionsminigames", "interaction-core"), ("minigames", "party"),
        ("zenmodules", "zen"), ("economysystems/resource", "economy-resource"),
        ("economysystems/research", "economy-research"), ("economysystems/build", "economy-build"),
        ("economysystems/buy", "economy-buy"), ("economysystems/command", "economy-command"),
        ("economysystems", "economy-core"), ("missioninit/jamming", "electronic-warfare"),
        ("missioninit/electronicwarfare", "electronic-warfare"), ("paradrop", "paradrop"),
        ("logistics/mhq", "mhq"), ("logistics/virtualvehicledepot", "vvd"),
        ("logistics", "loadouts"), ("missionflowandui", "mission-flow"),
        ("aiscripting", "ai"), ("missionmakersourcescripts", "ai"),
        ("missionmakerresourcescripts", "ai"), ("missioninit", "mission-init"),
    ]
    return next((station for token, station in rules if token in normalized), "control")


def has_exact_path_case(root: Path, relative: str) -> bool:
    """Return true only when every path component uses its on-disk spelling."""
    current = root
    for part in Path(relative.replace("\\", "/")).parts:
        if not current.is_dir() or part not in {entry.name for entry in current.iterdir()}:
            return False
        current /= part
    return current.is_file()


def function_manifest() -> dict:
    text = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
    functions = []
    seen = set()
    for name, relative in FUNCTION.findall(text):
        public_name = f"Waldo_fnc_{name}"
        if public_name in seen:
            raise ValueError(f"Duplicate function registration: {public_name}")
        seen.add(public_name)
        normalized = relative.replace("\\", "/")
        if not has_exact_path_case(ROOT, normalized):
            raise FileNotFoundError(
                f"Registered function has no exact-case source file: {relative}"
            )
        station = station_for(normalized)
        functions.append({
            "name": public_name,
            "file": normalized,
            "station": station,
            "activation": "quarantined" if station == "corpse-traps" else "manual",
        })
    station_ids = {station[0] for station in STATIONS}
    unmapped = {entry["station"] for entry in functions} - station_ids
    if unmapped:
        raise ValueError(f"Function manifest references unknown stations: {sorted(unmapped)}")
    runtime_functions = []
    runtime_seen = set()
    for source in sorted((ROOT / "MissionScripts").rglob("*.sqf")):
        source_text = source.read_text(encoding="utf-8", errors="replace")
        relative = source.relative_to(ROOT).as_posix()
        for name in RUNTIME_FUNCTION.findall(source_text):
            if name in runtime_seen:
                raise ValueError(f"Duplicate runtime function definition: {name}")
            runtime_seen.add(name)
            runtime_functions.append({
                "name": name,
                "file": relative,
                "station": station_for(relative),
                "activation": "internal",
            })
    return {
        "schema": 1,
        "registeredFunctionCount": len(functions),
        "runtimeFunctionCount": len(runtime_functions),
        "functionCount": len(functions) + len(runtime_functions),
        "stations": [
            {"id": station_id, "title": title, "position": [x, y, 0], "description": description}
            for station_id, title, (x, y), description in STATIONS
        ],
        "functions": functions,
        "runtimeFunctions": runtime_functions,
    }


def write_function_station_sqf(manifest: dict) -> None:
    by_station: dict[str, list[str]] = {}
    for entry in manifest["functions"] + manifest["runtimeFunctions"]:
        by_station.setdefault(entry["station"], []).append(entry["name"])
    rows = []
    for station in manifest["stations"]:
        names = sorted(by_station.get(station["id"], []), key=str.casefold)
        sqf_names = ", ".join(f'"{name}"' for name in names)
        x, y, z = station["position"]
        rows.append(
            f'    ["{station["id"]}", "{station["title"]}", [{x}, {y}, {z}], '
            f'"{station["description"]}", [{sqf_names}]]'
        )
    text = (
        "/* Generated by generate_full_arma_audit_mission.py. */\n"
        "missionNamespace setVariable [\"Waldo_QA_FunctionStations\", [\n"
        + ",\n".join(rows)
        + "\n], true];\n"
    )
    write_text_if_changed(MISSION / "functionStations.sqf", text)


def write_text_if_changed(path: Path, text: str) -> None:
    """Avoid reopening identical OneDrive-backed generated files."""
    if path.is_file() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8", newline="\n")


def _sync_tree_in_place(source: Path, target: Path) -> None:
    """Mirror a source tree when a synced filesystem refuses to remove its root."""
    target.mkdir(parents=True, exist_ok=True)
    source_entries = {path.relative_to(source) for path in source.rglob("*")}
    for path in sorted(target.rglob("*"), key=lambda item: len(item.parts), reverse=True):
        if path.relative_to(target) in source_entries:
            continue
        if path.is_dir():
            try:
                path.rmdir()
            except PermissionError:
                # OneDrive can retain an ACL-protected, empty historical folder.
                # Empty directories are not mission inputs and may safely remain.
                if any(entry.is_file() for entry in path.rglob("*")):
                    raise
        else:
            path.unlink()
    shutil.copytree(source, target, dirs_exist_ok=True)


def refresh_release_sources() -> None:
    for directory in ("MissionScripts", "MissionConfig", "Pictures", "UnitInsignias"):
        source = ROOT / directory
        target = MISSION / directory
        # OneDrive can remove a hydrated file after rmtree enumerates it but before
        # unlink runs. Treat that one race as progress, retry the remaining tree,
        # and still fail if the directory cannot actually be cleared.
        removal_blocked = False
        for _attempt in range(3):
            if not target.exists():
                break
            try:
                shutil.rmtree(target)
            except FileNotFoundError:
                continue
            except PermissionError:
                removal_blocked = True
                break
        if target.exists():
            if removal_blocked and source.is_dir():
                _sync_tree_in_place(source, target)
                continue
            raise OSError(f"Could not clear stale audit source directory: {target}")
        if source.is_dir():
            shutil.copytree(source, target)
    shutil.copy2(ROOT / "economyConfig.sqf", MISSION / "economyConfig.sqf")
    shutil.copy2(ROOT / "MissionConfig" / "acreConfig.sqf", MISSION / "MissionConfig" / "releaseAcreConfig.sqf")
    pack_source = MISSION / "WMPPackSource"
    pack_source.mkdir(exist_ok=True)
    _sync_tree_in_place(ROOT / "MissionConfig", pack_source / "MissionConfig")
    for stale in (MISSION / "acreConfig.sqf", MISSION / "releaseAcreConfig.sqf", pack_source / "acreConfig.sqf"):
        stale.unlink(missing_ok=True)
    for name in ("description.ext", "init.sqf", "initPlayerLocal.sqf", "initServer.sqf", "economyConfig.sqf", "LICENSE", "README.md"):
        source = ROOT / name
        if source.is_file():
            shutil.copy2(source, pack_source / name)
    shutil.copy2(MISSION / "auditAcreConfig.sqf", MISSION / "MissionConfig" / "acreConfig.sqf")


def write_active_pack(destination: Path) -> None:
    """Write the real pack entry points with only pre/post audit hooks around them."""
    description = (ROOT / "description.ext").read_text(encoding="utf-8")
    description = "\n".join(line.rstrip() for line in description.splitlines()) + "\n"
    write_text_if_changed(destination / "description.ext", description)
    for name, pre_hook, post_hook in (
        ("init.sqf", "auditPreInit.sqf", "auditInit.sqf"),
        ("initServer.sqf", "auditPreInitServer.sqf", "auditInitServer.sqf"),
        ("initPlayerLocal.sqf", "auditPreInitPlayerLocal.sqf", "auditInitPlayerLocal.sqf"),
    ):
        source = (ROOT / name).read_text(encoding="utf-8")
        source = "\n".join(line.rstrip() for line in source.splitlines())
        wrapper = (
            "// Generated full-pack audit entry point. Keep the real pack lifecycle intact.\n"
            'call compile preprocessFileLineNumbers "auditBootstrap.sqf";\n'
            f'call compile preprocessFileLineNumbers "{pre_hook}";\n\n'
            f"{source.rstrip()}\n\n"
            f'call compile preprocessFileLineNumbers "{post_hook}";\n'
        )
        write_text_if_changed(destination / name, wrapper)


def main() -> int:
    MISSION.mkdir(parents=True, exist_ok=True)
    destination = MISSION / "mission.sqm"
    write_text_if_changed(destination, build_sqm())
    stale_loadout = MISSION / "auditLoadoutSQM.hpp"
    if stale_loadout.exists():
        stale_loadout.unlink()
    manifest = function_manifest()
    manifest_text = json.dumps(manifest, indent=2) + "\n"
    write_text_if_changed(AUDIT / "function_station_manifest.json", manifest_text)
    write_text_if_changed(MISSION / "function_station_manifest.json", manifest_text)
    write_function_station_sqf(manifest)
    shutil.copy2(AUDIT / "audit_manifest.json", MISSION / "audit_manifest.json")
    shutil.copy2(AUDIT / "fixture_manifest.json", MISSION / "fixture_manifest.json")
    refresh_release_sources()
    write_active_pack(MISSION)
    write_text_if_changed(MISSION / "auditBootstrap.sqf",
        'Waldo_QA_BootSuite = "all";\n'
        'Waldo_QA_ExpectedVersion = "DEVELOPMENT";\n'
        'Waldo_QA_RequiredPatches = ["cba_main", "ace_main", "zen_main", "acre_main"];\n'
        'Waldo_QA_RunAutomation = false;\n'
        'Waldo_QA_Mode = "MANUAL";\n',
    )
    sqm_bytes = destination.read_bytes()
    if not sqm_bytes.lstrip().startswith(b"version=54;") or b"binarizationWanted=0;" not in sqm_bytes:
        raise ValueError("Generated audit mission.sqm is not editable Eden text")
    print(
        f"Generated {destination} with {len(FIXTURES)} fixtures, {len(STATIONS)} stations "
        f"and {manifest['functionCount']} mapped functions "
        f"({manifest['registeredFunctionCount']} registered, {manifest['runtimeFunctionCount']} runtime)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
