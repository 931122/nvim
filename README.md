# Nvim 导航快捷键说明

这个文件是这次新增导航功能的备忘，后面忘了可以直接看这里。

## 依赖

- `ctags` 或 `uctags`
- `global` / `gtags`
- `cscope`
- `telescope.nvim`

## 功能分工

- `ctags`：负责定义跳转，偏原生 Vim 的 tag 工作流
- `gtags`：负责定义搜索、引用搜索
- `cscope`：负责调用关系，谁调用了谁、当前函数调用了谁

## 快捷键

### Ctags

- `<C-]>`：跳到定义
  - 优先走原生 `ctags`
  - 如果当前符号没有 tag，会自动回退到 `gtags` 定义跳转
- `<C-t>`：从 tag 栈返回
- `<leader>tb`：生成项目级 `tags`
- `<leader>tf`：只给当前文件生成 tag，写到 `.tags.current`
- `<leader>ts`：用 Telescope 打开当前光标单词的 tag 列表
- `<leader>tn`：跳到下一个 tag 匹配
- `<leader>tp`：跳到上一个 tag 匹配

### Gtags

- `<leader>]`：用 GNU Global 查定义
- `<leader>r`：用 GNU Global 查引用
- `<leader>gb`：在当前工作目录生成 `GTAGS`

### Cscope

- `<leader>fc`：查当前函数被谁调用
- `<leader>fC`：查当前函数调用了谁

## 相关命令

- `:TagsBuild`
- `:TagsBuildCurrent`
- `:TagsSelect`
- `:TagsPicker`
- `:TagsInspect`

## 推荐使用流程

1. 先进入项目根目录。
2. 执行一次 `<leader>tb`，生成 `tags`。
3. 执行一次 `<leader>gb`，生成 `GTAGS`。
4. 如果项目要用调用关系查询，确保项目里有 `cscope.out`。
5. 日常使用时：
   - `<C-]>`：快速跳定义
   - `<leader>r`：查引用
   - `<leader>fc` / `<leader>fC`：查调用关系

## 说明

- `tags` 采用向上查找模式：`./tags;` / `./TAGS;`
- 如果项目里已经存在 `tags`，保存源码文件后会自动刷新项目 `tags`
- 如果某个符号 `<C-]>` 跳不过去，先执行 `:TagsInspect` 看当前 `tags` 里有没有这个符号
