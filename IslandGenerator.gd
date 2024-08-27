extends TileMap

@onready var tile_map = get_node("/root/Island/IslandGenerator")
@onready var embark_point = get_node("/root/Island/embark_point")
@onready var CollisionMap = get_node("/root/Island/CollisionMap")
@onready var turn_queue = get_node("/root/Island/TurnQueue")

var cellData = []
var islandSize
var astar_movement: AStarGrid2D
var astar_targetting: AStarGrid2D
var player = preload("res://player.tscn")
var party_member = preload("res://party_member.tscn")
var party_path: Array[Vector2i]
var deepCoords: Array[Vector2i]
var shallowCoords: Array[Vector2i]
var sandCoords: Array[Vector2i]
var grassCoords: Array[Vector2i]
var longgrassCoords: Array[Vector2i]
var rockCoords: Array[Vector2i]

var playerChar
var partyMember1



func _ready():
	cellData = global.currentIslandValues
	islandSize = global.currentIslandSize
	var count = 0
	for x in islandSize:
		for y in islandSize:
			var alt = cellData[count]
			
			if alt <= -0.4:
				set_cell(0, Vector2(x,y), 0, Vector2i(1,1))
				deepCoords.append(Vector2i(x,y))
			elif alt > -0.4 && alt <= -0.3:
				set_cell(0, Vector2(x,y), 0, Vector2i(1,4))
				shallowCoords.append(Vector2i(x,y))
			elif alt > -0.3 && alt <= -0.2:
				set_cell(0, Vector2(x,y), 0, Vector2i(4,1))
				sandCoords.append(Vector2i(x,y))
			elif alt > -0.2 && alt <= -0.1:
				set_cell(0, Vector2(x,y), 0, Vector2i(4,4))
				grassCoords.append(Vector2i(x,y))
			elif alt > -0.1 && alt <= 0.2:
				set_cell(0, Vector2(x,y), 0, Vector2i(7,1))
				longgrassCoords.append(Vector2i(x,y))
			else:
				set_cell(0, Vector2(x,y), 0, Vector2i(7,4))
				rockCoords.append(Vector2i(x,y))
			count += 1
		#Initialise Astar grid for pathfinding uses
	
	#set_cells_terrain_connect(0, deepCoords, 0, 0)
	#set_cells_terrain_connect(0, shallowCoords, 0, 1)
	#set_cells_terrain_connect(0, sandCoords, 0, 2)
	#set_cells_terrain_connect(0, grassCoords, 0, 3)
	#set_cells_terrain_connect(0, longgrassCoords, 0, 4)
	#set_cells_terrain_connect(0, rockCoords, 0, 5)
	
	
	
	
	CollisionMap.tile_map = tile_map
	CollisionMap.staticCollisions.append(tile_map.local_to_map(embark_point.position))
	CollisionMap.updateStaticCollisions()
	astar_targetting = CollisionMap.astar_targetting
	turn_queue.collisionMap = CollisionMap
	turn_queue.astar_targetting = CollisionMap.astar_targetting
	
	

	embark_point.set_locations(tile_map.local_to_map(embark_point.position))
	spawnPlayers()
	
	CollisionMap.initializeCharacterCollisions()
	astar_movement = CollisionMap.astar_movement
	
	turn_queue.player = get_tree().get_first_node_in_group("Party")
	turn_queue.tile_map = tile_map
	turn_queue.astar_movement = CollisionMap.astar_movement
	
	playerChar.connect("playerMoving", turn_queue.player_moving)
	
	#enemy.player = get_tree().get_first_node_in_group("Party")
	#enemy.tilemap = tile_map
	#enemy.astar_movement = astar_movement
	#enemy.turnQueue = turn_queue
	
	#enemy.connect("alert_turn_queue", turn_queue.startCombat)
	turn_queue.connect("combatStart", playerChar.setInCombat)
	
	for i in get_tree().get_nodes_in_group("Party"):
		i.astar_movement = CollisionMap.astar_movement
	
	
func spawnPlayers():
	playerChar = player.instantiate()
	partyMember1 = party_member.instantiate()
	
	playerChar.collisionMap = CollisionMap
	playerChar.global_position = (embark_point.spawn_point)
	playerChar.add_to_group("Party")
	add_child(playerChar)
	
	
	#(Vector2i(50,50)) * 16
	partyMember1.collisionMap = CollisionMap
	partyMember1.global_position = (embark_point.spawn_point + (Vector2i.DOWN * 32))
	partyMember1.add_to_group("Party")
	add_child(partyMember1)
#	partyMember1.global_position = (tile_map.local_to_map((playerChar.global_position) + Vector2.RIGHT) * 16)
	
	playerChar.connect("playerMoving", partyMember1.player_moving)
	get_tree().call_group("Party", "partySet")
	
#func _physics_process(delta):
##	partyMember1.current_id_path = playerChar.current_id_path
#	if (playerChar.current_id_path).is_empty():
#		return
#	else:
#		partyMember1.target_position = (playerChar.current_id_path).front()
#
#	if playerChar.is_moving == true:
#		partyMember1.is_moving = true
#	else:
#		partyMember1.is_moving = false
	


