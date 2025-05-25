package wayland
import "core:testing"
import "core:os"
import "core:fmt"
import "core:log"
main :: proc() {}

//should connect to wayland compositor.
@(test)
should_connect_to_compositor :: proc(t: ^testing.T) {
	display := display_connect(nil)
	wayland_display := os.get_env("WAYLAND_DISPLAY")
	ensure(len(wayland_display)  > 0 , "Not running in wayland server")
	testing.expect(t, display != nil)
}





