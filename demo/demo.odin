package Demo

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:mem"
import "vendor:OpenGL"
import "vendor:glfw"

import imgui "../imgui"
import imguiGLFW "../imgui/glfw"
import imguiOpenGL "../imgui/opengl3"

import imrefl "../imreflect"
import bootstrap "../imreflect/bootstrap"

My_Enum :: enum {
	_0 = 0,
	_1,
	_2,
	_3,
	_4,
	_5,
	_6,
	_7,
}

My_Bit_Set :: bit_set[My_Enum]

My_Union :: union {
	My_Enum,
	My_Bit_Set,
}

My_Raw_Union :: struct #raw_union {
	i: int,
	u: uint,
	f: f32,
	d: f64,
}

My_Bit_Field :: bit_field u32 {
	_0_10:  int  | 10,
	_10_15: byte | 5,
	_10_32: u32  | 17,
}

My_Proc :: #type proc(string)

My_Struct :: struct {
	str:       string,
	str16:     string16,
	cstr:      cstring,
	cstr16:    cstring16,
	int8:      i8,
	uint8:     u8,
	int16:     i16,
	uint16:    u16,
	int32:     i32,
	uint32:    u32,
	int64:     i64,
	uint64:    u64,
	float:     f32,
	double:    f64,
	bool:      bool,
	bool8:     b8,
	bool16:    b16,
	bool32:    b32,
	bool64:    b64,
	comp64:    complex64,
	comp128:   complex128,
	quat128:   quaternion128,
	quat256:   quaternion256,
	ptr:       rawptr,
	typePtr:   ^My_Struct,
	a:         any,
	enumValue: My_Enum,
	bits:      My_Bit_Set,
	uni:       My_Union,
	raw:       My_Raw_Union,
	mat:       matrix[4,4]f32,
	mapp:      map[int]string,
	arr:       [8]My_Enum,
	slice:     []int,
	dynArr:    [dynamic]int,
	multiPtr:  [^]int,
	simd:      #simd[4]int,
	fn:        My_Proc,
}

main :: proc() {
	if !bootstrap.init() {
		fmt.print("Failed bootstrap")
		return
	}
	defer bootstrap.shutdown()

	// test2 functions to make sure anon types still output correctly
	test2: struct {
		enumValue: enum {
			_0 = 0,
			_1,
			_2,
			_3,
			_4,
			_5,
			_6,
			_7,
		},
		a: any,
	}

	dummy: My_Struct
	dummy.str = "dummy"

	test: My_Struct
	test.bits = {._0, ._3}
	test.ptr = rawptr(uintptr(0xFFFF))
	test.a = 8
	test.typePtr = &dummy
	test.str    = "test"
	test.str16  = "test"
	test.cstr   = "ctest"
	test.cstr16 = "ctest"
	test.uni = My_Union(My_Bit_Set{._3})
	test.raw.i = 5
	test.mat = 1
	test.mapp[10]  = "ten"
	test.mapp[100] = "one hundred"
	test.mapp[2]   = "two"
	
	for val, idx in My_Enum {
		test.arr[idx] = val
	}
	
	test.slice = make([]int, 5)
	for &val, idx in test.slice {
		val = idx
	}
	
	test.dynArr = make([dynamic]int, 5)
	for &val, idx in test.dynArr {
		val = idx
	}

	ptr, _ := mem.alloc(size_of(int) * 5)
	test.multiPtr = ([^]int)(ptr)
	// We currently can't get the data from a multi-pointer due to the lack of len info.
	// But we might be able yo tag a length in future
	for idx in 0..<5 {
		test.multiPtr[idx] = idx
	}

	test.simd = {0, 1, 2, 3}
	test.fn = proc(text: string) {
		fmt.print(text)
	}

	for bootstrap.start_frame("Demo") {
		imrefl.draw_value("test", test)
		imrefl.draw_value("test2", test2)
		bootstrap.end_frame()
	}

	free_all(context.temp_allocator)
	free_all(context.allocator)
}

