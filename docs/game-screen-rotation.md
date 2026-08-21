# Game Screen Rotation

The game rotation button rotates the current game's output clockwise by 90 degrees at a time.

The selected rotation is saved per game and system in `UserDefaults`, so it is restored automatically the next time that game is opened.

## Final rendering design

The game content remains inside an unrotated `CALayerHost`. A separate wrapper layer is centered in the game view and receives the 90-degree transform. For portrait rotations, the wrapper swaps its width and height before the transform. This keeps the remote rendering surface in its normal coordinate space while the visible result is correctly rotated and centered.

During window startup, temporary dimensions with a width or height below 16 points are ignored. This prevents a core from initializing its video surface with invalid sizes such as `134×1` before the game window reaches its final size.
