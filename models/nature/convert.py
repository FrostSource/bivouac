import os, glob, re
from pathlib import Path

# 0 = Name
# 1 = Remap list
# 2 = Scale prefab
# 3 = Surface prop
# 4 = 'true' or 'false' set disabled
file_template = """<!-- kv3 encoding:text:version{{e21c7f3c-8a33-41c5-9977-a76d3a32aa0d}} format:modeldoc28:version{{fb63b6ca-f435-4aa0-a2c7-c66ddc651dca}} -->
{{
	rootNode = 
	{{
		_class = "RootNode"
		children = 
		[
			{{
				_class = "ModelModifierList"
				children = 
				[
					{{
						_class = "Prefab"
						target_file = "models/nature/prefabs/{2}.vmdl_prefab"
					}},
				]
			}},
			{{
				_class = "MaterialGroupList"
				children = 
				[
					{{
						_class = "DefaultMaterialGroup"
						remaps = 
						[
{1}
						]
						use_global_default = false
						global_default_material = ""
					}},
				]
			}},
			{{
				_class = "PhysicsShapeList"
				children = 
				[
					{{
						_class = "PhysicsMeshFile"
						name = "{0}"
                        disabled = {4}
						parent_bone = ""
						surface_prop = "{3}"
						collision_prop = "default"
						recenter_on_parent_bone = false
						offset_origin = [ 0.0, 0.0, 0.0 ]
						offset_angles = [ 0.0, 0.0, 0.0 ]
						filename = "models/nature/meshes/{0}.fbx"
						import_scale = 1.0
						maxMeshVertices = 0
						qemError = 0.0
						import_filter = 
						{{
							exclude_by_default = false
							exception_list = [  ]
						}}
					}},
				]
			}},
			{{
				_class = "RenderMeshList"
				children = 
				[
					{{
						_class = "RenderMeshFile"
						filename = "models/nature/meshes/{0}.fbx"
						import_scale = 1.0
						import_filter = 
						{{
							exclude_by_default = false
							exception_list = [  ]
						}}
					}},
				]
			}},
		]
		model_archetype = "static_prop_model"
		primary_associated_entity = "prop_static"
		anim_graph_name = ""
	}}
}}"""

remap_template = """							{{
								from = "{0}.vmat"
								to = "models/nature/materials/{0}.vmat"
							}},\n"""

surface_props = {
    "color": "default_silent",
    "corn": "world.foliage",
    "dirt": "world.dirt",
    "grass": "world.grass",
    "leafs": "world.foliage",
    "stone": "world.concrete",
    "water": "world.water_shallow",
    "wood": "prop.wood_plank",
}

scale128strings = [
    "path",
    "ground",
    "bridge",
    "cliff",
    "platform",
    "fence",
]
# If starts with any of these, non solid
nonsolidstrings = [
    "plant",
    "grass",
    "lily",
    "flower",
    "mushroom",
]

meshes:dict[str,list[str]] = {}
# remaps:list[str] = []

for filename in glob.glob('meshes/*.fbx'):
    # print(filename)
    with open(filename, 'r') as f:
        remaps = []
        for line in f:
            result = re.search(r'"Material::(.+)", "" {', line)
            if result is not None:
                # print('\t'+result.group(1))
                remaps.append(result.group(1))
        if len(remaps) > 0:
            meshes[Path(filename).stem] = remaps

for mesh, remaps in meshes.items():
    full_remap_template = ""
    final_surface_prop = "default_silent"
    for remap in remaps:
        # get best surface prop
        for surface in surface_props:
            if surface in remap:
                final_surface_prop = surface_props.get(surface, "default_silent")
        # add up template remaps
        full_remap_template += remap_template.format(remap)

    is_128 = any(x in mesh for x in scale128strings)
    is_nonsolid = any(x in mesh for x in nonsolidstrings)
    # create template
    full_template = file_template.format(
        mesh,
        full_remap_template,
        'ground_scale' if is_128 else 'scale',
        final_surface_prop,
        'true' if is_nonsolid else 'false'
        )
    # save new vmdl
    with open(mesh + '.vmdl', 'w') as f:
        print(f'Saving {mesh} with {len(remaps)} remaps, {"nonsolid" if is_nonsolid else "solid"}{", 128" if is_128 else ""}, {final_surface_prop}...')
        f.write(full_template)
