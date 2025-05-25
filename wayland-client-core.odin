/*
* Copyright © 2008 Kristian Høgsberg
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice (including the
* next paragraph) shall be included in all copies or substantial
* portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
* BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
* ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
package wayland

import "core:c"

_ :: c

foreign import lib "system:libwayland-client.so"

WL_MARSHAL_FLAG_DESTROY :: 1 << 0

Display :: struct {}
Proxy :: struct {}
Event_Queue :: struct {}
Event_Loop :: struct {}
Event_Source :: struct {}
Resource :: struct {}
Client :: struct {}
Object :: struct {}
Global :: struct {}
@(default_calling_convention="c", link_prefix="wl_")
foreign lib {
	event_queue_destroy                       :: proc(queue: ^Event_Queue) ---
	proxy_marshal_flags                       :: proc(proxy: ^Proxy, opcode: u32, interface: ^Interface, version: u32, flags: u32) -> ^Proxy ---
	proxy_marshal_array_flags                 :: proc(proxy: ^Proxy, opcode: u32, interface: ^Interface, version: u32, flags: u32, args: ^Argument) -> ^Proxy ---
	proxy_marshal                             :: proc(p: ^Proxy, opcode: u32) ---
	proxy_marshal_array                       :: proc(p: ^Proxy, opcode: u32, args: ^Argument) ---
	proxy_create                              :: proc(factory: ^Proxy, interface: ^Interface) -> ^Proxy ---
	proxy_create_wrapper                      :: proc(proxy: rawptr) -> rawptr ---
	proxy_wrapper_destroy                     :: proc(proxy_wrapper: rawptr) ---
	proxy_marshal_constructor                 :: proc(proxy: ^Proxy, opcode: u32, interface: ^Interface) -> ^Proxy ---
	proxy_marshal_constructor_versioned       :: proc(proxy: ^Proxy, opcode: u32, interface: ^Interface, version: u32) -> ^Proxy ---
	proxy_marshal_array_constructor           :: proc(proxy: ^Proxy, opcode: u32, args: ^Argument, interface: ^Interface) -> ^Proxy ---
	proxy_marshal_array_constructor_versioned :: proc(proxy: ^Proxy, opcode: u32, args: ^Argument, interface: ^Interface, version: u32) -> ^Proxy ---
	proxy_destroy                             :: proc(proxy: ^Proxy) ---
	proxy_add_listener                        :: proc(proxy: ^Proxy, implementation: proc "c" (), data: rawptr) -> i32 ---
	proxy_get_listener                        :: proc(proxy: ^Proxy) -> rawptr ---
	proxy_add_dispatcher                      :: proc(proxy: ^Proxy, dispatcher_func: Dispatcher_Func_T, dispatcher_data: rawptr, data: rawptr) -> i32 ---
	proxy_set_user_data                       :: proc(proxy: ^Proxy, user_data: rawptr) ---
	proxy_get_user_data                       :: proc(proxy: ^Proxy) -> rawptr ---
	proxy_get_version                         :: proc(proxy: ^Proxy) -> u32 ---
	proxy_get_id                              :: proc(proxy: ^Proxy) -> u32 ---
	proxy_set_tag                             :: proc(proxy: ^Proxy, tag: [^]cstring) ---
	proxy_get_tag                             :: proc(proxy: ^Proxy) -> [^]cstring ---
	proxy_get_class                           :: proc(proxy: ^Proxy) -> cstring ---
	proxy_get_display                         :: proc(proxy: ^Proxy) -> ^Display ---
	proxy_set_queue                           :: proc(proxy: ^Proxy, queue: ^Event_Queue) ---
	proxy_get_queue                           :: proc(proxy: ^Proxy) -> ^Event_Queue ---
	event_queue_get_name                      :: proc(queue: ^Event_Queue) -> cstring ---
	display_connect                           :: proc(name: cstring) -> ^Display ---
	display_connect_to_fd                     :: proc(fd: i32) -> ^Display ---
	display_disconnect                        :: proc(display: ^Display) ---
	display_get_fd                            :: proc(display: ^Display) -> i32 ---
	display_dispatch                          :: proc(display: ^Display) -> i32 ---
	display_dispatch_queue                    :: proc(display: ^Display, queue: ^Event_Queue) -> i32 ---
	display_dispatch_queue_pending            :: proc(display: ^Display, queue: ^Event_Queue) -> i32 ---
	display_dispatch_pending                  :: proc(display: ^Display) -> i32 ---
	display_get_error                         :: proc(display: ^Display) -> i32 ---
	display_get_protocol_error                :: proc(display: ^Display, interface: ^^Interface, id: ^u32) -> u32 ---
	display_flush                             :: proc(display: ^Display) -> i32 ---
	display_roundtrip_queue                   :: proc(display: ^Display, queue: ^Event_Queue) -> i32 ---
	display_roundtrip                         :: proc(display: ^Display) -> i32 ---
	display_create_queue                      :: proc(display: ^Display) -> ^Event_Queue ---
	display_create_queue_with_name            :: proc(display: ^Display, name: cstring) -> ^Event_Queue ---
	display_prepare_read_queue                :: proc(display: ^Display, queue: ^Event_Queue) -> i32 ---
	display_prepare_read                      :: proc(display: ^Display) -> i32 ---
	display_cancel_read                       :: proc(display: ^Display) ---
	display_read_events                       :: proc(display: ^Display) -> i32 ---
	log_set_handler_client                    :: proc(handler: Log_Func_T) ---
	display_set_max_buffer_size               :: proc(display: ^Display, max_buffer_size: uint) ---
}
