# TermSnake (Pure Coatl)

A terminal Snake game written in pure Coatl using only Coatl/WASI intrinsics:
- `__fd_read`
- `__fd_write`
- `__mem_load`
- `__mem_store`

## Build and Run

```bash
cd ~/Documents/Projects/TermSnake
coatl build snake.coatl --emit=bin -o snake
./snake
```

Controls:
- `w` `a` `s` `d` to move
- `q` to quit

If the game prints `Raw mode unavailable: use WASD then Enter.`, your current
terminal/PTY does not support the raw-mode ioctl path used by Coatl. In that
case, input falls back to line mode (press Enter after each move).

## Coatl Docs

- Wiki: https://github.com/euxaristia/Coatl/wiki
