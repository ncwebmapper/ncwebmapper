#' @name Csv-layer
#' @author 
#' Borja Latorre Garcés \url{http://eead.csic.es/home/staffinfo?Id=215}; Soil and Water, EEAD, CSIC \url{http://www.eead.csic.es}
#' Fergus Reig Gracia \url{http://fergusreig.es}; Environmental Hydrology, Climate and Human Activity Interactions, Geoenvironmental Processes, IPE, CSIC \url{http://www.ipe.csic.es/hidrologia-ambiental}
#' 
#' @details
#' \tabular{ll}{
#'   Version: \tab 1.0.0\cr
#'   License: \tab GPL version 3 or newer\cr
#' }
#'  
#' @description
#' write csv layer

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
#' @import sp
#' @import ncdf4

library(raster)
library(R.utils)
library(sp)
library(ncdf4)

# source("functions.R")

#' draw raster date
#' @param nc nc
#' @param date date
draw_raster_date <- function(nc, date){
	# read times
	times <- nc$dim[[timePosition(nc)]]$vals
	# read spatial dims
	dimNames <- returnXYNames(nc)
	nrow  <- nc$dim[[dimNames$Y]]$len
	lon   <- nc$dim[[dimNames$X]]$vals
	lat   <- nc$dim[[dimNames$Y]]$vals
	dx    <- lon[2] - lon[1]
	dy    <- lat[2] - lat[1]

	times.t <- as.Date(times, origin="1949-12-31")

	if(missing(date)){
		t <- 1
	}else{
		# Ej. date <- "1975-10-20" 
		t <- which(times.t==date)
	}
	index <- ncvar_get(nc, nc$var[[1]]$name, c(1, 1, t), c(-1, -1, 1))
	index <- index[c(nrow:1), ]
	r <- raster(index)
	extent(r) <- c(lon[1] - dx/2, rev(lon)[1] + dx/2, lat[1] - dy/2, rev(lat)[1] + dy/2)
	crs(r) <- crs(paste0("+init=epsg:", epsg))
	dir.create("image", recursive=TRUE, showWarnings=FALSE)
	png(filename=file.path("image", paste(times.t[t], "map.png", sep="_")), width=1024, height=800)
	plot(r)
	dev.off()
}

#' write csv query layer
#' @param file file
#' @param folder folder
#' @param epsg epsg
#' @param zoom zoom
#' @export
#' @examples
#' write_csv_layer(file="SPREAD_pen_pcp.nc", folder="pen")
#' write_csv_layer(file="SPREAD_bal_pcp.nc", folder="bal")
#' write_csv_layer(file="SPREAD_can_pcp.nc", folder="can")
write_csv_layer <- function(file, folder, epsg, zoom)
{
	# per-session temporary directory
	tempdir <- tempdir()
	dir.create(tempdir, recursive=TRUE, showWarnings=FALSE)
	
	# open nc
	nc <- nc_open(file)

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
	dimNames <- returnXYNames(nc)
	nrow  <- nc$dim[[dimNames$Y]]$len
	ncol  <- nc$dim[[dimNames$X]]$len
	lon   <- nc$dim[[dimNames$X]]$vals
	if(lon[1]>lon[length(lon)]){
		lon <- rev(lon)
	}
	lat   <- nc$dim[[dimNames$Y]]$vals
	if(lat[1]>lat[length(lat)]){
		lat <- rev(lat)
	}
	dx    <- lon[2] - lon[1]
	dy    <- lat[2] - lat[1]

	index <- t(array(c(1:(nrow*ncol)), c(ncol, nrow)))
	for(y in c(1:nrow)){		
		if(dimNames$YPos==1){
			matrix <- !is.na(ncvar_get(nc, nc$var[[1]]$name, c(y, 1, 1), c(1, -1, -1)))
		}else{
			matrix <- !is.na(ncvar_get(nc, nc$var[[1]]$name, c(1, y, 1), c(-1, 1, -1)))
		}
		index[y, apply(matrix, c(1), sum)==0] <- 0
	}

	# create output folder
	dir.create(file.path(folder, "map", 0), recursive=TRUE, showWarnings=FALSE)

	# create raster
	r <- raster(index[c(nrow:1),])
	extent(r) <- c(lon[1] - dx/2, rev(lon)[1] + dx/2, lat[1] - dy/2, rev(lat)[1] + dy/2)
	crs(r) <- crs(paste0("+init=epsg:", epsg))
	r.crs <- projectRaster(from=r, method="ngb", crs=CRS(paste0("+init=epsg:", "3857")))

	# estimate zoom level
	if(missing(zoom))
	{
		zoom <- readMaxZoom(r.crs)
	}
	
	# increase resolution 16 times (2^4)
	zoom <- zoom + 4

	# pixel size
	dx <- 20037508.343 * 2 / 2 ^ zoom / 256

	map1x <- extent(r.crs)[1]
	map2x <- extent(r.crs)[2]
	map1y <- extent(r.crs)[4]
	map2y <- extent(r.crs)[3]

	# range of tiles
	x1 <- get_tile(map1x, map1y, zoom)
	bounds1 <- tile_bounds(x1[1], x1[2], zoom)
	x2 <- get_tile(map2x, map2y, zoom)
	bounds2 <- tile_bounds(x2[1], x2[2], zoom)

	#warp to mercator
	r.ok <- raster(ncol=256*(x2[1]-x1[1]+1), 
				nrow=256*(x2[2]-x1[2]+1), 
				crs = CRS("+init=epsg:3857"))
	extent(r.ok) <- c(floor(bounds1[1]), floor(bounds2[3]),
				floor(bounds2[2]), floor(bounds1[4]))
	r.crs.ok <- projectRaster(from=r, to=r.ok, method="ngb")

	# read raster
	m <- raster::as.matrix(r.crs.ok)
	m[is.na(m)] <- 0

	# read tiles
	for( j in x1[2]:x2[2] )
	{
		for( i in x1[1]:x2[1] )
		{
			j1 <- (x2[2]-j)*256+1
			j2 <- (x2[2]-j+1)*256
			i1 <- (i-x1[1])*256+1
			i2 <- (i-x1[1]+1)*256
			m1 <- m[j1:j2, i1:i2]

			# if some data
			if(sum(m1 == 0) < 256*256)
			{
				destname = file.path(folder, "map", 0, zoom, i, paste0(x1[2]+x2[2]-j, ".bin.gz"))
				# create output folder
				dir.create(file.path(folder, "map", 0, zoom, i), showWarnings=FALSE, recursive=TRUE)

				# transpose matrix
				# first index in R represents y-axis
				m1 <- t(m1[,])

				# write matrix and gzip
				sdat.name <- paste(tempfile(pattern = "tile", tmpdir = tempdir), "sdat", sep=".")
				f <- file(sdat.name, 'wb')
				writeBin(as.integer(as.vector(m1)), f, size=4L, endian="little")
				close(f)
				gzip(sdat.name, destname=destname, overwrite=TRUE, remove=TRUE)
			}
		}
	}

	nc_close(nc)
}

#' merge csv layers
#' transform index values so do not overlap
#' @param folders folders
#' @param folder folder
#' @export
#' @examples
#' merge_csv_layer(folders=c("pen", "bal", "can"), folder="merge")
merge_csv_layer <- function(folders, folder)
{
	# per-session temporary directory
	tempdir <- tempdir()

	# check layers share zoom level
	zoom <- strtoi(list.files(file.path(folders[1], "map", 0))[1])
	for(x in folders)
	{
		if (strtoi(list.files(file.path(x, "map", 0))[1]) != zoom)
		{
			cat("Error: layers must share zoom level\n")
			return()
		}
	}

	# how much to add to each layer
	max <- c(0) # first layer remains unchanged

	# read index values	in each layer to get the maximum
	for(x in folders)
	{
		i <- 0
		subfolders <- list.files(file.path(x, "map", 0, zoom))
		for(y in subfolders)
		{
			files = list.files(file.path(x, "map", 0, zoom, y))
			for(z in files)
			{
				bin <- gzfile(file.path(x, "map", 0, zoom, y, z), 'rb')
				m <- matrix(readBin(bin, integer(), size=4, endian = "little", n=256*256), nrow = 256, ncol = 256)
				if(max(m) > i)
				{
					i <- max(m)
				}
				close(bin)
			}
		}

		# accumulate maximum values
		max <- c(max, i + tail(max, n=1))
	}

	# modify index values in each layer
	for(x in folders)
	{
		subfolders = list.files(file.path(x, "map", 0, zoom))
		for(y in subfolders)
		{
			files = list.files(file.path(x, "map", 0, zoom, y))
			for(z in files)
			{
				# read matrix
				bin <- gzfile(file.path(x, "map", 0, zoom, y, z), 'rb')
				m <- matrix(readBin(bin, integer(), size=4, endian = "little", n=256*256), nrow = 256, ncol = 256)
				close(bin)

				# sum previous maximum value
				m[m==0] <- NA
				m1 <- m + max[1]
				m1[is.na(m1)] <- 0

				# write matrix and gzip
				sdat.name = paste(tempfile(pattern = "tile", tmpdir = tempdir), "sdat", sep=".")
				f <- file(sdat.name, 'wb')
				writeBin(as.integer(as.vector(m1)), f, size=4L, endian="little")
				close(f)
				gzip(sdat.name,
					destname=file.path(folder, "map", 0, zoom, y, z), overwrite=TRUE, remove=TRUE)
			}
		}

		# remove first element to process next
		max <- max[-1]
	}
}

# test
#write_csv_layer(file="SPREAD_pen_pcp.nc", folder="pen")
#write_csv_layer(file="SPREAD_bal_pcp.nc", folder="bal")
#write_csv_layer(file="SPREAD_can_pcp.nc", folder="can")
#merge_csv_layer(folders=c("pen", "bal", "can"), folder="merge")

