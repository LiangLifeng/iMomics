#!/usr/bin/env Rscript

library(tidyverse)
library(argparse)
library(ggplot2)
library(ggupset)


# Combined with any kind of ggplot that uses a categorical x-axis. 

p7 <- tidy_movies %>%
  distinct(title, year, length, .keep_all=TRUE) %>%
  ggplot(aes(x=Genres, y=year)) +
    geom_violin() +
    scale_x_upset(order_by = "freq", n_intersections = 12)

pdf(paste0("07.Combined_with_violin.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p7
dev.off()


p8 <- df_complex_conditions %>%
  mutate(Label = pmap(list(KO, DrugA, Timepoint), function(KO, DrugA, Timepoint){
    c(if(KO) "KO" else "WT", if(DrugA == "Yes") "Drug", paste0(Timepoint, "h"))
  })) %>%
  ggplot(aes(x=Label, y=response)) +
    geom_boxplot() +
    geom_jitter(aes(color=KO), width=0.1) +
    geom_smooth(method = "lm", aes(group = paste0(KO, "-", DrugA))) +
    scale_x_upset(order_by = "degree",
                  sets = c("KO", "WT", "Drug", "8h", "24h", "48h"),
                  position="top", name = "") +
    theme_combmatrix(combmatrix.label.text = element_text(size=12),
                     combmatrix.label.extra_spacing = 5)

pdf(paste0("08.Combined_with_boxplot.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p8
dev.off()



# Percentage of votes for n stars for top 12 genres
avg_rating <- tidy_movies %>%
  mutate(Genres_collapsed = sapply(Genres, function(x) paste0(sort(x), collapse="-"))) %>%
  mutate(Genres_collapsed = fct_lump(fct_infreq(as.factor(Genres_collapsed)), n=12)) %>%
  group_by(stars, Genres_collapsed) %>%
  summarize(percent_rating = sum(votes * percent_rating)) %>%
  group_by(Genres_collapsed) %>%
  mutate(percent_rating = percent_rating / sum(percent_rating)) %>%
  arrange(Genres_collapsed)
#> `summarise()` has grouped output by 'stars'. You can override using the
#> `.groups` argument.


# Plot using the combination matrix axis
# the red lines indicate the average rating per genre
p9 <- ggplot(avg_rating, aes(x=Genres_collapsed, y=stars)) +
    geom_tile(aes(fill=percent_rating)) +
    stat_summary_bin(aes(y=percent_rating * stars), fun = sum,  geom="point", 
                     shape="—", color="red", size=6) +
    axis_combmatrix(sep = "-", levels = c("Drama", "Comedy", "Short", 
                    "Documentary", "Action", "Romance", "Animation", "Other")) +
    scale_fill_viridis_c()

pdf(paste0("09.Combined_with_tile.",prefix, ".pdf"),width = 8, height = 4, onefile = FALSE)
p9
dev.off()