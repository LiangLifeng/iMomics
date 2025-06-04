library(tidyverse)
library(ggupset)

# 加载数据
data("tidy_movies", package = "ggupset")

# 展开 list-column Genres
movies_long <- tidy_movies %>%
  select(title, Genres) %>%
  unnest(Genres)

# 创建输出文件夹
dir.create("genres_txt", showWarnings = FALSE)

# 遍历每个类型，写入一个对应 txt 文件
movies_long %>%
  group_by(Genres) %>%
  summarise(titles = unique(title), .groups = "drop") %>%
  group_split(Genres) %>%
  walk(function(df) {
    genre <- unique(df$Genres)
    file_name <- file.path("genres_txt", paste0(genre, ".txt"))
    write_lines(df$titles, file_name)
  })

cat("✅ 成功写出所有类型的 txt 文件到 'genres_txt' 文件夹。\n")
