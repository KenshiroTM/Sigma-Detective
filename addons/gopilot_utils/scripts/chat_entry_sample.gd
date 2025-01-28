@tool
extends MarginContainer

signal request_remove(message:Control)
signal request_edit(new_message:String, message:Control)

var COMMON := preload("res://addons/gopilot_utils/scripts/common.gd").new()

@export var script_icon:Texture2D

## Sets the message of the interface
## Animates progress bar to end when [param animate] is true
func set_message(msg:String, animate:bool = false):
	if animate:
		await set_progress(100.0)
	%ProgBar.hide()
	%Content.text = msg


func set_role(role:String, can_edit:bool = false, can_remove:bool = false, can_regen:bool = false, can_copy:bool = true):
	%Role.text = role
	%EditBtn.visible = can_edit
	%RemoveBtn.visible = can_remove
	%RegenerateBtn.visible = can_regen
	%CopyBtn.visible = can_copy
#

var prog_bar_tween:Tween


func _ready() -> void:
	%ProgBar.value = 0.0


## Function to set the progress bar value of the interface
func set_progress(progress:float = 50.0, duration:float = 0.3):
	if prog_bar_tween and prog_bar_tween.is_running():
		prog_bar_tween.kill()
	prog_bar_tween = create_tween()
	prog_bar_tween.tween_property(%ProgBar, "value", progress, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	%ProgBar.show()
	await prog_bar_tween.finished


## Function to add a citation to the interface
func add_citation(cite:Dictionary):
	# Duplicate the citation sample button and assign it to new_cit
	var new_cit = %CitationSample.duplicate()
	
	# Check if the file path exists in the dictionary and is within the resources directory
	if cite.has("file_path") and cite["file_path"].begins_with("res://"):
		var file_path:String = cite["file_path"]
		var file_content:String = FileAccess.open(file_path, FileAccess.READ).get_as_text()
		var file_name = file_path.split("/")[-1]
		
		# Set the text of the new citation button to the file name
		new_cit.text = file_name
		
		if file_name.ends_with(".gd"):
			# Connect the press event of the new citation button to open the script in the editor
			new_cit.pressed.connect(func():
				EditorInterface.edit_script(load(file_path))
			)
	
	# Set the text of the new citation button to the name from the dictionary
	new_cit.text = cite["name"]
	
	# Check if an icon is present in the dictionary and set it to the new citation button
	if cite.has("icon"):
		new_cit.icon = cite["icon"]
	
	# Check if a tooltip is present in the dictionary and set it to the new citation button
	if cite.has("tooltip"):
		var tooltip:String = cite["tooltip"]
		#new_cit.tooltip_text = "hello world"
		new_cit.tooltip_text = tooltip
	
	# Show the citation component
	%CitationCon.show()
	new_cit.show()
	
	# Add the new citation button to the citations container
	%Citations.add_child(new_cit)


func clear_citations() -> void:
	%CitationCon.hide()
	for cite in %Citations.get_children():
		cite.queue_free()


## Function to append text to the interface message area
func add_to_message(update:String):
	%Content.append_text(update)


func _on_mouse_entered() -> void:
	%Buttons.show()
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	if valid:
		%Buttons.hide()


var valid:bool = true

func _on_remove_btn_pressed() -> void:
	valid = false
	request_remove.emit(self)


func _on_edit_btn_pressed() -> void:
	%EditPopup.position = Vector2(get_window().position) + global_position
	%EditPopup.popup()
	%EditText.text = %Content.text


func _on_accept_edit_btn_pressed() -> void:
	%EditPopup.hide()
	request_edit.emit(%EditText.text, self)
	%Content.text = %EditText.text


func _on_copy_btn_pressed() -> void:
	var content:String = %Content.text.replace("    ", "\t")
	DisplayServer.clipboard_set(content)
