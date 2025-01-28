@tool
@icon("res://addons/gopilot_utils/textures/tool_chat_requester_icon.svg")
extends ChatRequester
##Like ChatRequester, but with access to [color=cyan]functions[/color] of a Node.
##Use the [color=white]pre_system_prompt[/color] property to set the models system prompt.
class_name ToolChatRequester

##The Node on which the functions will be called. You must handle all potential incorrect inputs from the model. Don't expect perfect output every time.
@export var target_node:Node:
	set(new):
		target_node = new
		notify_property_list_changed()
## Functions the model has access to
@export var tools:Array[ChatTool]
## Example tool calls. Emulates a previous conversation for the model to learn from
@export var tool_examples:Array[ToolCallExample] = []
##Some models are specifically trained to work with tool calling. If your model is trained on tools, enable this option![br]
##These models include: Llama3.1, Mistral Nemo and hermes3. Go look on ollama.com and filter for models that have tool support!
@export var built_in_tool_support:bool = false

## Prefix for models which don't support function-calling
const tool_prefix_prompt:String = "\nYou have access to the following functions:\n"
## Suffix for models which don't support function-calling
const tool_suffix_prompt:String = """
Use this exact schema to respond: [{"function":"my_function","args":["some arguments here",1234,6.0]},{"function":"another_function","args":["some more arguments"]}]
Every response you give must at least include every function marked as call_always. Respond using JSON and the schema
"""
## Internal variable. Do not change!
var tool_prompt:String = ""

## Emitted when a tool is called. Contains all called tools
signal tools_called(tools:Array[Dictionary])


func _set_tool_prompt():
	if !built_in_tool_support:
		tool_prompt = "["
		var tool_array : Array[Dictionary] = []
		for tool_index in tools.size():
			var tool:ChatTool = tools[tool_index]
			if !tool.active:
				continue
			tool_prompt += '{"function_name":"%s","description":"%s","call_always":%s,args['\
			% [tool.function_name, tool.description, tool.required]
			for i in tool.arguments.size():
				tool_prompt += '{arg_name:"%s","type":%s'\
				% [tool.arguments[i].name, tool.arguments[i].type_string[tool.arguments[i].type]]
				if tool.arguments[i].descrption != "":
					tool_prompt += ',"description":%s' % tool.arguments[i].descrption
				if tool.arguments[i].example != "":
					tool_prompt += ',"example_value":%s' % tool.arguments[i].example
				tool_prompt += "}"
				if i != tool.arguments.size() - 1:
					tool_prompt += ","
			tool_prompt += "]}"
			if tool_index != tools.size() - 1:
				tool_prompt += ","
			else:
				tool_prompt += "]"
		if tools:
			internal_system_prompt = system_prompt
			internal_system_prompt += tool_prefix_prompt
			internal_system_prompt += tool_prompt
			internal_system_prompt += tool_suffix_prompt
		if conversation.size() == 0:
			conversation.append({"role":"system", "content":internal_system_prompt})
		else:
			conversation[0] = {"role":"system", "content":internal_system_prompt}
		for example in tool_examples:
			conversation.append({"role":"user", "content":example.instruction})
			conversation.append({"role":"assistant", "content":example.response})


## Called by another [class ToolChatRequester] if it calls this method when [member ChatTool.is_tool_caller] is [param true]
func call_tools(_tools:PackedStringArray, instruction:String):
	if debug_mode:
		print("tools I got ", _tools)
	var previous_tools : Array[ChatTool] = tools.duplicate(true)
	var usable_tools:Array[ChatTool] = []
	for tool in _tools:
		for t in previous_tools:
			if t.function_name == tool and t.active:
				usable_tools.append(t)
				break
	if debug_mode:
		print("Usable tools: ", usable_tools)
	for t in usable_tools:
		tools = [t]
		if debug_mode:
			print("Calling tool ", t.function_name)
		var response:String = await send_message(instruction, chat_role.USER, true)
		if debug_mode:
			print("Got response: ", response)
	tools = previous_tools


func _process(delta):
	#if Engine.is_editor_hint() and !in_editor:
		#return
	client.poll()
	if(client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING):
		if(!connected):
			if debug_mode:
				print("Connecting...")
	elif(client.get_status() == HTTPClient.STATUS_CONNECTED):
		if(!connected):
			connected = true
			if debug_mode:
				print("Connected!")
	elif(client.get_status() == HTTPClient.STATUS_DISCONNECTED):
		if(connected):
			connected = false
			if debug_mode:
				print("Disconnected!")
	elif(client.get_status() == HTTPClient.STATUS_BODY):
		if debug_mode:
			print("Requesting...")
		if(client.has_response()):
			var chunk = client.read_response_body_chunk()
			var jsdata = JSON.new()
			jsdata.parse(chunk.get_string_from_utf8())
			var data = jsdata.get_data()
			if(data != null):
				if data.has("error"):
					push_error("ChatRequester Error: " + data["error"])
					return
				if built_in_tool_support:
					if data["message"].has("tool_calls"):
						var calls:Array = data["message"]["tool_calls"]
						tools_called.emit(calls)
						response[0] += str(calls)
						message_end.emit(response[0])
						send_message(response[0], chat_role.TOOL)
					elif debug_mode:
						printraw(data["message"]["content"])
				elif data.has("message"):
					if debug_mode:
						printraw(data["message"]["content"])
					var word:String = data["message"]["content"]
					new_word.emit(word)
					response[0] += word
					if data["done"] == true:
						message_end.emit(response[0])
						send_message(response[0], chat_role.ASSISTANT)
				else:
					if debug_mode:
						print(data)
					var word:String = data["response"]
					if debug_mode:
						printraw(word)
					new_word.emit(word)
					response[0] += word
					if data["done"] == true:
						message_end.emit(response[0])
						send_message(response[0], chat_role.ASSISTANT)


## Sets a given tools availability to the model
func set_tool_active(function_name:String, active:bool):
	var tool:ChatTool
	for t in tools:
		if t.function_name == function_name:
			tool = t
			break
	if tool == null:
		push_error("Function '", function_name, "' not found in tools array. Check your spelling!")
		return
	tool.active = active
	_set_tool_prompt()
	set_system_prompt(internal_system_prompt)


## Generate a response based on the input. Does not support [member conversaion] history.
## See also [method start_response]
func generate(prompt:String, stream:bool = false, format_json:bool = false, raw:bool = false, system:String = internal_system_prompt, prefix:String = "") -> String:
	response = [""]
	var query:Dictionary = {
		"model": model,
		"prompt":prompt,
		"stream": stream,
		"raw":raw,
		"options":{}
	}
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	if format_json:
		query["format"] = "json"
	for option:String in options:
		query["options"][option] = options[options]
	var query_string = JSON.stringify(query)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	client.request(HTTPClient.METHOD_POST, "/api/generate", [], query_string)
	message_start.emit()
	return response[0]


## Internal function. Used for parsing a models json output for function-calling
func parse_string_to_array(input_string: String) -> Array:
	input_string = input_string.replace("[[", "[")
	if input_string == "" or input_string == "[]":
		return []
	var json = JSON.parse_string(input_string)
	if json is Dictionary:
		return [json]
	return str_to_var(input_string)


func _ready() -> void:
	if Engine.is_editor_hint() and tools.size() == 0:
		var new_tool:ChatTool = ChatTool.new()
	if !Engine.is_editor_hint():
		message_end.connect(func(message:String):
			var blocks:Array = parse_string_to_array(message)
			_call_tools(blocks)
			)
		_set_tool_prompt()
	super()



func _call_tools(json:Array):
	if !target_node or !json:
		return
	var calls:int = 0
	if !built_in_tool_support:
		for call in json:
			if target_node.has_method(call["function"]):
				if debug_mode:
					print("Calling function '", call["function"], "' with arguments ", call["args"], ".")
				await target_node.callv(call["function"], call["args"])
				calls += 1
			else:
				if debug_mode:
					print("No method '", call["function"], "' in Node ", target_node)
	else:
		for function in json:
			var arguments:Array = []
			for arg in function["function"]["arguments"]:
				arguments.append(function["function"]["arguments"][arg])
			if target_node.has_method(function["function"]["name"]):
				var method_name:String = function["function"]["name"]
				var ordered_args := []
				var unfitting_args := []
				var current_method:ChatTool
				for tool in tools:
					if tool.function_name == function["function"]["name"]:
						current_method = tool
						break
				for arg in current_method.arguments:
					if arg.name in function["function"]["arguments"]:
						ordered_args.append(function["function"]["arguments"][arg.name])
					else:
						if debug_mode:
							print(arg["name"], " is not in ", function["function"]["arguments"])
						unfitting_args.append(function["function"]["arguments"][arg["name"]])
						#false_argument_names = true
						#break
				ordered_args += unfitting_args
				if debug_mode:
					print("ordered arguments: ", ordered_args)
				await target_node.callv(function["function"]["name"], ordered_args)
				calls += 1
			pass
	if debug_mode:
		print("Called ", calls, " out of ", json.size(), " calls.")


## Generates a response based on the [member conversation]
## See also [method send_message] and [method generate]
func start_response(format_json:bool = false, prefix:String = "") -> void:
	response = [""]
	var query:Dictionary = {}
	query = {
		"model": model,
		"messages": conversation,
		"stream": true,
		"stop":"\n",
		"options":{}
	}
	for option in options:
		query["options"][option] = options[option]
	if built_in_tool_support:
		var tools_array := []
		for tool_index in tools.size():
			var new_tool := {"type":"function"}
			var function := {}
			var tool:ChatTool = tools[tool_index]
			function["name"] = tool.function_name
			function["description"] = tool.description
			var parameters := {"type":"object"}
			var properties := {}
			var required : PackedStringArray = []
			for i in tool.arguments.size():
				var new_prop := {"type":tool.arguments[i].type_string[tool.arguments[i].type]}
				new_prop["description"] = tool.arguments[i].descrption
				if tool.arguments[i].example != "":
					new_prop["description"] += ", e.g. " + tool.arguments[i].example
				elif tool.is_tool_caller and target_node is ToolChatRequester:
					new_prop["description"] += ". These are the tools you can call: "
					for other_tool:ChatTool in target_node.tools:
						if other_tool.active:
							new_prop["description"] += "'" + other_tool.function_name + "', "
					if debug_mode:
						print("Prompt:\n" + new_prop["description"])
				if tool.arguments[i].type == ToolArgument.ArgType.ENUM:
					new_prop["enum"] = tool.arguments[i].enum_options
				properties[tool.arguments[i].name] = new_prop
				if tool.arguments[i].required:
					required.append(tool.arguments[i].name)
			if debug_mode:
				print("These are the properties btw: ", properties)
			parameters["properties"] = properties
			parameters["required"] = required
			function["parameters"] = parameters
			new_tool["function"] = function
			tools_array.append(new_tool)
		query["tools"] = tools_array
		if debug_mode:
			print("tools_array: ", tools_array)
	if format_json:
		query["format"] = "json"
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	if built_in_tool_support:
		query["stream"] = false
	var query_string = JSON.stringify(query)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	client.request(HTTPClient.METHOD_POST, "/api/chat", [], query_string)
	message_start.emit()


func get_streamed_response(format_json:bool = false) -> Array[String]:
	var query:Dictionary = {}
	query = {
		"model": model,
		"messages": conversation,
		"stream": true,
		"stop":"\n",
		"options":{}
	}
	for option in options:
		query["options"][option] = options[option]
	if built_in_tool_support:
		var tools_array := []
		for tool_index in tools.size():
			var new_tool := {"type":"function"}
			var function := {}
			var tool:ChatTool = tools[tool_index]
			function["name"] = tool.function_name
			function["description"] = tool.description
			var parameters := {"type":"object"}
			var properties := {}
			var required : PackedStringArray = []
			for i in tool.arguments.size():
				var new_prop := {"type":tool.arguments[i].type_string[tool.arguments[i].type]}
				new_prop["description"] = tool.arguments[i].descrption
				properties[tool.arguments[i].name] = new_prop
				if tool.arguments[i].required:
					required.append(tool.arguments[i].name)
			parameters["properties"] = properties
			parameters["required"] = required
			tools_array.append(new_tool)
		query["tools"] = tools_array
	if format_json:
		query["format"] = "json"
	if built_in_tool_support:
		query["stream"] = false
	var query_string = JSON.stringify(query)
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	var result = client.request(HTTPClient.METHOD_POST, "/api/chat", [], query_string)
	response = [""]
	message_start.emit()
	return response
