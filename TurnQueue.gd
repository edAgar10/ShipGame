extends Node2D

@onready var camera = $Camera2D
@onready var control = $Camera2D/Control
var collisionMap
signal combatStart

#Map data
var tile_map
var astar_movement
var astar_targetting

#Character variables, gets player and each group in combat, as well as positions
var player
var playerMoving = false
var party
var partyPosition: Array
var enemyParty
var enemyPartyPosition: Array
var targetUICheck = false

#Sorting variables for sorting the turn order of combat
var sortedList: Array
var swapped = true
var sortVar1
var sortVar2

#Pathfinding/Target selection variables
var targetSelect = false
var mousePosition
var targetPath
var selectedTarget
var selectedTargetPath
var previousTargetPath

#Movement restriction variables
var movementSelect = false
var movementValid = false
var currentMovementPath: Array
var movingCharacter = false
var movementPosition
var previousPosition
var step_count = 0

var turnCounter: int
#var turnEnded = false
var attack_taken = false
var movement_taken = false
var currentTurnNode

func player_moving(is_moving, player_position):
	playerMoving = is_moving

func _on_button_pressed():
	if global.in_combat == true:
		if targetSelect == false && attack_taken == false:
			tile_map.clear_layer(1)
			targetSelect = true
			movementSelect = false
		else:
			targetSelect = false
			tile_map.clear_layer(1)

func _on_button_2_pressed():
	if global.in_combat == true:
		if movementSelect == false && movement_taken == false:
			tile_map.clear_layer(1)
			movementSelect = true
			targetSelect = false
			if targetPath != null:
				targetPath.clear()
		else:
			movementSelect = false
			tile_map.clear_layer(1)

func _on_button_3_pressed():
	global.turn_ended = true
	movementSelect = false
	targetSelect = false
	tile_map.clear_layer(1)
	print(global.turn_ended)

func startCombat(combatState):
	global.in_combat = true
	control.show_combat_ui()
	updateGroups()
	updateGroupPositions()
	while global.in_combat == true:
		for i in sortedList:
			attack_taken = false
			movement_taken = false
			global.turn_ended = false
			currentTurnNode = i
			if i.is_in_group("Party"):
				i.enemyList = enemyParty
			elif i.is_in_group("Enemy"):
				i.enemyList = party
			i.turnStart()
			await(global.turnEnded)
			targetSelect = false
			movementSelect = false

	
	

func updateGroups():
	party = get_tree().get_nodes_in_group("Party")
	enemyParty = get_tree().get_nodes_in_group("Enemy")
	
	sortedList.clear()
	sortedList.append_array(party)
	sortedList.append_array(enemyParty)
	sortList()

func updateGroupPositions():
	partyPosition.clear()
	enemyPartyPosition.clear()
	for i in party:
		partyPosition.append(tile_map.local_to_map(i.position))
	for i in enemyParty:
		enemyPartyPosition.append(tile_map.local_to_map(i.position))
		
	get_tree().call_group("Party", "updateEnemyPosition", enemyPartyPosition)
	get_tree().call_group("Enemy", "updateEnemyPosition", partyPosition)

func sortList():
	for i in sortedList.size():
		swapped = false
		for j in sortedList.size() - 1:
			sortVar1 = sortedList[j]
			sortVar2 = sortedList[j + 1]
			if sortVar1.turnSpeed < sortVar2.turnSpeed:
				sortedList[j] = sortVar2
				sortedList[j+1] = sortVar1
				
				swapped = true
		if swapped == false:
			break
		
	#print(sortedList)



func _input(event):
		
	if !event.is_action_pressed("LeftClick"):
			return
	
	
	
	if targetSelect == true:
		print(targetPath)
		for i in currentTurnNode.enemyList:
			if tile_map.local_to_map(i.position) == tile_map.local_to_map(get_global_mouse_position()):
				print(i)
				
	
	if movementSelect == true:
		print(movementValid)
		if movementValid == true:
			tile_map.clear_layer(1)
			movementSelect = false
			currentMovementPath = targetPath
			movement_taken = true
			
		


func targetSelection():
	targetPath = astar_targetting.get_id_path(tile_map.local_to_map(currentTurnNode.position),  
			  	 tile_map.local_to_map(get_global_mouse_position()))
	targetPath.pop_front()
	
	step_count = 0
	
	for i in targetPath:
		step_count += 1
		if currentTurnNode.tileMovement > step_count:
			if currentTurnNode.enemyPositions.find(i) != -1:
				tile_map.set_cell(1, i, 2, Vector2i(2,0))
			else:
				tile_map.set_cell(1, i, 2, Vector2i(0,0))
			
		else:
			tile_map.set_cell(1, i, 2, Vector2i(1,0))
	
		if previousTargetPath != null:
			if previousTargetPath.find(i) != -1:
				previousTargetPath.remove_at(previousTargetPath.find(i))
	
	
	
	if previousTargetPath != null:
		if previousTargetPath == targetPath:
			return
		for i in previousTargetPath:
			tile_map.set_cell(1, i, 2, Vector2i(3,0))
	
	previousTargetPath = targetPath

func movementSelection():
	targetPath = astar_movement.get_id_path(tile_map.local_to_map(currentTurnNode.position),  
			  	 tile_map.local_to_map(get_global_mouse_position()))
	targetPath.pop_front()
	step_count = 0
	
	for i in targetPath:
		step_count += 1
		if currentTurnNode.tileMovement > step_count:
			tile_map.set_cell(1, i, 2, Vector2i(2,0))
			movementValid = true
		else: 
			tile_map.set_cell(1, i, 2, Vector2i(1,0))
			movementValid = false
		if previousTargetPath != null:
			if previousTargetPath.find(i) != -1:
				previousTargetPath.remove_at(previousTargetPath.find(i))
	
	if previousTargetPath != null:
		if previousTargetPath == targetPath:
			return
		for i in previousTargetPath:
			tile_map.set_cell(1, i, 2, Vector2i(3,0))
	
	previousTargetPath = targetPath
	
	

func _process(delta):
	if global.in_combat == true:
		camera.position = currentTurnNode.position
	else:
		camera.position = player.position
		
	if targetSelect == true:
		targetSelection()
	
	if movementSelect == true:
		movementSelection()
	
	if currentMovementPath.is_empty():
		return
	
	if movingCharacter == false:
		movementPosition = tile_map.map_to_local(currentMovementPath.front())
		previousPosition = currentTurnNode.global_position
		collisionMap.updateCharacterCollisions(tile_map.local_to_map(previousPosition), tile_map.local_to_map(currentMovementPath.back()))
		movingCharacter = true
	
	if !currentMovementPath.is_empty():
		currentTurnNode.global_position = currentTurnNode.global_position.move_toward(movementPosition, delta * 32 * currentTurnNode.speed)
		if currentTurnNode.global_position == movementPosition:
			
			previousPosition = currentTurnNode.global_position
			currentMovementPath.pop_front()
			
			#astar_grid.set_point_solid(tile_map.local_to_map(current_position), true)
			#astar_grid.set_point_solid(tile_map.local_to_map(previous_position),false)
		
			if currentMovementPath.is_empty() == false:
				movementPosition = tile_map.map_to_local(currentMovementPath.front())
				#collisionMap.updateCharacterCollisions(tile_map.local_to_map(previous_position), tile_map.local_to_map(target_position))
			else:
				movingCharacter = false
				currentMovementPath.clear()
				updateGroupPositions()
	
	
	
	
