tool
extends VBoxContainer

var translated_strings : Dictionary
var object_being_edited
var variable_path


func init():
	$KeyInput/KeyInput.text = object_being_edited.get(variable_path)
	_on_KeyInput_text_changed($KeyInput/KeyInput.text)


func set_title_label_text(new_text : String):
	$KeyInput/TitleLabel.text = new_text


func _on_KeyInput_text_changed(new_text: String) -> void:
	$TextContainer/TranslatedText.text = translate_text(new_text)
	
	if new_text.length() > 0 and new_text.begins_with(" "):
		while new_text.begins_with(" "):
			new_text.erase(0, 1)
		
		$KeyInput/KeyInput.text = new_text
	
	$KeyInput/SaveButton.disabled = new_text == ""
	
	object_being_edited.set(variable_path, new_text)


func _on_PickerButton_pressed() -> void:
	if translated_strings.size() == 0:
		load_translated_strings()
	
	$PopupContainer/PopupPanel.show_translated_text(translated_strings)


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


func _on_FileDialog_file_selected(path: String) -> void:
	create_csv_if_needed(path)
	append_to_csv(path, $KeyInput/KeyInput.text, $TextContainer/TranslatedText.text)
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
		base_folder = ProjectSettings.get_setting("viun_plugins/translation_plugin/translations_location")
	
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
	
	var line : String = file.get_line()
	while not line == "":
		var data = get_key_and_line(line)
		if(data.size() != 0):
			translated_strings[data[0]] = [data[1], file_path]
		
		line = file.get_line()
	
	file.close()


func get_key_and_line(var line : String, text_delimiter : String = "\"") -> Array:
	var split_string = line.split(",")
	var key = split_string[0]
	if key == "":
		return []
	
	var translated_text = split_string[1]
	
	if line.count(text_delimiter) > 0:
		translated_text = line.split(text_delimiter)[1]
	
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
	while line != "":
		var key_in_line = line.split(",")[0]
		if key_in_line == key:
			found = true
			#result_string += key_in_line + ",\"" + value + "\"" + "\n"
			result_string += generate_line_to_save(line, value)
			line = file.get_line()
			continue
		result_string += line + "\n"
		line = file.get_line()
	
	if not found:
		# If we get to the end, append the line.
		result_string += key + "," + "\"" + value + "\"" + "\n"
	
	file.close()
	
	file.open(path, 2)
	file.store_string(result_string)
	file.close()


func generate_line_to_save(var original_line : String, var new_value : String):
	var data = get_key_and_line(original_line)
	original_line.erase(0, get_line_length_to_delete(original_line))
	
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


func get_line_length_to_delete(var line : String):
	var data = get_key_and_line(line)
	var extra_chars_to_remove_length = 1 # there is always a comma
	var split_string = line.split(",")
	
	if(split_string[1][0] == "\""):
		extra_chars_to_remove_length += 2 # For the two quotation marks
	
	return data[0].length() + data[1].length() + extra_chars_to_remove_length








