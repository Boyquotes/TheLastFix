extends Fixable


func _ready():
	$Particles2D.emitting = true
	$AnimationPlayer.play("stream")
