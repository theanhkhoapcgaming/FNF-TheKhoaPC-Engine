Chart Editor Character Preview - CameraPosition Center Fix

Changes:
- Preserves the existing preview window dimensions and draggable position.
- Keeps the existing half-scale preview behavior (character.json scale * 0.5).
- Treats Character.cameraPosition as the camera target offset, matching PlayState.moveCamera().
- Centers that computed world-space camera target in the preview content viewport:
  * Opponent: midpoint.x + 150 + cameraPosition[0]
  * Player: midpoint.x - 100 - cameraPosition[0]
  * Both: midpoint.y - 100 + cameraPosition[1]
- The camera viewport center remains fixed at the center of the preview content area.

Modified file:
source/states/editors/ChartingState.hx

Note: This is a source-level patch. A Haxe build was not run in this environment.
