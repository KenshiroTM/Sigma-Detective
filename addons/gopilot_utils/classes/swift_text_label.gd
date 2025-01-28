@tool
extends RichTextLabel

@export var smoothing:bool = true

@export var fill_duration:float = 1.0

@onready var last_character_amount:int = text.length()

var length_tweener:Tween


func _set(property: StringName, value: Variant) -> bool:
	if property == "text":
		if !smoothing or value.length() <= text.length():
			if length_tweener and length_tweener.is_running():
				length_tweener.kill()
			visible_characters = value.length()
			return false
		text = value
		if length_tweener and length_tweener.is_running():
			length_tweener.kill()
		length_tweener = create_tween()
		length_tweener.tween_property(self, "visible_characters", value.length(), fill_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return false
