# Install packages
# install.packages(c("tidyverse", "purrr", "furrr"))

# Load packages
library(tidyverse)
library(rnaturalearth)
library(purrr)
library(furrr)
library(tmap)
library(terra)

# Create land object that we'll use for later
land <- ne_countries(scale = "small")


# BASIC EXAMPLES ----------------------------------------------------------

# `map`: apply a function to each element of a vector
vect <- list(seq(1, 5, 1),
             seq(1, 10, 1),
             seq(1, 20, 1))
map(vect, mean) # the output `map()` is always a list

x <- map_vec(vect, mean)
x

chars <- c("apple", "banapple", "banana")
map(chars, str_detect, pattern = "apple")
map_lgl(chars, str_detect, pattern = "apple")

map_chr(chars, paste0, "_orange")

# `walk` vs `map`
# Use walk when you don't really want a `return` output from your function
# Great when you're reading/writing something (e.g., read_rds, write_rds) or when you're just printing something

chars <- c("apple", "banapple", "banana")
walk(chars, print)

# What should I do if I have multiple inputs to a function?
v1 <- seq(1, 10, 1)
v2 <- seq(11, 20, 1)

pmap(list(v1, v2), sum, na.rm = TRUE)
out <- pmap_int(list(v1, v2), sum, na.rm = TRUE)

# MORE ADVANCED EXAMPLES --------------------------------------------------

# I want to plot three different rasters

plot_raster <- function(x) {

  # Load the file
  ras <- rast(x)

  tm <- tm_shape(ras) +
    tm_raster() +
    tm_shape(land) +
    tm_polygons()

  return(tm)

}

list_files <- list.files("rasters", full.names = TRUE)

plots <- map(list_files, plot_raster)

# I want to save these plots
# Let's edit the function

plot_raster <- function(x) {

  # Load the file
  ras <- rast(x)

  tm <- tm_shape(ras) +
    tm_raster() +
    tm_shape(land) +
    tm_polygons()

  out_name <- basename(x) %>%
    str_split(pattern = "[.]") %>%
    unlist()

  tmap_save(tm, filename = file.path("figures", paste0(out_name[1], ".png")))

}

walk(list_files, plot_raster)

# What if I want to have titles for these but they're different each time?

# Review the list of files
list_files
# Let's make a vector of the titles
titles <- c("Abyssopelagic", "Bathypelagic", "Epipelagic")

# Let's edit the function

plot_raster <- function(x, title) {

  # Load the file
  ras <- rast(x)

  tm <- tm_shape(ras) +
    tm_raster() +
    tm_shape(land) +
    tm_polygons() +
    tm_title(title)

  out_name <- basename(x) %>%
    str_split(pattern = "[.]") %>%
    unlist()

  tmap_save(tm, filename = file.path("figures", paste0(out_name[1], "_with_title", ".png")))

}

pwalk(list(list_files, titles), plot_raster)

# MORE TERRA EXAMPLES -----------------------------------------------------
