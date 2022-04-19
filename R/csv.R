#' @name Csv
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
#' write csv 

#####################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be raster_3857,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/> <http://www.gnu.org/licenses/gpl.txt/>.
#####################################################################

#' @import zip
#' @import sp
#' @import ncdf4

library(zip)
library(sp)
library(ncdf4)

# source("functions.R")

#' write csv files in a folder
#' @param file  file
#' @param folder folder
#' @param epsg epsg
#' @param dates dates
#' @param formatdates formatdates
#' @export
#' @examples
#' write_csv(file="SPREAD_pen_pcp.nc", folder="pen")
#' write_csv(file="SPREAD_bal_pcp.nc", folder="bal")
#' write_csv(file="SPREAD_can_pcp.nc", folder="can")
write_csv <- function(file, folder, epsg, dates, formatdates)
{
	# open nc
	nc = nc_open(file)

	# read epsg
	if(missing(epsg))
	{
		epsg = read_epsg(nc)
		if(epsg == 0)
		{
			cat("Error: EPSG not found\n")
			return()
		}
	}

	# read times
	if(missing(dates))
	{
		# times <- nc$dim[[timePosition(nc)]]$vals
		# units <- strsplit(nc$dim[[timePosition(nc)]]$units, " ")[[1]]
		# origin <- as.Date(units[which(units=="since")+1]) #length(units)
		# times <- as.Date(times, origin=origin)
		# if(!missing(formatdates)){
		# 	times = format(times, formatdates)
		# }
		if(!missing(formatdates)){
			times <- read_times(nc, formatdates)
		}else{
			times <- read_times(nc)		
		}
	}else{
		times <- dates
	}
	ntime <- length(times)
	if(ntime <= 1){
		nc_close(nc)
		return()
	}

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
	coords <- read_coords(nc, epsg)
	coords <- format(round(coords, 6), nsmall=6) # round to six decimal places

	# create output folder
	dir.create(file.path(folder, "csv"), recursive=TRUE, showWarnings=FALSE)

	# progress bar
	pb <- txtProgressBar(style = 3)

	# point id
	id <- 1

	# write csv files
	for(j in c(1:nrow))
	{
		if(dimNames$YPos==1){
			matrix <- ncvar_get(nc, nc$var[[1]]$name, c(j, 1, 1), c(1, -1, -1))
		}else{
			matrix <- ncvar_get(nc, nc$var[[1]]$name, c(1, j, 1), c(-1, 1, -1))
		}
		for(i in c(1:ncol))
		{
			# if some data
			if(sum(is.na(matrix[i,])) < ntime)
			{ #j = 1; i = 3; print(paste(j, " ", i))
				# three-level folder tree
				# print(paste(i, j))
				dir.create(file.path(folder, "csv", floor(id/100)%%10,
					floor(id/10)%%10, id%%10), recursive=TRUE, showWarnings=FALSE)

				# output table
				table <- array(numeric(), c(ntime, 2))
				colnames(table) <- c(nc$dim[[timePosition(nc)]]$units, nc$var[[1]]$name)
				table[,1] <- format(times)
				table[,2] <- signif(matrix[i,], digits = 5)
				table[table=="NaN"] <- NA
				# write csv and zip
				dir <- file.path(folder, "csv", floor(id/100)%%10, floor(id/10)%%10, id%%10)
				# zip.file <- file.path(paste0(id, ".zip"))
				zip.file <- trimws(sprintf("%10d%s", id, ".zip"))
				file <- file.path(paste0(coords[id,1], "_", coords[id,2], ".csv"))
				write.table(table, file=file, row.names=FALSE, sep=";", dec=",", quote=FALSE) #sep=",", dec=".")
				if (file.exists(zip.file)) file.remove(zip.file)
				zip(zip.file, c(file))
				file.remove(file)
				file.rename(zip.file, file.path(dir, zip.file))
				# set progress bar
				setTxtProgressBar(pb, (i + j * ncol) / (ncol * nrow))			
				# print(paste(i, j, id, zip.file))	 #305 128 
			}
			# increase point id
			id <- id + 1
		}
	}
	nc_close(nc)
}

#' merge csv folders
#' transform file names so do not overlap
#' @param folders folders
#' @param folder folder
#' @export
#' @examples
#' merge_csv(folders=c("pen", "bal", "can"), folder="merge")
merge_csv <- function(folders, folder)
{
	# how much to add to each layer
	max <- c(0) # first layer remains unchanged

	# read index values	in each layer to get the maximum
	for(x in folders)
	{
		i <- 0
		tree1 <- list.files(file.path(x, "csv"))
		for(y in tree1)
		{
			tree2 <- list.files(file.path(x, "csv", y))
			for(z in tree2)
			{
				tree3 <- list.files(file.path(x, "csv", y, z))
				for(u in tree3)
				{
					files <- list.files(file.path(x, "csv", y, z, u))
					for(file in files)
					{
						j <- strtoi(gsub("[A-z\\.]", "", file))

						if(j > i)
						{
							i <- j
						}
					}
				}
			}
		}

		# accumulate maximum values
		max <- c(max, i + tail(max, n=1))
	}


	# modify index values in each layer
	for(x in folders)
	{
		tree1 <- list.files(file.path(x, "csv"))
		for(y in tree1)
		{
			tree2 <- list.files(file.path(x, "csv", y))
			for(z in tree2)
			{
				tree3 <- list.files(file.path(x, "csv", y, z))
				for(u in tree3)
				{
					files <- list.files(file.path(x, "csv", y, z, u))
					for(file in files)
					{
						j <- strtoi(gsub("[A-z\\.]", "", file))
						k <- j + max[1]

						# three-level folder tree
						dir.create(file.path(folder, "csv", floor(k/100)%%10,
							floor(k/10)%%10, k%%10), recursive=TRUE, showWarnings=FALSE)

						# copy csv
						file1 <- file.path(x, "csv", floor(j/100)%%10,
						floor(j/10)%%10, j%%10, paste0(j, ".zip"))
						file2 <- file.path(folder, "csv", floor(k/100)%%10,
						floor(k/10)%%10, k%%10, paste0(k, ".zip"))
						file.copy(file1, file2)
					}
				}
			}
		}

		# remove first element to process next
		max <- max[-1]
	}
}

# test
#write_csv(file="SPREAD_pen_pcp.nc", folder="pen")
#write_csv(file="SPREAD_bal_pcp.nc", folder="bal")
#write_csv(file="SPREAD_can_pcp.nc", folder="can")
#merge_csv(folders=c("pen", "bal", "can"), folder="merge")

