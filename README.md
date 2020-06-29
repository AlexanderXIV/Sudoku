# Sudoku
Program that can solve sudokus very fast.

Tested on an average laptop:
An 9x9 Sudoku takes on average about 10 - 20 microseconds (only 9x9 support so far, tested with one million Sudokus in 18.23607 seconds)

```
nim c -d:danger -r main --opt:speed
```
