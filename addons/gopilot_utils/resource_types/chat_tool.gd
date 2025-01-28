@tool
extends Resource
class_name ChatTool


## Name of the function the model can call
@export var function_name:String = "function_name"
## Arguments the model must pass to the function.
@export var arguments:Array[ToolArgument]:
	set(new):
		arguments = new
		notify_property_list_changed()
## Description of what the function does and what its possible arguments are. Always add a description!
@export var description:String = "An example function"
## It false, model will not call this function
@export var active:bool = true
## When this tool calls another ToolChatRequester, activate this. It provide all the available tools to the model
@export var is_tool_caller:bool = false
