extends Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
  self.z_index = 0
  self.z_as_relative = false

  $Beam.z_index = 3
  $Beam.z_as_relative = false
