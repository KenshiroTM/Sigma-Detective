@tool
extends EditorInspectorPlugin

const CHAT_TESTER := preload("res://addons/gopilot_utils/scenes/chat_test.tscn")

var plugin:EditorPlugin


var last_requester:ChatRequester
var chat_tester
var added_panel:bool = false

#func _can_handle(object: Object) -> bool:
	#if added_panel:
		##plugin.remove_control_from_bottom_panel(chat_tester)
		#plugin.remove_control_from_docks(chat_tester)
		#chat_tester.queue_free()
		#chat_tester = null
		#added_panel = false
	#if last_requester:
		#last_requester.clear_conversation()
		#last_requester = null
	#if object is ChatRequester:
		#return true
	#return false
#
#
#func _parse_begin(object: Object) -> void:
	#last_requester = object
	#chat_tester = CHAT_TESTER.instantiate()
	#chat_tester.set_chat_requester(object)
	#added_panel = true
	#chat_tester.name = "ChatRequester"
	#plugin.add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, chat_tester)
	##plugin.add_control_to_bottom_panel(chat_tester, "ChatRequester")


func set_plugin(_plugin:EditorPlugin):
	plugin = _plugin
