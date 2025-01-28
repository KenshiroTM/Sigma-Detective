@tool
@icon("res://addons/gopilot_utils/textures/chat_requester_icon.svg")
extends Node
## A Node used to communicate with [b]ollama[/b].
## Use [method send_message] and [method start_generation] afterwards!
## Connect the [signal message_end] signal for simple use
## [codeblock]
## extends Node
## @onready var chat := $ChatRequester
## 
## func _ready():
##    var message := "Why is the sky blue?"
##    chat.send_message(message)
##    chat.start_respopnse()
##    chat.new_word.connect(_new_word_received)
## 
## # Prints the newly generated word
## func _new_word_received(word:String):
##    print(word)
## [/codeblock]
class_name ChatRequester
## Internal constant. Defines the headers for the HTTPClient for requesting a response by the LLM
const headers = ["Content-Type: application/json"]
## URL to the ollama endpoint. When running ollama on your local machine, keep this as is
@export var host:String = "http://127.0.0.1"
## Port to the ollama connection
@export var port:int = 11434
## Model to use for generation
@export var model:String = "llama3.2"
## [b]Temperature[/b], or [b]"creativity"[/b]. Keep low (around 0.1 and 0.2) for [b]consistent and stable generations[/b].
@export_range(-0.01, 2.0, 0.01) var temperature:float = 0.7
## Used for modifying the models character. You can make it act as a generic assistant, a pirate, a dog and many more! Give it a try!
@export_multiline var system_prompt:String = "Keep your answers short!"
## Additional options to be passed to the generation[br]
## Example options: [param seed], [param frequency_penalty], [param stop], [param num_ctx]
@export var options:Dictionary = {}
## Boring stuff. Don't use this unless you are getting errors
@export_group("Debug")
## Show what exactly how the conversation between you and the assistant goes on in the console
@export var debug_mode:bool = false
## Internal variable. The raw system prompt applied to the model. Do not modify!
@export_storage var internal_system_prompt:String
### Set this to true if you want to use the generation while in-Editor
#@export var in_editor:bool = false
## The content of the conversation. Looks like this:[br]
## [codeblock]
## [
##    {
##        "role":"user",
##        "content":"Why is the sky blue?"
##    },
##    {
##        "role":"assistant",
##        "content":"It's blue because of the sun or something"
##    },
##    {
##        "role":"tool",
##        "content":"some json tool call here"
##    }
## ]
## [/codeblock]
@onready var conversation:Array[Dictionary]

## Internal variable. Contains any potential errors which may arrise
var err := 0
## Internal variable. 
var client:HTTPClient
## Internal variable. 
var connected = false

## Emitted when the model starts loading
signal message_start
## Emitted whenever the model generates a new token (word or word-chunk). Contains the generated token
signal new_word(word:String)
## Emitted when the model finishes its generation. Contains the entire generated message
signal message_end(full_message:String)
## Emitted when the Node connects to the ollama host
signal connected_to_host
## Emitted when the Node disconnects from the ollama host. For example when calling [param reconnect()]
signal disconnected_from_host


func _set(property: StringName, value: Variant) -> bool:
	if property == "connected":
		push_error("ChatRequester Error: 'connected' is a read-only variable. It cannot be changed by other scripts")
		return true
	return false


func _ready():
	if self is ToolChatRequester:
		conversation = [{"role":"system", "content":system_prompt}]
		internal_system_prompt = system_prompt
	else:
		internal_system_prompt = system_prompt
	client = HTTPClient.new()
	err = client.connect_to_host(host, port)
	assert(err == OK)


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
			connected_to_host.emit()
	elif(client.get_status() == HTTPClient.STATUS_DISCONNECTED):
		if(connected):
			connected = false
			if debug_mode:
				print("Disconnected!")
			disconnected_from_host.emit()
	elif(client.get_status() == HTTPClient.STATUS_BODY):
		if debug_mode:
			print("Requesting...")
		if(client.has_response()):
			var chunk = client.read_response_body_chunk()
			var jsdata = JSON.new()
			jsdata.parse(chunk.get_string_from_utf8())
			var data = jsdata.get_data()
			if(data):
				if data.has("error"):
					push_error("ChatRequester Error: " + data["error"])
					return
				var word:String
				if self is ToolChatRequester:
					if self.built_in_tool_support:
						word = data["message"]["tool_calls"]
				elif data.has("message"):
					word = data["message"]["content"]
				else:
					#print(data)
					word = data["response"]
				new_word.emit(word)
				response[0] += word
				if data["done"] == true:
					message_end.emit(response[0])
					send_message(response[0], chat_role.ASSISTANT)


func fill_in_the_middle_fallback(before:String, stream:bool = false, ) -> String:
	options["stop"] = ["```"]
	const LENGTHEN_PRT := "Please extend the code in a logical and sensible way:\n```gdscript\n{.code}\n```"
	generate(LENGTHEN_PRT, stream, false, false, "You are an integrated AI assistant in the Godot 4 Game Engine. Always use best practices when writing GDSCript", "```gdscript\n" + before)
	message_start.emit()
	options.erase("stop")
	return await message_end


## When provided with a before and after string, can predict what comes in the middle
## Model must support fill-in-the-middle functionality for this to work
func fill_in_the_middle(before:String, after:String, stream:bool = false) -> String:
	var query = {
		"model":model,
		"prompt":before,
		"stream":stream,
		"suffix":after,
		"options":{}
	}
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	var query_string = JSON.stringify(query)
	#var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	client.request(HTTPClient.METHOD_POST, "/api/generate", [], query_string)
	message_start.emit()
	return await message_end


## Stops the generation of the current generation stream by reconnecting.
## Calls [method reconnect] internally, but has a nicer name
func stop_generation(emit_signal:bool = true) -> void:
	if emit_signal:
		message_end.emit(response[0])
	conversation.append({"role":"assistant", "content":response[0]})
	response = [""]
	reconnect()


## Disconnects and reconnects the Node from the ollama server. Can be used to halt generation
## Does not influence the models [member conversation] history
func reconnect() -> void:
	if debug_mode:
		print("Reconnecting to ollama...")
	connected = false
	disconnected_from_host.emit()
	client.close()
	if debug_mode:
		print("\tClosed connection...")
	client.connect_to_host(host, port)
	if debug_mode:
		print("\tReconnecting...")
	message_end.emit(response[0])


## Used for simple generations without chat history
## Can be used for text completion and code generation
## Can also be awaited:
## [codeblock]
## extends Node
## 
## @onready var chat_requester := $ChatRequester
## var prompt:String = "Why is the sky blue?"
## 
## func _ready() -> void:
##    var response:String = await chat_requester.generate(prompt)
##    print("response from model: ", response)
## [/codeblock]
func generate(prompt:String, stream:bool = false, format_json:bool = false, raw:bool = false, system:String = internal_system_prompt, prefix:String = "") -> String:
	response = [""]
	var query := {}
	if !raw:
		if prefix.is_empty():
			query = {
				"model": model,
				"prompt":prompt,
				"stream": stream,
				"system":system,
				"options":{}
			}
		else:
			query = {
				"model": model,
				"messages": [
					{"role":"system", "content":system_prompt},
					{"role":"user", "content":prompt},
					{"role":"assistant", "content":prefix}
				],
				"stream": stream,
				"options":{}
			}
	else:
		query = {
			"model":model,
			"prompt":prompt,
			"stream":stream,
			"raw":true,
			"options":{}
		}
	if format_json:
		query["format"] = "json"
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	var query_string = JSON.stringify(query)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	if prefix.is_empty():
		client.request(HTTPClient.METHOD_POST, "/api/generate", [], query_string)
	else:
		client.request(HTTPClient.METHOD_POST, "/api/chat", [], query_string)
	message_start.emit()
	return (await message_end)


## All the possible roles for a message[br]
## Example usage: use [param ASSSISTANT] as the [param role] parameter in the [method send_message] method to make the model think it said that message
## [codeblock]
## func _ready():
##    # Adds user message
##    chat_requester.send_message("Hello mister AI!", ChatRequester.chat_role.USER)
##    # Adds assistants message. The model will think that it said these words!
##    chat_requester.send_message("Huh, what do you mean? I'm not an AI, I'm a unicorn!", ChatRequester.chat_role.ASSISTANT)
##    # Adds another user message
##    chat_requester.send_message("Pff yeah right.", ChatRequester.chat_role.USER)
##    chat_requester.start_response()
##    chat_requester.new_word.connect(print)
## [/codeblock]
enum chat_role {
	USER,			## Used to send a message as the user. This is the default way to talk to a model: You say something as the user, and it replies as the assistant.
	ASSISTANT,		## The models role. you can add conversation responses using the [method send_message] method and passing this as the role
	SYSTEM,			## The system prompt role. Mostly used at the very beginning of the conversation. Inserted automatically by setting [member system_prompt]
	TOOL			## Used for function-calling-capable models. Insert a message with this role if you want to give the model a hint on what it should do or give it some context[br]
	## Example: "It is currently 11:46"
	}


## Adds a message to the [member conversation] Dictionary
## Specify who said the message with [param role][br]
## Set [method start_generation] to true, to call [method start_response] automatically
func send_message(msg:String, role:chat_role = chat_role.USER, start_generation:bool = false, format_json:bool = false, prefix:String = "") -> String:
	var role_name:String
	match role:
		chat_role.USER: role_name = "user"
		chat_role.ASSISTANT: role_name = "assistant"
		chat_role.SYSTEM: role_name = "system"
		chat_role.TOOL: role_name = "tool"
		_:
			push_error("Non supported role! Quitting")
			return "ERROR! Look in console"
	conversation.append(
		{
			"role" : role_name,
			"content" : msg
		}
	)
	if start_generation:
		start_response(format_json, prefix)
		return await message_end
	else:
		return "ONLY RETURNS MESSAGE WHEN 'start_generation' is true!"


## Sets the [member system_prompt] of the Node and model. Modifies [member conversation] to accomplish that
func set_system_prompt(system:String) -> void:
	internal_system_prompt = system
	if conversation.size() > 0:
		conversation[0]["content"] = internal_system_prompt
	else:
		conversation.append({"role":"system", "content":internal_system_prompt})


## Returns the current [member conversation]
## Use the format highlighted shown in [member conversation]!
func get_conversation() -> Array[Dictionary]:
	return conversation


## Returns the list of models in your ollama server 
func get_models() -> PackedStringArray:
	if debug_mode:
		print("Getting models...")
	var model_getter := HTTPClient.new()
	model_getter.connect_to_host(host, port)
	while true:
		await get_tree().create_timer(0.05).timeout
		model_getter.poll()
		if model_getter.get_status() == model_getter.Status.STATUS_CONNECTED:
			if debug_mode:
				print("\tConnected to host '", host, "'")
			break
	model_getter.request(HTTPClient.METHOD_GET, "/api/tags", [])
	var result:PackedByteArray = []
	while true:
		await get_tree().create_timer(0.05).timeout
		model_getter.poll()
		if model_getter.get_status() == model_getter.Status.STATUS_BODY:
			if debug_mode:
				print("\tHas response from host!")
			#model_getter.poll()
			result = model_getter.read_response_body_chunk()
			break
	var jsdata = JSON.new()
	#print(result)
	#print(result.get_string_from_utf8())
	jsdata.parse(result.get_string_from_utf8())
	var data = jsdata.get_data()
	#print(data)
	var all_models:PackedStringArray = []
	if data is Dictionary:
		for i in data["models"]:
			all_models.append(i["name"])
	if debug_mode:
		print("\t returning models: ", all_models)
	return all_models


## Sets the [member conversation]. The conversation must be structured like this
## [codeblock]
## [
##    {
##        "role":"user",
##        "content":"Some message here"
##    },
##    {
##        "role":"assistant",
##        "content":"Some message by the AI"
##    }
## ]
## [/codeblock]
func set_conversation(_conversation:Array[Dictionary]) -> void:
	conversation = _conversation


## Clears the current [member conversation]
## Set [param keep_system_prompt] to false, to remove the system prompt
func clear_conversation(keep_system_prompt:bool = true) -> void:
	conversation = []
	if keep_system_prompt:
		conversation = [{"role":"system", "content":internal_system_prompt}]


## Internal variable. Keeps track of the generated text
var response:Array = [""]

## Begins the generation of a response to the users instruction[br]
## Must be called to start generation
func start_response(format_json:bool = false, prefix:String = "") -> void:
	while true:
		if client.get_status() != client.Status.STATUS_CONNECTED:
			await get_tree().create_timer(0.1).timeout
		else:
			break
	response = [""]
	var query:Dictionary
	query = {
		"model": model,
		"messages": conversation,
		"stream": true,
		"options":{}
	}
	if !prefix.is_empty():
		query["messages"] = conversation + [{"role":"assistant", "content":prefix}]
	if format_json:
		query["format"] = "json"
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	var headers := ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(JSON.stringify(query).length())]
	client.request(HTTPClient.METHOD_POST, "/api/chat", [], JSON.stringify(query))
	message_start.emit()



## @deprecated
## Can be used instead of [method start_response][br]
## Returns the [member response] array which will repeatedly update it's contents to contain the updated generated text from the model[br]
## It is recommended to use the [signal new_word] signal instead of this, as it's notification functionality is easier to work with
func get_streamed_response(format_json:bool = false) -> Array[String]:
	var query := {
		"model": model,
		"messages": conversation,
		"stream": true,
		"options":{}
	}
	if format_json:
		query["format"] = "json"
	if temperature != -0.01:
		query["options"]["temperature"] = temperature
	for option in options:
		query["options"][option] = options[option]
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(JSON.stringify(query).length())]
	client.request(HTTPClient.METHOD_POST, "/api/chat", [], JSON.stringify(query))

	response = [""]
	message_start.emit()
	return response
