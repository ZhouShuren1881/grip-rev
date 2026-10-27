# grip-rev

`grip.ps1` 是一个 PowerShell 脚本，用 [Grip](https://github.com/joeyespo/grip) 在本地预览 Markdown 文件，并可显式指定 GitHub 风格的深色或浅色主题。

脚本只在当前进程内覆盖 Grip 的模板，不会修改已安装的 Grip 文件。

## 依赖

- PowerShell 5.1 或 PowerShell 7+
- Python，且已安装 Grip：

  ```powershell
  pip install grip
  ```

## 用法

```text
grip.ps1 [-Dark | -Light] [-Port <1-65535>] [-OpenBrowser] [-Python <path>] [-h] [file]
```

不指定 `[file]` 时，预览当前工作目录下的 `README.md`。`[file]` 可以放在选项之前、之间或之后。启动后访问 `http://localhost:<端口>/`，按 `Ctrl+C` 停止。

| 参数 | 说明 |
| --- | --- |
| `file` | 要预览的 Markdown 文件，默认 `README.md` |
| `-Dark` | 深色主题（默认） |
| `-Light` | 浅色主题，不能与 `-Dark` 同时使用 |
| `-Port` | 监听端口，默认 `6419`；端口被占用时脚本会报错退出，不会结束占用端口的进程 |
| `-OpenBrowser` | 启动后自动打开浏览器 |
| `-Python` | 装有 Grip 的 Python 解释器路径，默认 `python` |
| `-h`, `-Help` | 显示帮助 |

## 示例

```powershell
.\grip.ps1                                   # 预览 .\README.md（深色）
.\grip.ps1 docs\guide.md                     # 预览指定文件
.\grip.ps1 -Light docs\guide.md              # 浅色主题
.\grip.ps1 -Dark -Port 6420 notes.md         # 换一个端口
.\grip.ps1 -OpenBrowser                      # 自动打开浏览器
.\grip.ps1 -Python C:\venv\Scripts\python.exe README.md
```

如果执行策略阻止运行脚本，可以这样调用：

```powershell
powershell -ExecutionPolicy Bypass -File .\grip.ps1 README.md
```

## 许可证

[MIT](LICENSE)
