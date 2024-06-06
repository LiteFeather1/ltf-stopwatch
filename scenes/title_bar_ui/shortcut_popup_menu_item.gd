class_name ShortcutPopupMenuItem extends PopupMenuItem


@export var _shortcut: Shortcut


func add_to_popup_menu(menu: PopupMenu, id: int) -> void:
	menu.add_icon_shortcut(_icon, _shortcut, id)
	menu.set_item_text(id, _label)


func set_shortcut(shortcut: Shortcut) -> void:
	_shortcut = shortcut
