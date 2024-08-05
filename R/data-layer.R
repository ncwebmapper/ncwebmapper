#' @name Data-layer
#' @author 
#' Borja Latorre-Garcés \url{http://eead.csic.es/home/staffinfo?Id=215}; Soil and Water, EEAD, CSIC \url{http://www.eead.csic.es}
#' Fergus Reig-Gracia \url{http://fergusreig.es}; Environmental Hydrology, Climate and Human Activity Interactions, Geoenvironmental Processes, IPE, CSIC \url{http://www.ipe.csic.es/hidrologia-ambiental}
#' 
#' @details
#' \tabular{ll}{
#'   Version: \tab 1.0.0\cr
#'   License: \tab GPL version 3 or newer\cr
#' }
#'  
#' @description
#' write data layer

#####################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/> <http://www.gnu.org/licenses/gpl.txt/>.
#####################################################################

#' @import raster
#' @import R.utils
#' @import ncdf4

library(raster)
library(R.utils)
library(ncdf4)
library(terra)

# source("functions.R")

#' write data layer
#' @param file file
#' @param folder folder
#' @param epsg epsg
#' @param maxzoom maxzoom
#' @param timeshift timeshift
#' @param generate_times generate_times
#' @export
#' @examples
#' write_data_layer(file="SPREAD_pen_pcp.nc", folder="pen")
#' write_data_layer(file="SPREAD_bal_pcp.nc", folder="bal", timeshift=7670)
#' write_data_layer(file="SPREAD_can_pcp.nc", folder="can", timeshift=7670)
write_data_layer <- function(file, folder, epsg, maxzoom, timeshift = 0, generate_times)
{
	# open nc
	nc = nc_open(file)

	# read epsg
	if(missing(epsg))
	{
		epsg <- read_epsg(nc)
		if(epsg == 0)
		{
			cat("Error: EPSG not found\n")
			return()
		}
	}

	# read times
	times <- nc$dim[[timePosition(nc)]]$vals
	ntime <- length(times)

	# read spatial dims
	lonflip <- FALSE
	latflip <- FALSE
	dimNames <- returnXYNames(nc)
	nrow  <- nc$dim[[dimNames$Y]]$len
	ncol  <- nc$dim[[dimNames$X]]$len
	lon   <- nc$dim[[dimNames$X]]$vals
	if(lon[1]>lon[length(lon)]){
		lonflip <- TRUE
		lon <- rev(lon)
	}
	lat   <- nc$dim[[dimNames$Y]]$vals
	if(lat[1]>lat[length(lat)]){
		latflip <- TRUE
		lat <- rev(lat)
	}
	dx    <- lon[2] - lon[1]
	dy    <- lat[2] - lat[1]

	# per-session temporary directory
	tempdir <- tempdir(check = TRUE)
	dir.create(tempdir, recursive=TRUE, showWarnings=FALSE)

	# create output folder
	dir.create(file.path(folder, "map"), recursive=TRUE, showWarnings=FALSE)

	# create timeshift folders
	if(timeshift > 0)
	{
		for(i in 1:timeshift)
		{
			dir.create(file.path(folder, "map", i), recursive=TRUE, showWarnings=FALSE)
		}
	}

	# warp to mercator
	r.crs <- raster_3857(nc, epsg)

	# read extent
	map1x <- extent(r.crs)[1]
	map2x <- extent(r.crs)[2]
	map1y <- extent(r.crs)[4]
	map2y <- extent(r.crs)[3]

	# estimate maximum zoom level
	if(missing(maxzoom))
	{
		# estimate zoom level
		maxzoom <- readMaxZoom(r.crs)

		# increase resolution
		maxzoom <- maxzoom + 1
	}

	big_range <- 100
	if(missing(generate_times))
	{
		generate_times <- seq(from=1, to=length(times), by=big_range)
	}

	# progress bar
	pb <- txtProgressBar(style = 3)	

	# for each zoom
	for(zoom in 2:maxzoom)
	{
		# range of tiles
		x1 <- get_tile(map1x, map1y, zoom)
		bounds1 <- tile_bounds(x1[1], x1[2], zoom)
		x2 <- get_tile(map2x, map2y, zoom)
		bounds2 <- tile_bounds(x2[1], x2[2], zoom)

		# raster with pixel id
		if(dimNames$YPos==1){
			index <- array(1:(length(lon)*length(lat)), dim=c(length(lat), length(lon)))
		}else{
			index <- t(array(1:(length(lon)*length(lat)), dim=c(length(lon), length(lat))))
		}
		r <- raster(index[c(nrow:1),])
		extent(r) <- c(lon[1] - dx/2, rev(lon)[1] + dx/2, lat[1] - dy/2, rev(lat)[1] + dy/2)
		crs(r) <- crs(paste0("+init=epsg:", epsg))

		# r_good <- raster(ncol=ncol*2,
		# 									nrow=nrow*2-2,
		# 									crs = CRS("+init=epsg:4326"))
		# extent(r_good) <- c(-180, 180, -90, 90)
		# r <- terra::project(rast(r), rast(r_good), method="near", use_gdal=TRUE) 

		# warp to mercator
		r.ok <- raster(ncol=256*(x2[1]-x1[1]+1), 
					nrow=256*(x2[2]-x1[2]+1), 
					crs = CRS("+init=epsg:3857"))
		extent(r.ok) <- c(floor(bounds1[1]), floor(bounds2[3]),
					floor(bounds2[2]), floor(bounds1[4]))
		r.crs.ok <- terra::project(rast(r), rast(r.ok), method="near", use_gdal=TRUE)

		ptm <- proc.time()[3]
		# read raster
		index <- raster::as.matrix(raster(r.crs.ok))
		range <- big_range
		
		# for each time
		for(time in generate_times)
		{
			# set progress bar
			setTxtProgressBar(pb, time / length(times) * (zoom - 2 + 1) / (maxzoom - 2 + 1))

			if(time + range > length(times)){
				range <- length(times) - time + 1
			}

			# read matrix
			datarange <- ncvar_get(nc, nc$var[[1]]$name, c(1, 1, time), c(-1, -1, range))

			for(t in 0:(range-1)){
				if(range>1){
					data <- datarange[, , t+1]
				}else{
					data <- datarange
				}

				if(lonflip){
					data <- data[dim(data)[1]:1,]
				}
				if(latflip){
					data <- data[, dim(data)[2]:1]
				}

				# warp to mercator
				m <- array(data[index], dim=dim(index))

				# read tiles
				for( j in x1[2]:x2[2] )
				{
					for( i in x1[1]:x2[1] )
					{
						j1 = (x2[2]-j)*256+1
						j2 = (x2[2]-j+1)*256
						i1 = (i-x1[1])*256+1
						i2 = (i-x1[1]+1)*256
						m1 <- m[j1:j2, i1:i2]

						# if some data
						if(sum(is.na(m1)) < 256*256)
						{
							destname = file.path(folder, "map", time+t+timeshift, zoom, i, paste0(x1[2]+x2[2]-j, ".bin.gz"))
							# create output folder
							dir.create(file.path(folder, "map", time+t+timeshift, zoom, i), showWarnings=FALSE, recursive=TRUE)

							# transpose matrix
							# first index in R represents y-axis
							m1 <- t(m1[,])

							# write matrix and gzip
							sdat.name <- paste(tempfile(pattern = "tile", tmpdir = tempdir), "sdat", sep=".")
							f <- file(sdat.name, 'wb')
							writeBin(as.numeric(as.vector(m1)), f, size=4, endian="little")
							close(f)

							# f <- file(sdat.name, 'rb')
							# aux <- matrix(readBin(f, numeric(), size=4, endian = "little", n=256*256), nrow = 256, ncol = 256)
							# close(f)
							gzip(sdat.name, destname=destname, overwrite=TRUE, remove=TRUE)
						}
					}
				}
			}
		}
	}
	# Delete temp folder
	file.remove(rev(list.files(tempdir, full.names = TRUE, all.files = TRUE, recursive = TRUE, include.dirs = TRUE)))
	file.remove(tempdir)
}

#' merge data layers
#' @param folders folders
#' @param folder folder
#' @export
#' @examples
#' merge_data_layer(folders=c("pen", "bal", "can"), folder="merge")
merge_data_layer <- function(folders, folder)
{
	# check layers share time level
	times1 <- sort(list.files(file.path(folders[1], "map")))
	for(x in folders)
	{
		times2 <- sort(list.files(file.path(x, "map")))
		if (all(times1 == times2) != TRUE)
		{
			cat("Error: layers must share time level\n")
			return()
		}
	}

	# per-session temporary directory
	tempdir <- tempdir(check = TRUE)
	dir.create(tempdir, recursive=TRUE, showWarnings=FALSE)

	# read time list
	times <- sort(list.files(file.path(x, "map")))

	# remove time zero
	if(strtoi(times[1]) == 0)
	{
		times <- times[-1]
	}

	# for each time
	for(y in times)
	{
		# read folder list
		list1 <- c()
		# read tile list
		list2 <- c()
		for(x in folders)
		{
			zooms <- list.files(file.path(x, "map", y))
			for(z in zooms)
			{
				lats <- list.files(file.path(x, "map", y, z))
				for(k in lats)
				{
					tiles <- list.files(file.path(x, "map", y, z, k))
					for(tile in tiles)
					{
						list1 <- c(list1, file.path("map", y, z, k))
						list2 <- c(list2, file.path("map", y, z, k, tile))
					}
				}
			}
		}

		# unique folder list
		list1 <- sort(unique(list1))

		# create folders
		for(x in list1)
		{
			dir.create(file.path(folder, x), recursive=TRUE, showWarnings=FALSE)
		}

		# unique tile list
		list2 <- sort(unique(list2))

		# create tiles
		for(x in list2)
		{
			for(y in folders)
			{
				if(file.exists(file.path(y, x)))
				{
					# merge existing files
					if(file.exists(file.path(folder, x)))
					{
						# read matrix
						bin <- gzfile(file.path(folder, x), 'rb')
						m1 <- matrix(readBin(bin, numeric(), size=4, endian = "little", n=256*256), nrow = 256, ncol = 256)
						close(bin)

						# read matrix
						bin <- gzfile(file.path(y, x), 'rb')
						m2 <- matrix(readBin(bin, numeric(), size=4, endian = "little", n=256*256), nrow = 256, ncol = 256)
						close(bin)

						# merge values
						m3 <- m1
						m3[is.na(m1)] <- m2[is.na(m1)]

						# write matrix and gzip
						sdat.name <- paste(tempfile(pattern = "tile", tmpdir = tempdir), "sdat", sep=".")
						f <- file(sdat.name, 'wb')
						writeBin(as.vector(m3), f, size=4, endian="little")
						close(f)
						gzip(sdat.name,
							destname=file.path(folder, x), overwrite=TRUE, remove=TRUE)
					}
					# copy new files
					else
					{
						file.copy(file.path(y, x), file.path(folder, x))
					}
				}
			}		
		}
	}
	# Delete temp folder
	file.remove(rev(list.files(tempdir, full.names = TRUE, all.files = TRUE, recursive = TRUE, include.dirs = TRUE)))
	file.remove(tempdir)
}

# test
#write_data_layer(file="SPREAD_pen_pcp.nc", folder="pen")
#write_data_layer(file="SPREAD_bal_pcp.nc", folder="bal", timeshift=7670)
#write_data_layer(file="SPREAD_can_pcp.nc", folder="can", timeshift=7670)
#merge_data_layer(folders=c("pen", "bal", "can"), folder="merge")

