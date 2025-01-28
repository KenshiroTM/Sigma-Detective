extends Resource
##Can be used to create an example interaction which the model can use to create more predictable outcomes.
class_name ToolCallExample

##The instruction from the user
@export_multiline var instruction:String = ""
##The ideal response from the assistant.
@export_multiline var response:String = ""
