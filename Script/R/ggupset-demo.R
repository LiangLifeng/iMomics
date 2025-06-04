#!/usr/bin/env Rscript

library(tidyverse)
library(argparse)
library(ggplot2)
library(ggupset)

# ---- 命令行参数解析 ----
parser <- ArgumentParser()
parser$add_argument("--type_files", nargs="+", help="每个集合的文件列表，每个文件包含一列 item，无表头")
parser$add_argument("--type_names", nargs="+", help="与每个文件对应的集合名称")
parser$add_argument("--prefix", help=" prefix of output file", default="ggupset-demo")
args <- parser$parse_args()

if (length(args$type_files) != length(args$type_names)) {
  stop("type_files 和 type_names 数量必须一致")
}

prefix <- args$prefix
if (is.null(prefix) || prefix == "") {
  prefix <- "ggupset-demo"
}

# ---- 构建 item-to-types 映射 ----
item_type_list <- map2(args$type_files, args$type_names, function(file, type_name) {
  read_tsv(file, col_names = "item", show_col_types = FALSE) %>%
    mutate(type = type_name)
})

# 合并为一个大表
combined <- bind_rows(item_type_list)

# group_by item 后汇总所属集合为 list-column
upset_df <- combined %>%
  group_by(item) %>%
  summarise(types = list(unique(type)), .groups = "drop")


#---- normal figure
p1 <- ggplot(upset_df, aes(x = types)) +
  geom_bar() +
  scale_x_upset()

pdf(paste0("01.normal.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p1
dev.off()



#---- only show top 10 sets
p2 <- ggplot(upset_df, aes(x = types)) +
  geom_bar() +
  scale_x_upset(n_intersections = 10) # 仅显示前 10 个集合

pdf(paste0("02.Top10_set.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p2
dev.off()


#---- Adding Numbers on top
p3 <- ggplot(upset_df, aes(x = types)) +
  geom_bar() +
  scale_x_upset() +
  geom_text(stat = "count", aes(label = after_stat(count)), angle=-90,hjust= 1,size=3) + # 在每个集合上显示数量
  scale_y_continuous(name = "",breaks = NULL,expand = expansion(mult = c(0, 0.2))) # 去掉 y 轴 label, 并设置 y 轴范围

pdf(paste0("03.Adding_Numbers.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p3
dev.off()



#---- order combination

## axis_combmatrix 
### x 轴不再是文字标签，而是显示一个 矩阵图，矩阵的每一列代表一个组合，每一行代表一个类型（集合）
### 可能只有组合很多的时候才有效果

  p4 <- tidy_movies %>%
  distinct(title, year, length, .keep_all=TRUE) %>%
  ggplot(aes(x=Genres)) +
    geom_bar() +
    scale_x_mergelist(sep = "-") +
    axis_combmatrix(sep = "-")


pdf(paste0("04.X-combmatrix.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p4
dev.off()

## scale_x_upset() function is to automatically order the categories and genres by freq or by degree.


p5 <- ggplot(upset_df, aes(x = types)) +
  geom_bar() +
  scale_x_upset(order_by = "degree")

pdf(paste0("05.Order_by_degree.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p5
dev.off()

p6 <- ggplot(upset_df, aes(x = types)) +
  geom_bar() +
  scale_x_upset(order_by = "freq")
pdf(paste0("06.Order_by_freq.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p6
dev.off()
