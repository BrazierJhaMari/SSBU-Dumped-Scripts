Peach Turnip Simulation (Processing Java)

What this is
- A small Processing (Java-mode) sketch that simulates Peach's Down Special (turnip) RNG and basic behavior.
- Visualizes held turnips, thrown physics, planting, and includes configurable probabilities.

How to run
1. Install Processing (https://processing.org/download/) on your machine.
2. Open `PeachTurnipSimulation.pde` in the Processing IDE.
3. Press the Run button.

Controls
- G: Pick / roll a turnip (if not holding one).
- T: Throw the held turnip into the world.
- P: Plant (drop) the held turnip at Peach's position.
- R: Reroll (pick a fresh turnip).
- S: Toggle display of probability table.
- Up / Down: Adjust RNG seed.
- Space: Toggle auto-pick mode (automatically picks a new turnip when empty).
 - L: Print recent log entries to the console.
 - E: Export the in-sketch pick/explosion log to `processing/log.txt`.
 - 1/2/3: Increase probability of Variant1/MrSaturn/Bomb by +0.05 then renormalize.
 - Shift+1/2/3 (!/@/#): Decrease the same probabilities by -0.05 then renormalize.

Notes and assumptions
- This is a visual simulator, not an exact reimplementation of SSBU mechanics. Probabilities are configurable in the sketch (`prob1`, `prob2`, `prob3`, `probGiant`).
- In this tuned version, variant 2 has been replaced with "Mr. Saturn" and variant 3 with "Bomb"; the sketch draws and labels those differently.
- The RNG routine is a compact deterministic function for demonstrative purposes; replace with a precise PRNG if desired.

New behaviors in this tuned build
- Bombs: will explode on impact when thrown or after a short fuse if planted/thrown. Explosions are visualized and added to the log.
- Mr. Saturn: on landing it either emits a chirp (logged) or bounces away playfully (visual and logged).
- Simple logging: pick events and bomb explosions are recorded; export with E.

Next steps I can do for you
- Match exact in-game probabilities and rare-variant tables if you want realistic odds.
- Add more turnip behaviors (e.g., planted growth, pickup logic, item visibility flags similar to the C++ scripts in the repo).
- Produce equivalent Lua or converted C++ files that follow the repo's conventions.
