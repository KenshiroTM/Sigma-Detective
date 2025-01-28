@tool
extends Resource
class_name ToolArgument


func _to_string() -> String:
	var result = name
	if type == ArgType.VARIANT:
		return result
	return name + ":" + type_string[type]

enum ArgType {STRING, INT, FLOAT, BOOL, ENUM, ARRAY, VARIANT}
const type_string:Dictionary = {
	0:"string",
	1:"int",
	2:"float",
	3:"bool",
	4:"string",
	5:"array",
	6:"variant"
}

##Name of the parameter
@export var name:String = ""
##Type of the parameter 
@export var type:ArgType = ArgType.STRING:
	set(new):
		type = new
		notify_property_list_changed()
##Options for the enum
@export var enum_options:PackedStringArray = []
##Description of what the parameter changes
@export_multiline var descrption:String = ""
##Add an example of the parameter to further align the model. Always use this when using the Variant type.
@export var example:String = ""
##Tells the model if this property is mandatory for the function to work
@export var required:bool = true
