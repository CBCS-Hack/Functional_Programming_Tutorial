# Install packages
# install.packages(c("tidyverse", "purrr", "furrr", "rnaturalearth", "tmap", "terra"))

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

# combining rasters

load_rast <- function(x, name) {

  ras <- rast(x)
  names(ras) <- name
  return(ras)

}

# Review list_files
list_files

# Let's make a string of names
names <- c("abyssopelagic", "bathypelagic", "epipelagic")

# Let's load them
loaded <- pmap(list(list_files, names), load_rast)

# Let's concatenate (or layer) these rasters
conc <- loaded %>%
  reduce(c) # reduce is really powerful and you can use different functions like bind_rows, bind_cols depending on your intended functionality

# check if it's doing what you want it to do
plot(conc) # looks about right :)

# Now let's try to do some terra stats
rast_stats <- function(x) {

  # Load the file
  ras <- rast(x)

  mean_ras <- app(ras, fun = "mean", na.rm = TRUE)
  mean_time <- global(ras, fun = "mean", na.rm = TRUE)

  return(list(mean_ras = mean_ras,
              mean_time = mean_time)) # returning two outputs

}

list_files <- list.files("climate", full.names = TRUE)

stats <- map(list_files, rast_stats)

# let's 'pluck' the data that we want
# let's say we want to plot `mean_ras` but only of the first model
plt <- pluck(stats, 1, 1) # same as stats[[1]][[1]] or stats[[1]]$mean_ras
tm_shape(plt) +
  tm_raster("mean") # we're looking at mean temperature globally :)

# let's say we want to print `mean_time` of the second model
st <- pluck(stats, 2, 2) # same as stats[[2]][[2]] or stats[[2]]$mean_time
head(st) # we're looking at mean monthly temperatures across all of the cells


# FURRR  ------------------------------------------------------------------

# I won't go into too much detail with furrr, but it's functionality adds onto `purrr`s and increases its power using `parallel`
# If you are working on a lot of big data sets repetitively, then furrr is for you!

# Because we're working on smaller data, we can't really show the functionality of `furrr`, but the syntax is similar to `purrr`

# Just as an example
# DO NOT RUN because it won't work :)
w <- parallelly::availableCores(method = "system", omit = 2)

plan(future::multisession, workers = w)
future_walk(netCDFs, change_lvlbounds)
plan(future::sequential)
