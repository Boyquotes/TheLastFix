extends Fixable


func _ready():
	$GPUParticles2D.emitting = true
	$AnimationPlayer.play("stream")
