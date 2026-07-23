#!/usr/bin/env python3
"""Generate the original, dependency-free audio used by ACE corpse traps."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


RATE = 44_100
OUTPUT = Path(__file__).parents[1] / "MissionScripts" / "CorpseTraps" / "Audio"


def clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def write_wave(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = b"".join(struct.pack("<h", int(clamp(sample) * 32767)) for sample in samples)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)


def add_metal_click(samples: list[float], start: float, strength: float) -> None:
    start_index = int(start * RATE)
    length = int(0.11 * RATE)
    for offset in range(length):
        time = offset / RATE
        envelope = math.exp(-48 * time)
        tone = math.sin(2 * math.pi * 1750 * time) + 0.45 * math.sin(2 * math.pi * 3150 * time)
        samples[start_index + offset] += strength * envelope * tone


def make_plant() -> list[float]:
    randomizer = random.Random(1701)
    samples = [0.0] * int(1.35 * RATE)
    smoothed_noise = 0.0
    for index in range(len(samples)):
        time = index / RATE
        raw_noise = randomizer.uniform(-1, 1)
        smoothed_noise = 0.94 * smoothed_noise + 0.06 * raw_noise
        rustle = 0.12 * smoothed_noise * (0.45 + 0.55 * math.sin(math.pi * time / 1.35) ** 2)
        samples[index] = rustle
    add_metal_click(samples, 0.18, 0.38)
    add_metal_click(samples, 0.57, 0.46)
    add_metal_click(samples, 0.96, 0.34)
    return samples


def make_spoon() -> list[float]:
    randomizer = random.Random(6701)
    samples = [0.0] * int(0.42 * RATE)
    for index in range(len(samples)):
        time = index / RATE
        envelope = math.exp(-13 * time)
        strike = 0.62 * math.sin(2 * math.pi * 2320 * time)
        ring = 0.26 * math.sin(2 * math.pi * 3670 * time) + 0.14 * math.sin(2 * math.pi * 5210 * time)
        noise = randomizer.uniform(-1, 1) * math.exp(-70 * time) * 0.28
        samples[index] = envelope * (strike + ring) + noise
    return samples


def main() -> None:
    write_wave(OUTPUT / "plant.wav", make_plant())
    write_wave(OUTPUT / "spoon.wav", make_spoon())


if __name__ == "__main__":
    main()
