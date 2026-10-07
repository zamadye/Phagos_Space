# Wall tissue visual reference

This is the art-direction reference used for the current wall pass. The wall is not intended to look like a clean tube with decorative red cables.

## Observed structure

- Skeletal muscle has a nested hierarchy: an outer epimysium, fascicle bundles wrapped by perimysium, and individual fibers wrapped by endomysium.
- The fascicles are long bundled fibers with connective-tissue boundaries, not evenly spaced helical wires.
- Type-I/oxidative muscle reads dark red because of myoglobin and vascular density.
- Skin/dermis adds a hydrated collagen/elastin mesh: a loose papillary layer over a denser, irregular reticular layer.

References:

- Oregon State Open Textbook, skeletal muscle: https://open.oregonstate.education/anatomy2e/chapter/skeletal-muscle/
- Oregon State Open Textbook, skin layers: https://open.oregonstate.education/anatomy2e/chapter/layers-skin/
- Lumen Learning, dermis: https://courses.lumenlearning.com/wm-biology2/chapter/dermis/
- OpenStax-derived fascicle overview: https://med.libretexts.org/Bookshelves/Anatomy_and_Physiology/Anatomy_and_Physiology_(Boundless)/9:_Muscular_System/9.6:_Overview_of_the_Muscular_System/9.6E:_Arrangement_of_Fascicles

## Applied to Phagos Space

- Blender source `tools/blender/source/vessel_wall_breathing.blend` now uses wandering `VesselFascicle_*` sheath geometry, finer `VesselFiber_*` detail, and irregular raised wall sockets.
- The membrane mesh receives broad drifting folds; the fascicle angle changes along the vessel instead of repeating as a regular helix.
- Godot's `organic_wall.gdshader` supplies oxblood tissue layers, static hydrated wet glints, and low-frequency deformation. It does not scroll textures or fake travel with UV offsets.
- The Godot `WallStudy_Breathing` `AnimationPlayer` and imported Blender `VesselWall_Breathing` clip remain separate layers so the visual result is testable as actual source asset plus runtime animation.
