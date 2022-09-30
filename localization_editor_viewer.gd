extends EditorInspectorPlugin

var ui = preload("res://addons/localization_editor_viewer/ui/localization_editor_viewer.tscn")
var ui_instance = null

func _can_handle(object: Variant) -> bool:
	if object.get_class() == "MultiNodeEdit":
		return false
	return true


func _parse_property(object, type, path, hint, hint_text, usage, _bool) -> bool:
	if not type == TYPE_STRING:
		return false
	
	for variable_name in ProjectSettings.get_setting("translation_plugin/valid_variable_names"):
		if variable_name.to_lower() == path.to_lower():
			setup_ui(object, path)
			return true
	return false


func setup_ui(object, path):
	ui_instance = ui.instantiate()
	add_custom_control(ui_instance)
	ui_instance.set_title_label_text(path.capitalize())
	ui_instance.object_being_edited = object
	ui_instance.variable_path = path
	ui_instance.init()
