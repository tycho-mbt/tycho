// Pure-MoonBit SPIR-V bytecode reflector (zero C/C++ external dependencies).
// Parses SPIR-V binary word streams to extract entry point stage, vertex inputs,
// descriptor bindings (UBO, SSBO, combined image sampler, storage image),
// push-constant byte size, and fragment color output count.

///|
#derive(Eq, Debug)
pub(all) enum ReflectedStage {
  Vertex
  Fragment
  Compute
  Unknown
}

///|
#derive(Eq, Debug)
pub(all) enum ReflectedDescriptorKind {
  UniformBuffer
  StorageBuffer
  CombinedImageSampler
  StorageImage
}

///|
#derive(Eq, Debug)
pub(all) enum ReflectedVertexFormat {
  Float1
  Float2
  Float3
  Float4
  Int1
  Uint1
  Unknown
}

///|
#derive(Eq, Debug)
pub(all) struct ReflectedBinding {
  set : Int
  binding : Int
  kind : ReflectedDescriptorKind
  name : String
}

///|
#derive(Eq, Debug)
pub(all) struct ReflectedVertexInput {
  location : Int
  format : ReflectedVertexFormat
  name : String
}

///|
pub(all) struct SpirvReflection {
  stage : ReflectedStage
  entry_point : String
  vertex_inputs : Array[ReflectedVertexInput]
  bindings : Array[ReflectedBinding]
  push_constant_size : Int
  color_output_count : Int
}

///|
priv enum SpvType {
  TInt(Int, Int) // width, signedness
  TFloat(Int) // width
  TVector(Int, Int) // component_type_id, count
  TMatrix(Int, Int) // column_type_id, count
  TImage(Int) // sampled (1 = sampled, 2 = storage)
  TSampledImage
  TArray(Int, Int) // elem_type_id, length_const_id
  TRuntimeArray(Int) // elem_type_id
  TStruct(Array[Int]) // member type ids
  TPointer(Int) // pointee_type_id
}

///|
priv struct SpvVar {
  id : Int
  type_id : Int
  storage_class : Int
}

///|
fn read_spv_string(
  spv : FixedArray[UInt32],
  start : Int,
  end : Int,
) -> String {
  let sb = StringBuilder()
  for i = start; i < end; i = i + 1 {
    let w = spv[i]
    for shift = 0; shift < 32; shift = shift + 8 {
      let ch = ((w >> shift) & (0xFF : UInt32)).reinterpret_as_int()
      if ch == 0 {
        return sb.to_string()
      }
      sb.write_char(Int::unsafe_to_char(ch))
    }
  }
  sb.to_string()
}

///|
fn spv_type_size(
  ty_id : Int,
  types : Map[Int, SpvType],
  constants : Map[Int, Int],
  member_offsets : Map[(Int, Int), Int],
  member_mat_strides : Map[(Int, Int), Int],
) -> Int {
  match types.get(ty_id) {
    Some(TInt(w, _)) => w / 8
    Some(TFloat(w)) => w / 8
    Some(TVector(comp, cnt)) =>
      spv_type_size(comp, types, constants, member_offsets, member_mat_strides) *
      cnt
    Some(TMatrix(col, cnt)) =>
      spv_type_size(col, types, constants, member_offsets, member_mat_strides) *
      cnt
    Some(TArray(elem, len_id)) => {
      let elem_sz = spv_type_size(
        elem, types, constants, member_offsets, member_mat_strides,
      )
      let len = match constants.get(len_id) {
        Some(n) => n
        None => 1
      }
      elem_sz * len
    }
    Some(TStruct(members)) => {
      let mut max_end = 0
      for m = 0; m < members.length(); m = m + 1 {
        let off = match member_offsets.get((ty_id, m)) {
          Some(o) => o
          None => max_end
        }
        let m_ty = members[m]
        let m_sz = match (types.get(m_ty), member_mat_strides.get((ty_id, m))) {
          (Some(TMatrix(_, cols)), Some(stride)) => cols * stride
          _ =>
            spv_type_size(
              m_ty, types, constants, member_offsets, member_mat_strides,
            )
        }
        if off + m_sz > max_end {
          max_end = off + m_sz
        }
      }
      // Align struct size up to 4 bytes
      (max_end + 3) / 4 * 4
    }
    _ => 0
  }
}

///|
fn spv_vertex_format(
  ty_id : Int,
  types : Map[Int, SpvType],
) -> ReflectedVertexFormat {
  match types.get(ty_id) {
    Some(TFloat(32)) => ReflectedVertexFormat::Float1
    Some(TInt(32, 1)) => ReflectedVertexFormat::Int1
    Some(TInt(32, 0)) => ReflectedVertexFormat::Uint1
    Some(TVector(comp, cnt)) =>
      match types.get(comp) {
        Some(TFloat(32)) =>
          match cnt {
            2 => ReflectedVertexFormat::Float2
            3 => ReflectedVertexFormat::Float3
            4 => ReflectedVertexFormat::Float4
            _ => ReflectedVertexFormat::Unknown
          }
        _ => ReflectedVertexFormat::Unknown
      }
    _ => ReflectedVertexFormat::Unknown
  }
}

///|
fn unwrap_array_type(ty_id : Int, types : Map[Int, SpvType]) -> Int {
  match types.get(ty_id) {
    Some(TArray(elem, _)) => unwrap_array_type(elem, types)
    Some(TRuntimeArray(elem)) => unwrap_array_type(elem, types)
    _ => ty_id
  }
}

///|
pub fn reflect_spirv(spv : FixedArray[UInt32]) -> SpirvReflection {
  if spv.length() < 5 || spv[0] != (0x07230203 : UInt32) {
    return {
      stage: ReflectedStage::Unknown,
      entry_point: "",
      vertex_inputs: [],
      bindings: [],
      push_constant_size: 0,
      color_output_count: 0,
    }
  }

  let mut stage = ReflectedStage::Unknown
  let mut entry_point = "main"
  let names : Map[Int, String] = Map([])
  let types : Map[Int, SpvType] = Map([])
  let constants : Map[Int, Int] = Map([])
  let vars : Array[SpvVar] = []
  let dec_location : Map[Int, Int] = Map([])
  let dec_binding : Map[Int, Int] = Map([])
  let dec_set : Map[Int, Int] = Map([])
  let dec_block : Map[Int, Bool] = Map([])
  let dec_buffer_block : Map[Int, Bool] = Map([])
  let dec_builtin : Map[Int, Bool] = Map([])
  let member_offsets : Map[(Int, Int), Int] = Map([])
  let member_mat_strides : Map[(Int, Int), Int] = Map([])

  let mut idx = 5
  while idx < spv.length() {
    let w0 = spv[idx]
    let count = (w0 >> 16).reinterpret_as_int()
    let op = (w0 & (0xFFFF : UInt32)).reinterpret_as_int()
    if count <= 0 || idx + count > spv.length() {
      break
    }
    match op {
      5 => // OpName
        if count >= 3 {
          let tid = spv[idx + 1].reinterpret_as_int()
          names.set(tid, read_spv_string(spv, idx + 2, idx + count))
        }
      15 => // OpEntryPoint
        if count >= 4 {
          let model = spv[idx + 1].reinterpret_as_int()
          stage = match model {
            0 => ReflectedStage::Vertex
            4 => ReflectedStage::Fragment
            5 => ReflectedStage::Compute
            _ => ReflectedStage::Unknown
          }
          entry_point = read_spv_string(spv, idx + 3, idx + count)
        }
      21 => // OpTypeInt
        if count >= 4 {
          let id = spv[idx + 1].reinterpret_as_int()
          let width = spv[idx + 2].reinterpret_as_int()
          let signed = spv[idx + 3].reinterpret_as_int()
          types.set(id, TInt(width, signed))
        }
      22 => // OpTypeFloat
        if count >= 3 {
          let id = spv[idx + 1].reinterpret_as_int()
          let width = spv[idx + 2].reinterpret_as_int()
          types.set(id, TFloat(width))
        }
      23 => // OpTypeVector
        if count >= 4 {
          let id = spv[idx + 1].reinterpret_as_int()
          let comp = spv[idx + 2].reinterpret_as_int()
          let cnt = spv[idx + 3].reinterpret_as_int()
          types.set(id, TVector(comp, cnt))
        }
      24 => // OpTypeMatrix
        if count >= 4 {
          let id = spv[idx + 1].reinterpret_as_int()
          let col = spv[idx + 2].reinterpret_as_int()
          let cnt = spv[idx + 3].reinterpret_as_int()
          types.set(id, TMatrix(col, cnt))
        }
      25 => // OpTypeImage
        if count >= 9 {
          let id = spv[idx + 1].reinterpret_as_int()
          let sampled = spv[idx + 7].reinterpret_as_int()
          types.set(id, TImage(sampled))
        }
      27 => // OpTypeSampledImage
        if count >= 3 {
          let id = spv[idx + 1].reinterpret_as_int()
          types.set(id, TSampledImage)
        }
      28 => // OpTypeArray
        if count >= 4 {
          let id = spv[idx + 1].reinterpret_as_int()
          let elem = spv[idx + 2].reinterpret_as_int()
          let len_id = spv[idx + 3].reinterpret_as_int()
          types.set(id, TArray(elem, len_id))
        }
      29 => // OpTypeRuntimeArray
        if count >= 3 {
          let id = spv[idx + 1].reinterpret_as_int()
          let elem = spv[idx + 2].reinterpret_as_int()
          types.set(id, TRuntimeArray(elem))
        }
      30 => // OpTypeStruct
        if count >= 2 {
          let id = spv[idx + 1].reinterpret_as_int()
          let members : Array[Int] = []
          for m = 2; m < count; m = m + 1 {
            members.push(spv[idx + m].reinterpret_as_int())
          }
          types.set(id, TStruct(members))
        }
      32 => // OpTypePointer
        if count >= 4 {
          let id = spv[idx + 1].reinterpret_as_int()
          let pt = spv[idx + 3].reinterpret_as_int()
          types.set(id, TPointer(pt))
        }
      43 => // OpConstant
        if count >= 4 {
          let id = spv[idx + 2].reinterpret_as_int()
          let val = spv[idx + 3].reinterpret_as_int()
          constants.set(id, val)
        }
      59 => // OpVariable
        if count >= 4 {
          let ty = spv[idx + 1].reinterpret_as_int()
          let id = spv[idx + 2].reinterpret_as_int()
          let sc = spv[idx + 3].reinterpret_as_int()
          vars.push({ id, type_id: ty, storage_class: sc })
        }
      71 => // OpDecorate
        if count >= 3 {
          let tid = spv[idx + 1].reinterpret_as_int()
          let dec = spv[idx + 2].reinterpret_as_int()
          match dec {
            2 => dec_block.set(tid, true)
            3 => dec_buffer_block.set(tid, true)
            11 => dec_builtin.set(tid, true)
            30 =>
              if count >= 4 {
                dec_location.set(tid, spv[idx + 3].reinterpret_as_int())
              }
            33 =>
              if count >= 4 {
                dec_binding.set(tid, spv[idx + 3].reinterpret_as_int())
              }
            34 =>
              if count >= 4 {
                dec_set.set(tid, spv[idx + 3].reinterpret_as_int())
              }
            _ => ()
          }
        }
      72 => // OpMemberDecorate
        if count >= 4 {
          let st = spv[idx + 1].reinterpret_as_int()
          let mem = spv[idx + 2].reinterpret_as_int()
          let dec = spv[idx + 3].reinterpret_as_int()
          match dec {
            7 =>
              if count >= 5 {
                member_mat_strides.set(
                  (st, mem),
                  spv[idx + 4].reinterpret_as_int(),
                )
              }
            35 =>
              if count >= 5 {
                member_offsets.set((st, mem), spv[idx + 4].reinterpret_as_int())
              }
            _ => ()
          }
        }
      _ => ()
    }
    idx = idx + count
  }

  let vertex_inputs : Array[ReflectedVertexInput] = []
  let bindings : Array[ReflectedBinding] = []
  let mut push_constant_size = 0
  let mut color_output_count = 0

  for v in vars {
    let pointee = match types.get(v.type_id) {
      Some(TPointer(pt)) => pt
      _ => continue
    }
    let var_name = match names.get(v.id) {
      Some(n) => n
      None =>
        match names.get(pointee) {
          Some(n) => n
          None => ""
        }
    }
    match v.storage_class {
      1 => // Input
        if stage == ReflectedStage::Vertex && dec_builtin.get(v.id) is None {
          match dec_location.get(v.id) {
            Some(loc) =>
              vertex_inputs.push({
                location: loc,
                format: spv_vertex_format(pointee, types),
                name: var_name,
              })
            None => ()
          }
        }
      3 => // Output
        if stage == ReflectedStage::Fragment && dec_builtin.get(v.id) is None {
          match dec_location.get(v.id) {
            Some(loc) =>
              if loc + 1 > color_output_count {
                color_output_count = loc + 1
              }
            None => ()
          }
        }
      9 => {
        // PushConstant
        let sz = spv_type_size(
          pointee, types, constants, member_offsets, member_mat_strides,
        )
        if sz > push_constant_size {
          push_constant_size = sz
        }
      }
      0 | 2 | 12 =>
        // UniformConstant (0), Uniform (2), StorageBuffer (12)
        match dec_binding.get(v.id) {
          Some(b) => {
            let set_idx = match dec_set.get(v.id) {
              Some(s) => s
              None => 0
            }
            let base_ty = unwrap_array_type(pointee, types)
            let kind : ReflectedDescriptorKind? = if v.storage_class == 12 {
              Some(ReflectedDescriptorKind::StorageBuffer)
            } else if v.storage_class == 2 {
              if dec_buffer_block.get(base_ty) == Some(true) {
                Some(ReflectedDescriptorKind::StorageBuffer)
              } else if dec_block.get(base_ty) == Some(true) {
                Some(ReflectedDescriptorKind::UniformBuffer)
              } else {
                None
              }
            } else {
              match types.get(base_ty) {
                Some(TSampledImage) =>
                  Some(ReflectedDescriptorKind::CombinedImageSampler)
                Some(TImage(sampled)) =>
                  if sampled == 2 {
                    Some(ReflectedDescriptorKind::StorageImage)
                  } else {
                    Some(ReflectedDescriptorKind::CombinedImageSampler)
                  }
                _ => None
              }
            }
            match kind {
              Some(k) =>
                bindings.push({
                  set: set_idx,
                  binding: b,
                  kind: k,
                  name: var_name,
                })
              None => ()
            }
          }
          None => ()
        }
      _ => ()
    }
  }

  // Sort vertex inputs by location, bindings by (set, binding)
  vertex_inputs.sort_by(fn(a, b) { a.location - b.location })
  bindings.sort_by(fn(a, b) {
    if a.set != b.set {
      a.set - b.set
    } else {
      a.binding - b.binding
    }
  })

  {
    stage,
    entry_point,
    vertex_inputs,
    bindings,
    push_constant_size,
    color_output_count,
  }
}
