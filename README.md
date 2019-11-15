# LaunchHere

Finder 菜单扩展，从当前文件夹执行Shell命令。

可实现右键在当前或选定的文件夹进行打开终端、新建文件等操作。

![](https://raw.githubusercontent.com/claw6148/LaunchHere/master/Capture.png)

## 使用方法

1. 编译并运行

2. 在``系统偏好设置``-``扩展``启用Menu

3. 在终端执行以下命令添加菜单项

```
defaults write dotZ.Menu.MenuExtension MenuItems -array \
'("新建文件","F=New-$RANDOM && touch $F")' \
'("新建\".txt\"文件","F=New-$RANDOM.txt && touch $F")' \
'("新建\".sh\"文件","F=New-$RANDOM.sh && touch $F && chmod a+x $F")' \
'("打开终端","open -a Terminal .")' \
'("打开活动监视器","open -a Activity\\ Monitor")' \
'("复制路径","echo -n $PWD|pbcopy")' \
;
```
