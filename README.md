# Godot Voxel module 的一个练习
模仿了module作者Zylann的Voxel Game示例，在未来会加入原示例中没有的一些功能。<br/>
制作过程视频在这 https://www.bilibili.com/video/BV1mN411J7yv/<br/>
<br/>
目前已实现的功能：
- 使用了一个噪声+一个曲线的基本地形生成
- 一个基本的fps角色控制器
- 树等小型结构的生成（小于16x16x16）
- 放置和破坏方块
- 方块更新
- 自动处理方块的旋转，目前支持`2/3/4/6/8`共五种朝向<br/>
  `2: X/Z`<br/>
  `3: X/Y/Z`<br/>
  `4: X/NX/Z/NZ`<br/>
  `6: X/NX/Y/NY/Z/NZ`<br/>
  `8: X/DX/NX/DNX/Z/DZ/NZ/DNZ`<br/>
  其中N表示负向，D表示整体朝下<br/>
<br/>
Based on Zylann's Voxel Game example. Some features that were not included in the original example will be added in the future. The coding process is here https://www.bilibili.com/video/BV1mN411J7yv/ <br/>
<br/>
Implemented features:<br/>
Basic terrain generator with 1 noise and 1 curve<br/>
Basic FPS character controller<br/>
Generation of small structures such as trees (less than 16x16x16)<br/>
Place and destroy blocks<br/>
Update blocks<br/>
Handle blocks'orientation automatically. Currently supports five orientation type : `2/3/4/6/8` <br/>
2: X/Z<br/>
3: X/Y/Z<br/>
4: X/NX/Z/NZ<br/>
6: X/NX/Y/NY/Z/NZ<br/>
8: X/DX/NX/DNX/Z/DZ/NZ/DNZ<br/>
N represents negative direction and D represents the block is downward<br/>

