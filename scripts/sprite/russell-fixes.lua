-- Per-frame settings and hand corrections for build-russell.lua.
-- Keys are "move:frame" (frames count from 1). See the top of that script
-- for what each field does.

-- The head thrown back, face to the sky, mouth open (the dark mark is the
-- one the template draws): hair behind and below, the face up and forward.
local HEAD_UP = {
  "  hhsss  ",
  " hHhssss ",
  " hh  sss ",
  "hhh   sss",
  "hHhs sssS",
  "hhhhssssS",
  " hHhhsS  ",
  "  hhhS   ",
  "    S    ",
}
local LOOKING_UP = { view = "right", headStamp = HEAD_UP }
-- Curled into a ball: the top of the head and the back of the jacket.
local CURLED = { view = "none", torso = "back" }
-- In the slide the far foot is hidden behind the near leg.
local SLIDING = { farLeg = { noShoe = true } }

return {
  -- Dropping into the slide: both shins still come down to the floor, so the
  -- shoes are the bottom two rows, not the front of the knee.
  ["slide:1"] = {
    nearLeg = { noShoe = true, noSock = true }, farLeg = { noShoe = true, noSock = true },
    patch = {
      { 72, 70, { "Q ", " Q" } },
      { 72, 74, { "kQ ", "kQ ", "kkQ" } },
      { 65, 77, {
        "    kkkkkQ ",
        "BBgBKBBBBgB",
        "bbbbKbbbbbb",
      } },
    },
  },
  ["slide:2"] = { torso = "flat", farLeg = { noShoe = true } }, ["slide:3"] = SLIDING, ["slide:4"] = SLIDING,
  ["slide:5"] = SLIDING, ["slide:6"] = SLIDING,
  ["death:2"] = CURLED, ["death:3"] = CURLED, ["death:4"] = CURLED,
  ["death:5"] = CURLED, ["death:6"] = CURLED, ["death:7"] = CURLED,
  ["death:8"] = LOOKING_UP, ["death:9"] = LOOKING_UP, ["death:10"] = LOOKING_UP,
  ["death:11"] = LOOKING_UP, ["death:12"] = LOOKING_UP, ["death:13"] = LOOKING_UP,

  -- Russell's own edits in Aseprite (2026-11-15), kept exactly as he drew them.
  -- jump 1: the far arm hangs down and back, so its hand is at the lower end.
  ["jump:1"] = {
    full = { 51, 51, {
      "..............KKK......", -- 51
      "............KKhhhKKK...", -- 52
      "...........KhhHhhhhhK..", -- 53
      "..........KhhHhhhHhHhK.", -- 54
      "..........KhHhhhHhhhHK.", -- 55
      "..........KhhhhHhhhhhK.", -- 56
      "..........KhhhhHhssshK.", -- 57
      ".......KKKKKhhhsKKssKK.", -- 58
      ".....KKllllKhhSsKKssKK.", -- 59
      "...KKllddddldhPsssssSK.", -- 60
      "..KlldddDDDdddKSsssSK..", -- 61
      ".KsddddDKKKddddKKKKKDK.", -- 62
      "KsssdddK.KdddddDrrKDDK.", -- 63
      "KssssdDK.KdddDRrrDKDDDK", -- 64
      "KsssSsK..KdDrrrlPKDDDDK", -- 65
      ".KssSK..KdDrRrKKKDDDDDK", -- 66
      "..KKK...KrrRlKSDDDDDDK.", -- 67
      "........KrDDKSSDDDDDDK.", -- 68
      ".......KKkkQKSSDDDDDK..", -- 69
      "......KkkkkkQKSSDDKK...", -- 70
      ".....KkkkkQKKKKKKKQK...", -- 71
      "....KkkkkQK...KQQQQQK..", -- 72
      "....KkkkQK.....KQQQQQK.", -- 73
      "...KkkkkQK.....KQQQQQK.", -- 74
      "...KkkkQK......KQQQQQK.", -- 75
      "...KkkkQK.....KQQQQQK..", -- 76
      "..KkkkkQK....KQQQBBK...", -- 77
      "..KBBBgBK....KbBBBgBK..", -- 78
      "..KbbbbbK.....KbbbbbK..", -- 79
    } },
  },
  -- jump 6: the far leg hangs straight down behind the near one, so its shoe
  -- is the two rows at the bottom; he also took one pixel off its width.
  ["jump:6"] = {
    full = { 46, 44, {
      ".................KKK.........", -- 44
      "...............KKhhhKKK......", -- 45
      "..............KhhHhhhhhKKKK..", -- 46
      ".............KhhHhhhHhHhKSSK.", -- 47
      "....KKKKK....KhHhhhHhhhHKSSSK", -- 48
      "..KKdllllKK..KhhhhHhhhhhKDSSK", -- 49
      ".KssdddddllKKKhhhhHhssshKDDDK", -- 50
      "KsssdddddddllKKhhhsKKssKKDDK.", -- 51
      "KsssdddDDddddlKhhSsKKssKKKK..", -- 52
      "KsssdDDKKDDdddllhPsssssSK....", -- 53
      ".KssDKK..KKDdddSSrSsssSK.....", -- 54
      "..KKK......KDddDrSrDDK.......", -- 55
      "............KddDrPrDK........", -- 56
      "............KddDrrRDK........", -- 57
      "............KddDRrrDK........", -- 58
      "............KdddDrrrlK.......", -- 59
      "............KdddDrRrPlK......", -- 60
      ".............KddDrrRlPKKK....", -- 61
      ".............KdkkkkQKQQQQK...", -- 62
      ".............KkkkkkQKQQQQQK..", -- 63
      "..............KkkkkkQKQQQQK..", -- 64
      "..............KkkkkkkQKQQQK..", -- 65
      "...............KkkkkkQKQQQK..", -- 66
      "...............KkkkkQKQQKK...", -- 67
      "..............KkkkkkQKQK.....", -- 68
      "..............KkkkkQKgBK.....", -- 69
      ".............KkkkkQKbbK......", -- 70
      ".............KkkkkQKKK.......", -- 71
      "............KBBgBbK..........", -- 72
      "............KbbbbK...........", -- 73
      ".............KKKK............", -- 74
    } },
  },

  -- The two frames Russell approved on 2026-11-15, kept exactly as approved.
  ["idle:1"] = {
    full = { 52, 47, {
      ".........KKK..........", -- 47
      ".......KKhhhKKK.......",
      "......KhhHhhhhhK......",
      ".....KhhHhhhHhHhK.....", -- 50
      ".....KhHhhhHhhhHK.....",
      ".....KhhhhHhhhhhK.....",
      ".....KhhhhHhssshK.....",
      "......KhhhsKKssKK.....",
      "......KhhSsKKssKK.....", -- 55
      "......KHhPsssssSK.....",
      ".....KHhhKSsssSK......",
      "......KKKddrSSrdK.....",
      ".....KKldddDrSrDK.....",
      "....KldddddDrPrDKK....", -- 60
      "...KlddddddDrrRDKK....",
      "...KlddDKddDRrrDKDK...",
      "..KlddDKKddDrrrDKDK...",
      "..KldDK..KdDrRrDKDK...",
      "..KldDK..KdDrrRlKDDK..", -- 65
      ".KldddDK.KdDRrrPlKDK..",
      ".KddddDKKddDrRrDPKSK..",
      ".KssssSKKdddDrrDDKSK..",
      ".KsssSsKKkkkkkQQQKK...",
      "..KssSKKkkkkkQQQQQK...", -- 70
      "...KKKKkkkkQKKQQQQK...",
      "......KkkkQKKKQQQQK...",
      ".....KkkkQK..KQQQQK...",
      "....KkkkkQK..KQQQQK...",
      "...KkkkkQK...KQQQQK...", -- 75
      "...KkkkkQK...KQQQQK...",
      "..KkkkkQK....KQQQBBK..",
      "..KBBBgBK....KBBBgBBK.",
      "..KbbbbbK....KbbbbbbK.", -- 79
    } },
  },
  ["walk:6"] = {
    full = { 53, 48, {
      "..........KKK...........", -- 48
      "........KKhhhKKK........",
      ".......KhhHhhhhhK.......", -- 50
      "......KhhHhhhHhHhK......",
      "......KhHhhhHhhhHK......",
      "......KhhhhHhhhhhK......",
      "......KhhhhHhssshK......",
      ".......KhhhsKKssKK......", -- 55
      ".......KhhSsKKssKK......",
      ".......KHhPsssssSK......",
      "......KHhhKSsssSK.......",
      ".......KldKKKKKKK.......",
      "......KlddDKdSrKDK......", -- 60
      ".....KldddDKdrPDKK......",
      "....KldddDKdDrrDKK......",
      "....KlddDKddDRrDKDK.....",
      "...KldddDKddDrrDKDDKK...",
      "...KlddDKKddDrRDKDDDDK..", -- 65
      "...KlddDKKddDRrPKDDDSSK.",
      "...KddddDKddDrrlKDDDSSK.",
      "...KssssSKddDrRDKDDSSSK.",
      "...KsssSsKdddDrkKKDSSK..",
      "....KssSKKkkkkkkQKKKK...", -- 70
      ".....KKKKQKKkkkkkQK.....",
      ".......KQQQQKkkkkQK.....",
      "......KQQQQQQKkkkkQK....",
      "....KKQQQQQQKKkkkkQK....",
      "...KQQQQQQQK.KkkkkQK....", -- 75
      "..KQQQQQQQK...KkkkQK....",
      ".KQQQQQQQK....KkkQBBK...",
      ".KBBBBBBK.....KBBBgBBK..",
      ".KbbbbbK......KbbbbbbK..", -- 79
    } },
  },
}
