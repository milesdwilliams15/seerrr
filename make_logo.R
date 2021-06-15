# Make seerrr package logo

library(hexSticker)
library(UCSCXenaTools)
library(tidyverse)

dt <-
  tibble(
    x = c(0, 0, 0, 0),
    y = c(0, 0.5, 1, 1.5)
  )
p <-
  ggplot(dt) +
  aes(x, y) +
  geom_point(
    col = c("white", "green", "lightblue", "white"),
    shape = c(1, 17, 19, 1),
    size = c(0, 20, 20, 0)
  ) +
  labs(
    x = NULL,
    y = NULL
  ) +
  theme_transparent() +
  theme(
    axis.ticks = element_blank(),
    axis.text = element_blank()
  )

sticker(
  p,
  package = "seerrr",
  p_size = 42,
  s_x = 1,
  s_y=1,
  s_width=1.5,
  s_height = 1.5,
  p_x = 1,
  p_y = 1,
  p_color = "darkgreen",
  h_fill = "darkgrey",
  h_color = "darkgreen",
  url = "https://github.com/milesdwilliams15/seerrr",
  filename = "inst/logo.png"
)
