class_name PopupMenuItem extends PopupMenuItemSeparator


@export var _icon: Texture2D


func add_to_popup_menu(menu: PopupMenu, id: int) -> void:
	menu.add_icon_item(_icon, _label, id)
