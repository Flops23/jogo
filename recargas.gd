extends Control

const Player := preload("res://personagem.gd")
const BASIC_COLOR := Color(0.2, 0.85, 1.0)
const BURST_COLOR := Color(0.85, 0.35, 1.0)

@onready var player: Player = $"../../Personagem"

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var center := size / 2.0
	_draw_indicator(center - Vector2(23, 0), BASIC_COLOR,
		_ready_fraction(player.basic_ready_at, Player.BASIC_COOLDOWN, now))
	_draw_indicator(center + Vector2(23, 0), BURST_COLOR,
		_ready_fraction(player.burst_ready_at, Player.BURST_COOLDOWN, now))

func _ready_fraction(ready_at: float, cooldown: float, now: float) -> float:
	return clampf(1.0 - (ready_at - now) / cooldown, 0.0, 1.0)

func _draw_indicator(center: Vector2, color: Color, progress: float) -> void:
	draw_circle(center, 17.0, Color(0.05, 0.06, 0.09, 0.92), true, -1.0, true)
	draw_circle(center, 12.0, color.darkened(0.78).lerp(color, progress), true, -1.0, true)
	draw_arc(center, 15.0, 0.0, TAU, 48, color.darkened(0.68), 2.0, true)
	if progress > 0.0:
		draw_arc(center, 15.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, color, 2.0, true)
