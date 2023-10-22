extends Control

signal selected_item_changed(new_item : Item)

@export var num_of_slots := 10
@export var hot_keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, ]

@onready var slots := []

var selected_slot := 0

func _ready():
	for i in num_of_slots:
		var new_slot := preload("res://character/gui/hot_slot.tscn").instantiate()
		slots.append(new_slot)
		$Slots.add_child(new_slot)
	var items = Items.items
	items.resize(num_of_slots)
	set_items(items)
	select(0)
		
func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode in hot_keys and event.pressed:
			select(hot_keys.find(event.keycode))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			select(selected_slot - 1 if selected_slot > 0 else num_of_slots - 1) 
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			select((selected_slot + 1) % num_of_slots)
			
func select(index : int):
	$Slots.get_child(selected_slot).selected = false
	selected_slot = index
	$Slots.get_child(selected_slot).selected = true
	selected_item_changed.emit(get_item())

func get_item() -> Item:
	return $Slots.get_child(selected_slot).item

func set_item(slot : int, item : Item):
	$Slots.get_child(slot).item = item
	if slot == selected_slot:
		selected_item_changed.emit(get_item())

func set_items(items : Array):
	assert(items.size() == num_of_slots, '物品数和快捷栏槽位数量不符')
	for i in min(items.size(), num_of_slots):
		set_item(i, items[i])
