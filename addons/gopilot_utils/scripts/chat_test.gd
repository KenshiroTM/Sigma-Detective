@tool
extends Control

@export var SEND_ICON:Texture2D
@export var STOP_ICON:Texture2D

var generating:bool = false

var chat:ChatRequester
@onready var conv_node := %ChatConversation
var conv:Array[Dictionary] = []

func set_chat_requester(requester:ChatRequester) -> void:
	chat = requester
	chat.new_word.connect(_on_new_word)
	chat.message_end.connect(_on_message_finished)


func _on_new_word(word:String):
	conv_node.add_to_last_bubble(word)
	%PromptField.set_status("Writing")


func _on_message_finished(full_message:String):
	if chat is ToolChatRequester:
		conv_node.add_to_last_bubble(full_message)
	%PromptField.set_generating(false)


func _on_prompt_submitted(user_prompt:String) -> void:
	_send_message(user_prompt, ChatRequester.chat_role.USER)


func _send_message(prompt:String, role:ChatRequester.chat_role = ChatRequester.chat_role.USER):
	if !chat:
		push_error("Gopilot Interface: No ChatRequester found! Please report!")
		return
	conv_node.create_user_bubble(prompt)
	conv_node.create_assistant_bubble()
	chat.set_system_prompt(chat.system_prompt)
	chat.send_message(prompt)
	chat.start_response()


func _on_prompt_field_stop_pressed() -> void:
	chat.stop_generation()
