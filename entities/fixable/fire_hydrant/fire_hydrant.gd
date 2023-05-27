extends Fixable


func _ready():
	$Particles.emitting = true
	$AnimationPlayer.play("stream")
