extends MarginContainer

var text_particle_scene = preload("res://source/misc/TextParticle.tscn")

onready var game_system = get_node("/root/GameSystem")
onready var state_nodes = get_node("MarginContainer2/MarginContainer/HBoxContainer/State").get_children()
onready var on_screen_message = get_node("CenterContainer/VBoxContainer/OnScreenMessage")

var on_screen_message_timer: float = 0
var on_screen_message_queue: Array = []

func _ready():
  game_system.connect("on_state_change", self, "on_state_change")
  for id in range(0, len(state_nodes)):
    sync_state(id)

func on_state_change(id, old_state, new_state):
  sync_state(id)
  if id == game_system.currency_id:
      var currency_change = game_system.interpret_currency(new_state) - game_system.interpret_currency(old_state)
      var text_particle = text_particle_scene.instance()
      text_particle.modulate = Color(0.25, 0.9, 0.25) if currency_change > 0 else Color(0.9, 0.25, 0.25)
      text_particle.font_size = 20
      text_particle.text = ("+$" if currency_change > 0 else "-$") + str(abs(currency_change))
      
      $UnmanagedContainer.add_child(text_particle)
      text_particle.rect_global_position = $MarginContainer2/MarginContainer/HBoxContainer/Names/CurrencyChangeLocation.global_position - (text_particle.rect_size * text_particle.rect_scale) * 0.5
      text_particle.velocity = Vector2(-3, 0)
      text_particle.time = 1.5

func sync_state(id):
  state_nodes[id].text = str(game_system.state[id])

func render_on_screen_message(message, color):
  if self.on_screen_message.modulate.a >= 0.0:
    self.on_screen_message_queue.append([message, color])
  else:
    self.on_screen_message_timer = 5.0
    on_screen_message.modulate = Color(color.r, color.g, color.b, 1.0)
    on_screen_message.text = message
    
func render_on_screen_message_once(message, color):
  if self.on_screen_message.modulate.a >= 0.0:
    if self.on_screen_message.text == message:
      return
  
  for next in on_screen_message_queue:
    if next[0] == message:
      return
  
  render_on_screen_message(message, color)

func _process(dt):
  self.on_screen_message_timer -= dt
  if self.on_screen_message_timer < 0:
    if on_screen_message.modulate.a > 0:
      on_screen_message.modulate.a -= 0.05
    elif len(self.on_screen_message_queue) > 0:
      var next = self.on_screen_message_queue[0]
      self.on_screen_message_queue.remove(0)
      self.render_on_screen_message(next[0], next[1])

func show_upgrade_ui():
  if !$UpgradeUICenterContainer.visible:
    $UpgradeUICenterContainer.visible = true
    
func hide_upgrade_ui():
  if $UpgradeUICenterContainer.visible:
    $UpgradeUICenterContainer.visible = false
