extends Control



static func trim_code_block(text:String, convert_to_tabs:bool = true) -> String:
	text = text.trim_prefix("```")
	text = text.trim_prefix("gdscript")
	text = text.trim_prefix("\n")
	text = text.trim_suffix("\n")
	text = text.trim_suffix("\n```")
	if convert_to_tabs:
		text = text.replace("    ", "\t")
	return text


func fix_broken_json(broken_json: String) -> String:
	var stack = []
	var in_string = false
	var escape_next = false
	var current_key = ""
	var expecting_colon = false
	var expecting_value = false
	
	# First pass: validate and track structure
	for i in range(broken_json.length()):
		var char = broken_json[i]
		
		# Handle escape sequences
		if escape_next:
			escape_next = false
			continue
			
		if char == "\\":
			escape_next = true
			continue
			
		# Handle strings
		if char == "\"" and not escape_next:
			in_string = !in_string
			continue
			
		if in_string:
			continue
			
		# Handle structure
		match char:
			"{":
				stack.push_back("{")
			"[":
				stack.push_back("[")
			"}":
				if stack.size() > 0 and stack.back() == "{":
					stack.pop_back()
			"]":
				if stack.size() > 0 and stack.back() == "[":
					stack.pop_back()
	
	# If we're still in a string, the JSON is broken
	if in_string:
		# Close the string
		broken_json += "\""
	
	# Close remaining open structures
	while stack.size() > 0:
		var last = stack.pop_back()
		if last == "{":
			broken_json += "}"
		elif last == "[":
			broken_json += "]"
	
	# Validate the result
	var json = JSON.new()
	var error = json.parse(broken_json)
	
	# If parsing failed, return empty object
	if error != OK:
		return "{}"
	
	return broken_json



const INCLUDE_PROPERTIES := false
const INCLUDE_CHILDREN := true
const MAX_DEPTH = 5


func get_node_as_dict(node:Node, depth:int = 0, max_depth:int = MAX_DEPTH, include_properties:bool = INCLUDE_PROPERTIES, include_children := INCLUDE_CHILDREN) -> Dictionary:
	var dict := {}
	if !node.name.begins_with(node.get_class()):
		var n:String = String(node.name)
		if node.unique_name_in_owner:
			n = "%" + n
		dict["name"] = n
	dict["type"] = node.get_class()
	if include_properties:
		var properties:Array[Dictionary] = []
		var prop_list := node.get_property_list()
		for prop in prop_list:
			var n:String = prop["name"]
			if node.property_get_revert(n) != node.get(n):
				properties.append({"name":n, "value":node.get(n)})
		dict["properties"] = properties
	if !node.scene_file_path.is_empty() and depth != 0:
		dict["scene_path"] = node.scene_file_path
	elif depth <= max_depth and node.get_child_count() != 0 and include_children:
		var children:Array[Dictionary] = []
		for child in node.get_children():
			var child_dict := get_node_as_dict(child, depth + 1)
			children.append(child_dict)
		dict["children"] = children
	return dict

const ACTION_KEYS:PackedStringArray = ["get_selected_nodes", "get_selected_code"]

const ACTION_TYPES:PackedStringArray = ["edit_script", "create_script", "edit_scene_tree"]

const ACTION_DESCRIPTION := {
	"get_selected_code":"Gets you the code I have selected in the script editor",
	"get_selected_node":"Gets you the nodes I have selected in the SceneTree",
	"edit_node_property":"Lets you edit a property of a specific node",
}

var overlay:Control

var json_chatter:ChatRequester

var ACTION_SELECTION_PROMPT := """You are an integrated AI assistant in the Godot 4 Game Engine.
Instruction: {.instruction}

What info do you want to get?
You must respond in JSON using this schema
```json
{
	"action":"your_action_here" // Must be one of these: """ + str(ACTION_KEYS) + """
}
```
DO NOT ADD ANY OTHER KEYS!
Only perform an action when the user asks you to do it! If no action is requested, set the action to "reply"."""

const GET_INFO_PROMPT := """You are an integrated AI assistant in the Godot 4 Game Engine.
Instruction: {.instruction}

Would you like to get additional information or respond to me?
You must respond in JSON using this schema
```json
{
	"action":"your_action_here" // Must be either "respond" or "get_info"
}
```
DO NOT ADD ANY OTHER KEYS!
"""


const ANALYSIS_PRT := """Have a look at this conversation:\n{.conversation}\n
What is the intent of the user? What do they want to do?
Think about if the user wants to do something themselves or if they want the AI to do it."""

const ANALYSIS_JSON_PRT := """Provide your findings in JSON using this schema:
```json
{
	"user_intent":"The intent of the user",
	"message_type":type of the message // Should be either "question" or "work_assignment"
}
```
Respond with nothing else."""

func perform_action(gpi:ChatRequester, prompt:String, conversation:Array[Dictionary]):
	var conv:String
	for i in min(conversation.size(), 3):
		conv += conversation[i]["role"] + ": " + conversation[i]["content"] + "\n"
	var prt := ANALYSIS_PRT.replace("{.conversation}", conv)
	gpi.send_message(prt, ChatRequester.chat_role.USER, true)
	# ChatRequester.chat_role.USER, true, false, "{\"user_intent\":\""
	gpi.options["stop"] = ["\n```"]
	var json_response = "{\"user_intent\":\"" + await gpi.send_message(ANALYSIS_JSON_PRT, ChatRequester.chat_role.USER, true, false, "```json\n{\"user_intent\":\"")
	gpi.options.erase("stop")
	json_response = JSON.parse_string(json_response)
	print(json_response)
	if json_response is not Dictionary:
		gpi.clear_conversation()
		return
	
class MyResource extends Resource:
	@export_multiline var some_string:String
	@export_range(0.0, 1.0, 0.01) var some_number:int

const PACKED_SCENE_ICON := preload("res://addons/gopilot_utils/textures/PackedScene.png")
const replace_for_interface:Dictionary[String, String] = {"/nodes":"nodes", "/script":"opened script", "/scene":"scene tree"}

##  Returns dictionary like this
##  [codeblock]
##  {
##     "prompt":"the parsed prompt here",
##     "citations":[
##         {
##             "name":"name of citation e.g. some_script.gd",
##             "file_path":"path to file, if any",
##             "tooltip":"some tooltip here",
##             "icon":<custom icon for the citation>
##         },
##         ...
##     ]
##  }
##  [/codeblock]
func parse_prompt(prompt:String) -> Dictionary[String, Variant]:
	var citations:Array[Dictionary] = []
	var editor := EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	var final_prompt = ""
	var selected_code:String
	var node_json:String
	var full_script:String
	var scene_tree:String
	
	# Adding complete open script into the prompt by using /script
	if editor:
		if "/script" in prompt:
			var script_path:String = EditorInterface.get_script_editor().get_current_script().resource_path
			var file_name:String = script_path.split("/")[-1]
			full_script = "## Opened Script '" + file_name + "'\n```gdscript\n" + editor.text + "\n```\n"
			citations.append({"name":file_name,
			"file_path":script_path,
			"tooltip":"Open script '" + script_path + "'"})
		
		# Adding the selected code to the prompt by using /code
		if "/code" in prompt and editor and editor.get_selected_text().length() != 0:
			selected_code += "I want you to focus on this code I have selected right now:\n```gdscript\n" + editor.get_selected_text() + "\n```\n"
			citations.append({"name":"Selected Code", "tooltip":"The code you currently have selected"})
	
	# Adding the scene tree
	if "/scene" in prompt:
		var root:Node = EditorInterface.get_edited_scene_root()
		var scene_path:String = root.scene_file_path
		var root_children:Array[Dictionary]
		for node in root.get_children():
			root_children.append(get_node_as_dict(root))
		citations.append({"name":root.scene_file_path.split("/")[-1], "tooltip":"The currently opened scene '"\
		+ root.scene_file_path + "'", "file_path":root.scene_file_path, "icon":PACKED_SCENE_ICON})
		var scene := {"file_name":root.scene_file_path, "name":root.name, "children":root_children}
		scene_tree += "This is my current scene tree:\n```json\n" + str(scene) + "\n```\n"
	
	# Adding selected node tree information into the prompt by using /nodes
	# TODO Include information only about the selected nodes, not the entire children tree aswell.
	# TODO So then we can focus on what's important most!
	if "/nodes" in prompt:
		var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
		var nodes := {"selected_nodes":[]}
		for node in selected_nodes:
			nodes["selected_nodes"].append(get_node_as_dict(node))
			
			citations.append({"name":node.name, "tooltip":"The " + node.get_class() + " you have selected", "icon":get_theme_icon(node.get_class(), "EditorIcons")})
		node_json += "This is my currently selected Node:\n```json\n" + str(nodes) + "\n```\n"
	for key in replace_for_interface:
		prompt = prompt.replace(key, replace_for_interface[key])
	
	# Adding selected code, if any
	if editor.get_selected_text() != "":
		var file_path:String = EditorInterface.get_script_editor().get_current_script().resource_path
		var file_name:String = file_path.split("/")[-1]
		selected_code = "Currently I have this code selected:\n```gdscript\n" + editor.get_selected_text() + "\n```\n"
		citations.append({"name":"Selected Code", "tooltip":"The code you have selected in the script editor", "file_path":file_path})
	
	# Adding other referenced scripts into prompt by using /script_name.gd in the prompt
	# Only works if script is open in the script side bar
	var other_scripts:String
	if "/" in prompt:
		var space_split := prompt.split(" ")
		for split in space_split:
			if !split.begins_with("/"):
				continue
			split = split.trim_suffix(".").trim_suffix("?").trim_suffix("!")
			if split.ends_with(".gd"):
				var script_path:String
				var scripts := EditorInterface.get_script_editor().get_open_scripts()
				for script in scripts:
					if script.resource_path.ends_with(split):
						script_path = script.resource_path
						break
				if script_path.is_empty():
					continue
				other_scripts += "## " + script_path + "\n```gdscript\n"\
				+ FileAccess.open(script_path, FileAccess.READ).get_as_text() + "\n```\n"
				citations.append({"name":split, "tooltip":"Open script '" + script_path + "'", "file_path":script_path})
		prompt = prompt.replace(" /", " ")
	
	final_prompt = other_scripts + scene_tree + full_script + selected_code + prompt
	return {"prompt":final_prompt, "citations":citations}


func get_class_reference(_class:String) -> String:
	var engine_script_editor = EditorInterface.get_script_editor()
	var engine_edit_tab=engine_script_editor.get_child(0).get_child(1).get_child(1).get_child(0)
	engine_script_editor.goto_help(_class)
	var script:Script = engine_script_editor.get_current_script()
	var text:String
	for i in engine_edit_tab.get_children():
		if i.get_class()=="EditorHelp" and i.name == _class:
			var engine_edit_help:RichTextLabel=i.get_child(0)
			text = engine_edit_help.get_parsed_text()
			print(text)
			if script:
				EditorInterface.edit_script(script)
			break
	if !text.is_empty():
		if "Description" in text:
			var description:String = text.split("\t")[1]
			return description
		pass
	return text


func create_inherited_scene(inherits: PackedScene, root_name := "Scene") -> PackedScene:
	var scene := PackedScene.new()
	scene._bundled = { "names": [root_name], "variants": [inherits], "node_count": 1, "nodes": [-1, -1, 2147483647, 0, -1, 0, 0], "conn_count": 0, "conns": [], "node_paths": [], "editable_instances": [], "base_scene": 0, "version": 3 }
	return scene


var patterns := {
	# Inline code
	"`([^`]*?)(`|$)": "[code]$1[/code]",
	
	# Headers (must be at start of line)
	"(?m)^###\\s*(.+?)$": "[font_size=30][b]$1[/b][/font_size]\n",
	"(?m)^##\\s*(.+?)$": "[font_size=35][b]$1[/b][/font_size]\n",
	"(?m)^#\\s*(.+?)$": "[font_size=40][b]$1[/b][/font_size]\n",
	
	# Bold and italic (descending priority)
	"\\*\\*\\*([^\\*]*?)(?:\\*\\*\\*|$)": "[b][i]$1[/i][/b]",
	"\\*\\*([^\\*]*?)(?:\\*\\*|$)": "[b]$1[/b]",
	"\\*([^\\*]*?)(?:\\*|$)": "[i]$1[/i]",
	
	# Lists
	#"\\d+?\\. (.+?)\\n": "[ol]$1[/ol]",
	#"(?s)(?:^|\\s)(\\[(?:ol]\\n)?(?:\\d+\\..*(?:\\n|$))+(?:\\n?[\\s|$])":"",
	#"(?s)(?:^|\\s)(?:\\n?)?(\\d+\\..*(?:\\n\\d+\\..*)*)(?:\\n|$)":"[ol]\n" + 
#"\\1\n".replace("\\n", "\n").replace("  ", "\n").replace("\\d+\\.", "[*]") + 
#"[/ol]",
	#"- (.+?)$": "[ul]$1[/ul]",
	
	# Link replacement
	"\\[([^\\]]+?)\\]\\(([^\\)]+?)\\)": "[url=$2]$1[/url]"
}
func markdown_to_bbcode(markdown:String) -> String:
	var split := markdown.split("\n```")
	
	var start_with_code:bool = split[0].begins_with("```") or split[0].begins_with("\n```")
	
	var markdown_texts:PackedStringArray
	var code_blocks:PackedStringArray
	
	if start_with_code:
		for i in split.size():
			if i % 2 == 0.0:
				code_blocks.append(split[i])
			else:
				markdown_texts.append(split[i])
	else:
		for i in split.size():
			if i % 2 == 0.0:
				markdown_texts.append(split[i])
			else:
				code_blocks.append(split[i])
	
	var code_regex := RegEx.new()
	code_regex.compile("\\A.*?\\n([\\s\\S]+)\\Z")
	
	for code in code_blocks.size():
		#print("replacing ", code_blocks[code] , "\nwith ", code_regex.sub(code_blocks[code], "$1"))
		code_blocks[code] = code_regex.sub(code_blocks[code], "\n$1").trim_prefix("\n")
	
	for text in markdown_texts.size():
		#print("iterating over markdown")
		for pattern in patterns:
			var regex := RegEx.new()
			var err := regex.compile(pattern, true)
			if err != OK:
				continue
			var replacement:String = patterns[pattern]
			var result := regex.sub(markdown_texts[text], replacement, true)
			#if markdown_texts[text] != result:
				#print("from: ", markdown_texts[text], "\nto: ", result)
			markdown_texts[text] = result
		# Create a RegEx pattern to match Markdown tables
		var table_pattern = RegEx.new()
		table_pattern.compile(r'\|.*\|\n\|.*\|\n(\|.*\|\n)*')
		
		# Find all tables in the text
		var matches = table_pattern.search_all(markdown_texts[text])
		
		for match in matches:
			# Extract the table content
			var table_content = match.get_string(0)
			
			# Split the table into rows
			var rows := table_content.split('\n')
			
			# Remove the separator row (second row)
			rows.remove_at(1)
			
			# Determine the number of columns from the header row
			var header_row := rows[0]
			var columns := header_row.split('|')
			var num_columns := columns.size() - 2  # Exclude the leading and trailing pipes
			
			# Start the BBCode table
			var bbcode_table := '[table=' + str(num_columns) + ']'
			
			for row in rows:
				# Split the row into cells
				var cells = row.split('|')
				for i in range(1, cells.size() - 1):  # Exclude the leading and trailing pipes
					var cell = cells[i].strip_edges()  # Trim leading and trailing whitespace
					bbcode_table += '[cell]' + cell + '[/cell]'
				bbcode_table += '\n'
			
			# End the BBCode table
			bbcode_table += '[/table]'
			
			# Replace the markdown table with the BBCode table
			markdown_texts[text] = markdown_texts[text].replace(table_content, bbcode_table)
	
	#print("code:", code_blocks)
	#print("text:", markdown, "\n")
	var result:String
	var mark_i := 0
	var code_i := 0
	if start_with_code:
		for i in markdown_texts.size() + code_blocks.size():
			if i % 2 == 0.0:
				result += "[bgcolor=00000080]" + code_blocks[code_i] + "[/bgcolor]"
				code_i += 1
			else:
				result += markdown_texts[mark_i]
				mark_i += 1
	else:
		for i in markdown_texts.size() + code_blocks.size():
			if i % 2 == 0.0:
				result += markdown_texts[mark_i]
				mark_i += 1
			else:
				result += "[bgcolor=00000080]" + code_blocks[code_i] + "[/bgcolor]"
				code_i += 1
	return result



func json_to_node(json_text: String, expand_interface: bool = true) -> Node:
	var obj := JSON.new()
	var parse_err := obj.parse(json_text)
	if parse_err != OK:
		print("Error line: ", obj.get_error_line(), "\nError message: ", obj.get_error_message())
		return Node.new()
	
	var response = obj.get_data()
	var json: Dictionary
	if obj.data is Array:
		json = obj.data[0]
	elif obj.data is Dictionary:
		json = obj.data
	
	if obj.data.has("Root"):
		json = obj.data["Root"]
	
	var new_node: Node = Node.new()
	
	if json.has("type") and json["type"] in ClassDB.get_class_list():
		new_node = ClassDB.instantiate(json["type"])
	
	if new_node is Control:
		if json.has("expand") and json["expand"] == true:
			pass
		else:
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			new_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var properties:PackedStringArray
	for property in new_node.get_property_list():
		properties.append(property["name"])
	
	for key in json:
		if key in ["type", "children"]:
			continue
		if key in properties:
			new_node.set(key, json[key])
	
	if json.has("children"):
		var children:Array[Node]
		for child:Dictionary in json["children"]:
			children.append(json_to_node(str(child)))
		
		for node in children:
			new_node.add_child(node)
	return new_node
