# Dogsled Kart — Controls

## Keyboard

| Action        | Primary | Alternate |
|---------------|---------|-----------|
| Accelerate    | W       | ↑ Arrow   |
| Brake/Reverse | S       | ↓ Arrow   |
| Steer Left    | A       | ← Arrow   |
| Steer Right   | D       | → Arrow   |
| Pause         | Esc     | —         |
| Item Use      | Space   | — (Phase 2+) |
| Drift         | Shift   | — (stretch) |

## Movement Notes
- Steering has no effect below ~1.5 m/s (`MIN_SPEED_TO_TURN`).
- Steering sensitivity scales with current speed (faster = sharper turns, up to cap).
- Reverse speed is capped at 30 % of `MAX_SPEED`.
- Releasing all inputs coasts to a stop via drag.

## Input Map (Godot)
Actions are defined in `project.godot` under `[input]`:
`move_forward`, `move_back`, `turn_left`, `turn_right`.
