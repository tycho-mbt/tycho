// UAX #9 subset: L/R/AL/EN/AN/ES/ET/CS/NSM/WS/ON/B/S classes, W1-W7,
// N1/N2 and I1/I2 levels, then visual reordering by embedding level.
// Explicit embeddings/isolates and bracket pairs (BD16) are still future work.

///|
const BIDI_L : Int = 0

///|
const BIDI_R : Int = 1

///|
const BIDI_AL : Int = 2

///|
const BIDI_EN : Int = 3

///|
const BIDI_AN : Int = 4

///|
const BIDI_ES : Int = 5

///|
const BIDI_ET : Int = 6

///|
const BIDI_CS : Int = 7

///|
const BIDI_NSM : Int = 8

///|
const BIDI_WS : Int = 9

///|
const BIDI_ON : Int = 10

///|
const BIDI_B : Int = 11

///|
const BIDI_S : Int = 12

///|
fn bidi_class(cp : Int) -> Int {
  // Explicit formatting controls are treated as BN/ON.
  if cp == 0x200E || cp == 0x200F {
    return BIDI_ON
  }
  if cp >= 0x0590 && cp <= 0x05FF {
    return BIDI_R
  }
  if (cp >= 0x0600 && cp <= 0x06FF) ||
    (cp >= 0x0700 && cp <= 0x074F) ||
    (cp >= 0x0750 && cp <= 0x077F) ||
    (cp >= 0x08A0 && cp <= 0x08FF) ||
    (cp >= 0xFB50 && cp <= 0xFDFF) ||
    (cp >= 0xFE70 && cp <= 0xFEFF) {
    return BIDI_AL
  }
  if cp >= 0x0660 && cp <= 0x0669 {
    return BIDI_AN
  }
  if cp >= 0x06F0 && cp <= 0x06F9 {
    return BIDI_EN
  }
  if cp >= 48 && cp <= 57 {
    return BIDI_EN
  }
  if (cp >= 0x0300 && cp <= 0x036F) ||
    (cp >= 0x064B && cp <= 0x065F) ||
    (cp >= 0x0670 && cp <= 0x0670) ||
    (cp >= 0x06D6 && cp <= 0x06ED) ||
    (cp >= 0xFE00 && cp <= 0xFE0F) {
    return BIDI_NSM
  }
  if cp == 43 || cp == 45 {
    return BIDI_ES
  }
  if cp == 35 || cp == 36 || cp == 37 || cp == 162 || cp == 163 ||
    cp == 164 || cp == 165 || cp == 176 {
    return BIDI_ET
  }
  if cp == 44 || cp == 46 || cp == 58 || cp == 59 || cp == 0x00A0 {
    return BIDI_CS
  }
  if cp == 10 || cp == 13 {
    return BIDI_B
  }
  if cp == 9 || cp == 11 {
    return BIDI_S
  }
  if cp == 32 || cp == 0x3000 {
    return BIDI_WS
  }
  if (cp >= 65 && cp <= 90) || (cp >= 97 && cp <= 122) || cp > 0x00A0 {
    // CJK, emoji and other non-RTL letters treat as L for this subset.
    return BIDI_L
  }
  return BIDI_ON
}

///|
fn bidi_is_neutral(t : Int) -> Bool {
  t == BIDI_WS || t == BIDI_ON || t == BIDI_B || t == BIDI_S
}

///|
fn bidi_strong_dir(t : Int) -> Int {
  if t == BIDI_R || t == BIDI_AL || t == BIDI_EN || t == BIDI_AN {
    return 1
  }
  if t == BIDI_L {
    return 0
  }
  -1
}

///|
fn bidi_visual_order(
  chars : Array[LayoutChar],
  rs : Int,
  re : Int,
) -> Array[Int] {
  let n = re - rs
  let order : Array[Int] = []
  if n <= 0 {
    return order
  }
  let types = Array::make(n, BIDI_L)
  let mut base = 0
  let mut strong_seen = false
  for k = 0; k < n; k = k + 1 {
    let t = bidi_class(chars[rs + k].cp)
    types[k] = t
    if !strong_seen && (t == BIDI_L || t == BIDI_R || t == BIDI_AL) {
      base = if t == BIDI_L { 0 } else { 1 }
      strong_seen = true
    }
  }

  // W1: NSM takes the previous type.
  for k = 1; k < n; k = k + 1 {
    if types[k] == BIDI_NSM {
      types[k] = types[k - 1]
    }
  }
  if n > 0 && types[0] == BIDI_NSM {
    types[0] = BIDI_ON
  }

  // W2: EN after AL becomes AN.
  let mut last_strong = if base == 1 { BIDI_R } else { BIDI_L }
  for k = 0; k < n; k = k + 1 {
    if types[k] == BIDI_AL {
      last_strong = BIDI_AL
    } else if types[k] == BIDI_L || types[k] == BIDI_R {
      last_strong = types[k]
    } else if types[k] == BIDI_EN && last_strong == BIDI_AL {
      types[k] = BIDI_AN
    }
  }

  // W3: AL -> R.
  for k = 0; k < n; k = k + 1 {
    if types[k] == BIDI_AL {
      types[k] = BIDI_R
    }
  }

  // W4: ES/CS between numbers.
  for k = 1; k + 1 < n; k = k + 1 {
    if types[k] == BIDI_ES &&
      types[k - 1] == BIDI_EN &&
      types[k + 1] == BIDI_EN {
      types[k] = BIDI_EN
    } else if types[k] == BIDI_CS &&
      types[k - 1] == BIDI_EN &&
      types[k + 1] == BIDI_EN {
      types[k] = BIDI_EN
    } else if types[k] == BIDI_CS &&
      types[k - 1] == BIDI_AN &&
      types[k + 1] == BIDI_AN {
      types[k] = BIDI_AN
    }
  }

  // W5: ET adjacent to EN becomes EN.
  let mut k = 0
  while k < n {
    if types[k] == BIDI_ET {
      let start = k
      while k < n && types[k] == BIDI_ET {
        k = k + 1
      }
      let left_en = start > 0 && types[start - 1] == BIDI_EN
      let right_en = k < n && types[k] == BIDI_EN
      if left_en || right_en {
        for j = start; j < k; j = j + 1 {
          types[j] = BIDI_EN
        }
      }
    } else {
      k = k + 1
    }
  }

  // W6: remaining separators/terminators -> ON.
  for k = 0; k < n; k = k + 1 {
    if types[k] == BIDI_ES || types[k] == BIDI_ET || types[k] == BIDI_CS {
      types[k] = BIDI_ON
    }
  }

  // W7: EN after L becomes L.
  last_strong = if base == 1 { BIDI_R } else { BIDI_L }
  for k = 0; k < n; k = k + 1 {
    if types[k] == BIDI_L || types[k] == BIDI_R {
      last_strong = types[k]
    } else if types[k] == BIDI_EN && last_strong == BIDI_L {
      types[k] = BIDI_L
    }
  }

  // N1/N2: resolve neutral runs.
  k = 0
  while k < n {
    if bidi_is_neutral(types[k]) {
      let start = k
      while k < n && bidi_is_neutral(types[k]) {
        k = k + 1
      }
      let left = if start > 0 { bidi_strong_dir(types[start - 1]) } else { base }
      let right = if k < n { bidi_strong_dir(types[k]) } else { base }
      let dir = if left >= 0 && left == right { left } else { base }
      for j = start; j < k; j = j + 1 {
        types[j] = if dir == 1 { BIDI_R } else { BIDI_L }
      }
    } else {
      k = k + 1
    }
  }

  // I1/I2: implicit levels.
  let levels = Array::make(n, base)
  for k = 0; k < n; k = k + 1 {
    if base % 2 == 0 {
      if types[k] == BIDI_R {
        levels[k] = base + 1
      } else if types[k] == BIDI_EN || types[k] == BIDI_AN {
        levels[k] = base + 2
      }
    } else {
      if types[k] == BIDI_L || types[k] == BIDI_EN || types[k] == BIDI_AN {
        levels[k] = base + 1
      }
    }
  }

  for k = 0; k < n; k = k + 1 {
    order.push(rs + k)
  }
  let mut max_level = base
  let mut lowest_odd = 1000
  for k = 0; k < n; k = k + 1 {
    if levels[k] > max_level {
      max_level = levels[k]
    }
    if levels[k] % 2 == 1 && levels[k] < lowest_odd {
      lowest_odd = levels[k]
    }
  }
  if lowest_odd > max_level {
    return order
  }
  let mut lv = max_level
  while lv >= lowest_odd {
    let mut i = 0
    while i < n {
      if levels[order[i] - rs] >= lv {
        let start = i
        while i < n && levels[order[i] - rs] >= lv {
          i = i + 1
        }
        let mut a = start
        let mut b = i - 1
        while a < b {
          let tmp = order[a]
          order[a] = order[b]
          order[b] = tmp
          a = a + 1
          b = b - 1
        }
      } else {
        i = i + 1
      }
    }
    lv = lv - 1
  }
  order
}
