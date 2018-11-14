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
#' @import ncdf4
#' @import raster

library(js)
library(sp)
library(ncdf4)
library(raster)

# source("functions.R")

#' write web configuration
#' @param file file nc
#' @param folder folder
#' @param maxZoom maxZoom
#' @param epsg epsg
#' @param dates dates
#' @param formatdates formatdates
#' @param latIni latIni
#' @param lonIni lonIni
#' @param latEnd latEnd
#' @param lonEnd lonEnd
#' @param timeIni timeIni
#' @param timeEnd timeEnd
#' @param varmin varmin
#' @param infoJs infoJs
#' @param legend legend
#' @param write write
#' @export
config_web <- function(file, folder, maxzoom, epsg, dates, formatdates, latIni, lonIni, latEnd, lonEnd, timeIni, timeEnd, varmin, varmax, infoJs, legend="NaN", write=TRUE){

  if(missing(infoJs) || sum(!is.na(infoJs))==0)
  {
    infoJs <- list(mapMinZoom=2, mapMaxZoom=NA, legend=legend, varMin=NA, varMax=NA, levelcsv=NA, times=list(), latM=NA, lonM=NA, latIni=NA, latEnd=NA, lonIni=NA, lonEnd=NA)
  }

  if(!missing(file)){
    # open nc
    nc <- nc_open(file)
    # nc name
    varName <- basename(gsub(".nc", "", file))
  }else{
    varName <- "NaN"
  }

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

  # Márgenes del mapa
  if(missing(latIni) | missing(latEnd) | missing(lonIni) | missing(lonEnd))
  {
    coords <- read_coords(nc, epsg)

    latIni <- min(coords[, "lat"])
    latEnd <- max(coords[, "lat"])
    lonIni <- min(coords[, "lon"])
    lonEnd <- max(coords[, "lon"])
  }
  infoJs$latIni <- latIni
  infoJs$latEnd <- latEnd
  infoJs$lonIni <- lonIni
  infoJs$lonEnd <- lonEnd

  # Centro del mapa
  infoJs$latM <- mean(c(latIni, latEnd))
  infoJs$lonM <- mean(c(lonIni, lonEnd))

  # Tiempos disponibles
  if(!missing(timeIni) & !missing(timeEnd)){
    times.write <- seq(as.Date(timeIni), as.Date(timeEnd), by=1)
    if(!missing(formatdates)){
      times.write <- format(times.write, formatdates)
    }
  }else{
    if(missing(dates))
    {
      if(!missing(formatdates)){
        times.write <- read_times(nc, formatdates)
      }else{
        times.write <- read_times(nc)
      }  
    }else{
      times.write <- dates
    }
  }

  if(missing(varmin) | missing(varmax)) {
    varMinMax = readMinMax(nc)
    varmin = varMinMax$min
    varmax = varMinMax$max
  }else{
    if(!missing(file)){
      varmin = array(varmin, dim=length(nc$dim[["time"]]$vals))
      varmax = array(varmax, dim=length(nc$dim[["time"]]$vals))
    }
  }
  # Delete Inf
  aux = varmin == Inf | varmin == -Inf | varmax == Inf | varmax == -Inf
  infoJs$varmin[[varName]] = varmin[!aux]
  infoJs$varmax[[varName]] = varmax[!aux]
  infoJs$times[[varName]] <- times.write[!aux]

  # estimate maximum zoom level
  if(missing(maxzoom))
  {
    # warp to mercator
    r.crs <- raster_3857(nc, epsg)

    # estimate zoom level
    maxzoom <- readMaxZoom(r.crs)
  }
  infoJs$mapMaxZoom <- maxzoom

  # increase resolution 16 times (2^4)
  infoJs$levelCsv <- maxzoom + 3

  varNames <- varName
  varTitle <- varName
  legendTitle <- "Values"

  if(write){
    writeJs(folder, infoJs, varNames, varTitle, legendTitle)
  }

  return(infoJs)
}

#' 
#' @param name name
#' @param value value
#' @param type type
#' @return None
arrayRtojs <- function(name, value, type="character"){
  times = ""
  t = names(value)[1]
  for (t in names(value)){
    if(times!=""){
      times <- paste0(times, ", ") 
    }
    if(type=="character"){
      sep <- "'"
      values <- value[[t]]
    }else{
      sep <- ""
      values <- round(value[[t]], digits=3)
    }
    times <- paste0(times, "'", t, "'", ":" , " ", "[", sep, paste(values, collapse=paste0(sep, ",", sep)), sep, "]")
  }
  times.write <- paste0("var ", name, " = {", times, "};\n")
  return(times.write)
}

#' 
#' @param value value
#' @return None
#' "Temperature-based":["bio4_year", {"cd":["cd_month","cd_season","cd_year"]}, "bio5_year"],"Bioclimatic":["bio4_year", "bio5_year"]
listRtojs_ <- function(value){
  times = ""
  t = names(value)[1]
  for (t in names(value)){
    if(times!=""){
      times <- paste0(times, ", ") 
    }
    v = names(value[[t]])[1]
    times2 = ""
    for (v in names(value[[t]])){
      if(times2!=""){
        times2 <- paste0(times2, ", ") 
      }
      if(length(value[[t]][[v]])>1){
        text = paste(value[[t]][[v]], collapse=paste0("'", ",", "'"))
        text = paste0("['", text, "']")
        times2 <- paste0(times2, "{", "'", v, "'", ":" , " ", text, "}")
      }else{
        times2 <- paste0(times2, "'", value[[t]][[v]], "'")
      }
    }
    times <- paste0(times, "'", t, "'", ":" , " ", "[", times2, "]")
  }
  return(times)
}

#' 
#' @param name name
#' @param value value
#' @return None
#' varNames={"Temperature-based":["bio5_year"], "cd":["cd_month", "cd_season", "cd_year"]};
#' varNames={"Temperature-based":["bio4_year", {"cd":["cd_month","cd_season","cd_year"]}, "bio5_year"],"Bioclimatic":["bio4_year", "bio5_year"]};
listRtojs <- function(name, value){
  times <- listRtojs_(value)
  times.write <- paste0("var ", name, " = {", times, "};\n")
  return(times.write)
}

generaltojs <- function(name, value){
  times <- ""

  i <- 1
  for (i in 1:dim(value)[1]){
    if(times!=""){
      times <- paste0(times, ", ") 
    }
    text <- paste0("'", paste(value[i, ], collapse="', '"), "'")
    times <- paste0(times, rownames(value)[i], ":", " ", "[", text, "]")
  }

  times.write <- paste0("var ", name, " = {", times, "};\n")
  return(times.write)
}

#' 
#' @param folder folder
#' @param infoJs infoJs
#' @param varNames varNames
#' @param varTitle varTitle
#' @param legendTitle legendTitle
#' @param title title
#' @return None
writeJs <- function(folder, infoJs, varNames, varTitle, legendTitle, menuNames, generalInformation, generalInformationNames, title="Map web"){
  file <-  file.path(folder, "times.js")

  if(missing(menuNames)){
    menuNames = varTitle
  }

  text.js <- ""

  text.js <- paste(text.js, paste0("var center = new L.LatLng(", infoJs$latM, ", ", infoJs$lonM, ");\n"))

  lat_lon.write <- paste0("var marginBounds = L.latLngBounds(L.latLng(", infoJs$latIni, ", ", infoJs$lonIni, "), L.latLng(", infoJs$latEnd, ", ", infoJs$lonEnd, "));\n")
  text.js <- paste(text.js, lat_lon.write)
 
  text.js <- paste(text.js, arrayRtojs(name="times", value=infoJs$times))

  # Niveles de zoom
  text.js <- paste(text.js, paste0("var mapMinZoom = ", infoJs$mapMinZoom, ";\n"))
  text.js <- paste(text.js, paste0("var mapMaxZoom = ", infoJs$mapMaxZoom, ";\n"))
  text.js <- paste(text.js, paste0("var legend = ", infoJs$legend, ";\n"))
  text.js <- paste(text.js, arrayRtojs(name="varMin", value=infoJs$varmin, type="numeric"))
  text.js <- paste(text.js, arrayRtojs(name="varMax", value=infoJs$varmax, type="numeric"))
  text.js <- paste(text.js, paste0("var levelcsv = ", infoJs$levelCsv, ";\n"))
  
  text.js <- paste(text.js, paste0("var title = '", title, "';\n"))

  text.js <- paste(text.js, listRtojs(name="varNames", value=varNames))
  text.js <- paste(text.js, arrayRtojs(name="varTitle", value=varTitle))

  if(class(legendTitle)=="list"){
    text.js <- paste(text.js, arrayRtojs(name="legendTitle", value=legendTitle))
  }else{
    text.js <- paste(text.js, paste0("var legendTitle = {NaN:['", legendTitle, "']};\n"))
  }
  text.js <- paste(text.js, arrayRtojs(name="menuNames", value=menuNames))
  if(!missing(generalInformation)){
    text.js <- paste(text.js, generaltojs(name="generalInformation", value=generalInformation))
  }
  if(!missing(generalInformation)){
    text.js <- paste(text.js, paste0("var generalInformationNames = ", "[", "'", paste(generalInformationNames, collapse="', '"), "'", "]", ";\n"))
  }
  text.js <- uglify_optimize(text.js)

  write(text.js, file=file, append = FALSE)
}

