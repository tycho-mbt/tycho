// Cross-platform system-font lookup for the examples.
//
// The 2D examples need a Latin UI face, a CJK fallback, a CBDT colour-emoji
// face and a Devanagari face. Linux distributions ship them at well-known
// paths; Windows and macOS ship different families under different names.
// `TYCHO_FONT_DIR` is searched first with the canonical (Linux) file names,
// which is also how the committed screenshots can be reproduced with exactly
// the faces they were made with.
//
// Every accessor returns empty bytes when no candidate exists, so each example
// keeps its existing builtin-font / skip / fail behaviour.

///|
fn join(dir : String, name : String) -> String {
  if dir == "" {
    return ""
  }
  let sep = match @win.platform() {
    @win.Platform::Windows => "\\"
    _ => "/"
  }
  if dir.has_suffix("/") || dir.has_suffix("\\") {
    dir + name
  } else {
    dir + sep + name
  }
}

///|
fn first_existing(paths : Array[String]) -> Bytes {
  for path in paths {
    if path != "" {
      let bytes = @image.read_file_bytes(path)
      if bytes.length() > 0 {
        return bytes
      }
    }
  }
  b""
}

///|
/// Resolve `canonical` and the platform fallbacks to the first readable file.
///
/// The order is: `TYCHO_FONT_DIR`, the platform font directory (with the
/// canonical name first so an installed copy wins), then the platform family
/// fallbacks.
fn candidates(
  canonical : String,
  linux_dirs : Array[String],
  windows_names : Array[String],
  macos_paths : Array[String],
) -> Array[String] {
  let out : Array[String] = []
  let env_dir = match @env.get_env_var("TYCHO_FONT_DIR") {
    Some(dir) => dir
    None => ""
  }
  if env_dir != "" {
    out.push(join(env_dir, canonical))
  }
  match @win.platform() {
    @win.Platform::Windows => {
      let windir = match @env.get_env_var("WINDIR") {
        Some(dir) => dir
        None => "C:\\Windows"
      }
      let fonts = join(windir, "Fonts")
      out.push(join(fonts, canonical))
      for name in windows_names {
        out.push(join(fonts, name))
      }
    }
    @win.Platform::MacOS => {
      for path in macos_paths {
        out.push(path)
      }
    }
    _ => {
      for dir in linux_dirs {
        out.push(join(dir, canonical))
      }
    }
  }
  out
}

///|
/// Latin UI face: DejaVu Sans on Linux, Segoe UI / Arial on Windows and Arial
/// on macOS.
pub fn latin() -> Bytes {
  first_existing(
    candidates(
      "DejaVuSans.ttf",
      [
        "/usr/share/fonts/truetype/dejavu",
        "/usr/share/fonts/TTF",
        "/usr/share/fonts/dejavu",
        "/usr/local/share/fonts",
      ],
      ["segoeui.ttf", "arial.ttf"],
      [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Supplemental/DejaVuSans.ttf",
      ],
    ),
  )
}

///|
/// Strict DejaVu Sans lookup for the MSDF gate, which is calibrated for that
/// face and must not silently pick a different font family.
pub fn dejavu_sans() -> Bytes {
  first_existing(
    candidates(
      "DejaVuSans.ttf",
      [
        "/usr/share/fonts/truetype/dejavu",
        "/usr/share/fonts/TTF",
        "/usr/share/fonts/dejavu",
        "/usr/local/share/fonts",
      ],
      [],
      ["/System/Library/Fonts/Supplemental/DejaVuSans.ttf"],
    ),
  )
}

///|
/// CJK fallback: Droid Sans Fallback on Linux, DengXian / SimHei on Windows.
pub fn cjk() -> Bytes {
  first_existing(
    candidates(
      "DroidSansFallbackFull.ttf",
      [
        "/usr/share/fonts/truetype/droid",
        "/usr/share/fonts/google-droid",
        "/usr/share/fonts/truetype/noto",
        "/usr/local/share/fonts",
      ],
      ["Deng.ttf", "simhei.ttf"],
      [
        "/Library/Fonts/Arial Unicode.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      ],
    ),
  )
}

///|
/// CBDT colour emoji: only Noto Color Emoji qualifies. Windows' Segoe UI Emoji
/// is COLR/CPAL and macOS' Apple Color Emoji is sbix, so neither can satisfy
/// the CBDT bitmap path; point `TYCHO_FONT_DIR` at Noto to run this check
/// there.
pub fn color_emoji() -> Bytes {
  first_existing(
    candidates(
      "NotoColorEmoji.ttf",
      [
        "/usr/share/fonts/truetype/noto",
        "/usr/share/fonts/noto",
        "/usr/local/share/fonts",
      ],
      [],
      [],
    ),
  )
}

///|
/// Devanagari face: Lohit Devanagari on Linux. Windows' Nirmala is a TTC
/// collection, which the 2D font parser does not read yet.
pub fn devanagari() -> Bytes {
  first_existing(
    candidates(
      "Lohit-Devanagari.ttf",
      [
        "/usr/share/fonts/truetype/lohit-devanagari",
        "/usr/share/fonts/truetype/lohit",
        "/usr/local/share/fonts",
      ],
      [],
      [],
    ),
  )
}
