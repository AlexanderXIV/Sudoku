import strutils, times

type Sudoku = array[9, array[9, tuple[val: int, opt: array[9, bool]]]]

proc `$`(node: Sudoku): string =
  for item in node:
    for it in item:
      if it.val == 0:
        result = result & "- "
      else:
        result = result & $it.val & " "
    result = result & "\n"

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

proc check_vertical(s: var Sudoku, y: int) =
  for x in 0..<9:
    if s[y][x].val != 0:
      for x1 in 0..<9:
        s[y][x1].opt[s[y][x].val - 1] = true

proc check_horizontal(s: var Sudoku, x: int) =
  for y in 0..<9:
    if s[y][x].val != 0:
      for y1 in 0..<9:
        s[y1][x].opt[s[y][x].val - 1] = true

proc check_section(s: var Sudoku, mx1: int, my1: int) =
  for y in my1..<(my1 + 3):
    for x in mx1..<(mx1 + 3):
      if s[y][x].val != 0:
        for y1 in my1..<(my1 + 3):
          for x1 in mx1..<(mx1 + 3):
            s[y1][x1].opt[s[y][x].val - 1] = true

proc check(s: var Sudoku, x, y: int) =
  s.check_section((int (x / 3)) * 3, (int (y / 3)) * 3);
  s.check_vertical(y)
  s.check_horizontal(x)

proc set_value(s: var Sudoku, x, y, value: int) =
  s[y][x].val = value
  s.check(x, y)

proc check_all(s: var Sudoku) =
  for my1 in 0..<3:
    for mx1 in 0..<3: s.check_section(mx1 * 3, my1 * 3)
  for y in 0..<9: s.check_vertical(y)
  for x in 0..<9: s.check_horizontal(x)

proc init_Sudoku(str: string): Sudoku =
  for i, n in str: result[i mod 9][int (i / 9)].val = (int n) - 48
  result.check_all()

proc simplify(node: var Sudoku): (bool, bool) = # (Fehler beim lösen, fertig gelöst)
  var set_val = true
  var ready = false

  while set_val:
    ready = true
    set_val = false

    for y in 0..<9:
      for x in 0..<9:
        if node[y][x].val != 0: continue
        ready = false

        var
          error = false
          value = -1

        for it, item in node[y][x].opt:
          if item == false:
            if value != -1:
              error = true
              break
            value = it

        if error == false:
          if value == -1:
            return (false, false)
          else:
            set_val = true
            node.set_value(x, y, value + 1)

    for my1 in 0..<3:
      for mx1 in 0..<3:
        var l2: array[9, tuple[val, x, y: int]]
        for y in (my1 * 3)..<(my1 * 3 + 3):
          for x in (mx1 * 3)..<(mx1 * 3 + 3):
            if node[y][x].val != 0: continue
            for i in 0..<9:
              if node[y][x].opt[i] == false and l2[i].val < 2:
                inc l2[i].val
                l2[i].x = x
                l2[i].y = y

        for it, item in l2:
          if item.val == 1:
            set_val = true
            node.set_value(item.x, item.y, it + 1)

    for x in 0..<9:
      var l2: array[9, tuple[val, x, y: int]]
      for y in 0..<9:
        if node[y][x].val != 0: continue
        for i in 0..<9:
          if node[y][x].opt[i] == false and l2[i].val < 2:
            inc l2[i].val
            l2[i].x = x
            l2[i].y = y

      for it, item in l2:
        if item.val == 1:
          set_val = true
          node.set_value(item.x, item.y, it + 1)

    for y in 0..<9:
      var l2: array[9, tuple[val, x, y: int]]
      for x in 0..<9:
        if node[y][x].val != 0: continue
        for i in 0..<9:
          if node[y][x].opt[i] == false and l2[i].val < 2:
            inc l2[i].val
            l2[i].x = x
            l2[i].y = y

      for it, item in l2:
        if item.val == 1:
          set_val = true
          node.set_value(item.x, item.y, it + 1)
  return (true, ready)

proc real_solve(node: Sudoku): (bool, Sudoku) =
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

      if so1[0]:
        if so1[1]:
          return (true, newSudo)
        else:
          var solu = real_solve(newSudo)
          if solu[0]:
            return solu
  return (false, result[1])

proc solve(node: var Sudoku): (bool, Sudoku) =
  var res1 = node.simplify()
  if res1[0] == false: return (false, result[1])
  if res1[1]: return (true, node)
  return node.real_solve()

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

var strings = @["600008300000000857043000000700010400000723000001040006000000120526000000008300004", "000090005100800000038007040009008000756000823000200600040500790000001008600020000", "100000000009580040025600000090070080008000500010040070000008630070034200000000009", "006005700070000002000608004000050030001807900080060000400901000100000060008700300", "000000306030068000090040010350020100000804000004090067070030090000510070506000000", "090002030050040006000000074000080200010000050004070000930000000800030060020900010", "000005304500020001006040007000009270080000090079100000800030600700050002304600000", "000502700000600001004000200000008046600000009190700000007000500400009000003801000", "009080000060270009000000501006800007000764000400009200103000000200048060000050800", "000306000025000300901000020200000080000814000070000009060000103004000760000407000", "100900074000004020000080056030000700000635000002000090590060000020100000460002001", "000000003000001700650000048020009670000050000078300020790000061004500000200000000", "000000042900040010030005008020370500000020000005091060100700030080010007690000000", "105070000000100204900000070060007000004201600000600030090000001607008000000090803", "000000070034100000700060405502008700000020000008900506301040007000009860020000000", "060000008000100907050030004007051006000000000600490200900040080104003000200000030", "090060000100000806003200007000800019005000200270001000500004700704000003000050060", "009200050380017000000000060400020980000000000038040007040000000000980036020005100", "280001900000000070000060012032008007000040000400500820320070000010000000008900054", "100000007500643000009000000010000008406205309300000070000000200000381004900000005", "010020000060004800004609030000100600050000090002003000030506100009800050000070040", "096800000700050060800041000020000700500000001008000090000160009040090006000007230", "680507000000000200000021800030060105000000000906040080001290000009000000000803097", "600000300205080700090007000400000001000561000900000002000200050008010604003000009", "003006000070200000080010609000800010067030840050007000308090020000001060000400100", "020009708068500000000000000200070004040000030500090001000000000000003290401200050", "090010007000500600703000002000705000820000079000804000400000106005006000600070030", "000630010000809630006004000600000700200050003001000005000700900057908000040065000", "000030005230000000901000340000407090008000400090805000087000506000000072500060000", "349000000000000700000509002200095007001000400800720005100402000008000000000000376", "000009350450002007007000100040080003070000010100040020006000700300500069084900000", "860000200000740005000000016000095600030000090005160000210000000700083000004000039", "410000003030900008000200000003060000508000904000080500000002000100005020800000016", "070090804400200000100005000039070000007000200000050980000600001000009008701080040", "000350060070000054009002000060000008003000600800000070000100900450000080010036000", "860000020000090500020008004904000000000519000000000302300100050002060000040000068", "000800070047091060130600000000000203000040000605000000000002051060310480050008000", "000001000080052097000800240205007000000000000000900304017008000460790080000600000", "000008000000007029270109038003000060700000005080000100930501087140700000000400000", "010008602000001009000470000000000750035000120086000000000054000900300000602700030", "000004000000500062706010000000400073004090500950002000000060308390007000000900000", "080005020070210000000060300400000001035020490900000003009080000000059080050700060", "700064085800200000000000430184000000000000000000000576027000000000009001410350002", "040020700000008001000001208490000100107000604003000057304200000700900000006080020", "000006708000007400200900030080000010000538000020000050090004006005200000406100000", "005002000200000007010400300060010409800000001103070050004005080900000003000600900", "006000000200908010000100530300007100600000008002400003058006000020801009000000400", "000000504003400002009082000240001900000000000008900076000230800600009700107000000", "690000800008500047002003000000800053000000000970001000000300400240006500001000062", "070090150980070000200300000060408000100000002000609030000003007000060018097040020"]

benchmark "Löse " & $strings.len & " Sudokus":
  for str in strings:
    var s = solve(str)
    if s[0] == false and valid(s[1]): echo "unlösbar"
