#' @name Config-web
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
#' write web configuration

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

#' @import js
#' @import sp

library(js)
library(sp)

# source("functions.R")

#' write web configuration
#' @param folder folder
#' @param maxZoom maxZoom
#' @param latIni latIni
#' @param lonIni lonIni
#' @param latEnd latEnd
#' @param lonEnd lonEnd
#' @param timeIni timeIni
#' @param timeEnd timeEnd
#' @export
config_web <- function(file, folder, maxzoom, epsg, dates, formatdates, latIni, lonIni, latEnd, lonEnd, timeIni, timeEnd, varmin=0, varmax=100, legend="NaN"){
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

  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  file <-  file.path(folder, "times.js")
  text.js <- ""
  latM <- lonM <- 0
  # Márgenes del mapa
  if(missing(latIni) | missing(latEnd) | missing(lonIni) | missing(lonEnd))
  {
    coords <- read_coords(nc, epsg)

    latIni <- min(coords[, "lat"])
    latEnd <- max(coords[, "lat"])
    lonIni <- min(coords[, "lon"])
    lonEnd <- max(coords[, "lon"])
  }
  lat_lon.write <- paste0("var marginBounds = L.latLngBounds(L.latLng(", latIni, ", ", lonIni, "), L.latLng(", latEnd, ", ", lonEnd, "));\n")
  text.js <- paste(text.js, lat_lon.write)

  latM <- mean(c(latIni, latEnd))
  lonM <- mean(c(lonIni, lonEnd))

  # Centro del mapa
  text.js <- paste(text.js, paste0("var center = new L.LatLng(", latM, ", ", lonM, ");\n"))

  # Tiempos disponibles
  if(!missing(timeIni) & !missing(timeEnd)){
    times.write <- seq(as.Date(timeIni), as.Date(timeEnd), by=1)
    if(!missing(formatdates)){
      times.write <- format(times.write, formatdates)
    }
  }else{
    if(missing(dates))
    {
      times.write <- read_times(nc, formatdates)
    }else{
      times.write <- dates
    }
  }
  times.write <- paste0("var times = ['", paste(times.write, collapse="','"), "'];\n") 
  text.js <- paste(text.js, times.write)

  # estimate maximum zoom level
  if(missing(maxzoom))
  {
    # warp to mercator
    r.crs <- raster_3857(nc, epsg)

    # estimate zoom level
    maxzoom <- readMaxZoom(r.crs)
  }

  # increase resolution 16 times (2^4)
  levelCsv <- maxzoom + 3

  # Niveles de zoom
  text.js <- paste(text.js, paste0("var mapMinZoom = ", 2, ";\n"))
  text.js <- paste(text.js, paste0("var mapMaxZoom = ", maxzoom, ";\n"))
  text.js <- paste(text.js, paste0("var legend = ", "NaN", ";\n"))
  text.js <- paste(text.js, paste0("var varMin = ", varmin, ";\n"))
  text.js <- paste(text.js, paste0("var varMax = ", varmax, ";\n"))
  text.js <- paste(text.js, paste0("var levelcsv = ", levelCsv, ";\n"))
  text.js <- uglify_optimize(text.js)

  write(text.js, file=file, append = FALSE)
}
