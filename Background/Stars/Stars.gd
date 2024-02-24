extends MeshInstance3D
class_name Stars

@export var star_count: int = 1000000

@export var material: Material

func generate_star(vertexes, colors, i):
	var x: float = randfn(0, 800)
	var z: float = randfn(0, 800)
	var y: float = randfn(0, clamp(100 - (Vector2(x, z).length() / 32), 0, 32))
	
	vertexes[i] = Vector3(x, y, z)
	
	colors[i] = Color.from_hsv(randf_range(0, 1), randf_range(0, 0.5), 1) # Color can be anything though limit saturation to 50% to keep whiteness

func generate_stars_mesh(stars_mesh: Mesh):
	# Make the mesh array
	var stars_mesh_surface: Array
	stars_mesh_surface.resize(Mesh.ARRAY_MAX)
	
	# Make the vertex array and add it to the mesh
	var vertexes: PackedVector3Array
	vertexes.resize(star_count)
	stars_mesh_surface[Mesh.ARRAY_VERTEX] = vertexes
	
	# Make the color array and add it to the mesh
	var colors: PackedColorArray
	colors.resize(star_count)
	stars_mesh_surface[Mesh.ARRAY_COLOR] = colors

	# Generate the stars
	for i in range(0, star_count):
		generate_star(vertexes, colors, i)

	stars_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, stars_mesh_surface, [], {}, Mesh.ARRAY_FORMAT_VERTEX | Mesh.ARRAY_FORMAT_COLOR)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	generate_stars_mesh(mesh)
	
	mesh.surface_set_material(0, material)
