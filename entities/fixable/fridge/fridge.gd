extends Fixable

signal tony_angered(level)


func anger_tony(level: int):
	emit_signal("tony_angered", level)


func _on_Fridge_finished_fixing():
	_fix_animator.play("postfix")
