extends RefCounted

static func build(blocks: PackedByteArray) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var normals := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	var palette := [Color.TRANSPARENT, Color(0.55, 0.64, 0.75), Color(0.08, 0.3, 0.5), Color(0.1, 0.65, 0.85), Color(0.15, 0.21, 0.3)]
	for y in 16:
		for z in 16:
			for x in 16:
				var block: int = blocks[(y * 16 + z) * 16 + x]
				if block == 0: continue
				var center := Vector3(x, y, z) + Vector3.ONE * 0.5 - Vector3.ONE * 8
				for normal in normals:
					var next := Vector3i(x, y, z) + Vector3i(normal)
					if next.x >= 0 and next.x < 16 and next.y >= 0 and next.y < 16 and next.z >= 0 and next.z < 16:
						if blocks[(next.y * 16 + next.z) * 16 + next.x] != 0: continue
					var u: Vector3 = Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT
					var v: Vector3 = normal.cross(u)
					var first := vertices.size()
					var shade := 1.0 if block == 3 else 0.55 + 0.45 * maxf(normal.dot(Vector3(-0.4, 0.8, -0.3).normalized()), 0)
					var color: Color = palette[mini(block, 4)]
					for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
						vertices.append(center + normal * 0.5 + (u * corner.x + v * corner.y) * 0.5)
						colors.append(Color(color.r * shade, color.g * shade, color.b * shade))
					indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

