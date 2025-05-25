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
import "core:sys/posix"
_ :: c

foreign import lib "system:libwayland-server.so"

EVENT_READABLE :: 1

EVENT_WRITABLE :: 2

EVENT_HANGUP :: 4

EVENT_ERROR :: 8

/** File descriptor dispatch function type
*
* Functions of this type are used as callbacks for file descriptor events.
*
* \param fd The file descriptor delivering the event.
* \param mask Describes the kind of the event as a bitwise-or of:
* \c WL_EVENT_READABLE, \c WL_EVENT_WRITABLE, \c WL_EVENT_HANGUP,
* \c WL_EVENT_ERROR.
* \param data The user data argument of the related wl_event_loop_add_fd()
* call.
* \return If the event source is registered for re-check with
* wl_event_source_check(): 0 for all done, 1 for needing a re-check.
* If not registered, the return value is ignored and should be zero.
*
* \sa wl_event_loop_add_fd()
* \memberof wl_event_source
*/
Event_Loop_Fd_Func_T :: proc "c" (i32, u32, rawptr) -> i32

/** Timer dispatch function type
*
* Functions of this type are used as callbacks for timer expiry.
*
* \param data The user data argument of the related wl_event_loop_add_timer()
* call.
* \return If the event source is registered for re-check with
* wl_event_source_check(): 0 for all done, 1 for needing a re-check.
* If not registered, the return value is ignored and should be zero.
*
* \sa wl_event_loop_add_timer()
* \memberof wl_event_source
*/
Event_Loop_Timer_Func_T :: proc "c" (rawptr) -> i32

/** Signal dispatch function type
*
* Functions of this type are used as callbacks for (POSIX) signals.
*
* \param signal_number
* \param data The user data argument of the related wl_event_loop_add_signal()
* call.
* \return If the event source is registered for re-check with
* wl_event_source_check(): 0 for all done, 1 for needing a re-check.
* If not registered, the return value is ignored and should be zero.
*
* \sa wl_event_loop_add_signal()
* \memberof wl_event_source
*/
Event_Loop_Signal_Func_T :: proc "c" (i32, rawptr) -> i32

/** Idle task function type
*
* Functions of this type are used as callbacks before blocking in
* wl_event_loop_dispatch().
*
* \param data The user data argument of the related wl_event_loop_add_idle()
* call.
*
* \sa wl_event_loop_add_idle() wl_event_loop_dispatch()
* \memberof wl_event_source
*/
Event_Loop_Idle_Func_T :: proc "c" (rawptr)

Notify_Func_T :: proc "c" (^Listener, rawptr)

Global_Bind_Func_T :: proc "c" (^Client, rawptr, u32, u32)

/** A filter function for wl_global objects
*
* \param client The client object
* \param global The global object to show or hide
* \param data   The user data pointer
*
* A filter function enables the server to decide which globals to
* advertise to each client.
*
* When a wl_global filter is set, the given callback function will be
* called during wl_global advertisement and binding.
*
* This function should return true if the global object should be made
* visible to the client or false otherwise.
*/
Display_Global_Filter_Func_T :: proc "c" (^Client, ^Global, rawptr) -> bool

Client_For_Each_Resource_Iterator_Func_T :: proc "c" (^Resource, rawptr) -> Iterator_Result

User_Data_Destroy_Func_T :: proc "c" (rawptr)

/** \class wl_listener
*
* \brief A single listener for Wayland signals
*
* wl_listener provides the means to listen for wl_signal notifications. Many
* Wayland objects use wl_listener for notification of significant events like
* object destruction.
*
* Clients should create wl_listener objects manually and can register them as
* listeners to signals using #wl_signal_add, assuming the signal is
* directly accessible. For opaque structs like wl_event_loop, adding a
* listener should be done through provided accessor methods. A listener can
* only listen to one signal at a time.
*
* \code
* struct wl_listener your_listener;
*
* your_listener.notify = your_callback_method;
*
* // Direct access
* wl_signal_add(&some_object->destroy_signal, &your_listener);
*
* // Accessor access
* wl_event_loop *loop = ...;
* wl_event_loop_add_destroy_listener(loop, &your_listener);
* \endcode
*
* If the listener is part of a larger struct, #wl_container_of can be used
* to retrieve a pointer to it:
*
* \code
* void your_listener(struct wl_listener *listener, void *data)
* {
* 	struct your_data *data;
*
* 	your_data = wl_container_of(listener, data, your_member_name);
* }
* \endcode
*
* If you need to remove a listener from a signal, use wl_list_remove().
*
* \code
* wl_list_remove(&your_listener.link);
* \endcode
*
* \sa wl_signal
*/
Listener :: struct {
	link:   List,
	notify: Notify_Func_T,
}

/** \class wl_signal
*
* \brief A source of a type of observable event
*
* Signals are recognized points where significant events can be observed.
* Compositors as well as the server can provide signals. Observers are
* wl_listener's that are added through #wl_signal_add. Signals are emitted
* using #wl_signal_emit, which will invoke all listeners until that
* listener is removed by wl_list_remove() (or whenever the signal is
* destroyed).
*
* \sa wl_listener for more information on using wl_signal
*/
Signal :: struct {
	listener_list: List,
}

Resource_Destroy_Func_T :: proc "c" (^Resource)

Protocol_Logger_Type :: enum c.int {
	REQUEST,
	EVENT,
}

Protocol_Logger_Message :: struct {
	resource:        ^Resource,
	message_opcode:  i32,
	message:         ^Message,
	arguments_count: i32,
	arguments:       ^Argument,
}

Protocol_Logger_Func_T :: proc "c" (rawptr, Protocol_Logger_Type, ^Protocol_Logger_Message)

@(default_calling_convention="c", link_prefix="wl_")
foreign lib {
	/** \struct wl_event_source
	*
	* \brief An abstract event source
	*
	* This is the generic type for fd, timer, signal, and idle sources.
	* Functions that operate on specific source types must not be used with
	* a different type, even if the function signature allows it.
	*/
	event_loop_create                    :: proc() -> ^Event_Loop ---
	event_loop_destroy                   :: proc(loop: ^Event_Loop) ---
	event_loop_add_fd                    :: proc(loop: ^Event_Loop, fd: i32, mask: u32, func: Event_Loop_Fd_Func_T, data: rawptr) -> ^Event_Source ---
	event_source_fd_update               :: proc(source: ^Event_Source, mask: u32) -> i32 ---
	event_loop_add_timer                 :: proc(loop: ^Event_Loop, func: Event_Loop_Timer_Func_T, data: rawptr) -> ^Event_Source ---
	event_loop_add_signal                :: proc(loop: ^Event_Loop, signal_number: i32, func: Event_Loop_Signal_Func_T, data: rawptr) -> ^Event_Source ---
	event_source_timer_update            :: proc(source: ^Event_Source, ms_delay: i32) -> i32 ---
	event_source_remove                  :: proc(source: ^Event_Source) -> i32 ---
	event_source_check                   :: proc(source: ^Event_Source) ---
	event_loop_dispatch                  :: proc(loop: ^Event_Loop, timeout: i32) -> i32 ---
	event_loop_dispatch_idle             :: proc(loop: ^Event_Loop) ---
	event_loop_add_idle                  :: proc(loop: ^Event_Loop, func: Event_Loop_Idle_Func_T, data: rawptr) -> ^Event_Source ---
	event_loop_get_fd                    :: proc(loop: ^Event_Loop) -> i32 ---
	event_loop_add_destroy_listener      :: proc(loop: ^Event_Loop, listener: ^Listener) ---
	event_loop_get_destroy_listener      :: proc(loop: ^Event_Loop, notify: Notify_Func_T) -> ^Listener ---
	display_create                       :: proc() -> ^Display ---
	display_destroy                      :: proc(display: ^Display) ---
	display_get_event_loop               :: proc(display: ^Display) -> ^Event_Loop ---
	display_add_socket                   :: proc(display: ^Display, name: cstring) -> i32 ---
	display_add_socket_auto              :: proc(display: ^Display) -> cstring ---
	display_add_socket_fd                :: proc(display: ^Display, sock_fd: i32) -> i32 ---
	display_terminate                    :: proc(display: ^Display) ---
	display_run                          :: proc(display: ^Display) ---
	display_flush_clients                :: proc(display: ^Display) ---
	display_destroy_clients              :: proc(display: ^Display) ---
	display_set_default_max_buffer_size  :: proc(display: ^Display, max_buffer_size: uint) ---
	display_get_serial                   :: proc(display: ^Display) -> u32 ---
	display_next_serial                  :: proc(display: ^Display) -> u32 ---
	display_add_destroy_listener         :: proc(display: ^Display, listener: ^Listener) ---
	display_add_client_created_listener  :: proc(display: ^Display, listener: ^Listener) ---
	display_get_destroy_listener         :: proc(display: ^Display, notify: Notify_Func_T) -> ^Listener ---
	global_create                        :: proc(display: ^Display, interface: ^Interface, version: i32, data: rawptr, bind: Global_Bind_Func_T) -> ^Global ---
	global_remove                        :: proc(global: ^Global) ---
	global_destroy                       :: proc(global: ^Global) ---
	display_set_global_filter            :: proc(display: ^Display, filter: Display_Global_Filter_Func_T, data: rawptr) ---
	global_get_interface                 :: proc(global: ^Global) -> ^Interface ---
	global_get_name                      :: proc(global: ^Global, client: ^Client) -> u32 ---
	global_get_version                   :: proc(global: ^Global) -> u32 ---
	global_get_display                   :: proc(global: ^Global) -> ^Display ---
	global_get_user_data                 :: proc(global: ^Global) -> rawptr ---
	global_set_user_data                 :: proc(global: ^Global, data: rawptr) ---
	client_create                        :: proc(display: ^Display, fd: i32) -> ^Client ---
	display_get_client_list              :: proc(display: ^Display) -> ^List ---
	client_get_link                      :: proc(client: ^Client) -> ^List ---
	client_from_link                     :: proc(link: ^List) -> ^Client ---
	client_destroy                       :: proc(client: ^Client) ---
	client_flush                         :: proc(client: ^Client) ---
	client_get_credentials               :: proc(client: ^Client, pid: ^posix.pid_t, uid: ^posix.uid_t, gid: ^posix.gid_t) ---
	client_get_fd                        :: proc(client: ^Client) -> i32 ---
	client_add_destroy_listener          :: proc(client: ^Client, listener: ^Listener) ---
	client_get_destroy_listener          :: proc(client: ^Client, notify: Notify_Func_T) -> ^Listener ---
	client_add_destroy_late_listener     :: proc(client: ^Client, listener: ^Listener) ---
	client_get_destroy_late_listener     :: proc(client: ^Client, notify: Notify_Func_T) -> ^Listener ---
	client_get_object                    :: proc(client: ^Client, id: u32) -> ^Resource ---
	client_post_no_memory                :: proc(client: ^Client) ---
	client_post_implementation_error     :: proc(client: ^Client, msg: cstring) ---
	client_add_resource_created_listener :: proc(client: ^Client, listener: ^Listener) ---
	client_for_each_resource             :: proc(client: ^Client, iterator: Client_For_Each_Resource_Iterator_Func_T, user_data: rawptr) ---
	client_set_user_data                 :: proc(client: ^Client, data: rawptr, dtor: User_Data_Destroy_Func_T) ---
	client_get_user_data                 :: proc(client: ^Client) -> rawptr ---
	client_set_max_buffer_size           :: proc(client: ^Client, max_buffer_size: uint) ---

	/** Initialize a new \ref wl_signal for use.
	*
	* \param signal The signal that will be initialized
	*
	* \memberof wl_signal
	*/
	signal_init :: proc(signal: ^Signal) ---

	/** Add the specified listener to this signal.
	*
	* \param signal The signal that will emit events to the listener
	* \param listener The listener to add
	*
	* \memberof wl_signal
	*/
	signal_add :: proc(signal: ^Signal, listener: ^Listener) ---

	/** Gets the listener struct for the specified callback.
	*
	* \param signal The signal that contains the specified listener
	* \param notify The listener that is the target of this search
	* \return the list item that corresponds to the specified listener, or NULL
	* if none was found
	*
	* \memberof wl_signal
	*/
	signal_get :: proc(signal: ^Signal, notify: Notify_Func_T) -> ^Listener ---

	/** Emits this signal, notifying all registered listeners.
	*
	* \param signal The signal object that will emit the signal
	* \param data The data that will be emitted with the signal
	*
	* \memberof wl_signal
	*/
	signal_emit         :: proc(signal: ^Signal, data: rawptr) ---
	signal_emit_mutable :: proc(signal: ^Signal, data: rawptr) ---

	/*
	* Post an event to the client's object referred to by 'resource'.
	* 'opcode' is the event number generated from the protocol XML
	* description (the event name). The variable arguments are the event
	* parameters, in the order they appear in the protocol XML specification.
	*
	* The variable arguments' types are:
	* - type=uint:	uint32_t
	* - type=int:		int32_t
	* - type=fixed:	wl_fixed_t
	* - type=string:	(const char *) to a nil-terminated string
	* - type=array:	(struct wl_array *)
	* - type=fd:		int, that is an open file descriptor
	* - type=new_id:	(struct wl_object *) or (struct wl_resource *)
	* - type=object:	(struct wl_object *) or (struct wl_resource *)
	*/
	resource_post_event           :: proc(resource: ^Resource, opcode: u32) ---
	resource_post_event_array     :: proc(resource: ^Resource, opcode: u32, args: ^Argument) ---
	resource_queue_event          :: proc(resource: ^Resource, opcode: u32) ---
	resource_queue_event_array    :: proc(resource: ^Resource, opcode: u32, args: ^Argument) ---
	resource_post_error_vargs     :: proc(resource: ^Resource, code: u32, msg: cstring, argp: ^c.va_list) ---
	resource_post_error           :: proc(resource: ^Resource, code: u32, msg: cstring) ---
	resource_post_no_memory       :: proc(resource: ^Resource) ---
	client_get_display            :: proc(client: ^Client) -> ^Display ---
	resource_create               :: proc(client: ^Client, interface: ^Interface, version: i32, id: u32) -> ^Resource ---
	resource_set_implementation   :: proc(resource: ^Resource, implementation: rawptr, data: rawptr, destroy: Resource_Destroy_Func_T) ---
	resource_set_dispatcher       :: proc(resource: ^Resource, dispatcher: Dispatcher_Func_T, implementation: rawptr, data: rawptr, destroy: Resource_Destroy_Func_T) ---
	resource_destroy              :: proc(resource: ^Resource) ---
	resource_get_id               :: proc(resource: ^Resource) -> u32 ---
	resource_get_link             :: proc(resource: ^Resource) -> ^List ---
	resource_from_link            :: proc(resource: ^List) -> ^Resource ---
	resource_find_for_client      :: proc(list: ^List, client: ^Client) -> ^Resource ---
	resource_get_client           :: proc(resource: ^Resource) -> ^Client ---
	resource_set_user_data        :: proc(resource: ^Resource, data: rawptr) ---
	resource_get_user_data        :: proc(resource: ^Resource) -> rawptr ---
	resource_get_version          :: proc(resource: ^Resource) -> i32 ---
	resource_set_destructor       :: proc(resource: ^Resource, destroy: Resource_Destroy_Func_T) ---
	resource_instance_of          :: proc(resource: ^Resource, interface: ^Interface, implementation: rawptr) -> i32 ---
	resource_get_class            :: proc(resource: ^Resource) -> cstring ---
	resource_add_destroy_listener :: proc(resource: ^Resource, listener: ^Listener) ---
	resource_get_destroy_listener :: proc(resource: ^Resource, notify: Notify_Func_T) -> ^Listener ---
	display_init_shm              :: proc(display: ^Display) -> i32 ---
	display_add_shm_format        :: proc(display: ^Display, format: u32) -> ^u32 ---
	log_set_handler_server        :: proc(handler: Log_Func_T) ---
}
