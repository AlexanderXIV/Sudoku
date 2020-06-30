import strutils, times

type Sudoku = array[9, array[9, tuple[val: int, opt: array[9, bool]]]]

proc `$`(node: Sudoku): string =
  for y in 0..<9:
    if y mod 3 == 0:
      for i in 0..<9:
        if i mod 3 == 0: result &= "\u00B7 "
        result &= "\u2015 "
      result &= "\u00B7 \n"

    for x, item in node[y]:
      if x mod 3 == 0: result &= "| "
      if item.val == 0:
        result &= "- "
      else:
        result &= $item.val & " "
    result &= "|\n"
  for i in 0..<9:
    if i mod 3 == 0: result &= "\u00B7 "
    result &= "\u2015 "
  result &= "\u00B7 "

proc `$`(node: array[9, bool]): string =
  var b = false
  for it, item in node:
    if item == false:
      if b:
        result &= ", " & $(it + 1)
      else:
        result = $(it + 1)
        b = true

proc clone(node: Sudoku): Sudoku =
  for n1, i1 in node:
    for n2, i2 in i1:
      result[n1][n2].val = i2.val
      for n3, i3 in i2.opt:
        result[n1][n2].opt[n3] = i3


proc del_val_in_vertical(node: var Sudoku, y, value: int) =
  for x in 0..<9:
    node[y][x].opt[value - 1] = true

proc del_val_in_horizontal(node: var Sudoku, x, value: int) =
  for y in 0..<9:
    node[y][x].opt[value - 1] = true

proc del_val_in_section(node: var Sudoku, x1, y1, value: int) =
  let
    mx1 = (int (x1 / 3)) * 3
    my1 = (int (y1 / 3)) * 3
  for y in my1..<(my1 + 3):
    for x in mx1..<(mx1 + 3):
      node[y][x].opt[value - 1] = true

proc check_all(node: var Sudoku) =
  for y in 0..<9:
    for x in 0..<9:
      if node[y][x].val != 0:
        node.del_val_in_vertical(y, node[y][x].val)
        node.del_val_in_horizontal(x, node[y][x].val)
        node.del_val_in_section(x, y, node[y][x].val);

proc set_value(node: var Sudoku, x, y, value: int) =
  node[y][x].val = value
  node.del_val_in_section(x, y, value);
  node.del_val_in_vertical(y, value)
  node.del_val_in_horizontal(x, value)

proc init_Sudoku(str: string): Sudoku =
  for i, n in str: result[i mod 9][int (i / 9)].val = (int n) - 48
  result.check_all()

proc contains_only(arr: array[9, bool], v1, v2: int): bool =
  var b: bool
  for it, item in arr:
    if item == false and (it == v1 or it == v2) == false: b = true
  return b and (arr[v1] == false or arr[v2] == false)

# =========================================================

proc naked_single(node: var Sudoku): int = # -1: Fehler, 0: keine Änderung, 1: Änderung
  var
    already: bool
    temp: int
  result = 0

  for y in 0..<9:
    for x in 0..<9:
      if node[y][x].val != 0: continue

      block l1:
        already = false

        for it, item in node[y][x].opt:
          if item == false:
            if already: break l1
            already = true
            temp = it

        if already:
          result = 1
          node.set_value(x, y, temp + 1)
        else:
          return -1

proc hidden_single(node: var Sudoku): int =
  # nur Probe, extrem ineffizient
  # effizienter: 3 arrays
  # array[...] = ... -> statt Iteration besserere Datenstruktur
  var
    val1, val2: int
    already: bool
  result = 0

  for i in 0..<9:
    for my1 in 0..<3:
      for mx1 in 0..<3:
        block l1:
          already = false
          for y in (my1 * 3)..<(my1 * 3 + 3):
            for x in (mx1 * 3)..<(mx1 * 3 + 3):
              if node[y][x].val == 0 and node[y][x].opt[i] == false:
                if already: break l1
                already = true
                val1 = y
                val2 = x
          if already:
            result = 1
            node.set_value(val2, val1, i + 1)

    for n1 in 0..<9:
      block l1:
        already = false
        for y in 0..<9:
          if node[y][n1].val == 0 and node[y][n1].opt[i] == false:
            if already: break l1
            already = true
            val1 = y
        if already:
          result = 1
          node.set_value(n1, val1, i + 1)

      block l1:
        already = false
        for x in 0..<9:
          if node[n1][x].val == 0 and node[n1][x].opt[i] == false:
            if already: break l1
            already = true
            val1 = x
        if already:
          result = 1
          node.set_value(val1, n1, i + 1)

proc naked_pair(node: var Sudoku): int =
  # Speichertechnisch / Laufzeitteechnisch alles andere als ideal
  var
    spalten: array[9, array[9, array[9, bool]]]
    zeilen: array[9, array[9, array[9, bool]]]
    blocke: array[3, array[3, array[9, array[9, bool]]]]
  result = 0

  for y in 0..<9:
    for x in 0..<9:
      if node[y][x].val != 0: continue

      block l1:
        var
          v: array[2, int]
          i = 0

        for it, item in node[y][x].opt:
          if item == false:
            if i == 2: break l1
            v[i] = it
            inc i

        if i == 0: return -1

        if spalten[x][v[0]][v[1]]:
          # echo "Spalten Found naked pair in: ", (x, y), ", values: ", v, "\t", node[y][x].opt
          for y in 0..<9:
            if node[y][x].val == 0 and contains_only(node[y][x].opt, v[0], v[1]):
              node[y][x].opt[v[0]] = true
              node[y][x].opt[v[1]] = true
              result = 1

        if zeilen[y][v[0]][v[1]]:
          # echo "Zeilen Found naked pair in: ", (x, y), ", values: ", v, "\t", node[y][x].opt
          for x in 0..<9:
            if node[y][x].val == 0 and contains_only(node[y][x].opt, v[0], v[1]):
              node[y][x].opt[v[0]] = true
              node[y][x].opt[v[1]] = true
              result = 1

        if blocke[int (y / 3)][int (x / 3)][v[0]][v[1]]:
          # echo "Blöcke Found naked pair in: ", (x, y), ", values: ", v, "\t", node[y][x].opt
          let
            mx1 = (int (x / 3)) * 3
            my1 = (int (y / 3)) * 3
          for yn in my1..<(my1 + 3):
            for xn in mx1..<(mx1 + 3):
              if node[yn][xn].val == 0 and contains_only(node[yn][xn].opt, v[0], v[1]):
                node[yn][xn].opt[v[0]] = true
                node[yn][xn].opt[v[1]] = true
                result = 1

        spalten[x][v[0]][v[1]] = true
        zeilen[y][v[0]][v[1]] = true
        blocke[int (y / 3)][int (x / 3)][v[0]][v[1]] = true

proc pointing_pair(node: var Sudoku): int = # oder auch triple
  discard

proc claiming_pair(node: var Sudoku): int = # oder auch triple
  discard

proc naked_triple(node: var Sudoku): int =
  discard

proc x_wing(node: var Sudoku): int =
  discard

proc hidden_pair(node: var Sudoku): int =
  discard

proc naked_quad(node: var Sudoku): int =
  discard

proc simplify(node: var Sudoku): bool = # Fehler
  var
    change = true
    temp: int

  while change:
    change = false

    # templates benutzen, um folgendes zu verhindern!
    # mit folgender Verbesserung theoretisch schneller, praktisch jedoch langsamer
    # temp = node.naked_pair()
    # if temp == -1: return true
    # change = change or temp == 1

    temp = node.naked_single()
    if temp == -1: return true
    change = change or temp == 1

    temp = node.hidden_single()
    if temp == -1: return true
    change = change or temp == 1

    # temp = node.pointing_pair()
    # if temp == -1: return true
    # change = change or temp == 1

    # temp = node.claiming_pair()
    # if temp == -1: return true
    # change = change or temp == 1

    # temp = node.naked_triple()
    # if temp == -1: return true
    # change = change or temp == 1

    # temp = node.x_wing()
    # if temp == -1: return true
    # change = change or temp == 1

    # temp = node.hidden_pair()
    # if temp == -1: return true
    # change = change or temp == 1

    # temp = node.naked_quad()
    # if temp == -1: return true
    # change = change or temp == 1
  return false

proc is_ready(node: Sudoku): bool =
  for item1 in node:
    for item in item1:
      if item.val == 0: return false
  return true

proc solve1(node: Sudoku): (bool, Sudoku) =
  var pos: tuple[val: int, x: int, y: int]

  block loop:
    for y in 0..<9:
      for x in 0..<9:
        if node[y][x].val != 0: continue

        var counter = 0
        for item in node[y][x].opt:
          if item == false:
            inc counter

        if counter == 0: return (false, result[1])
        if pos.val == 0 or counter < pos.val:
          pos.x = x
          pos.y = y
          pos.val = counter
          if counter == 2: break loop

  for it, item in node[pos.y][pos.x].opt:
    if item == false:
      var newSudo = node.clone()
      newSudo.set_value(pos.x, pos.y, it + 1)
      var so1 = newSudo.simplify()

      if so1:
        return (false, result[1])
      else:
        if node.is_ready(): return (true, node)

        var solu = solve1(newSudo)
        if solu[0]:
          return solu
  return (false, result[1])

proc solve(node: var Sudoku): (bool, Sudoku) =
  var res1 = node.simplify()
  if res1 == true: return (false, result[1])
  if node.is_ready(): return (true, node)
  return solve1(node)

proc solve(str: string): (bool, Sudoku) =
  var node = init_Sudoku(str)
  return node.solve()

template benchmark(benchmarkName: string, code: untyped) =
  block:
    let t0 = epochTime()
    code
    let elapsed = epochTime() - t0
    let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 5)
    echo "CPU Time [", benchmarkName, "] ", elapsedStr, "ms"

proc valid(node: Sudoku): bool =
  for y in 0..<9:
    var b1: array[9, bool]
    var b2: array[9, bool]
    for x in 0..<9:
      if node[y][x].val == 0 or b1[node[y][x].val - 1] or b2[node[x][y].val - 1]: return false
      b1[node[y][x].val - 1] = true
      b2[node[x][y].val - 1] = true

  for y in 0..<3:
    for x in 0..<3:
      var b1: array[9, bool]
      for y1 in (y * 3)..<(y * 3 + 3):
        for x1 in (x * 3)..<(x * 3 + 3):
          if b1[node[y1][x1].val - 1]: return false
          b1[node[y1][x1].val - 1] = true
  return true

proc toString(node: Sudoku): string =
  for x in 0..<9:
    for y in 0..<9:
      result &= $node[y][x].val

echo "loading ..."
var sudokus = readFile("./sudoku.csv").split("\n")
echo sudokus.len

var num = sudokus.len - 3
echo "start"
benchmark "Löse " & $num & " Sudokus":
  for i in 1..num:
    let sudoku = sudokus[i]
    let s1 = sudoku.split(",")

    if (s1[1] == solve(s1[0])[1].toString) == false:
      echo "Fehler: ", i
      break
echo "ready"
