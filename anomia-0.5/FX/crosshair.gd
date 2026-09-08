@tool
extends Control


func _draw() -> void:
	draw_circle(Vector2.ZERO,2,Color.HOT_PINK)
	draw_circle(Vector2.ZERO,3,Color.WHITE_SMOKE)
	draw_circle(Vector2.ZERO,30,Color.HOT_PINK,false, 3)
