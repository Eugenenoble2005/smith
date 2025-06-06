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
/** \file wayland-util.h
*
* \brief Utility classes, functions, and macros.
*/
package wayland

import "core:c"

_ :: c

foreign import lib "libwayland-client.so"

// WL_EXPORT :: _Attribute ((Visibility("default")))

// WL_DEPRECATED :: _Attribute ((Deprecated))

/**
* Protocol message signature
*
* A wl_message describes the signature of an actual protocol message, such as a
* request or event, that adheres to the Wayland protocol wire format. The
* protocol implementation uses a wl_message within its demarshal machinery for
* decoding messages between a compositor and its clients. In a sense, a
* wl_message is to a protocol message like a class is to an object.
*
* The `name` of a wl_message is the name of the corresponding protocol message.
*
* The `signature` is an ordered list of symbols representing the data types
* of message arguments and, optionally, a protocol version and indicators for
* nullability. A leading integer in the `signature` indicates the _since_
* version of the protocol message. A `?` preceding a data type symbol indicates
* that the following argument type is nullable. While it is a protocol violation
* to send messages with non-nullable arguments set to `NULL`, event handlers in
* clients might still get called with non-nullable object arguments set to
* `NULL`. This can happen when the client destroyed the object being used as
* argument on its side and an event referencing that object was sent before the
* server knew about its destruction. As this race cannot be prevented, clients
* should - as a general rule - program their event handlers such that they can
* handle object arguments declared non-nullable being `NULL` gracefully.
*
* When no arguments accompany a message, `signature` is an empty string.
*
* Symbols:
*
* * `i`: int
* * `u`: uint
* * `f`: fixed
* * `s`: string
* * `o`: object
* * `n`: new_id
* * `a`: array
* * `h`: fd
* * `?`: following argument (`o` or `s`) is nullable
*
* While demarshaling primitive arguments is straightforward, when demarshaling
* messages containing `object` or `new_id` arguments, the protocol
* implementation often must determine the type of the object. The `types` of a
* wl_message is an array of wl_interface references that correspond to `o` and
* `n` arguments in `signature`, with `NULL` placeholders for arguments with
* non-object types.
*
* Consider the protocol event wl_display `delete_id` that has a single `uint`
* argument. The wl_message is:
*
* \code
* { "delete_id", "u", [NULL] }
* \endcode
*
* Here, the message `name` is `"delete_id"`, the `signature` is `"u"`, and the
* argument `types` is `[NULL]`, indicating that the `uint` argument has no
* corresponding wl_interface since it is a primitive argument.
*
* In contrast, consider a `wl_foo` interface supporting protocol request `bar`
* that has existed since version 2, and has two arguments: a `uint` and an
* object of type `wl_baz_interface` that may be `NULL`. Such a `wl_message`
* might be:
*
* \code
* { "bar", "2u?o", [NULL, &wl_baz_interface] }
* \endcode
*
* Here, the message `name` is `"bar"`, and the `signature` is `"2u?o"`. Notice
* how the `2` indicates the protocol version, the `u` indicates the first
* argument type is `uint`, and the `?o` indicates that the second argument
* is an object that may be `NULL`. Lastly, the argument `types` array indicates
* that no wl_interface corresponds to the first argument, while the type
* `wl_baz_interface` corresponds to the second argument.
*
* \sa wl_argument
* \sa wl_interface
* \sa <a href="https://wayland.freedesktop.org/docs/html/ch04.html#sect-Protocol-Wire-Format">Wire Format</a>
*/
Message :: struct {
	/** Message name */
	name: cstring,

	/** Message signature */
	signature: cstring,

	/** Object argument interfaces */
	types: ^^Interface,
}

/**
* Protocol object interface
*
* A wl_interface describes the API of a protocol object defined in the Wayland
* protocol specification. The protocol implementation uses a wl_interface
* within its marshalling machinery for encoding client requests.
*
* The `name` of a wl_interface is the name of the corresponding protocol
* interface, and `version` represents the version of the interface. The members
* `method_count` and `event_count` represent the number of `methods` (requests)
* and `events` in the respective wl_message members.
*
* For example, consider a protocol interface `foo`, marked as version `1`, with
* two requests and one event.
*
* \code{.xml}
* <interface name="foo" version="1">
*   <request name="a"></request>
*   <request name="b"></request>
*   <event name="c"></event>
* </interface>
* \endcode
*
* Given two wl_message arrays `foo_requests` and `foo_events`, a wl_interface
* for `foo` might be:
*
* \code
* struct wl_interface foo_interface = {
*         "foo", 1,
*         2, foo_requests,
*         1, foo_events
* };
* \endcode
*
* \note The server side of the protocol may define interface <em>implementation
*       types</em> that incorporate the term `interface` in their name. Take
*       care to not confuse these server-side `struct`s with a wl_interface
*       variable whose name also ends in `interface`. For example, while the
*       server may define a type `struct wl_foo_interface`, the client may
*       define a `struct wl_interface wl_foo_interface`.
*
* \sa wl_message
* \sa wl_proxy
* \sa <a href="https://wayland.freedesktop.org/docs/html/ch04.html#sect-Protocol-Interfaces">Interfaces</a>
* \sa <a href="https://wayland.freedesktop.org/docs/html/ch04.html#sect-Protocol-Versioning">Versioning</a>
*/
Interface :: struct {
	/** Interface name */
	name: cstring,

	/** Interface version */
	version: i32,

	/** Number of methods (requests) */
	method_count: i32,

	/** Method (request) signatures */
	methods: ^Message,

	/** Number of events */
	event_count: i32,

	/** Event signatures */
	events: ^Message,
}

/** \class wl_list
*
* \brief Doubly-linked list
*
* On its own, an instance of `struct wl_list` represents the sentinel head of
* a doubly-linked list, and must be initialized using wl_list_init().
* When empty, the list head's `next` and `prev` members point to the list head
* itself, otherwise `next` references the first element in the list, and `prev`
* refers to the last element in the list.
*
* Use the `struct wl_list` type to represent both the list head and the links
* between elements within the list. Use wl_list_empty() to determine if the
* list is empty in O(1).
*
* All elements in the list must be of the same type. The element type must have
* a `struct wl_list` member, often named `link` by convention. Prior to
* insertion, there is no need to initialize an element's `link` - invoking
* wl_list_init() on an individual list element's `struct wl_list` member is
* unnecessary if the very next operation is wl_list_insert(). However, a
* common idiom is to initialize an element's `link` prior to removal - ensure
* safety by invoking wl_list_init() before wl_list_remove().
*
* Consider a list reference `struct wl_list foo_list`, an element type as
* `struct element`, and an element's link member as `struct wl_list link`.
*
* The following code initializes a list and adds three elements to it.
*
* \code
* struct wl_list foo_list;
*
* struct element {
*         int foo;
*         struct wl_list link;
* };
* struct element e1, e2, e3;
*
* wl_list_init(&foo_list);
* wl_list_insert(&foo_list, &e1.link);   // e1 is the first element
* wl_list_insert(&foo_list, &e2.link);   // e2 is now the first element
* wl_list_insert(&e2.link, &e3.link); // insert e3 after e2
* \endcode
*
* The list now looks like <em>[e2, e3, e1]</em>.
*
* The `wl_list` API provides some iterator macros. For example, to iterate
* a list in ascending order:
*
* \code
* struct element *e;
* wl_list_for_each(e, foo_list, link) {
*         do_something_with_element(e);
* }
* \endcode
*
* See the documentation of each iterator for details.
* \sa http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/include/linux/list.h
*/
List :: struct {
	/** Previous list element */
	prev: ^List,

	/** Next list element */
	next: ^List,
}

/**
* \class wl_array
*
* Dynamic array
*
* A wl_array is a dynamic array that can only grow until released. It is
* intended for relatively small allocations whose size is variable or not known
* in advance. While construction of a wl_array does not require all elements to
* be of the same size, wl_array_for_each() does require all elements to have
* the same type and size.
*
*/
Array :: struct {
	/** Array size */
	size: uint,

	/** Allocated space */
	alloc: uint,

	/** Array data */
	data: rawptr,
}

/**
* Fixed-point number
*
* A `wl_fixed_t` is a 24.8 signed fixed-point number with a sign bit, 23 bits
* of integer precision and 8 bits of decimal precision. Consider `wl_fixed_t`
* as an opaque struct with methods that facilitate conversion to and from
* `double` and `int` types.
*/
Fixed :: i32

/**
* Protocol message argument data types
*
* This union represents all of the argument types in the Wayland protocol wire
* format. The protocol implementation uses wl_argument within its marshalling
* machinery for dispatching messages between a client and a compositor.
*
* \sa wl_message
* \sa wl_interface
* \sa <a href="https://wayland.freedesktop.org/docs/html/ch04.html#sect-Protocol-wire-Format">Wire Format</a>
*/
Argument :: struct #raw_union {
	i: i32,     /**< `int`    */
	u: u32,     /**< `uint`   */
	f: Fixed, /**< `fixed`  */
	s: cstring, /**< `string` */
	o: ^Object, /**< `object` */
	n: u32,     /**< `new_id` */
	a: ^Array,  /**< `array`  */
	h: i32,     /**< `fd`     */
}

/**
* Dispatcher function type alias
*
* A dispatcher is a function that handles the emitting of callbacks in client
* code. For programs directly using the C library, this is done by using
* libffi to call function pointers. When binding to languages other than C,
* dispatchers provide a way to abstract the function calling process to be
* friendlier to other function calling systems.
*
* A dispatcher takes five arguments: The first is the dispatcher-specific
* implementation associated with the target object. The second is the object
* upon which the callback is being invoked (either wl_proxy or wl_resource).
* The third and fourth arguments are the opcode and the wl_message
* corresponding to the callback. The final argument is an array of arguments
* received from the other process via the wire protocol.
*
* \param user_data Dispatcher-specific implementation data
* \param target Callback invocation target (wl_proxy or `wl_resource`)
* \param opcode Callback opcode
* \param msg Callback message signature
* \param args Array of received arguments
*
* \return 0 on success, or -1 on failure
*/
Dispatcher_Func_T :: proc "c" (rawptr, rawptr, u32, ^Message, ^Argument) -> i32

/**
* Log function type alias
*
* The C implementation of the Wayland protocol abstracts the details of
* logging. Users may customize the logging behavior, with a function conforming
* to the `wl_log_func_t` type, via `wl_log_set_handler_client` and
* `wl_log_set_handler_server`.
*
* A `wl_log_func_t` must conform to the expectations of `vprintf`, and
* expects two arguments: a string to write and a corresponding variable
* argument list. While the string to write may contain format specifiers and
* use values in the variable argument list, the behavior of any `wl_log_func_t`
* depends on the implementation.
*
* \note Take care to not confuse this with `wl_protocol_logger_func_t`, which
*       is a specific server-side logger for requests and events.
*
* \param fmt String to write to the log, containing optional format
*            specifiers
* \param args Variable argument list
*
* \sa wl_log_set_handler_client
* \sa wl_log_set_handler_server
*/
Log_Func_T :: proc "c" (cstring, ^c.va_list)

/**
* Return value of an iterator function
*
* \sa wl_client_for_each_resource_iterator_func_t
* \sa wl_client_for_each_resource
*/
Iterator_Result :: enum c.int {
	/** Stop the iteration */
	STOP,

	/** Continue the iteration */
	CONTINUE,
}

@(default_calling_convention="c", link_prefix="wl_")
foreign lib {
	/**
	* Initializes the list.
	*
	* \param list List to initialize
	*
	* \memberof wl_list
	*/
	list_init :: proc(list: ^List) ---

	/**
	* Inserts an element into the list, after the element represented by \p list.
	* When \p list is a reference to the list itself (the head), set the containing
	* struct of \p elm as the first element in the list.
	*
	* \note If \p elm is already part of a list, inserting it again will lead to
	*       list corruption.
	*
	* \param list List element after which the new element is inserted
	* \param elm Link of the containing struct to insert into the list
	*
	* \memberof wl_list
	*/
	list_insert :: proc(list: ^List, elm: ^List) ---

	/**
	* Removes an element from the list.
	*
	* \note This operation leaves \p elm in an invalid state.
	*
	* \param elm Link of the containing struct to remove from the list
	*
	* \memberof wl_list
	*/
	list_remove :: proc(elm: ^List) ---

	/**
	* Determines the length of the list.
	*
	* \note This is an O(n) operation.
	*
	* \param list List whose length is to be determined
	*
	* \return Number of elements in the list
	*
	* \memberof wl_list
	*/
	list_length :: proc(list: ^List) -> i32 ---

	/**
	* Determines if the list is empty.
	*
	* \param list List whose emptiness is to be determined
	*
	* \return 1 if empty, or 0 if not empty
	*
	* \memberof wl_list
	*/
	list_empty :: proc(list: ^List) -> i32 ---

	/**
	* Inserts all of the elements of one list into another, after the element
	* represented by \p list.
	*
	* \note This leaves \p other in an invalid state.
	*
	* \param list List element after which the other list elements will be inserted
	* \param other List of elements to insert
	*
	* \memberof wl_list
	*/
	list_insert_list :: proc(list: ^List, other: ^List) ---

	/**
	* Initializes the array.
	*
	* \param array Array to initialize
	*
	* \memberof wl_array
	*/
	array_init :: proc(array: ^Array) ---

	/**
	* Releases the array data.
	*
	* \note Leaves the array in an invalid state.
	*
	* \param array Array whose data is to be released
	*
	* \memberof wl_array
	*/
	array_release :: proc(array: ^Array) ---

	/**
	* Increases the size of the array by \p size bytes.
	*
	* \param array Array whose size is to be increased
	* \param size Number of bytes to increase the size of the array by
	*
	* \return A pointer to the beginning of the newly appended space, or NULL when
	*         resizing fails.
	*
	* \memberof wl_array
	*/
	array_add :: proc(array: ^Array, size: uint) -> rawptr ---

	/**
	* Copies the contents of \p source to \p array.
	*
	* \param array Destination array to copy to
	* \param source Source array to copy from
	*
	* \return 0 on success, or -1 on failure
	*
	* \memberof wl_array
	*/
	array_copy :: proc(array: ^Array, source: ^Array) -> i32 ---

	/**
	* Converts a fixed-point number to a floating-point number.
	*
	* \param f Fixed-point number to convert
	*
	* \return Floating-point representation of the fixed-point argument
	*/
	fixed_to_double :: proc(f: Fixed) -> f64 ---

	/**
	* Converts a floating-point number to a fixed-point number.
	*
	* \param d Floating-point number to convert
	*
	* \return Fixed-point representation of the floating-point argument
	*/
	fixed_from_double :: proc(d: f64) -> Fixed ---

	/**
	* Converts a fixed-point number to an integer.
	*
	* \param f Fixed-point number to convert
	*
	* \return Integer component of the fixed-point argument
	*/
	fixed_to_int :: proc(f: Fixed) -> i32 ---

	/**
	* Converts an integer to a fixed-point number.
	*
	* \param i Integer to convert
	*
	* \return Fixed-point representation of the integer argument
	*/
	fixed_from_int :: proc(i: i32) -> Fixed ---
}
