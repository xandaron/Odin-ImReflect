package ImRefl

import "base:runtime"
import "core:fmt"
import "core:reflect"
import "core:strings"

import imgui "../imgui"


Draw_Flag :: enum {
	Read_Only,

	// For internal use.
	Using_Flatten,
	Padding,
}
Draw_Flags :: bit_set[Draw_Flag]

draw_value :: proc(name: string, value: any, flags: Draw_Flags = nil) {
	switch reflect.type_kind(value.id) {
	case .Invalid: panic("Invalid Type!")
	case .Named:                  draw_value(name, any{value.data, reflect.typeid_base(value.id)}, flags)
	case .Struct:                 draw_struct_type(name, value, flags)
	case .Bit_Field:              draw_bit_field_type(name, value, flags)
	case .Union:                  draw_union_type(name, value, flags)
	case .Bit_Set:                draw_bit_set_type(name, value, flags)
	case .Enum:                   draw_enum_type(name, value, flags)
	case .Any:                    draw_any_type(name, value, flags)
	case .Type_Id:                draw_type_id(name, value, flags)
	case .Pointer:                draw_pointer_type(name, value, flags)
	case .String:                 draw_string_type(name, value, flags)
	case .Complex:                draw_complex_type(name, value, flags)
	case .Quaternion:             draw_quat_type(name, value, flags)
	case .Boolean:                draw_bool_type(name, value, flags)
	case .Integer, .Rune, .Float: draw_literal_type(name, value, flags)
	case .Map:                    draw_map_type(name, value, flags)
	case .Matrix:                 draw_matrix_type(name, value, flags)
	case .Array:                  draw_array_type(name, value, flags)
	case .Slice:                  draw_slice_type(name, value, flags)
	case .Enumerated_Array:       draw_enum_array_type(name, value, flags)
	case .Dynamic_Array:          draw_dyn_array_type(name, value, flags)
	case .Multi_Pointer:          draw_multi_pointer_type(name, value, flags)
	case .Simd_Vector:            draw_simd_vec_type(name, value, flags)
	case .Soa_Pointer:            draw_soa_pointer_type(name, value, flags)
	case .Procedure:              draw_proc_type(name, value, flags)
	case .Parameters: // As is a proc param? I don't think we need to cover this.
	}
}

@(private)
assert_kind :: #force_inline proc(got, expected: reflect.Type_Kind, loc := #caller_location) {
	fmt.assertf(got == expected, "Value type kind must be %v! Got %v", expected, got, loc = loc)
}

@(private)
type_id_to_data_type :: proc(id: typeid) -> imgui.GuiDataType {
	switch id { // what should I do with be and le types? I might have to convert the type first
	case i8:        return .S8
	case u8, byte:  return .U8
	case i16:       return .S16
	case u16, rune: return .U16
	case i32:       return .S32
	case u32:       return .U32
	case i64:       return .S64
	case u64:       return .U64
	case int:       return .S64 when size_of(    int) == 8 else .S32
	case uint:      return .U64 when size_of(   uint) == 8 else .U32
	case uintptr:   return .U64 when size_of(uintptr) == 8 else .U32
	// TODO: Idk what to do here. Maybe we can use s16 with some funky stuff?
	// Maybe we just have to cast to a storage f32 and back.
	// case f16:
	case f32:       return .Float
	case f64:       return .Double
	}
	panic("Invalid type id!")
}

@(private)
write_int_to_any :: proc(int64: $T, value: any) {
	switch reflect.typeid_base_without_enum(value.id) {
	case i8:      (^i8     )(value.data)^ = auto_cast int64
	case i16:     (^i16    )(value.data)^ = auto_cast int64
	case i32:     (^i32    )(value.data)^ = auto_cast int64
	case i64:     (^i64    )(value.data)^ = auto_cast int64
	case i128:    (^i128   )(value.data)^ = auto_cast int64
	case int:     (^int    )(value.data)^ = auto_cast int64
	case u8:      (^u8     )(value.data)^ = auto_cast int64
	case u16:     (^u16    )(value.data)^ = auto_cast int64
	case u32:     (^u32    )(value.data)^ = auto_cast int64
	case u64:     (^u64    )(value.data)^ = auto_cast int64
	case u128:    (^u128   )(value.data)^ = auto_cast int64
	case uint:    (^uint   )(value.data)^ = auto_cast int64
	case uintptr: (^uintptr)(value.data)^ = auto_cast int64
	case u16le:   (^u16le  )(value.data)^ = auto_cast int64
	case u32le:   (^u32le  )(value.data)^ = auto_cast int64
	case u64le:   (^u64le  )(value.data)^ = auto_cast int64
	case u128le:  (^u128le )(value.data)^ = auto_cast int64
	case i16le:   (^i16le  )(value.data)^ = auto_cast int64
	case i32le:   (^i32le  )(value.data)^ = auto_cast int64
	case i64le:   (^i64le  )(value.data)^ = auto_cast int64
	case i128le:  (^i128le )(value.data)^ = auto_cast int64
	case u16be:   (^u16be  )(value.data)^ = auto_cast int64
	case u32be:   (^u32be  )(value.data)^ = auto_cast int64
	case u64be:   (^u64be  )(value.data)^ = auto_cast int64
	case u128be:  (^u128be )(value.data)^ = auto_cast int64
	case i16be:   (^i16be  )(value.data)^ = auto_cast int64
	case i32be:   (^i32be  )(value.data)^ = auto_cast int64
	case i64be:   (^i64be  )(value.data)^ = auto_cast int64
	case i128be:  (^i128be )(value.data)^ = auto_cast int64
	case rune:    (^rune   )(value.data)^ = auto_cast int64
	case: fmt.panicf("Non supported typeid: %v", value.id)
	}
}

@(private)
read_int_any_as_type :: proc(value: any, $T: typeid) -> T {
	switch reflect.typeid_base_without_enum(value.id) {
	case i8:      return auto_cast (^i8     )(value.data)^
	case i16:     return auto_cast (^i16    )(value.data)^
	case i32:     return auto_cast (^i32    )(value.data)^
	case i64:     return auto_cast (^i64    )(value.data)^
	case i128:    return auto_cast (^i128   )(value.data)^
	case int:     return auto_cast (^int    )(value.data)^
	case u8:      return auto_cast (^u8     )(value.data)^
	case u16:     return auto_cast (^u16    )(value.data)^
	case u32:     return auto_cast (^u32    )(value.data)^
	case u64:     return auto_cast (^u64    )(value.data)^
	case u128:    return auto_cast (^u128   )(value.data)^
	case uint:    return auto_cast (^uint   )(value.data)^
	case uintptr: return auto_cast (^uintptr)(value.data)^
	case u16le:   return auto_cast (^u16le  )(value.data)^
	case u32le:   return auto_cast (^u32le  )(value.data)^
	case u64le:   return auto_cast (^u64le  )(value.data)^
	case u128le:  return auto_cast (^u128le )(value.data)^
	case i16le:   return auto_cast (^i16le  )(value.data)^
	case i32le:   return auto_cast (^i32le  )(value.data)^
	case i64le:   return auto_cast (^i64le  )(value.data)^
	case i128le:  return auto_cast (^i128le )(value.data)^
	case u16be:   return auto_cast (^u16be  )(value.data)^
	case u32be:   return auto_cast (^u32be  )(value.data)^
	case u64be:   return auto_cast (^u64be  )(value.data)^
	case u128be:  return auto_cast (^u128be )(value.data)^
	case i16be:   return auto_cast (^i16be  )(value.data)^
	case i32be:   return auto_cast (^i32be  )(value.data)^
	case i64be:   return auto_cast (^i64be  )(value.data)^
	case i128be:  return auto_cast (^i128be )(value.data)^
	case rune:    return auto_cast (^rune   )(value.data)^
	}
	fmt.panicf("Non supported typeid: %v", value.id)
}

@(private)
tag_value_to_flag :: proc(str: string) -> (Draw_Flag, bool) {
	switch str {
	case "read-only": return .Read_Only, true
	case "padding":   return .Padding,   true
	}
	return nil, false
}

@(private)
flags_from_field_tag :: proc(tag: reflect.Struct_Tag) -> (flags: Draw_Flags) {
	values, ok := reflect.struct_tag_lookup(tag, "imrefl")
	if !ok {
		return nil
	}

	for true {
		idx := strings.index_byte(values, ',')
		str: string
		if idx == -1 {
			str = values
		} else {
			str = values[:idx]
		}

		flag, ok := tag_value_to_flag(str)
		if ok {
			flags += {flag}
		}

		if idx == -1 {
			break
		}
		values = values[idx + 1:]
	}
	return
}

@(private)
draw_struct_type :: proc(name: string, value: any, flags: Draw_Flags) {
	struct_content :: proc(name: string, value: any, flags: Draw_Flags) {
		bytes := ([^]byte)(value.data)
		for &field in reflect.struct_fields_zipped(value.id) {
			field_flags := flags + flags_from_field_tag(field.tag)
			if .Padding in field_flags {
				continue
			}

			if field.is_using && field.name == "_" {
				field_flags += {.Using_Flatten}
			}
			draw_value(field.name, any{&bytes[field.offset], field.type.id}, field_flags)
		}
	}
	assert_kind(reflect.type_kind(value.id), .Struct)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if .Using_Flatten not_in flags {
		if imgui.Gui_TreeNode(fmt.ctprint(name)) {
			defer imgui.Gui_TreePop()
			struct_content(name, value, flags)
		}
	} else {
		struct_content(name, value, flags - {.Using_Flatten})
	}
}

@(private)
draw_bit_field_type :: proc(name: string, value: any, flags: Draw_Flags) {
	bit_field_content :: proc(name: string, value: any, flags: Draw_Flags) {
		bytes := ([^]byte)(value.data)
		for &field in reflect.bit_fields_zipped(value.id) {
			// TODO: We probably have to parse these differently due to them only occupying a set number of bits
			draw_value(field.name, any{&bytes[field.offset], field.type.id}, flags + flags_from_field_tag(field.tag))
		}
	}
	assert_kind(reflect.type_kind(value.id), .Bit_Field)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if .Using_Flatten not_in flags {
		if imgui.Gui_TreeNode(fmt.ctprint(name)) {
			defer imgui.Gui_TreePop()
			bit_field_content(name, value, flags)
		}
	} else {
		bit_field_content(name, value, flags - {.Using_Flatten})
	}
}

@(private)
draw_union_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Union)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		type_info := type_info_of(value.id)
		union_info := type_info.variant.(reflect.Type_Info_Union)
		bytes := ([^]byte)(value.data)

		variant_idx, _ := reflect.as_u64(any{&bytes[union_info.tag_offset], union_info.tag_type.id})
		if variant_idx == 0 {
			imgui.Gui_TextEx(fmt.ctprint("variant: nil"))
			return
		}

		variant_info := union_info.variants[variant_idx - 1]
		imgui.Gui_TextEx(fmt.ctprintf("variant: %v", variant_info.id))
		draw_value("data", any{value.data, variant_info.id}, flags)
	}
}

@(private)
draw_bit_set_type :: proc(name: string, value: any, flags: Draw_Flags) {
	value := value
	assert_kind(reflect.type_kind(value.id), .Bit_Set)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		type_info := type_info_of(value.id)
		set_info := type_info.variant.(reflect.Type_Info_Bit_Set)

		value.id = runtime.typeid_underlying(value.id)
		value_u64 := read_int_any_as_type(value, u64)

		imgui.Gui_BeginDisabled(.Read_Only in flags)
		defer imgui.Gui_EndDisabled()

		new_val: u64
		for &enum_value in reflect.enum_fields_zipped(set_info.elem.id) {
			active := (1 << u64(enum_value.value)) & value_u64 != 0
			imgui.Gui_Checkbox(fmt.ctprint(enum_value.name), &active)
			if active {
				new_val += 1 << u64(enum_value.value)
			}
		}
		write_int_to_any(new_val, value)
	}
}

@(private)
draw_enum_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Enum)

	getter :: proc "c" (user_data: rawptr, idx: i32) -> cstring {
		context = runtime.default_context()
		fields := (^#soa[]reflect.Enum_Field)(user_data)
		return fmt.ctprint(fields[idx].name)
	}

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	if imgui.Gui_BeginCombo(fmt.ctprint(name), fmt.ctprint(reflect.enum_string(value)), nil) {
		defer imgui.Gui_EndCombo()

		value_i64 := read_int_any_as_type(value, i64)
		for &enum_value in reflect.enum_fields_zipped(value.id) {
			if i64(enum_value.value) == value_i64 {
				continue
			}

			if imgui.Gui_Selectable(fmt.ctprint(enum_value.name)) {
				write_int_to_any(enum_value.value, value)
				break
			}
		}
	}
}

@(private)
draw_any_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Any)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if (^any)(value.data).id == nil {
		imgui.Gui_TextEx(fmt.ctprintf("%s: nil", name))
		return
	}

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		draw_type_id("typeid", (^any)(value.data).id, flags)
		draw_value("data", (^any)(value.data)^, flags)
		imgui.Gui_TreePop()
	}
}

@(private)
draw_type_id :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Type_Id)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_TextEx(fmt.ctprintf("%s: %v", name, (^typeid)(value.data)^))
}

@(private)
draw_pointer_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Pointer)
	
	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if value.id == rawptr {
		imgui.Gui_TextEx(fmt.ctprintf("%s: %v", name, (^rawptr)(value.data)^))
	} else {
		pointee_type_id := type_info_of(value.id).variant.(reflect.Type_Info_Pointer).elem.id
		data_ptr := (^rawptr)(value.data)^
		draw_value(fmt.tprintf("%s: %v", name, data_ptr), any{data_ptr, pointee_type_id}, flags)
	}
}

@(private)
draw_string_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .String)
	
	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	switch value.id {
	// How do we support utf16 strings properly?
	case cstring:   imgui.Gui_TextEx(fmt.ctprintf("\"%s\" %s", (^cstring  )(value.data)^, name))
	case cstring16: imgui.Gui_TextEx(fmt.ctprintf("\"%s\" %s", (^cstring16)(value.data)^, name))
	case string:    imgui.Gui_TextEx(fmt.ctprintf("\"%s\" %s", (^string   )(value.data)^, name))
	case string16:  imgui.Gui_TextEx(fmt.ctprintf("\"%s\" %s", (^string16 )(value.data)^, name))
	}
}

@(private)
draw_complex_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Complex)
	real, imag: rawptr
	data_type: imgui.GuiDataType
	switch value.id {
	// case complex32:  dataType = .Float // TODO: It's unclear what we should do here
	case complex64:
		data_type = .Float
		raw := (^runtime.Raw_Complex64)(value.data)
		real = &raw.real
		imag = &raw.imag
	case complex128:
		data_type = .Double
		raw := (^runtime.Raw_Complex128)(value.data)
		real = &raw.real
		imag = &raw.imag
	case: panic("Invalid type id!")
	}

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	// We could alternatively use imgui.Gui_ScalarN here but we'd lose the text
	width := imgui.Gui_GetContentRegionAvail().x / 3 // TODO: make this less arbitrary
	imgui.Gui_SetNextItemWidth(width)
	imgui.Gui_InputScalar("+", data_type, real)
	imgui.Gui_SameLine()
	imgui.Gui_SetNextItemWidth(width)
	imgui.Gui_InputScalar(fmt.ctprintf("i %s", name), data_type, imag)
}

@(private)
draw_quat_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Quaternion)
	data_type: imgui.GuiDataType
	switch value.id {
	// case quaternion64:  data_type = // TODO: f16
	case quaternion128: data_type = .Float
	case quaternion256: data_type = .Double
	case: panic("Invalid type id!!")
	}

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()	

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	imgui.Gui_DragScalarN(fmt.ctprint(name), data_type, value.data, 4)
}

@(private)
draw_bool_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Boolean)
	value_bool, _ := reflect.as_bool(value)
	
	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	if imgui.Gui_Checkbox(fmt.ctprint(name), &value_bool) {
		switch value.id {
		case b8:   (^b8  )(value.data)^ = auto_cast value_bool
		case b16:  (^b16 )(value.data)^ = auto_cast value_bool
		case b32:  (^b32 )(value.data)^ = auto_cast value_bool
		case b64:  (^b64 )(value.data)^ = auto_cast value_bool
		case bool: (^bool)(value.data)^ = value_bool
		}
	}
}

@(private)
draw_literal_type :: proc(name: string, value: any, flags: Draw_Flags) {
	kind := reflect.type_kind(value.id)
	fmt.assertf(kind == .Integer || kind == .Float || kind == .Rune, "Value type kind must be %v, %v or %v! Got %v", reflect.Type_Kind.Integer, reflect.Type_Kind.Float, reflect.Type_Kind.Rune, kind)
	
	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	imgui.Gui_InputScalar(fmt.ctprint(name), type_id_to_data_type(value.id), value.data)
}

@(private)
draw_map_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Map)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		map_info := type_info_of(value.id).variant.(reflect.Type_Info_Map)

		width := (imgui.Gui_GetContentRegionAvail().x - imgui.Gui_GetStyle().ItemSpacing.x * 3) / 4
		imgui.Gui_SetNextItemWidth(width)
		
		it: int = 0
		for idx := 0;; idx += 1 {
			key, value, ok := reflect.iterate_map(value, &it)
			if !ok {
				break
			}

			if imgui.Gui_TreeNode(fmt.ctprint(idx)) {
				draw_value("key",   any{key.data, map_info.key.id}, flags)
				draw_value("value", any{value.data, map_info.value.id}, flags)
				imgui.Gui_TreePop()
			}
		}
	}
}

@(private)
draw_matrix_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Matrix)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		type_info := type_info_of(value.id)
		matrix_info := type_info.variant.(reflect.Type_Info_Matrix)

		row_stride := matrix_info.layout == .Row_Major ? (matrix_info.elem_size * matrix_info.column_count) : matrix_info.elem_size
		column_stride := matrix_info.layout == .Column_Major ? (matrix_info.elem_size * matrix_info.row_count) : matrix_info.elem_size

		data_type := type_id_to_data_type(matrix_info.elem.id)
		width := (imgui.Gui_GetContentRegionAvail().x - imgui.Gui_GetStyle().ItemSpacing.x * 3) / f32(matrix_info.column_count)
		bytes := ([^]byte)(value.data)

		for c in 0..<matrix_info.column_count {
			for r in 0..<matrix_info.row_count {
				imgui.Gui_SetNextItemWidth(width)
				if r > 0 {
					imgui.Gui_SameLine()
				}

				ptr := &bytes[c * column_stride + r * row_stride]
				imgui.Gui_PushIDPtr(ptr)
				defer imgui.Gui_PopID()

				imgui.Gui_BeginDisabled(.Read_Only in flags)
				defer imgui.Gui_EndDisabled()

				imgui.Gui_InputScalar("", data_type, ptr)
			}
		}
	}
}

@(private)
draw_array_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Array)
	
	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		array_info := type_info_of(value.id).variant.(reflect.Type_Info_Array)
		for idx in 0..<array_info.count {
			draw_value(fmt.tprint(idx), any{rawptr(uintptr(value.data) + uintptr(array_info.elem.size * idx)), array_info.elem.id}, flags)
		}
	}
}

@(private)
draw_slice_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Slice)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		slice_info := type_info_of(value.id).variant.(reflect.Type_Info_Slice)
		raw_slice := (^runtime.Raw_Slice)(value.data)
		bytes := ([^]byte)(raw_slice.data)
		
		for idx in 0..<raw_slice.len {
			draw_value(fmt.tprint(idx), any{&bytes[idx * slice_info.elem_size], slice_info.elem.id}, flags)
		}
	}
}

@(private)
draw_enum_array_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Enumerated_Array)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		array_info := type_info_of(value.id).variant.(reflect.Type_Info_Enumerated_Array)
		// TODO: Implement.
	}
}

@(private)
draw_dyn_array_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Dynamic_Array)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		array_info := type_info_of(value.id).variant.(reflect.Type_Info_Dynamic_Array)
		raw_array := (^runtime.Raw_Dynamic_Array)(value.data)
		bytes := ([^]byte)(raw_array.data)
		
		for idx in 0..<raw_array.len {
			draw_value(fmt.tprint(idx), any{&bytes[array_info.elem_size * idx], array_info.elem.id}, flags)
		}
	}
}

@(private)
draw_multi_pointer_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Multi_Pointer)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	imgui.Gui_BeginDisabled(.Read_Only in flags)
	defer imgui.Gui_EndDisabled()

	draw_pointer_type(name, any{value.data, typeid_of(rawptr)}, nil)
}

@(private)
draw_simd_vec_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Simd_Vector)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		vector_info := type_info_of(value.id).variant.(reflect.Type_Info_Simd_Vector)
		bytes := ([^]byte)(value.data)
		for idx in 0..<vector_info.count {
			draw_value(fmt.tprint(idx), any{&bytes[vector_info.elem_size * idx], vector_info.elem.id}, flags)
		}
	}
}

// TODO: What's this even meant to represent?
// How should we display this?
@(private)
draw_soa_pointer_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Soa_Pointer)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		raw_soa := (^runtime.Raw_Soa_Pointer)(value.data)
		soa_info := type_info_of(value.id).variant.(reflect.Type_Info_Soa_Pointer)
	}
}

// What should this even do? I'll just write the proc address.
// Maybe we can make the proc callable with struct tags.
@(private)
draw_proc_type :: proc(name: string, value: any, flags: Draw_Flags) {
	assert_kind(reflect.type_kind(value.id), .Procedure)

	imgui.Gui_PushIDPtr(value.data)
	defer imgui.Gui_PopID()

	if imgui.Gui_TreeNode(fmt.ctprint(name)) {
		defer imgui.Gui_TreePop()

		imgui.Gui_Text(fmt.ctprintf("%v proc address", (^rawptr)(value.data)^))
	}
}

