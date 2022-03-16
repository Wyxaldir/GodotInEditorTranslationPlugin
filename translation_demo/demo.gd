extends Control

onready var main_label = get_node("ContentContainer/MainContainer/HBoxContainer/VBoxContainer/Label")


func _on_LanguageSelector_language_selected(language_key) -> void:
	TranslationServer.set_locale(language_key)


func _on_LivingRock_pressed() -> void:
	main_label.text = "KEY_LIVING_ROCK"


func _on_RustyKey_pressed() -> void:
	main_label.text = "KEY_RUSTY_KEY"


func _on_Ax_pressed() -> void:
	main_label.text = "KEY_AX"
