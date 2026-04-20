# 导航快捷键速查

## 定义

- `<C-]>`：跳到定义
  - 先走 `ctags` 的精确匹配
  - 只有一个结果时直接跳转
  - 有多个结果时弹出 Telescope 选择
  - `ctags` 没命中时，自动回退到 `gtags`
- `<C-t>`：从 tag 栈返回上一个位置
- `<leader>ts`：强制打开 Telescope，手动选择当前光标单词的 tag 定义
- `<leader>]`：用 `gtags` 查定义
- `<leader>tn`：下一个 tag 匹配
- `<leader>tp`：上一个 tag 匹配

## 引用

- `<leader>r`：查引用

## 调用关系

- `<leader>fc`：查谁调用了当前函数
- `<leader>fC`：查当前函数调用了谁

## 数据库生成

- `<leader>tb`：生成项目 `tags`
- `<leader>tf`：只给当前文件生成 tag
- `<leader>gT`：生成 `GTAGS`

## 排查

- `:TagsInspect`：检查当前光标单词是否在 `tags` 里
- `:TagsPicker`：打开 tag 的 Telescope 选择列表
