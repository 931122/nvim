# 导航快捷键速查

## 定义

- `<C-]>`：跳到定义
- `<C-t>`：返回上一个 tag 位置
- `<leader>ts`：Telescope 选择当前光标单词的 tag
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
- `<leader>gb`：生成 `GTAGS`

## 排查

- `:TagsInspect`：检查当前光标单词是否在 `tags` 里
- `:TagsPicker`：打开 tag 的 Telescope 选择列表
