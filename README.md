# Model Advisor Workflow.skill

> 让贵模型做判断，让执行模型做落地。

同事.skill 证明了一个人的工作方式可以被蒸馏成 Skill。  
女娲.skill 证明了顶级人物的思维框架可以被蒸馏成 Skill。  

Model Advisor Workflow 蒸馏的是另一件事：**多模型协作的工作流**。

不是让 Codex 包揽所有事。  
不是让 Claude Code 闷头一直写。  
而是把一次开发任务拆成清晰的三段：

```text
Codex / 强模型      负责规划与审查
Claude Code / 执行模型 负责实现与验证
你                 负责确认方向与交接
```

看效果 · 安装 · 怎么用 · 工作原理 · 仓库结构

---

## 它解决什么问题

现在很多人会同时使用多个 Agent：

- Codex 规划能力强，适合做方案、审查、找风险
- Claude Code 执行顺手，适合改代码、跑测试、持续推进
- DeepSeek V4 Pro 这类模型性价比高，适合承担大量执行 token

但问题是：**两个 Agent 不共享上下文**。

如果直接让 Codex 一路做完，贵模型 token 花得快。  
如果只让执行模型一路做完，容易在方向、设计、测试缺口上跑偏。  
如果靠人工口头同步，又很快变成复制粘贴地狱。

这个 Skill 给出一个文件化交接协议：

```text
.codex-advisor/context.md        当前里程碑事实
.codex-advisor/claude-prompt.md  交给 Claude Code 的执行指令
.codex-advisor/last.md           Codex 顾问的只读审查结果
ask-advisor.sh                   里程碑审查触发器
```

---

## 效果示例

### 你

```text
使用 model-advisor-workflow skill。

项目目录：/Users/oripi/Documents/bionicReading

我的 idea 是：
做一个 Bionic Reading 网页工具，用户输入英文文本后，把每个单词前半部分加粗显示。
```

### Codex

```text
我会先安装 advisor workflow，然后只做规划和交接。
我不会实现功能。

计划：
1. 创建最小 HTML/CSS/JS 页面
2. 实现文本输入和转换按钮
3. 实现单词前半部分加粗
4. 做基础空输入和标点处理
5. 本地打开验证

我已写入：
.codex-advisor/claude-prompt.md

请在 Claude Code 中运行：
Read .codex-advisor/claude-prompt.md and execute it exactly.
```

### Claude Code

```text
完成 milestone 1。
已更新 .codex-advisor/context.md。
现在运行 ./ask-advisor.sh。
```

### Codex 顾问

```text
目标没有偏离。
当前实现足够小，没有明显过度设计。
缺口：需要验证标点、换行、空输入。
下一步最小动作：补一个针对 mixed punctuation 的手动验证或测试。
```

这就是整个循环：Codex 不抢执行权，Claude Code 不跳过顾问检查。

---

## 安装

### 用 Codex skill installer

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo OllyPai/model-advisor-workflow-skill \
  --path model-advisor-workflow
```

安装后重启 Codex。

### 手动安装

```bash
git clone https://github.com/OllyPai/model-advisor-workflow-skill.git
mkdir -p ~/.codex/skills
cp -R model-advisor-workflow-skill/model-advisor-workflow ~/.codex/skills/
```

---

## 使用

在 Codex 里直接说：

```text
使用 model-advisor-workflow skill。

项目目录：[你的项目路径]

我的 idea 是：
[你的任务想法]
```

Codex 会做四件事：

1. 识别项目根目录
2. 自动安装 advisor workflow 文件
3. 把 idea 变成计划
4. 写入 `.codex-advisor/claude-prompt.md` 后停止

然后你打开 Claude Code，在项目根目录输入：

```text
Read .codex-advisor/claude-prompt.md and execute it exactly.
```

Claude Code 会执行 milestone，并在每个 milestone 后：

1. 更新 `.codex-advisor/context.md`
2. 运行 `./ask-advisor.sh`
3. 读取 `.codex-advisor/last.md`
4. 根据顾问建议继续或停下

---

## 工作原理

### 1. Codex 只做规划

Codex 可以理解项目、拆任务、写计划、生成 Claude Code prompt。  
但它有一个硬边界：**写完 `.codex-advisor/claude-prompt.md` 就停。**

它不应该：

- 实现功能
- 修改产品源码
- 跑项目测试
- 在 Claude Code 完成 milestone 前运行 `./ask-advisor.sh`

### 2. Claude Code 负责执行

Claude Code 拿到 `.codex-advisor/claude-prompt.md` 后执行计划。  
执行到一个 milestone，必须更新 `.codex-advisor/context.md`。

### 3. `ask-advisor.sh` 是回传通道

Claude Code 不需要把消息发回原来的 Codex 聊天。  
它只需要运行：

```bash
./ask-advisor.sh
```

这个脚本会启动一个新的 Codex 只读顾问会话，读取当前项目和 `.codex-advisor/context.md`，然后把建议写入：

```text
.codex-advisor/last.md
```

### 4. 用户保留方向控制权

顾问只给建议。  
执行模型只做实现。  
最终是否采纳、是否继续，由你决定。

---

## 仓库结构

```text
model-advisor-workflow-skill/
└── model-advisor-workflow/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── scripts/
        └── install-advisor-workflow.sh
```

安装到项目后，会生成：

```text
your-project/
├── ask-advisor.sh
└── .codex-advisor/
    ├── context.md
    ├── claude-prompt.md
    └── last.md
```

---

## 适合谁

适合你，如果你：

- 同时使用 Codex 和 Claude Code
- 想让贵模型少做执行、多做判断
- 想让 DeepSeek V4 Pro 这类模型承担主要实现
- 经常在多 Agent 之间复制粘贴上下文
- 希望每个 milestone 都有一次强模型 review

不适合你，如果你：

- 只用一个 Agent
- 想完全无人值守执行
- 不愿意在关键交接点做确认
- 每写一个函数都想跑一次顾问

---

## 关键原则

```text
Codex 不写产品代码。
Claude Code 不跳过 checkpoint。
context.md 只写事实，不写聊天记录。
last.md 是上一轮输出，不是本轮输入。
用户永远保留最终判断权。
```

贵模型不是更贵的键盘。  
它应该坐在审查席上，而不是一直敲代码。

---

## 致谢

这个 README 的呈现方式参考了：

- [同事.skill / dot-skill](https://github.com/titanwings/colleague-skill)
- [女娲.skill](https://github.com/alchaincyf/nuwa-skill)

同事.skill 把“人做什么”结构化。  
女娲.skill 把“人怎么想”结构化。  

Model Advisor Workflow 把“模型怎么协作”结构化。
