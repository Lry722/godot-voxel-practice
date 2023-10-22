# A project for getting familiar with Godot Voxel module
Based on Zylann's Voxel Game example. Some features that were not included in the original example will be added in the future. The coding process is here https://www.bilibili.com/video/BV1mN411J7yv/ <br/>
<br/>
Implemented features:<br/>
- Basic terrain generator with 1 noise and 1 curve
- Basic FPS character controller
- Generation of small structures such as trees (less than 16x16x16)
- Place and destroy blocks
- Update blocks
- Handle blocks'orientation automatically. Currently supports five orientation type : `2/3/4/6/8` <br/>
2: X/Z<br/>
3: X/Y/Z<br/>
4: X/NX/Z/NZ<br/>
6: X/NX/Y/NY/Z/NZ<br/>
8: X/DX/NX/DNX/Z/DZ/NZ/DNZ<br/>
N represents negative direction and D represents the block is downward
- Liquid system, currently only containing water
- Hotbar with support for hot keys and mouse wheel
