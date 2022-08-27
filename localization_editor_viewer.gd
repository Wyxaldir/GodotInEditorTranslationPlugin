extends EditorInspectorPlugin

var ui = preload("res://addons/localization_editor_viewer/ui/localization_editor_viewer.tscn")
var ui_instance = null

func can_handle(object: Object) -> bool:
	return true


func parse_property(object, type, path, hint, hint_text, usage) -> bool:
	if not type == TYPE_STRING:
		return false

	for variable_name in ProjectSettings.get_setting("translation_plugin/valid_variable_names"):
		if variable_name.to_lower() == path.to_lower():
			setup_ui(object, path)
			return true
	return false


func setup_ui(var object, var path):
	ui_instance = ui.instance()
	add_custom_control(ui_instance)
	ui_instance.set_title_label_text(path.capitalize())
	ui_instance.object_being_edited = object
	ui_instance.variable_path = path
	ui_instance.init()


func transfer_translated_strings():
	if ui_instance == null:
		ui_instance = ui.instance()
		return 
	
	var data = ui_instance.translated_strings
	ui_instance = ui.instance()
	ui_instance.translated_strings = data



