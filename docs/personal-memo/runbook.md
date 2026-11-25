# personal-memo 操作手册

## 环境与前置安装

运行时只需要 SQLite（嵌入式关系数据库）官方 `sqlite3` 命令行程序和 POSIX（Portable Operating System Interface，可移植操作系统接口）兼容 Shell（命令解释器）。不需要数据库服务器、Python 或 Node.js。仓库整体仍使用 Bun（JavaScript 工具链）管理，备忘录运行不依赖它。

macOS 先检查系统命令，不因默认搜索路径中的其他版本失败就直接重装：

```bash
command -v sqlite3
/usr/bin/sqlite3 --version
```

缺失或功能探测失败时，如果已安装 Homebrew（macOS 包管理器）：

```bash
brew install sqlite
"$(brew --prefix sqlite)/bin/sqlite3" --version
```

Homebrew 的 SQLite 不一定覆盖系统命令；后续使用实际安装路径。没有 Homebrew 时，按 [SQLite 官方下载页](https://www.sqlite.org/download.html)选择平台工具，或使用平台包管理器；不要为了本技能自动部署其他工具链。Linux 的 Debian / Ubuntu 环境可执行 `sudo apt-get install sqlite3`，此安装命令尚未在本项目实测。

## 源码验证

在 Kairos 仓库根目录执行。以下测试只使用独立临时目录，不访问正式 `~/person.memo.db`：

```bash
bash tests/personal-memo/sqlite-cli.sh
SQLITE_BIN=/usr/bin/sqlite3 bash tests/personal-memo/sqlite-cli.sh
bash scripts/check-skill-boundaries.sh
bash scripts/test-skill-boundaries.sh
```

也可在已安装 Bun 时运行 `bun run test:memo`。技能元数据验证使用 `skill-creator`（技能制作与校验工具）分发的 `scripts/quick_validate.py`；本轮通过已有 `uv`（Python 环境与包工具）的临时环境加载 PyYAML（YAML 格式解析库）执行，没有向仓库添加 Python 依赖。该校验器不属于技能运行时依赖。

`SQLITE_BIN` 是本次测试选择的 SQLite 可执行文件绝对路径；未指定时使用 `command -v sqlite3` 的结果。测试应退出 0 并显示通过摘要；失败时根据报错修复，不能用重新创建个人数据库来绕过。临时数据在退出时清理。

## 使用与数据库位置

默认路径是 `$HOME/person.memo.db`。首次“记下……”时建库；纯查询不会创建库。实际初始化、分类和关键词查询、带时区的时间筛选、更新与删除命令均见随技能分发的[操作细则](../../skills/personal-memo/references/operations.md)，冷启动智能体从[技能入口](../../skills/personal-memo/SKILL.md)开始。

示例自然语言输入：

- “记一下，我有一台香港备用机，连接信息是……”
- “查服务器分类里含香港的记录。”
- “查北京时间 2026 年 11 月 5 日新记的内容。”
- “把第 3 条的正文改成……”“删除第 3 条。”

模型根据用户表达选择创建或更新时间作为筛选字段。数据库以 UTC（Coordinated Universal Time，协调世界时）保存时间。查询按用户时区转换边界，不把机器时区当成用户时区。

## 本地安装与更新

源码与安装副本分离；只有本地安装后，其他会话才可从已安装技能发现它。以下命令使用 `skills` CLI（Command-Line Interface，命令行界面）进行注册。`npx` 是 Node.js 的包命令执行器，仅用于安装技能，不是技能运行依赖。

在 Kairos 根目录：

```bash
# 核对同名技能和已注册的智能体
npx skills ls -g --json

# 首次安装到 Codex 与 Claude Code
npx skills add ./skills/personal-memo -g -s personal-memo -a codex claude-code -y

# 修改源码后，先移除旧副本再安装
npx skills remove -g personal-memo -y
npx skills add ./skills/personal-memo -g -s personal-memo -a codex claude-code -y

# 验证注册与关键文件内容
npx skills ls -g --json
diff -ru skills/personal-memo "$HOME/.agents/skills/personal-memo"
```

目标已存在时先移除再安装；部分智能体不支持全局安装时，以注册状态和安装文件是否一致判断结果。不要手工修改统一安装目录副本。安装技能不创建或迁移备忘录数据库。

## 失败处理

| 错误或现象 | 处理 |
| --- | --- |
| 找不到命令或不支持输出选项 | 更换可执行文件并重新运行内存功能探测；失败则停止 |
| 查询时数据库不存在 | 返回尚未初始化，不创建文件；新增或明确初始化时再建 |
| 文件存在但结构版本不符、空文件或缺表 | 停止并报告路径；核对是否选错文件，保留原文件，不自动重建 |
| 目录不存在、文件只读或无法打开 | 修正路径或权限；不改用当前项目目录 |
| `database is locked` | 等待本次 5 秒忙等待结束后报告失败，检查其他写进程，不无限重试 |
| 更新或删除影响 0 行 | 报告目标不存在或已变化，重新定位，不扩大操作范围 |
| 事务内语句失败 | 连接退出后未提交事务回滚；读回复查再决定是否重试 |
| 查询成功但空输出 | 视为无匹配，不能把执行错误也解释为无匹配 |

## 验证记录

- 2026-11-05：本机系统 SQLite 内存库已实测中文子串、分类时间组合、多行特殊字符、增删改查和结构化输出。
- 文件数据库实测通过：默认命令 `sqlite3` 3.50.6（本机来自 Android 工具目录）与系统 `/usr/bin/sqlite3` 3.51.0，分别运行 `tests/personal-memo/sqlite-cli.sh`，均退出 0。
- 测试覆盖：含空格路径、内存能力探测、完整多行正文往返、单引号与命令样式正文、中文和特殊字符搜索、分类筛选、带时区日期范围及终点排除、更新保留创建时间、删除标识不复用、目标缺失、失败事务回滚、重复初始化不覆盖、只读拒绝写入、只读查询不创建文件、备份可读和源库完整性。
- 备份在临时目录以独立数据库打开并核对完整性和记录数；未执行覆盖正式数据库的恢复操作。
- 运行时资源边界检查、边界检查器测试、技能元数据校验、Shell 语法检查通过。
- 初次测试发现 macOS 旧版 Bash 对命令替换内的复杂多行测试夹具解析异常；已将预期正文先写临时文件再读取，两种 SQLite 可执行文件均重新通过。技能示例使用独立的多行输入块，不依赖该嵌套写法。
- 全局安装已实测：使用 `skills` 1.7.6 从本地源码安装，Codex 与 Claude Code 均已注册；统一安装目录和 Claude Code 入口的全部内容与源码逐文件对比一致。未创建正式数据库，等待新会话实际使用反馈。
- 尚未验证：Linux、Windows、多智能体并发编辑、较大数据规模、新会话实际调用。原生 Windows Shell 暂不在操作合约范围内。

## 能力导向修订

2026-11-05：技能入口改为能力概览，命令参考提供可组合示例；取消默认“未分类”、固定检查顺序、固定分页和只允许单条操作等限制。新库分类由写入时明确提供，旧库仍可继续使用。分类与组织效果由模型结合上下文决定，实际交互效果待新会话反馈。

本轮实测：两种本机 SQLite 的现有回归测试均通过；临时构造的新库和带旧分类默认值的数据库都能正常写入明确分类。技能元数据、资源边界和文档链接检查通过。已移除旧全局副本并重新安装到 Codex 与 Claude Code，两处安装内容均与源码一致。未访问用户正式数据库。
