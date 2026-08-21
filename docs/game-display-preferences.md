# Game Display Preferences

## FPS Overlay

The in-game controls menu contains **FPS Overlay**.

- **Show FPS** displays the emulation frame rate measured by the helper process.
- **Configure FPS Overlay…** lets the player select the text color (white, yellow, green, or red) and position (each corner).

The settings are stored in the user's preferences and apply to future game sessions. The measurement is reported twice per second to keep the label responsive without adding work to every UI frame.

## Screen Rotation

The rotation control turns the game display clockwise in 90-degree steps. Rotation is stored for each game and system. A centered wrapper layer performs the visual rotation while the game renderer remains unrotated inside it, keeping games with different aspect ratios aligned and uncropped.
