extends Fixable

signal tony_angered(level)


func anger_tony(level: int):
	emit_signal("tony_angered", level)
