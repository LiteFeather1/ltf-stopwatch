class_name PopupMenuItemCheck extends PopupMenuItem


@export var _is_checked: bool


func add_to_popup_menu(menu: PopupMenu, id: int) -> void:
	menu.add_check_item(_label, id)
	if _is_checked:
		menu.set_item_checked(id, true)
