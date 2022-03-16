tool
extends PopupPanel

signal key_selected(key)

var current_button_parent

func show_translated_text(var translated_text : Dictionary):
	var button_container = $HBoxContainer/ButtonContainer
	
	if button_container.get_child_count() > 0:
		for child in button_container.get_children():
			child.queue_free()
	
	var keys = translated_text.keys()
	var current_header := ""
	
	for key in keys:
		if(translated_text[key][1] != current_header):
			add_header(translated_text[key][1])
			current_header = translated_text[key][1]
		
		add_button(key, translated_text[key][0])
	
	popup()
	rect_position = get_global_mouse_position() - Vector2(rect_size.x, 0)
	rect_size.y = 0


func add_button(var key : String, var value : String):
	var new_button = Button.new()
	current_button_parent.add_child(new_button)
	#$HBoxContainer/ButtonContainer.add_child(new_button)
	
	new_button.text = key
	
	new_button.connect("mouse_entered", 
		self, 
		"_on_button_hovered", 
		[value])
		
	new_button.connect("pressed", self, "_on_button_pressed", [key])


func add_header(var header_name):
	var button = Button.new()
	var header = load("res://addons/localization_editor_viewer/ui/popup_panel_header.tscn").instance()
	
	button.text = header_name.split("\\")[-1]
	
	$HBoxContainer/ButtonContainer.add_child(button)
	button.connect("pressed", self, "_on_header_pressed", [header])
	
	$HBoxContainer/ButtonContainer.add_child(header)
	
	current_button_parent = header.get_node("ButtonParent")


func _on_header_pressed(var header):
	header.visible = !header.visible
	self.visible = false
	self.visible = true


func _on_button_hovered(var text : String):
	$HBoxContainer/TranslatedText.text = text


func _on_button_pressed(var key : String):
	emit_signal("key_selected", key)
	hide()
