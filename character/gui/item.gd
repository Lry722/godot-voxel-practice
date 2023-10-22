extends RefCounted
class_name Item

enum Type{BLOCK, LIQUID, ITEM}

var name : String
var type : Type
var id : int
var count : int
var display : Texture2D
