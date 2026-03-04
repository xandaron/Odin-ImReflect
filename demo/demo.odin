#+feature dynamic-literals
package Demo

import "base:runtime"
import "core:fmt"
import "core:mem"

import imrefl "../imreflect"
import bootstrap "../imreflect/bootstrap"

main :: proc() {
	if !bootstrap.init() {
		fmt.print("Failed bootstrap")
		return
	}
	defer bootstrap.shutdown()

	int64: i64 = 64
	float32: f32 = 3.1415926
	bool32: b32 = true
	str: string = "Test string!"
	comp: complex128 = complex(4.5, 16.2)
	quat: quaternion128 = quaternion(x = 1, y = 1, z = 1, w = 0)
	Enum :: enum {
		_0,
		_1,
		_2,
		_3,
	}
	Bit_Set :: bit_set[Enum]
	enum_val: Enum = ._2
	bits: Bit_Set = {._0, ._3}
	field: bit_field u32 {
		i: u32 | 8,
		j: u32 | 8,
		k: u32 | 8,
		w: u32 | 8,
	}
	Struct :: struct {
		using _: struct {
			i, j, k: int,
		},
		
		x, y, z: f32,
		ptr: ^Struct,
	}
	stru: Struct = {
		i = 1,
		j = 2,
		k = 3,
		x = 1,
		y = 2,
		z = 3,
	}
	Union :: union {
		Struct,
		Bit_Set,
		Enum,
	}
	uni: Union = stru
	Raw :: struct #raw_union {
		stru: Struct,
		bits: Bit_Set,
		enue: Enum,
	}
	raw: Raw = {
		enue = enum_val,
	}
	ptr := rawptr(uintptr(0xFB2A))
	any_val: any = uni
	id: typeid = typeid_of(int)
	arr: [4]int = {0, 1, 2, 3}
	slice: []int = arr[:]
	dyn: [dynamic]int = {0, 1, 2, 3}
	
	alloc_ptr, _ := mem.alloc(4 * size_of(int))
	defer free(alloc_ptr)
	mult := ([^]int)(alloc_ptr)
	
	mapp: map[int]string
	mapp[10] = "ten"
	mapp[2] = "two"
	mapp[4] = "four"
	defer delete(mapp)
	
	mat: matrix[4, 4]int = 1
	mat[2, 3] = 10

	simd: #simd[4]int = {0, 1, 2, 3}
	fn: proc() = proc() {
		return
	}

	for bootstrap.start_frame("Demo") {
		imrefl.draw_value("int64", int64)
		imrefl.draw_value("float32", float32)
		imrefl.draw_value("bool32", bool32)
		imrefl.draw_value("str", str)
		imrefl.draw_value("comp", comp)
		imrefl.draw_value("quat", quat)
		imrefl.draw_value("enum_val", enum_val)
		imrefl.draw_value("bits", bits)
		imrefl.draw_value("field", field)
		imrefl.draw_value("stru", stru)
		imrefl.draw_value("uni", uni)
		imrefl.draw_value("raw", raw)
		imrefl.draw_value("ptr", ptr)
		imrefl.draw_value("any_val", any_val)
		imrefl.draw_value("id", id)
		imrefl.draw_value("arr", arr)
		imrefl.draw_value("slice", slice)
		imrefl.draw_value("dyn", dyn)
		imrefl.draw_value("mult", mult)
		imrefl.draw_value("mapp", mapp)
		imrefl.draw_value("mat", mat)
		imrefl.draw_value("simd", simd)
		imrefl.draw_value("fn", fn)
		bootstrap.end_frame()
	}

	free_all(context.temp_allocator)
	free_all(context.allocator)
}

