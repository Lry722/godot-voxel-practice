extends Control
class_name HotSlot

const defulat_size := 40

var item : Item :
	set(_item):
		item = _item
		$Icon.texture = item.display if item else null
	get:
		return item

var selected := false:
	set(selected_):
		if selected == selected_:
			return
		selected = selected_
		if selected:
			$SelectBox.show()
		else:
			$SelectBox.hide()
	get:
		return selected

func _ready():
	custom_minimum_size = Vector2(defulat_size, defulat_size)
