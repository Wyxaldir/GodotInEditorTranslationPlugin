@tool
extends VBoxContainer

var translated_strings : Dictionary
var object_being_edited :
	get:
		return object_being_edited
	set(value):
		if value == null:
			printerr("Object being set was null?")
		object_being_edited = value


var variable_path
var language = "en"


func init() -> void:
	var path_value = object_being_edited.get(variable_path)
	if path_value == null: $KeyInput/KeyInput.text = ""
	else: $KeyInput/KeyInput.text = path_value
	
	_on_KeyInput_text_changed($KeyInput/KeyInput.text)
	_init_language_dropdown()


func set_title_label_text(new_text : String) -> void:
	$KeyInput/TitleLabel.text = new_text


func _on_KeyInput_text_changed(new_text: String) -> void:
	$TextContainer/HBoxContainer/TranslatedText.text = translate_text(new_text)
	
	if new_text.length() > 0 and new_text.begins_with(" "):
		while new_text.begins_with(" "):
			new_text.trim_prefix(" ")
		
		$KeyInput/KeyInput.text = new_text
	
	%SaveButton.disabled = new_text == ""
	
	object_being_edited.set(variable_path, new_text)


func _on_PickerButton_pressed() -> void:
	if translated_strings.size() == 0:
		load_translated_strings()
	
	#$PopupContainer/TranslationKeyBrowserPopup.base_position = $KeyInput/TitleLabel.get_global_rect().position
	#$PopupContainer/TranslationKeyBrowserPopup.show_keys()

	$KeyInput/TitleLabel/TranslationKeyBrowserPopup.base_position = $KeyInput/TitleLabel.get_global_rect().position
	$KeyInput/TitleLabel/TranslationKeyBrowserPopup.show_keys()

func _on_PopupPanel_key_selected(key) -> void:
	$KeyInput/KeyInput.text = key
	_on_KeyInput_text_changed(key)


func _on_SaveButton_pressed() -> void:
	var key = $KeyInput/KeyInput.text
	if key == "" or key.count(" ") == key.length():
		return
	var default_path = get_default_path($KeyInput/KeyInput.text)
	var path_elements = get_path_elements(default_path)
	$PopupContainer/FileDialog.current_dir = path_elements[0]
	$PopupContainer/FileDialog.current_file = path_elements[1]
	$PopupContainer/FileDialog.current_path = path_elements[2]

	$PopupContainer/FileDialog.popup_centered(Vector2(350, 600))
	#$PopupContainer/FileDialog.position = get_global_mouse_position() - Vector2($PopupContainer/FileDialog.size.x, 0)


func _on_ShowTextPopoutButton_pressed() -> void:
	$PopupContainer/TextEditPopup.popup_centered(Vector2(600, 700))
	$PopupContainer/TextEditPopup/VBoxContainer/PopoutTextEdit.grab_focus()
	$PopupContainer/TextEditPopup/VBoxContainer/PopoutTextEdit.text = $TextContainer/HBoxContainer/TranslatedText.text

func _on_PopoutTextEdit_text_changed() -> void:
	$TextContainer/HBoxContainer/TranslatedText.text = $PopupContainer/TextEditPopup/VBoxContainer/PopoutTextEdit.text


func _on_FileDialog_file_selected(path: String) -> void:
	create_csv_if_needed(path)
	
	var key_text = $KeyInput/KeyInput.text
	var translated_text = $TextContainer/HBoxContainer/TranslatedText.text
	
	append_to_csv(path, key_text, translated_text)
	load_translated_strings()


func translate_text(text : String) -> String:
	text = text.to_upper()
	
	if not translated_strings.size() == 0 and translated_strings.has(text):
		return translated_strings[text][0]
	
	if not load_translated_strings():
		return ""
	
	if translated_strings.has(text):
		return translated_strings[text][0]
	
	return ""


func load_translated_strings(base_folder : String = "") -> bool:
	if base_folder == "":
		base_folder = ProjectSettings.get_setting("translation_plugin/translations_location")
	
	var dir = DirAccess.open(base_folder)
	if dir == null:
		printerr("Error loading translations!")
		return false
	
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			load_translated_strings(base_folder + "\\" + file_name)
			file_name = dir.get_next()
			continue
		if file_name.ends_with(".csv"):
			load_csv(base_folder, file_name)
		file_name = dir.get_next()
	
	return true


func load_csv(path : String, file_name : String):
	var file_path = path + "\\" + file_name
	var file = FileAccess.open(file_path, 1)
	if file == null:
		printerr("Error loading CSV at path " + file_path + "!")
		return
	
	var line = file.get_line()
	var headers = line.split(",")
	var language_index = _get_language_index(headers)
	if language_index == -1: # Something went wrong or the file is invalid
		return
	
	line = file.get_csv_line()
	
	while line != null and line.size() > language_index:
		translated_strings[line[0]] = [line[language_index], file_path]
		
		line = file.get_csv_line()


func _get_language_index(header_line : PackedStringArray) -> int:
	for i in range(header_line.size()):
		if header_line[i] == language:
			return i
	return -1


func get_key_and_line(line : String, language_index : int, text_delimiter : String = "\"") -> Array:
	var split_string = line.split(",")
	var key = split_string[0]
	if key == "":
		return []
	
	var translated_text = split_string[language_index]
	
	if line.count(text_delimiter) > 0:
		translated_text = line.split(text_delimiter)[language_index]
	
	return [key, translated_text]


func create_csv_if_needed(path : String):
	if FileAccess.file_exists(path):
		return
	
	var file = FileAccess.open(path, 2)
	var text := ","
	var languages_loaded = []
	var languages = _get_languages_or_defaults()
	for language in languages:
		if languages_loaded.has(language):
			continue
		
		languages_loaded.append(language)
		text += language + ","
	
	# Erase the last comma
	text = text.left(-1)
	
	
	file.store_line(text)


func append_to_csv(path, key, value):
	var file = FileAccess.open(path, 3)
	if file == null:
		printerr("ERROR OPENING FILE: " + String(path))
		return
	
	var result_string : String = ""
	var found = false
	
	var line = file.get_line()
	var headers = line.split(",")
	var language_index = _get_language_index(headers)
	
	result_string += line + "\n"
	
	line = file.get_csv_line()
	
	while line != null and line.size() > language_index:
		var key_in_line = line[0]
		if key_in_line == key:
			found = true
			line[language_index] = "\"" + value + "\""
			#result_string += key_in_line + ",\"" + value + "\"" + "\n"
			#result_string += generate_line_to_save(line, value, language_index)
			result_string += combine_string_array(line) + "\n"
			line = file.get_csv_line(",")
			continue
		result_string += combine_string_array(line) + "\n"
		line = file.get_csv_line()
	
	if not found:
		# If we get to the end, append the line.
		result_string += _generate_default_line(key, value, language_index, headers)
	
	file = file.open(path, 2)
	file.store_string(result_string)


func combine_string_array(array : PackedStringArray, delimiter = ","):
	var result = ""
	for string in array:
		result += string + delimiter
	result = result.trim_suffix(",")
	return result


func _generate_default_line(key, value, language_index, header) -> String:
	var result := ""
	
	result = key +","
	
	for i in range(1, header.size(), 1):
		if i == language_index:
			result += value + ","
		else:
			result += "?,"
	
	result = result.trim_suffix(",") # remove_at the trailing comma
	
	result += "\n"
	
	return result


#func generate_line_to_save(original_line : String, new_value : String, language_index : int):
#	var data = get_key_and_line(original_line, language_index)
#	original_line.erase(0, get_line_length_to_delete(original_line, language_index))
#
#	return data[0] + "," + "\"" + new_value +"\"" + original_line + "\n"


func get_default_path(key) -> String:
	if not translated_strings.has(key):
		return "res://translations/text.csv"
	return translated_strings[key][1]


func get_path_elements(path : String) -> Array:
	path = "res://" + path
	var file = path.split("\\")[-1]
	var directory = path.substr(0, path.length() - (file.length() + 1))
	
	#directory.erase(directory.length() - (file.length() + 1), file.length() + 1)
	
	return [directory, file, path] # directory, file, path


func get_line_length_to_delete(line : String, language_index : int):
	var data = get_key_and_line(line, language_index)
	var extra_chars_to_remove_length = 1 # there is always a comma
	var split_string = line.split(",")
	
	if(split_string[1][0] == "\""):
		extra_chars_to_remove_length += 2 # For the two quotation marks
	
	return data[0].length() + data[1].length() + extra_chars_to_remove_length


func _on_TranslationKeyBrowserPopup_key_selected(key) -> void:
	$KeyInput/KeyInput.text = key
	_on_KeyInput_text_changed(key)


func _init_language_dropdown():
	var locales = _get_languages_or_defaults()
	var unique_locales = []
	
	for locale in locales:
		if not unique_locales.has(locale):
			unique_locales.append(locale)
	
	unique_locales.sort()
	
	$KeyInput/LanguageSelectButton.clear()
	for locale in unique_locales:
		$KeyInput/LanguageSelectButton.add_item(locale)


func _on_LanguageSelectButton_item_selected(index: int) -> void:
	language = $KeyInput/LanguageSelectButton.get_item_text(index)
	load_translated_strings()
	_on_KeyInput_text_changed($KeyInput/KeyInput.text)


func _get_languages_or_defaults() -> PackedStringArray:
	var result = TranslationServer.get_loaded_locales()
	if result == null or result.size() == 0:
		return ProjectSettings.get_setting("translation_plugin/default_locales")
	return result
