class_name PopupMenuItem extends Resource


@export var _icon: Texture2D
@export var _label: String = "label"


func add_to_popup_menu(menu: PopupMenu, id: int) -> void:
	menu.add_icon_item(_icon, _label, id)
