extends CharacterBody2D

#@onready var tile_map = get_node("/root/Island/IslandGenerator")
@onready var tile_map = get_node("/root/TestIsland/Test_Island")
@onready var party_member
@onready var ray = $RayCast2D
@onready var sprite = $Sprite2D

signal playerMoving(is_moving)

var turnSpeed = 6
var enemyList
var enemyPositions
var collisionMap

var tile_size = 32
var astar_movement: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var current_position:Vector2
var previous_position: Vector2
var is_moving: bool:
	get:
		return is_moving
	set(is_moving):
		emit_signal("playerMoving", is_moving, previous_position)
var player_in_combat = false
		
var speed = 4
var tileMovement = 6
var direction: Vector2

var turnLoop = false

var inputs = {"right": Vector2.RIGHT,
			"left": Vector2.LEFT,
			"up": Vector2.UP,
			"down": Vector2.DOWN}
			

func setInCombat(in_combat):
	player_in_combat = in_combat

func partySet():
	var party = get_tree().get_nodes_in_group("Party")
	for i in party:
		party_member = i

func updateEnemyPosition(updatedPosition):
	enemyPositions = updatedPosition
	print(enemyPositions)

		
#func combatStart(in_combat):
#	while is_moving == true:
#		continue
#	in_combat = in_combat

func turnStart():
	pass
	#print(enemyList, "player")
#	turnLoop = true
#	while turnLoop == true:
#		continue
	

func _ready():
	
	global_position = global_position.snapped(Vector2.ONE * tile_size)
	global_position += Vector2.ONE * tile_size/2
	previous_position = global_position
	current_position = global_position


func _input(event):
	var id_path
	
	if !global.in_combat:
		for dir in inputs.keys():
			if event.is_action_pressed(dir) && is_moving == false:
				ray.target_position = inputs[dir] * (tile_size/2)
				ray.force_raycast_update()
				if !ray.is_colliding():
					id_path = tile_map.local_to_map(global_position + (inputs[dir] * tile_size))
					current_id_path.append(id_path)
				else:
					print(ray.get_collider())
				
		if event.is_action_pressed("Interact"):
			ray.force_raycast_update()
			if ray.is_colliding():
				var interactCheck = ray.get_collider()
				print(interactCheck)
				if interactCheck.has_method("Interactable"):
					interactCheck.Interactable()
		
		if !event.is_action_pressed("LeftClick"):
			return
		
		if is_moving == true:
			#Get character position and mouse location
			id_path = astar_movement.get_id_path(tile_map.local_to_map(target_position),  
			tile_map.local_to_map(get_global_mouse_position()))
			print(tile_map.local_to_map(get_global_mouse_position()))
		else:
			id_path = astar_movement.get_id_path(tile_map.local_to_map(global_position),  
			tile_map.local_to_map(get_global_mouse_position())).slice(1)
			print(tile_map.local_to_map(get_global_mouse_position()))
		
		
		if !id_path.is_empty():
			current_id_path = id_path



#func move(dir):
#	ray.target_position = inputs[dir] * tile_size
#	ray.force_raycast_update()
#	if !ray.is_colliding():
#		position += inputs[dir] * tile_size
	

func _physics_process(delta):
	if current_id_path.is_empty():
		return
	
	if global.in_combat == true:
		global_position = global_position.move_toward(target_position, delta * tile_size * speed)
		if global_position == target_position:
			current_id_path.clear()
			is_moving = false
		return
	

		
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		previous_position = current_position
		collisionMap.updateCharacterCollisions(tile_map.local_to_map(previous_position), tile_map.local_to_map(target_position))
		is_moving = true
	
	
	
	
	direction = target_position - global_position
	if direction.x > 1:
		direction = Vector2.RIGHT
		sprite.flip_h = false
	elif direction.x < -1:
		direction = Vector2.LEFT
		sprite.flip_h = true
	elif direction.y > 1:
		direction = Vector2.DOWN
	elif direction.y < -1:
		direction = Vector2.UP
	
	ray.target_position = direction * (tile_size/2)
	ray.force_raycast_update()
	
	
	if ray.is_colliding():
		current_id_path.clear()
		is_moving = false
		return
	
	if !current_id_path.is_empty():
		global_position = global_position.move_toward(target_position, delta * tile_size * speed)
		if global_position == target_position:
			
			previous_position = current_position
			current_id_path.pop_front()
			current_position = global_position
			
			#astar_grid.set_point_solid(tile_map.local_to_map(current_position), true)
			#astar_grid.set_point_solid(tile_map.local_to_map(previous_position),false)
		
			if current_id_path.is_empty() == false:
				target_position = tile_map.map_to_local(current_id_path.front())
				collisionMap.updateCharacterCollisions(tile_map.local_to_map(previous_position), tile_map.local_to_map(target_position))
			else:
				is_moving = false
	
	
	


