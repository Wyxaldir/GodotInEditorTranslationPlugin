extends OptionButton

signal language_selected(language_key)

func _on_LanguageSelector_item_selected(index: int) -> void:
	match index:
		0:
			emit_signal("language_selected", "en")
		1:
			emit_signal("language_selected", "fr")
