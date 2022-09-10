tool
extends VBoxContainer

var translated_strings : Dictionary
var object_being_edited setget _object_being_edited_set
var variable_path
var language = "en"

func init() -> void:
	$KeyInput/KeyInput.text = object_being_edited.get(variable_path)
	_on_KeyInput_text_changed($KeyInput/KeyInput.text)
	_init_language_dropdown()


func set_title_label_text(new_text : String) -> void:
	$KeyInput/TitleLabel.text = new_text


func _on_KeyInput_text_changed(new_text: String) -> void:
	$TextContainer/HBoxContainer/TranslatedText.text = translate_text(new_text)
	
	if new_text.length() > 0 and new_text.begins_with(" "):
		while new_text.begins_with(" "):
			new_text.erase(0, 1)
		
		$KeyInput/KeyInput.text = new_text
	
	$KeyInput/SaveButton.disabled = new_text == ""
	
	object_being_edited.set(variable_path, new_text)


func _object_being_edited_set(var value):
	if value == null:
		printerr("Object being set was null?")
	object_being_edited = value


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
	
	$PopupContainer/FileDialog.popup()
	$PopupContainer/FileDialog.rect_position = get_global_mouse_position() - Vector2($PopupContainer/FileDialog.rect_size.x, 0)


func _on_ShowTextPopoutButton_pressed() -> void:
	$PopupContainer/TextEditPopup.popup()
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


func translate_text(var text : String) -> String:
	text = text.to_upper()
	
	if not translated_strings.size() == 0 and translated_strings.has(text):
		return translated_strings[text][0]
	
	if not load_translated_strings():
		return "No text available"
	
	if translated_strings.has(text):
		return translated_strings[text][0]
	
	return "No text available"


func load_translated_strings(var base_folder : String = "") -> bool:
	if base_folder == "":
		base_folder = ProjectSettings.get_setting("translation_plugin/translations_location")
	
	var dir = Directory.new()
	var err = dir.open(base_folder)
	if not err == OK:
		printerr("Error loading translations!")
		return false
	
	dir.list_dir_begin(true)
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


func load_csv(var path : String, var file_name : String):
	var file_path = path + "\\" + file_name
	var file = File.new()
	var err = file.open(file_path, 1)
	if not err == OK:
		printerr("Error loading CSV! + " + String(err))
		return
	
	var line = file.get_line()
	var headers = line.split(",")
	var language_index = _get_language_index(headers)
	if language_index == -1: # Something went wrong or the file is invalid
		file.close()
		return
	
	line = file.get_csv_line()
	
	while line != null and line.size() > language_index:
		translated_strings[line[0]] = [line[language_index], file_path]
		
		line = file.get_csv_line()
	
	file.close()


func _get_language_index(var header_line : PoolStringArray) -> int:
	for i in range(header_line.size()):
		if header_line[i] == language:
			return i
	return -1


func get_key_and_line(var line : String, var language_index : int, text_delimiter : String = "\"") -> Array:
	var split_string = line.split(",")
	var key = split_string[0]
	if key == "":
		return []
	
	var translated_text = split_string[language_index]
	
	if line.count(text_delimiter) > 0:
		translated_text = line.split(text_delimiter)[language_index]
	
	return [key, translated_text]


func create_csv_if_needed(var path : String):
	var file : File = File.new()
	
	if file.file_exists(path):
		return
	
	file.open(path, 2)
	var text = ","
	var languages_loaded = []
	for language in TranslationServer.get_loaded_locales():
		if languages_loaded.has(language):
			continue
		
		languages_loaded.append(language)
		text += language + ","
	
	# Erase the last comma
	text.erase(text.length() - 1, 1)
	
	file.store_line(text)
	file.close()


func append_to_csv(var path, var key, var value):
	var file : File = File.new()
	var err = file.open(path, 3)
	if err != OK:
		printerr("ERROR OPENING FILE: " + String(err))
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
	
	file.close()
	
	file.open(path, 2)
	file.store_string(result_string)
	file.close()


func combine_string_array(var array : PoolStringArray, var delimiter = ","):
	var result = ""
	for string in array:
		result += string + delimiter
	result = result.trim_suffix(",")
	return result


func _generate_default_line(var key, var value, var language_index, var header) -> String:
	var result = ""
	
	result = key +","
	
	for i in range(1, header.size(), 1):
		if i == language_index:
			result += value + ","
		else:
			result += "?,"
	
	#result += value
	
	result += "\n"
	
	return result


func generate_line_to_save(var original_line : String, var new_value : String, var language_index : int):
	var data = get_key_and_line(original_line, language_index)
	original_line.erase(0, get_line_length_to_delete(original_line, language_index))
	
	return data[0] + "," + "\"" + new_value +"\"" + original_line + "\n"


func get_default_path(var key) -> String:
	if not translated_strings.has(key):
		return "res://translations/text.csv"
	return translated_strings[key][1]


func get_path_elements(var path : String) -> Array:
	path = "res://" + path
	var file = path.split("\\")[-1]
	var directory = path
	directory.erase(directory.length() - (file.length() + 1), file.length() + 1)
	
	return [directory, file, path] # directory, file, path


func get_line_length_to_delete(var line : String, var language_index : int):
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
	var locales = TranslationServer.get_loaded_locales()
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
