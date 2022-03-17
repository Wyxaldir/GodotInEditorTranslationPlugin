tool
extends EditorPlugin

var plugin

func _enter_tree() -> void:
	init_project_settings()
	
	plugin = preload("res://addons/localization_editor_viewer/localization_editor_viewer.gd").new()
	add_inspector_plugin(plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(plugin)


func init_project_settings():
	var projectSettingsBasePath = "translation_plugin/"
	
	if not ProjectSettings.has_setting(projectSettingsBasePath + "translations_location"):
		ProjectSettings.set_setting(projectSettingsBasePath + "translations_location", "res://translations/")
	if not ProjectSettings.has_setting(projectSettingsBasePath + "valid_variable_names"):
		var newArray : PoolStringArray = ["text"]
		ProjectSettings.set_setting(projectSettingsBasePath + "valid_variable_names", newArray)
