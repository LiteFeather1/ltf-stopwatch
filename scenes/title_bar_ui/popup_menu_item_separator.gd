class_name PopupMenuItemSeparator extends Resource


@export var _label: String


func add_to_popup_menu(menu: PopupMenu, id: int) -> void:
	menu.add_separator(_label, id)
