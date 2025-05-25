#+feature dynamic-literals
//todo: Not use concatenate as it is not efficient
package scanner
import "core:encoding/xml"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"

Side :: enum {
	Client,
	Server,
}
ProtocolData :: struct {
	name:                string,
	interfaces:          [dynamic]Interface,
	events:              [dynamic]Event,
	enums:               [dynamic]Enumeration,
	description:         string,
	description_summary: string,
	side:                Side,
}
LineBreak :: "\r\n"
protocol_data: ProtocolData
Buffer: strings.Builder
Tab_Size :: 4
Element_Id :: xml.Element_ID
Interface :: struct {
	name:        string,
	description: string,
	requests:    [dynamic]Request,
	events:      [dynamic]Event,
	version:     string,
}

Enumeration :: struct {
	name:        string,
	description: string,
	values:      [dynamic]map[string]string, //should probably be an int as the map value
}
Request :: struct {
	name:          string,
	true_name:     string,
	description:   string,
	since:         string,
	opcode:        int,
	args:          [dynamic]Arg,
	is_destructor: bool,
	has_newid:     bool,
}
Event :: Request //??

Arg :: struct {
	name:        string,
	type:        string,
	summary:     string,
	interface:   string,
	enumeration: string,
	allow_null:  bool,
	new_type:    bool,
}
type_map := map[string]string {
	"int"    = "c.int32_t",
	"fd"     = "c.int32_t",
	"new_id" = "c.uint32_t",
	"uint"   = "c.uint32_t",
	"fixed"  = "wl.Fixed",
	"string" = "cstring",
	"object" = "rawptr",
	"array"  = "^wl.Array",
}

parse_protocol :: proc(doc: ^xml.Document) {
	element_count := doc.element_count
	for x in 0 ..< element_count {
		element := doc.elements[x]
		//get protocol name as defined in the xml 
		if element.ident == "protocol" {
			for attrib in element.attribs {
				if attrib.key == "name" do protocol_data.name = attrib.val
				break
			}
			for el in element.value {
				node := doc.elements[el.(xml.Element_ID)] //potentially problematic
				//copyright
				if node.ident == "copyright" {
					if len(node.value) != 1 do continue //invalid
					copyright_text, ok := node.value[0].(string)
					if ok {
						write_to_buffer("/*")
						write_to_buffer(copyright_text)
						write_to_buffer("*/")
					}
				}
				//description
				if node.ident == "description" {
					//try get summary if it exists
					for attrib in node.attribs {
						if attrib.key == "summary" do protocol_data.description_summary = attrib.val
						break
					}
					if len(node.value) != 1 do continue //invalid
					desc_text, ok := node.value[0].(string)
					if ok do protocol_data.description = desc_text
				}
				//interface
				if node.ident == "interface" {
					append(&protocol_data.interfaces, parse_interface(doc, &node))
				}
			}
		}
	}
}
wl_type_to_odin_type :: proc(arg: Arg) -> string {
	if arg.type == "object" {
		if len(arg.interface) != 0 do return strings.concatenate({"^", arg.interface})
	}
	return type_map[arg.type]
}
parse_interface :: proc(doc: ^xml.Document, el: ^xml.Element) -> Interface {
	interface: Interface
	//try get name and version if they exist
	for attrib in el.attribs {
		if attrib.key == "name" do interface.name = attrib.val
		if attrib.key == "version" do interface.version = attrib.val
	}
	opcode := 0
	for val in el.value {
		node := doc.elements[val.(Element_Id)]
		//requst 
		if node.ident == "request" {
			append(
				&interface.requests,
				parse_requests_or_events(doc, &node, interface.name, opcode, .Request),
			)
			opcode += 1
		}
		//event
		if node.ident == "event" {
			append(
				&interface.events,
				parse_requests_or_events(doc, &node, interface.name, opcode, .Event),
			)
		}
		//enum
		if node.ident == "enum" {
			append(&protocol_data.enums, parse_enum(doc, &node, interface.name))
		}
	}
	return interface
}
parse_requests_or_events :: proc(
	doc: ^xml.Document,
	el: ^xml.Element,
	interface_name: string,
	opcode: int,
	type: enum {
		Request,
		Event,
	},
) -> Request {
	request: Request
	//initially set to not a destructor, will be updated in below loop if necessary
	request.is_destructor = false
	request.has_newid = false
	request.opcode = opcode
	for attrib in el.attribs {
		//do not concatenate interface name if it is an event
		if attrib.key == "name" {
			request.name =
				strings.concatenate({interface_name, "_", attrib.val}) if type == .Request else attrib.val
			request.true_name = attrib.val
		}
		if attrib.key == "type" {
			if attrib.val == "destructor" {
				request.is_destructor = true
			}
		}
		if attrib.key == "since" do request.since = attrib.val
	}
	//check for args
	for val in el.value {
		node := doc.elements[val.(Element_Id)]
		if node.ident == "arg" {
			arg: Arg
			for attrib in node.attribs {
				if attrib.key == "type" {
					arg.type = attrib.val
					if arg.type == "new_id" {
						request.has_newid = true
						arg.new_type = true
					}
				}
				if attrib.key == "name" do arg.name = attrib.val
				if attrib.key == "interface" do arg.interface = attrib.val
				if attrib.key == "enum" do arg.enumeration = attrib.val
				if attrib.key == "allow-null" do arg.allow_null = attrib.val == "true"
				if attrib.key == "summary" do arg.summary = attrib.val
			}
			append(&request.args, arg)
		}
	}
	return request
}
parse_enum :: proc(doc: ^xml.Document, el: ^xml.Element, interface_name: string) -> Enumeration {
	enum_: Enumeration
	for attrib in el.attribs {
		if attrib.key == "name" {
			enum_.name = strings.concatenate({interface_name, "_", attrib.val})
		}
	}
	for val in el.value {
		node := doc.elements[val.(Element_Id)]
		if node.ident == "description" {
			enum_.description, _ = el.value[0].(string)
		}
		if node.ident == "entry" {
			entry_id, _ := val.(Element_Id)
			entry_data := make(map[string]string)
			defer delete(entry_data)
			entry_name, _ := xml.find_attribute_val_by_key(doc, entry_id, "name")
			entry_value, _ := xml.find_attribute_val_by_key(doc, entry_id, "value")
			entry_data[entry_name] = entry_value
			append(&enum_.values, entry_data)
			entry_data = nil
		}
	}
	return enum_
}
parse_args :: proc(args: []string) {
	if len(args) == 2 && args[1] == "-h" {
		fmt.println(
			"Wayland Scanner implementation in Odin. Format : scanner <server|client> <input_xml> <output_location>",
		)
		return
	}
	if len(args) < 4 do die("Not enough arguments")
	if args[1] != "client" && args[1] != "server" do die("Argument one must be either 'client' or 'server'")
	if args[1] == "server" {
		protocol_data.side = .Server
		die("Only client side scanning is supported")
	} else if args[1] == "client" {
		protocol_data.side = .Client
	}

}

die :: proc(msg: string) {
	fmt.println(msg)
	os.exit(0)
}

emit_enums :: proc() {
	using strings
	for enumeration in protocol_data.enums {
		enum_ := concatenate({enumeration.name, "_enum ", ":: ", "enum c.int32_t", "{\r\n"})
		for value in enumeration.values {
			for key, val in value {
				enum_ = concatenate(
					{
						enum_,
						repeat(" ", Tab_Size),
						enumeration.name,
						"_",
						key,
						" = ",
						val,
						",",
						"\r\n",
					},
				)
			}
		}
		enum_ = concatenate({enum_, "}", "\r\n"})
		write_to_buffer(enum_)
	}
}

emit_interface :: proc() {
	using strings
	//first emit simple opaque structs
	for interface in protocol_data.interfaces {
		//exclude wl_display because that is in the core library.
		struct_: string
		if interface.name == "wl_display" {
			struct_ = "wl_display :: wl.Display"
		} else {
			struct_ = concatenate({interface.name, " :: ", "struct {}"})
		}

		//wl_interface
		interface_ := concatenate({interface.name, "_interface", " : ", "wl.Interface"})

		//userdata getters and setters
		//there is definetly a better way to do this
		setter := concatenate(
			{
				interface.name,
				"_set_user_data",
				" :: ",
				"proc \"c\" (",
				interface.name,
				" : ",
				"^",
				interface.name,
				",",
				"user_data",
				" : rawptr",
				")",
				"{",
				LineBreak,
			},
		)
		setter = concatenate(
			{
				setter,
				repeat(" ", Tab_Size),
				"wl.proxy_set_user_data((^wl.Proxy)(",
				interface.name,
				"), user_data)",
				LineBreak,
				"}",
			},
		)
		getter := concatenate(
			{
				interface.name,
				"_get_user_data",
				" :: ",
				"proc \"c\" (",
				interface.name,
				" : ",
				"^",
				interface.name,
				") -> rawptr ",
				"{",
				LineBreak,
			},
		)
		getter = concatenate(
			{
				getter,
				repeat(" ", Tab_Size),
				"return ",
				"wl.proxy_get_user_data((^wl.Proxy)(",
				interface.name,
				"))",
				LineBreak,
				"}",
			},
		)

		version := concatenate(
			{
				interface.name,
				"_get_version",
				" :: ",
				"proc \"c\" (",
				interface.name,
				" : ",
				"^",
				interface.name,
				") -> c.uint32_t ",
				"{",
				LineBreak,
			},
		)
		version = concatenate(
			{
				version,
				repeat(" ", Tab_Size),
				"return ",
				"wl.proxy_get_version((^wl.Proxy)(",
				interface.name,
				"))",
				LineBreak,
				"}",
			},
		)
		write_to_buffer(struct_)
		write_to_buffer(interface_)
		write_to_buffer(setter)
		write_to_buffer(getter)
		write_to_buffer(version)
		write_to_buffer(LineBreak)
	}
}
emit_requests :: proc() {
	using strings
	for interface in protocol_data.interfaces {
		for request in interface.requests {
			//if destructor request 
			if request.is_destructor {
				emit_client_destructor_request(request, interface)
				continue
			}
			if request.has_newid {
				emit_client_new_type_request(request, interface)
				continue
			}

			request_body := concatenate(
				{request.name, " :: ", "proc \"c\" (_", interface.name, ": ^", interface.name},
			)
			//go through args
			for arg in request.args {
				request_body = concatenate(
					{request_body, ",", arg.name, ": ", wl_type_to_odin_type(arg)},
				)
			}
			opcode_to_int_buf: [64]u8
			request_body = concatenate({request_body, " ){", LineBreak})
			request_body = concatenate(
				{
					request_body,
					repeat(" ", Tab_Size),
					"wl.proxy_marshal_flags(",
					"(^wl.Proxy)(_",
					interface.name,
					"), ",
					strconv.itoa(opcode_to_int_buf[:], request.opcode),
					", ",
					"nil, ",
					"wl.proxy_get_version(",
					"(^wl.Proxy)(_",
					interface.name,
					")), ",
					"0", //?
				},
			)
			//append variables to proxy_marshal_flags
			for arg in request.args {
				request_body = concatenate({request_body, ", ", arg.name})
			}
			request_body = concatenate({request_body, ")", LineBreak, "}"})
			write_to_buffer(request_body)
			write_to_buffer(LineBreak)
		}
	}
}
emit_events :: proc() {
	using strings
	for interface in protocol_data.interfaces {
		//skip if interface has no events 
		if len(interface.events) == 0 do continue
		//every interface needs an add listener procedure
		add_listener := concatenate(
			{
				interface.name,
				"_add_listener :: proc \"c\" (",
				interface.name,
				" : ^",
				interface.name,
				", listener: ^",
				interface.name,
				"_listener, data: rawptr) -> c.int {",
				LineBreak,
			},
		)
		add_listener = concatenate(
			{
				add_listener,
				repeat(" ", Tab_Size),
				"return wl.proxy_add_listener((^wl.Proxy)(",
				interface.name,
				"), (^rawptr)(listener),data)",
				LineBreak,
				"}",
			},
		)
		write_to_buffer(add_listener)
		//listener for interface
		listener_body := concatenate({interface.name, "_listener :: struct {", LineBreak})
		for event in interface.events {
			listener_body = concatenate(
				{
					listener_body,
					repeat(" ", Tab_Size),
					event.name,
					" : proc \"c\" (data:rawptr,",
					interface.name,
					": ^",
					interface.name,
				},
			)
			//append arguments
			for arg in event.args {
				listener_body = concatenate(
					{listener_body, " ,", arg.name, " : ", wl_type_to_odin_type(arg)},
				)
			}
			listener_body = concatenate({listener_body, "),", LineBreak})
		}
		//close listener struct
		listener_body = concatenate({listener_body, LineBreak, "}"})
		write_to_buffer(listener_body)
		write_to_buffer(LineBreak)
	}
}
emit_client_destructor_request :: proc(request: Request, interface: Interface) {
	using strings
	request_body := concatenate(
		{request.name, " :: ", "proc \"c\" (_", interface.name, ": ^", interface.name, "){", LineBreak},
	)
	opcode_to_int_buf: [64]u8
	request_body = concatenate(
		{
			request_body,
			repeat(" ", Tab_Size),
			"wl.proxy_marshal_flags(",
			"(^wl.Proxy)(_",
			interface.name,
			"), ",
			strconv.itoa(opcode_to_int_buf[:], request.opcode),
			", ",
			"nil, ",
			"wl.proxy_get_version(",
			"(^wl.Proxy)(_",
			interface.name,
			")), ",
			"wl.MARSHAL_FLAG_DESTROY",
			")",
			LineBreak,
			"}",
		},
	)
	write_to_buffer(request_body)
	write_to_buffer(LineBreak)
}
emit_client_new_type_request :: proc(request: Request, interface: Interface) {
	using strings
	request_body := concatenate(
		{request.name, " :: ", "proc \"c\" (_", interface.name, ": ^", interface.name},
	)
	new_id_arg: Arg
	//go through args but skip the new_id 
	for arg in request.args {
		if arg.new_type {
			new_id_arg = arg
			continue
		}
		request_body = concatenate({request_body, ",", arg.name, ": ", wl_type_to_odin_type(arg)})
	}
	//if new id has interface
	if len(new_id_arg.interface) != 0 {
		opcode_to_int_buf: [64]u8
		request_body = concatenate({request_body, " ) -> ^", new_id_arg.interface, "{", LineBreak})
		request_body = concatenate(
			{request_body, repeat(" ", Tab_Size), "data: ^wl.Proxy", LineBreak},
		)
		request_body = concatenate(
			{
				request_body,
				repeat(" ", Tab_Size),
				"data = wl.proxy_marshal_flags(",
				"(^wl.Proxy)(_",
				interface.name,
				"), ",
				strconv.itoa(opcode_to_int_buf[:], request.opcode),
				", ",
				"&",
				new_id_arg.interface,
				"_interface",
				",",
				"wl.proxy_get_version(",
				"(^wl.Proxy)(_",
				interface.name,
				")), ",
				"0,", //?
				"nil",
			},
		)
		//append variables to proxy_marshal_flags
		for arg in request.args {
			if arg.new_type do continue
			request_body = concatenate({request_body, ", ", arg.name})
		}
		request_body = concatenate({request_body, ")", LineBreak})
		request_body = concatenate(
			{
				request_body,
				repeat(" ", Tab_Size),
				"return (^",
				new_id_arg.interface,
				")(data)",
				LineBreak,
				"}",
			},
		)
	} else {
		//return rawptr
		opcode_to_int_buf: [64]u8
		request_body = concatenate(
			{
				request_body,
				", interface: ^wl.Interface, version: c.uint32_t ) -> rawptr",
				"{",
				LineBreak,
			},
		)
		request_body = concatenate(
			{request_body, repeat(" ", Tab_Size), "data: ^wl.Proxy", LineBreak},
		)
		request_body = concatenate(
			{
				request_body,
				repeat(" ", Tab_Size),
				"data = wl.proxy_marshal_flags(",
				"(^wl.Proxy)(_",
				interface.name,
				"), ",
				strconv.itoa(opcode_to_int_buf[:], request.opcode),
				", ",
				"interface",
				",version",
				",0",
				//command args here?
				// "wl.proxy_get_version(",
				// "(^wl.Proxy)(_",
				// interface.name,
				// ")), ",
				// "0,", //?
				// "nil",
			},
		)
		for arg in request.args {
			if arg.new_type do continue
			request_body = concatenate({request_body, ", ", arg.name})
		}
		request_body = concatenate(
			{
				request_body,
				", interface.name,version,nil)",
				LineBreak,
				repeat(" ", Tab_Size),
				"return (rawptr)(data)",
				LineBreak,
				"}",
			},
		)


	}
	write_to_buffer(request_body)
	write_to_buffer(LineBreak)
}
// copied from https://github.com/jqcorreia/wayland-odin, i dont really understand how it works
emit_private_code :: proc() {
	using strings
	for interface in protocol_data.interfaces {
		request_body := concatenate({interface.name, "_requests := []wl.Message {", LineBreak})
		events_body := concatenate({interface.name, "_events:= []wl.Message {", LineBreak})
		for request in interface.requests {
			type_arr: [dynamic]string
			for arg in request.args {
				if arg.interface != "" {
					append(&type_arr, fmt.tprintf("&%s_interface", arg.interface))
				} else {
					append(&type_arr, "nil")
				}
			}
			request_body = concatenate(
				{
					request_body,
					repeat(" ", Tab_Size),
					"{ ",
					"\"",
					request.true_name,
					"\"",
					",",
					"\"",
					emit_args_strings(request.args),
					"\"",
					",",
					"raw_data([]^wl.Interface{",
					strings.join(type_arr[:], ","),
					"}) },",
					LineBreak,
				},
			)
		}
		for event in interface.events {
			events_body = concatenate(
				{
					events_body,
					repeat(" ", Tab_Size),
					"{",
					"\"",
					event.name,
					"\", ",
					"\"",
					emit_args_strings(event.args),
					"\", ",
					"nil },",
					LineBreak,
				},
			)
		}
		//init method
		init_method := "@(init)"
		init_method = concatenate(
			{init_method, LineBreak, "init_", interface.name, "_interface :: proc \"c\" (){", LineBreak},
		)
		init_method = concatenate({init_method, repeat(" ", Tab_Size)})
		init_method = concatenate({init_method, interface.name, "_interface = {"})
		conv_buf: [64]u8
		init_method = concatenate(
			{
				init_method,
				"\"",
				interface.name,
				"\", ",
				interface.version,
				", ",
				strconv.itoa(conv_buf[:], len(interface.requests)),
				", ",
			},
		)
		if len(interface.requests) > 0 {
			init_method = concatenate({init_method, "&", interface.name, "_requests[0], "})
		} else {
			init_method = concatenate({init_method, "nil, "})
		}
		init_method = concatenate(
			{init_method, strconv.itoa(conv_buf[:], len(interface.events)), ","},
		)
		if len(interface.events) > 0 {
			init_method = concatenate({init_method, "&", interface.name, "_events[0], "})
		} else {
			init_method = concatenate({init_method, "nil, "})
		}

		init_method = concatenate({init_method, "}", LineBreak, "}"})
		request_body = concatenate({request_body, "}"})
		events_body = concatenate({events_body, "}"})
		write_to_buffer(request_body)
		write_to_buffer(events_body)
		write_to_buffer(init_method)
	}
}
emit_args_strings :: proc(args: [dynamic]Arg) -> string {
	res: string = ""
	for arg in args {
		c: string = ""
		// Just check if it is indeed a nullable type
		if (arg.type == "object" || arg.type == "string") && arg.allow_null {
			res = strings.concatenate({res, "?"})
		}
		switch (arg.type) {
		case "int":
			c = "i"
		case "new_id":
			c = arg.interface == "" ? "sun" : "n"
		case "uint":
			c = "u"
		case "fixed":
			c = "f"
		case "string":
			c = "s"
		case "object":
			c = "o"
		case "array":
			c = "a"
		case "fd":
			c = "h"
		}
		res = strings.concatenate({res, c})
	}
	return res
}
emit_protocol_to_file :: proc(output_path: string) {
	output_path := output_path
	side := "client" if protocol_data.side == .Client else "server"
	file_name := strings.concatenate({protocol_data.name, "_", side, ".odin"})
	abs_path, ok := filepath.abs(output_path)
	if !ok do die("Ouput path does not exist")
	output_path = filepath.join({abs_path, file_name})
	os.write_entire_file(output_path, Buffer.buf[:])
}
write_to_buffer :: proc(text: string) {
	strings.write_string(&Buffer, text)
	if text != LineBreak do strings.write_string(&Buffer, LineBreak)
}
main :: proc() {
	args := os.args
	parse_args(args)
	protocol_file := args[2]
	doc, err := xml.load_from_file(protocol_file)
	if err != .None do die("Could not load protocol. Aborting...")
	write_to_buffer("/* GENERATED BY ODIN WAYLAND SCANNER*/")
	//scanner currently assumes wayland bindings are in the shared collection, write import of binds to buffer
	write_to_buffer("package scanner")
	write_to_buffer("import wl \"shared:wayland\"")
	// write_to_buffer("import wl \"../\"")
	write_to_buffer("import \"core:c\"")
	parse_protocol(doc)

	//emissions
	emit_interface()
	emit_requests()
	emit_events()
	emit_enums()
	emit_private_code()
	emit_protocol_to_file(args[3])
}
