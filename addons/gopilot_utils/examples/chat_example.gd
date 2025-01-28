extends Control


func _on_button_pressed():
	$ChatRequester.send_message($User.text)
	$ChatRequester.start_response()


# This function is called when a new word is detected in the chat requester.
func _on_chat_requester_new_word(word: String):
	$AI.text += word


# This function is called when the stop button is pressed.
func _on_stop_pressed() -> void:
	$ChatRequester.stop_generation()
