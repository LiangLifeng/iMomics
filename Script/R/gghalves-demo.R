#!/usr/bin/env Rscript

library(ggplot2)
library(gghalves)
library(ggbeeswarm)  # 为 jitter 点增强效果可选
library(RColorBrewer)

# 示例数据：mtcars 设置为因素
df <- mtcars
df$cyl <- factor(df$cyl)

# 1️⃣ 半小提琴 + 点图
p1 <- ggplot(df, aes(x = cyl, y = mpg, fill = cyl)) +
  geom_half_violin(side = "l", alpha = 0.6, trim = FALSE, width = 1) +
  geom_half_point(side = "r", size = 1, alpha = 0.8, aes(color = cyl)) +
  scale_fill_brewer(palette = "Pastel2") +
  scale_color_brewer(palette = "Dark2") +
  theme_minimal(base_size = 12) +
  labs(title = "Half Violin + Point", x = "", y = "mpg") +
  theme(legend.position = "none")

# 2️⃣ 半箱线 + 点图
p2 <- ggplot(df, aes(x = cyl, y = mpg, fill = cyl)) +
  geom_half_boxplot(side = "l", outlier.shape = NA, width = 0.6, alpha = 0.7) +
  geom_half_point(side = "r", size = 1, alpha = 0.8, aes(color = cyl)) +
  scale_fill_brewer(palette = "Pastel2") +
  scale_color_brewer(palette = "Dark2") +
  theme_minimal(base_size = 12) +
  labs(title = "Half Boxplot + Point", x = "", y = "mpg") +
  theme(legend.position = "none")


# 3️⃣ 半箱线 + dotplot（点堆积图）
p3 <- ggplot(df, aes(x = cyl, y = mpg, fill = cyl)) +
  geom_half_boxplot(side = "l", outlier.shape = NA, width = 0.6, alpha = 0.7) +
  geom_beeswarm(side = 1,aes(color = cyl))+
  scale_fill_brewer(palette = "Pastel2") +
  scale_color_brewer(palette = "Dark2") +
  theme_minimal(base_size = 12) +
  labs(title = "Half Boxplot + Dotplot", x = "", y = "mpg") +
  theme(legend.position = "none")

# 输出图像
pdf("gghalves_demo_all.pdf", width = 11, height = 4)
gridExtra::grid.arrange(p1, p2, p3, ncol = 3)
dev.off()