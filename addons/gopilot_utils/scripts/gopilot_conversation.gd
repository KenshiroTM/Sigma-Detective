@tool
extends Control

enum Role {SYSTEM, ASSISTANT, USER, TOOL}

var messages:Array[Control]

signal remove_message_requested(message_index:int)
signal edit_message_requested(message_index:int, new_text:String)

const CONVERSATION_CONTEXT_OPTIONS:Dictionary[String, Callable] = {
	#"Remove Message":
}

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()


@export var use_markdown_formatting:bool = false
@export var buddy_visible:bool = true:
	set(new):
		buddy_visible = new
		if is_node_ready():
			%BuddyCon.visible = new
		else:
			ready.connect(func():
				var buddy_con:CenterContainer = get_node("%BuddyCon")
				buddy_con.set_visible.bind(new))

#
@export var welcome_message_visible:bool = true:
	set(new):
		welcome_message_visible = new
		if is_node_ready():
			%WelcomeMessage.visible = new
		else:
			ready.connect(%WelcomeMessage.set_visible.bind(new))

@export var warning_visible:bool = true:
	set(new):
		warning_visible = new
		if is_node_ready():
			%Warning.visible = new
		else:
			ready.connect(%Warning.set_visible.bind(new))

func _process(delta:float):
	%ScrollCon.scroll_vertical = %ContentCon.size.y


var locked_to_floor:bool = true


func scroll_container_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			locked_to_floor = false
			set_process(false)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if %ContentCon.size.y - %ScrollCon.size.y == %ScrollCon.scroll_vertical or\
			%ContentCon.size.y == %ScrollCon.size.y:
				locked_to_floor = true
				set_process(true)


func play_godot_animation(animation:String):
	if %BuddyCon.get_child_count() != 0:
		%BuddyCon.get_child(0).get_node("Anim").play(animation)


func _ready() -> void:
	play_godot_animation("idle")
	%ScrollCon.gui_input.connect(scroll_container_input)


func clear_conversation():
	for child in %Conversation.get_children():
		child.queue_free()
	messages.clear()




func add_custom_control(control:Control) -> void:
	%Conversation.add_child(control)


func update_conversation(con:Array[Dictionary]) -> void:
	for msg in con:
		create_custom_bubble(msg["role"], msg["content"])

var text_so_far:String = ""

func create_custom_bubble(role:String = "", content:String = "", citations:Array = []):
	text_so_far = ""
	var new_chat_bubble := %ChatEntrySample.duplicate()
	match role:
		"Assistant", "assistant": new_chat_bubble.set_role(role, true, false, false)
		"User", "user": new_chat_bubble.set_role(role, true, true, false)
		_: new_chat_bubble.set_role(role)
	new_chat_bubble.set_message(content)
	for cite in citations:
		new_chat_bubble.add_citation(cite)
	messages.append(new_chat_bubble)
	%Conversation.add_child(new_chat_bubble, true)
	new_chat_bubble.request_edit.connect(_on_message_edit)
	new_chat_bubble.request_remove.connect(_on_message_remove)
	new_chat_bubble.show()


func add_action(title:String, action_description:String = "", content:String = ""):
	var new_action_block := %ActionSample.duplicate()
	%Conversation.add_child(new_action_block)
	if !new_action_block.is_node_ready():
		print("not ready")
		await new_action_block.ready
		print("now ready")
	new_action_block.add_action(title, action_description, content)
	new_action_block.show()
	#print(%Conversation.get_tree_string_pretty())


## Can only be called when there is no chat block after the action block
func add_sub_action(title:String, action_description:String = "", content:String = ""):
	%Conversation.get_child(-1).add_action(title, action_description, content)


func _on_message_edit(new_text:String, message:Control):
	var parsed_data:Dictionary[String, Variant] = COMMON.parse_prompt(new_text)
	message.clear_citations()
	var prompt:String = parsed_data["prompt"]
	var citations:Array[Dictionary] = parsed_data["citations"]
	for cite in citations:
		message.add_citation(cite)
	edit_message_requested.emit(messages.find(message), new_text)
	if chat:
		var message_index:int = -(messages.size() - messages.find(message))
		chat.conversation[message_index]["content"] = prompt


func _on_message_remove(message:Control):
	remove_message_requested.emit(messages.find(message))
	var index := message.get_index()
	var amount_to_remove:int = %Conversation.get_child_count() - message.get_index()
	for i in amount_to_remove:
		%Conversation.get_child(-i - 1).queue_free()
		messages.pop_back()
	if chat:
		for i in amount_to_remove:
			chat.get_conversation().pop_back()


func create_user_bubble(prompt:String, citations:Array = []):
	create_custom_bubble("User", prompt, citations)


func create_assistant_bubble(prompt:String = "", citations:Array = [{"name":"Not Grounded", "file_path":"res://addons/gopilot_utils/trust_me_bro.md", "tooltip":"There is no source.\nGopilot didn't ground its response"}]):
	create_custom_bubble("Assistant", prompt, citations)

func add_to_last_bubble(new_word:String) -> void:
	if %Conversation.get_child_count() == 0:
		return
	text_so_far += new_word
	if use_markdown_formatting:
		if %Conversation.get_child(-1).has_method("set_message"):
			%Conversation.get_child(-1).set_message(COMMON.markdown_to_bbcode(text_so_far))
	else:
		%Conversation.get_child(-1).set_message(text_so_far)


func pop_last_bubble():
	if %Conversation.get_child_count() > 0:
		%Conversation.get_child(-1).queue_free()


#func markdown_to_bbcode(markdown_text: String) -> String:
	## Create a RegEx pattern to match **bold** text
	#var bold_pattern = RegEx.new()
	#bold_pattern.compile(r'\*\*(.*?)\*\*')
	#
	## Replace the matched pattern with [b]bold[/b]
	#var bbcode_text = bold_pattern.sub(markdown_text, '[b]$1[/b]', true)
	#
	## Create a RegEx pattern to match *italic* text
	#var italic_pattern = RegEx.new()
	#italic_pattern.compile(r'\*(.*?)\*')
	#
	## Replace the matched pattern with [i]italic[/i]
	#bbcode_text = italic_pattern.sub(bbcode_text, '[i]$1[/i]', true)
	#
	## Alternative for *italic* text
	##var alt_italic_pattern = RegEx.new()
	##alt_italic_pattern.compile(r'\_(.*?)\_')
	#
	## Replace the matched pattern with [i]italic[/i]
	##bbcode_text = alt_italic_pattern.sub(bbcode_text, '[i]$1[/i]', true)
	#
	## Create a RegEx pattern to match Markdown tables
	#var table_pattern = RegEx.new()
	#table_pattern.compile(r'\|.*\|\n\|.*\|\n(\|.*\|\n)*')
	#
	## Find all tables in the text
	#var matches = table_pattern.search_all(bbcode_text)
	#
	#for match in matches:
		## Extract the table content
		#var table_content = match.get_string(0)
		#
		## Split the table into rows
		#var rows := table_content.split('\n')
		#
		## Remove the separator row (second row)
		#rows.remove_at(1)
		#
		## Determine the number of columns from the header row
		#var header_row := rows[0]
		#var columns := header_row.split('|')
		#var num_columns := columns.size() - 2  # Exclude the leading and trailing pipes
		#
		## Start the BBCode table
		#var bbcode_table := '[table=' + str(num_columns) + ']'
		#
		#for row in rows:
			## Split the row into cells
			#var cells = row.split('|')
			#for i in range(1, cells.size() - 1):  # Exclude the leading and trailing pipes
				#var cell = cells[i].strip_edges()  # Trim leading and trailing whitespace
				#bbcode_table += '[cell]' + cell + '[/cell]'
			#bbcode_table += '\n'
		#
		## End the BBCode table
		#bbcode_table += '[/table]'
		#
		## Replace the markdown table with the BBCode table
		#bbcode_text = bbcode_text.replace(table_content, bbcode_table)
	#
	#var code_splitter = ""
	#if "```" in bbcode_text:
		#var split := bbcode_text.split("```")
		#var new_text := ""
		#for i in split.size():
			#new_text += split[i]
			#if i == split.size():
				#break
			#if i % 2 == 0.0:
				#new_text += "[bgcolor=black][color=white]"
			#else:
				#new_text += "[/color][/bgcolor]"
		#bbcode_text = new_text
	#if "`" in bbcode_text:
		#var split := bbcode_text.split("`")
		#var new_text := ""
		#for i in split.size():
			#new_text += split[i]
			#if i == split.size():
				#break
			#if i % 2 == 0.0:
				#new_text += "[bgcolor=black][color=white]"
			#else:
				#new_text += "[/color][/bgcolor]"
		#bbcode_text = new_text
	#
	#return bbcode_text


func set_user(user:String, format:String = "[b]Hello {.user}[/b]\nWhat would you like to do?"):
	%WelcomeMessage.text = format.replace("{.user}", user)


func set_buddy(buddy:Control):
	if %BuddyCon.get_child_count() != 0:
		for child in %BuddyCon.get_children():
			child.queue_free()
	%BuddyCon.add_child(buddy)
	buddy.get_node("Anim").play("idle")


var chat:ChatRequester

func set_chat(_chat:ChatRequester):
	chat = _chat
