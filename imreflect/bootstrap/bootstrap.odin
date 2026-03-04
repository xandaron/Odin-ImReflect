package ImRefl_Bootstrap

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:mem"
import OpenGL "vendor:OpenGL"
import "vendor:glfw"

import "../../imgui"
import imguiGLFW "../../imgui/glfw"
import imguiOpenGL "../../imgui/opengl3"

@(private)
imgui_alloc :: proc "c" (sz: c.size_t, user_data: rawptr) -> rawptr {
	context = runtime.default_context()
	ptr, _ := mem.alloc(int(sz), allocator = (^mem.Allocator)(user_data)^)
	return ptr
}

@(private)
imgui_free :: proc "c" (ptr: rawptr, user_data: rawptr) {
	context = runtime.default_context()
	mem.free(ptr, allocator = (^mem.Allocator)(user_data)^)
}

@(private)
window: glfw.WindowHandle

@(private)
internal_allocator: mem.Allocator

@(private)
ctx: ^imgui.GuiContext

init :: proc(width, height: i32, allocator := context.allocator) -> bool {
	internal_allocator = allocator
	if !glfw.Init() {
		fmt.println("Failed init GLFW")
		return false
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.RESIZABLE, false)

	window = glfw.CreateWindow(width, height, "Demo", nil, nil)
	if window == nil {
		fmt.println("Failed window create.")
		return false
	}
	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	imgui.Gui_SetAllocatorFunctions(imgui_alloc, imgui_free, &internal_allocator)

	ctx = imgui.Gui_CreateContext(nil)
	imgui.Gui_StyleColorsDark(nil)

	if !imguiGLFW.InitForOpenGL(window, true) {
		fmt.println("Failed init imgui glfw.")
		return false
	}

	OpenGL.load_up_to(3, 3, glfw.gl_set_proc_address)
	if !imguiOpenGL.Init() {
		fmt.println("Failed init imgui OpenGL.")
		return false
	}
	return true
}

shutdown :: proc() {
	imguiOpenGL.Shutdown()
	imguiGLFW.Shutdown()
	imgui.Gui_DestroyContext(ctx)
	glfw.DestroyWindow(window)
	glfw.Terminate()
}

start_frame :: proc(name: cstring) -> bool {
	if glfw.WindowShouldClose(window) {
		return false
	}
	
	glfw.PollEvents()

	imguiOpenGL.NewFrame()
	imguiGLFW.NewFrame()
	imgui.Gui_NewFrame()

	imgui.Gui_Begin(name, nil, nil)

	return true
}

end_frame :: proc() {
	imgui.Gui_End()

	imgui.Gui_EndFrame()

	// Rendering
	width, height := glfw.GetFramebufferSize(window)
	OpenGL.Viewport(0, 0, width, height)
	OpenGL.ClearColor(100.0 / 255.0, 149.0 / 255.0, 237.0 / 255.0, 1)
	OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)
	imgui.Gui_Render()
	imguiOpenGL.RenderDrawData(imgui.Gui_GetDrawData())

	glfw.SwapBuffers(window)
	free_all(context.temp_allocator)
}

