
@tool
extends TileMap

var islandSize = 50
var fastNoise = FastNoiseLite.new()

var generation = true

var mapHeight = 1000
var mapWidth = 1000
var islandAmnt = 7

var islandCoords = []
var islandNoiseValues = []
var spawnPoint
var bridgeCoords = []

var islandIDCoords = {}
var islandIDCentre = {}
var islandIDNoise = {}
var islandIDSpawnPoints = {}
var islandIDBridge

var disembark_point = preload("res://disembark_point.tscn")

@export var noiseType = 3
@export var octaves = 3
@export var gain = 0.5
@export var fractalType = 1
@export var lacunarity = 1.575
@export var frequency = 0.05

func setMapVariables():
	fastNoise.noise_type = noiseType
	fastNoise.fractal_octaves = octaves
	fastNoise.fractal_gain = gain
	fastNoise.fractal_type = fractalType
	fastNoise.fractal_lacunarity = lacunarity
	fastNoise.frequency = frequency

func setSingletonVariables():
	MapGeneratorSingleton.islandIDCoords = islandIDCoords
	MapGeneratorSingleton.islandIDNoise = islandIDNoise
	MapGeneratorSingleton.islandIDCentre = islandIDCentre
	MapGeneratorSingleton.generator = false
	

	

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	generation = MapGeneratorSingleton.generator
	if generation == true:
		genMap()
	else:
		buildMap()
		

func buildMap():
	islandIDCoords = MapGeneratorSingleton.islandIDCoords
	islandIDCentre = MapGeneratorSingleton.islandIDCentre
	islandIDNoise = MapGeneratorSingleton.islandIDNoise
	
	for x in mapWidth:
		for y in mapHeight:
			set_cell(0, Vector2(x, y), 0, Vector2i(0,0))
	
	buildIslands()
	genDisembarks()

func buildIslands():
	var noiseData = []
	var coordData = []
	for id in islandIDCoords:
		noiseData = islandIDNoise[id]
		coordData = islandIDCoords[id]
		for i in coordData.size():
			var alt = noiseData[i]
			if alt <= -0.4:
				set_cell(0, coordData[i], 0, Vector2i(0,0))
			if alt > -0.4 && alt <= -0.3:
				set_cell(0, coordData[i], 0, Vector2i(0,1))
			elif alt > -0.3 && alt <= -0.2:
				set_cell(0, coordData[i], 0, Vector2i(1,0))
			elif alt > -0.2 && alt <= -0.1:
				set_cell(0, coordData[i], 0, Vector2i(1,1))
			elif alt > -0.1 && alt <= 0.2:
				set_cell(0, coordData[i], 0, Vector2i(2,0))
			elif alt > 0.2:
				set_cell(0, coordData[i], 0, Vector2i(2,1))


func genMap():
	print("Starting Generation")
	for islandID in islandAmnt: #Generates
		islandCoords = [] 
		islandNoiseValues = []
		print("Generating Island " + str(islandID + 1))
		rdmzIsland()
		islandIDCoords[islandID + 1] = islandCoords
		islandIDNoise[islandID + 1] = islandNoiseValues
		islandIDCentre[islandID + 1] = islandCoords[0] + Vector2(islandSize,islandSize)
		print("Island Generated " + str(islandID + 1))
	genDisembarks()
	setSingletonVariables()
	

func genDisembarks():
	for id in islandIDCentre.keys():
		var disembark = disembark_point.instantiate()
		disembark.islandID = id
		disembark.noiseValues = islandIDNoise[id]
		disembark.islandSize = islandSize
		add_child(disembark)
		disembark.global_position = islandIDCentre[id] * 8
		

#Generates random coordinates in the map range and checks if there is room for an island
#Keeps generating until valid coords are found and appends them to the coordinate array
func rndCoords():
	var sizeCheck = false
	var posCheck = false
	var rnd_x = randi_range(0, mapWidth)
	var rnd_y = randi_range(0, mapHeight)
	while posCheck == false: #Checks if another island is already present
		while sizeCheck == false: #Checks if the island can fit on the map (stops clipping over the boundary)
			if rnd_x + (islandSize*2) <= mapWidth or rnd_y + (islandSize*2) <= mapHeight:
				sizeCheck = true
				print("Size Check Passed")
			else:
				rnd_x = randi_range(0, mapWidth)
				rnd_y = randi_range(0, mapHeight)
					
					
		posCheck = checkGrid(rnd_x, rnd_y, islandSize, islandSize, Vector2i(0,0)) 
		if posCheck == false:	#Resets back to the size check
			sizeCheck = false
			print("Position Check Failed: Ressetting")
			rnd_x = randi_range(0, mapWidth)
			rnd_y = randi_range(0, mapHeight)
		else:	#Adds the cells of the designated space to the coordinate array
			print("Position Check Passed: Generating Coordinates")
			for x in range(0, islandSize*2):
				for y in range(0 , islandSize*2):
					islandCoords.append(Vector2(rnd_x+x,rnd_y+y))
						
						
					
					
		
#Cycles through the cells in the area of the genned coords and checks for islands tiles
func checkGrid(rnd_x, rnd_y, sizeX, sizeY, check):
	var tileData
	for x in range(rnd_x, rnd_x + (sizeX*2)):
		for y in range(rnd_y, rnd_y + (sizeY*2)):
			tileData = get_cell_atlas_coords(0, Vector2i(x,y))
			if tileData != check:
				return false
	return true

func rdmzIsland():
	randomize()
	fastNoise.seed = randi()
	rndCoords()
	print("Finished Coords")
	setMapVariables()
	genIsland()
	


func genIsland():
	var dis
	var alt
	var count = 0
	var cellCoords: Vector2
	
	var sandTiles: Array
	var shallowTiles: Array
	var deepTiles: Array
	
	var surroundingCheck: Array
	
	var randSand
	var shipSize = Vector2(6, 14)
	var dockingPoint
	var shipOrigin
	var bridgeOrigin
	var bridgeValidation = false
	var stageCheck = false
	var maxBridgeLength = 10
	var bridgeDirection
	

	var bridgeTiles: Array
	var checkTiles: Array
	
	for x in range(-islandSize, islandSize):
		for y in range(-islandSize, islandSize):
			
			cellCoords = islandCoords[count]

			dis = Vector2(x,y).distance_to(Vector2(0,0)) / (islandSize / 1.2)
			alt = fastNoise.get_noise_2d(x,y) - dis
			islandNoiseValues.append(alt)
			count = count+1

			if alt <= -0.4:
				set_cell(0, cellCoords, 0, Vector2i(0,0))
				deepTiles.append(cellCoords)
			elif alt > -0.4 && alt <= -0.3:
				set_cell(0, cellCoords, 0, Vector2i(0,1))
				shallowTiles.append(cellCoords)
			elif alt > -0.3 && alt <= -0.2:
				set_cell(0, cellCoords, 0, Vector2i(1,0))
				sandTiles.append(cellCoords)
			elif alt > -0.2 && alt <= -0.1:
				set_cell(0, cellCoords, 0, Vector2i(1,1))
			elif alt > -0.1 && alt <= 0.2:
				set_cell(0, cellCoords, 0, Vector2i(2,0))
			else:
				set_cell(0, cellCoords, 0, Vector2i(2,1))
					
	#Creates docking bridge and spawn point
	while bridgeValidation == false:
		stageCheck = false

			
		surroundingCheck.clear()
		randSand = sandTiles.pick_random()
		sandTiles.remove_at(sandTiles.find(randSand))
		surroundingCheck = get_surrounding_cells(randSand)

		for i in surroundingCheck:
			if get_cell_atlas_coords(0, i) == Vector2i(0,1):
				bridgeDirection = Vector2(i) - randSand
				bridgeOrigin = randSand
				stageCheck = true
				
		if stageCheck == true:
			checkTiles.clear()
			for i in maxBridgeLength:
				var tiledata
				tiledata = get_cell_atlas_coords(0, bridgeOrigin+(bridgeDirection*i))
				checkTiles.append(tiledata)
			if checkTiles.count(Vector2i(0,0)) < 6:
				stageCheck = false
	
		if stageCheck == true:
			if bridgeDirection.is_equal_approx(Vector2.LEFT) or bridgeDirection.is_equal_approx(Vector2.RIGHT):
				print(bridgeDirection)
				dockingPoint = (bridgeOrigin + (bridgeDirection * maxBridgeLength))
				shipOrigin = dockingPoint + Vector2(0,-7)
				if bridgeDirection.is_equal_approx(Vector2.LEFT):
					shipOrigin = shipOrigin - Vector2((shipSize - Vector2(1,0)).x, 0)
				bridgeValidation = checkGrid(shipOrigin.x, shipOrigin.y, shipSize.x, shipSize.y, Vector2i(0,0))

				if bridgeValidation == true:
#					for x in range(shipOrigin.x, shipOrigin.x + shipSize.x):
#						for y in range(shipOrigin.y, shipOrigin.y + shipSize.y):
#							set_cell(0, Vector2(x,y), 0, Vector2i(3,0))
					for i in maxBridgeLength:
						set_cell(0, bridgeOrigin + (bridgeDirection * i), 0, Vector2i(3,0))
						set_cell(0, (bridgeOrigin + Vector2(0,1)) + (bridgeDirection * i), 0, Vector2i(3,0))
			elif bridgeDirection.is_equal_approx(Vector2.UP) or bridgeDirection.is_equal_approx(Vector2.DOWN):
				print(bridgeDirection)
				dockingPoint = (bridgeOrigin + (bridgeDirection * maxBridgeLength))
				shipOrigin = dockingPoint + Vector2(-7,0)
				if bridgeDirection.is_equal_approx(Vector2.UP):
					shipOrigin = shipOrigin - Vector2(0, (shipSize - Vector2(1,0)).x)
				bridgeValidation = checkGrid(shipOrigin.x, shipOrigin.y, shipSize.y, shipSize.x, Vector2i(0,0))

				if bridgeValidation == true:
					bridgeCoords.clear()
#					for x in range(shipOrigin.x, shipOrigin.x + shipSize.y):
#						for y in range(shipOrigin.y, shipOrigin.y + shipSize.x):
#							set_cell(0, Vector2(x,y), 0, Vector2i(3,0))
					for i in maxBridgeLength: 
						set_cell(0, bridgeOrigin + (bridgeDirection * i), 0, Vector2i(3,0))
						set_cell(0, (bridgeOrigin + Vector2(1,0)) + (bridgeDirection * i), 0, Vector2i(3,0))

						

	
#
#
#	for i in maxBridgeLength:
#		set_cell(0, (dockingPoint + Vector2(-1,0)) + (Vector2(-1,0) * i), 0, Vector2i(3,0))
	
#			randOcean = deepTiles.pick_random()
#			stageCheck = checkGrid(randOcean.x, randOcean.y, shipSize.x, shipSize.y, Vector2i(0,0))
#			if stageCheck == true:
#				stageCheck = false
#				dockingPoint = randOcean + Vector2(0,7)
#				for x in range(dockingPoint.x, dockingPoint.x + maxBridgeLength):
#					var tileData
#					tileData = get_cell_atlas_coords(0, Vector2i(x, dockingPoint.y))
#					if tileData == Vector2i(1,0):
#						stageCheck = true
						
				
				#stageCheck = checkGrid(dockingPoint.x, dockingPoint.y, maxBridgeLength, 1, Vector2i(1,0))
#				if stageCheck == false:
#					stageCheck = true
#				else:
#					stageCheck = false
		
#		for x in range(randOcean.x, randOcean.x + shipSize.x):
#			for y in range(randOcean.y, randOcean.y + shipSize.y):
#				set_cell(0, Vector2(x,y), 0, Vector2i(3,0))
#
#
#		for i in maxBridgeLength:
#			set_cell(0, (dockingPoint + Vector2(-1,0)) + (Vector2(-1,0) * i), 0, Vector2i(3,0))

		
#
#	print(bridgeDirection)
#
#	bridgeOrigin = randSand
#	if bridgeDirection == Vector2(0,-1) or Vector2(0,1):
#		print(bridgeDirection)
#		for i in maxBridgeLength: 
#			set_cell(0, bridgeOrigin + (bridgeDirection * i), 0, Vector2i(3,0))
#			set_cell(0, (bridgeOrigin + Vector2(1,0)) + (bridgeDirection * i), 0, Vector2i(3,0))
#
#	if bridgeDirection == Vector2(-1,0) or Vector2(1,0):
#		print(bridgeDirection)
#		for i in maxBridgeLength:
#			set_cell(0, bridgeOrigin + (bridgeDirection * i), 0, Vector2i(3,0))
#			set_cell(0, (bridgeOrigin + Vector2(0,1)) + (bridgeDirection * i), 0, Vector2i(3,0))
			#print( bridgeOrigin + (bridgeDirection * i), (bridgeOrigin + Vector2(1,0)) + (bridgeDirection * i))
	
			#print( bridgeOrigin + (bridgeDirection * i), (bridgeOrigin + Vector2(1,0)) + (bridgeDirection * i))
	
	
	
		
		
	
	
				
				
	

#func _process(_delta):
#	if !Engine.is_editor_hint():
#		setMapVariables()   
#		genIsland()
		
#	if Input.is_action_just_released("genNewMap"): 
#		fastNoise = FastNoiseLite.new()
#		rdmzIsland(fastNoise)

