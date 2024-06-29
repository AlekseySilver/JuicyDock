extends CPUParticles3D


func _ready():
	emitting = true
	await finished
	queue_free()


