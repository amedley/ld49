extends Node2D

var train_scene = preload("res://source/train/Train.tscn")
var level_hud_scene = preload("res://source/ui/LevelHud.tscn")

onready var game_system = get_node("/root/GameSystem")

var trains: Array = []
var drop_offs: Array = []
var drop_off_exits: Array = []
var character_next_drop_off_index: int = 0
var trains_next_drop_off_index: Array = []
var world_hud: CanvasLayer = null
var level_hud: Control = null

func _ready():
  for child in self.get_children():
    if child.name.find("TrainSpawner") > -1:
      var spawner = child
      var train = train_scene.instance()
      train.name = "TrainNode"
      train.train_links = game_system.interpret_saplings()
      self.add_child_below_node(spawner, train)
      var torch = train.saplings[0].get_node_or_null("Torch")
      if torch:
        torch.size = game_system.interpret_torch()
      train.position = spawner.position
      self.trains.append(train)
      self.trains_next_drop_off_index.append(0)

  var level_hud_layer = CanvasLayer.new()
  level_hud_layer.layer = 10
  self.level_hud = level_hud_scene.instance()
  level_hud_layer.add_child(level_hud)
  self.add_child(level_hud_layer)

  world_hud = CanvasLayer.new()
  world_hud.layer = 9
  world_hud.follow_viewport_enable = true
  self.add_child(world_hud)

  game_system.connect("on_state_change", self, "on_state_change")

  for child in self.get_children():
    if child.name.find("DropOffPoint") > -1:
      child.drop_off_index = len(self.drop_offs)
      self.drop_offs.append(child)
      self.drop_off_exits.append(child.position.x + 250)

  if game_system.is_start:
    self.level_hud.render_on_screen_message("The Waste from the Sky, it poisons our woods...", Color.greenyellow)
    self.level_hud.render_on_screen_message("...guide my Saplings and dispose of it, they will bear the load...", Color.greenyellow)
    self.level_hud.render_on_screen_message("...press on until you reach the Source... Good luck.", Color.greenyellow)
  elif game_system.is_reset:
    self.level_hud.render_on_screen_message("Starting over isn't so bad...", Color.greenyellow)
    self.level_hud.render_on_screen_message("...my saplings will only get stronger...", Color.greenyellow)
    self.level_hud.render_on_screen_message("...please, guide them to the Source of this poisonous Waste.", Color.greenyellow)

func get_next_drop_off_index(position):
  var result = 0
  for exit in drop_off_exits:
    if position.x > exit:
      result += 1
    else:
      break
  return result

func _physics_process(dt):
  character_next_drop_off_index = get_next_drop_off_index($CharacterBody.position)
  var character_in_upgrade_area_index = $CharacterBody.in_upgrade_area
  var character_just_entered_upgrade_area = $CharacterBody.just_entered_upgrade_area
  var rendered_abandon = false
  var push_character_left = false
  for i in range(0, len(trains)):
    var train = trains[i]
    var saplings = train.saplings
    var drop_off_index = max(trains_next_drop_off_index[i], get_next_drop_off_index(saplings[0].global_position))
    saplings[len(saplings) - 1].stop_moving = drop_off_index > character_next_drop_off_index
    if character_in_upgrade_area_index > saplings[0].last_upgrade_area:
      push_character_left = true
      if character_just_entered_upgrade_area && !rendered_abandon:
        level_hud.render_on_screen_message_once("Please stay near my saplings...", Color.yellow)
        rendered_abandon = true

  $CharacterBody.just_entered_upgrade_area = false
  if push_character_left:
    $CharacterBody.move_and_slide(Vector2(-abs($CharacterBody.final_velocity.x), 0), Vector2.UP)

  if character_in_upgrade_area_index > -1 && !push_character_left:
    level_hud.show_upgrade_ui()
    for i in range(0, len(trains)):
      var train = trains[i]
      train.character_has_upgrade_window = true
  else:
    level_hud.hide_upgrade_ui()
    for i in range(0, len(trains)):
      var train = trains[i]
      train.character_has_upgrade_window = false

func on_state_change(id, old_state, new_state):
  if id == game_system.saplings_id:
    var spawn_amount = game_system.interpret_saplings(new_state) - game_system.interpret_saplings(old_state)
    for train in trains:
      for i in range(0, spawn_amount):
        var previous = train.saplings[len(train.saplings) - 1]
        train.add_sapling()
        var next = train.saplings[len(train.saplings) - 1]
        if previous.stop_moving:
          previous.stop_moving = false
          next.stop_moving = true
  elif id == game_system.torch_id:
    var new_size = game_system.interpret_torch(new_state)
    for train in trains:
      if train.saplings[0].get_node_or_null("Torch") == null:
        train.saplings[0].add_child(train.saplings[0].torch)
      train.saplings[0].torch.size = new_size

