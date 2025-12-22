return {
  "Mr-LLLLL/interestingwords.nvim",
  config = function()
    -- 配置 interestingwords.nvim 插件
    require("interestingwords").setup {
      -- 设置单词高亮的颜色
      colors = { '#aeee00', '#ff0000', '#0000ff', '#b88823', '#ffa724', '#ff2c4b' },
      -- 启用搜索计数
      search_count = true,
      -- 启用导航
      navigation = true,
      -- 启用滚动时保持高亮词汇在屏幕中央
      scroll_center = true,
      -- 设置搜索的快捷键
      -- search_key = "",
      -- 设置取消搜索的快捷键
      -- cancel_search_key = "",
      -- 设置更改高亮颜色的快捷键
      color_key = "<leader>k",
      -- 设置取消高亮颜色的快捷键
      cancel_color_key = "<leader>K",
      -- 设置选择模式，可以选择 "random" 或 "loop"
      select_mode = "random",  -- random or loop
    }
  end,
}
