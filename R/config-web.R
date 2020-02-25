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
#' @param varName varName
#' @param write true si se escribe el fichero js al terminar la ejecución; implica que la web solo muestra un "mapa"; en otro caso se supone que la web tendrá más de un mapa
#' @export
config_web <- function(file, folder, maxzoom, epsg, dates, formatdates, latIni, lonIni, latEnd, lonEnd, timeIni, timeEnd, varmin, varmax, varName, infoJs = NA, legend="NaN", write=TRUE){

  if(missing(infoJs) || sum(!is.na(infoJs))==0)
  {
    infoJs <- list(mapMinZoom=2, mapMaxZoom=NA, legend=legend, varMin=NA, varMax=NA, levelcsv=NA, times=list(), latM=NA, lonM=NA, latIni=NA, latEnd=NA, lonIni=NA, lonEnd=NA)
  }

  if(!missing(file)){
    # open nc
    nc <- nc_open(file)
  }

  if(missing(varName)){
    if(!missing(file)){
      # nc name
      varName <- basename(gsub(".nc", "", file))
    }
    if(missing(file) | write){
      varName <- "NaN"
    }
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

  if(!is.na(infoJs$latIni) & !is.na(infoJs$latEnd) & !is.na(infoJs$lonIni) & !is.na(infoJs$lonEnd)){
    latIni <- min(latIni, infoJs$latIni)
    latEnd <- max(latEnd, infoJs$latEnd)
    lonIni <- min(lonIni, infoJs$lonIni)
    lonEnd <- max(lonEnd, infoJs$lonEnd)
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

  varmin[aux] = 0
  varmax[aux] = 100
  positions = 1:length(varmin)

  if(!is.null(infoJs$times[[varName]])){
    if(length(times.write)==sum(times.write%in%infoJs$times[[varName]])){
      positions = match(times.write, infoJs$times[[varName]])
      times.write = infoJs$times[[varName]]
    }
  }

  if(!is.null(infoJs$varmin[[varName]]) & !is.null(infoJs$varmax[[varName]])){
    varmin = minFusion(min1=varmin, min2=infoJs$varmin[[varName]], positions=positions)
    varmax = maxFusion(varmax, infoJs$varmax[[varName]], positions)
  }

  infoJs$varmin[[varName]] = varmin
  infoJs$varmax[[varName]] = varmax
  infoJs$times[[varName]] <- times.write

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

  if(write){
    writeJs(folder, infoJs)
  }

  if(!missing(file)){
    # open nc
    nc_close(nc)
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
#' @param name name
#' @param value value
#' @return None
#' varNames={"Temperature-based":["bio5_year"], "cd":["cd_month", "cd_season", "cd_year"]};
#' varNames={"Temperature-based":["bio4_year", {"cd":["cd_month","cd_season","cd_year"]}, "bio5_year"],"Bioclimatic":["bio4_year", "bio5_year"]};
listRtojs <- function(name, value){
  library(jsonlite)
  times <- toJSON(value)
  times.write <- paste0("var ", name, " = ", times, ";\n")
  return(times.write)
}

generaltojs <- function(name, value.ori){
  max <- dim(value.ori)[1]
  times <- ""

  value <-  gsub("\\", "\\\\", value.ori, fixed=TRUE)
  value <-  gsub("'", "\\'", value, fixed=TRUE)
  for (i in 1:max){
    if(times!=""){
      times <- paste0(times, ", ")
    }
    text <- paste0("'", paste(value[i, ], collapse="', '"), "'")
    times <- paste0(times, rownames(value)[i], ":", " ", "[", text, "]")
  }

  times.write <- paste0("var ", name, " = {", times, "};\n")
  # uglify_optimize(times.write)
  return(times.write)
}

#' 
#' @param folder folder
#' @param infoJs infoJs
#' @param varNames varNames
#' @param varTitle varTitle
#' @param legendTitle legendTitle
#' @param menuNames menuNames
#' @param generalInformation generalInformation
#' @param generalInformationNames generalInformationNames
#' @param extensionDownloadFile extensionDownloadFile
#' @param title title
#' @param showDonwloadCoordinates show CSV download menu and graph display
#' @return text written in the file 
writeJs <- function(folder, infoJs, varNames, varTitle, legendTitle, menuNames, generalInformation, generalInformationNames, extensionDownloadFile = "nc", title="Map web", showDonwloadCoordinates=TRUE){
  file <-  file.path(folder, "times.js")

  if(missing(varTitle)){
    if(length(infoJs$varmin)>1){
      varTitle = names(infoJs$varmin)
      names(varTitle) = names(infoJs$varmin)
    }else{
      varTitle = names(infoJs$varmin)
    }
  }

  if(missing(varNames)){
    # Ej. 
    # varNames = list("Temperature-based"=list("cd"=c("cd_month", "cd_season", "cd_year"), "gtx"=c("gtx_year"), "ptg"=c("ptg_year")), "Precipitation-based"=list("mfi"=c("mfi_year")), "Bioclimatic"=list("bio4" = c("bio4_year"), "bio5" = c("bio5_year")))
    # if(length(infoJs$varmin)>1){
    #   varNames = list("Menu1"=list("SubMenu1"=names(infoJs$varmin)[(1:length(names(infoJs$varmin))%%2)==0]), "Menu2"=list("SubMenu1"=names(infoJs$varmin)[(1:length(names(infoJs$varmin))%%2)!=0]))
    #   # varNames = list("Menu1"=names(infoJs$varmin)[(1:length(names(infoJs$varmin))%%2)==0], "Menu2"=names(infoJs$varmin)[(1:length(names(infoJs$varmin))%%2)!=0])
    # }else{
    #   varNames = names(infoJs$varmin)
    # }
    varNames = names(infoJs$varmin)
  }

  if(missing(menuNames)){
    menuNames = varTitle
  }

  if(missing(legendTitle)){
    legendTitle = "Legend"
  }

  text.js <- ""

  text.js <- paste(text.js, paste0("var center = new L.LatLng(", infoJs$latM, ", ", infoJs$lonM, ");\n"))

  lat_lon.write <- paste0("var marginBounds = L.latLngBounds(L.latLng(", infoJs$latIni, ", ", infoJs$lonIni, "), L.latLng(", infoJs$latEnd, ", ", infoJs$lonEnd, "));\n")
  text.js <- paste(text.js, lat_lon.write)
 
  text.js <- paste(text.js, arrayRtojs(name="times", value=infoJs$times))
  text.js <- paste0(text.js, " var showDonwloadCoordinates = ", tolower(showDonwloadCoordinates), ";\n")

  # Niveles de zoom
  text.js <- paste(text.js, paste0("var mapMinZoom = ", infoJs$mapMinZoom, ";\n"))
  text.js <- paste(text.js, paste0("var mapMaxZoom = ", infoJs$mapMaxZoom, ";\n"))
  text.js <- paste(text.js, paste0("var legend = ", infoJs$legend, ";\n"))
  text.js <- paste(text.js, arrayRtojs(name="varMin", value=infoJs$varmin, type="numeric"))
  text.js <- paste(text.js, arrayRtojs(name="varMax", value=infoJs$varmax, type="numeric"))
  text.js <- paste(text.js, paste0("var levelcsv = ", infoJs$levelCsv, ";\n"))
  
  text.js <- paste(text.js, paste0("var title = '", title, "';\n"))
  if(class(varNames)!="character"){
    text.js <- paste(text.js, listRtojs(name="varNames", value=varNames))
  }else{
    text.js <- paste(text.js, paste0("var varNames = ", "[", "'", paste(varNames, collapse="', '"), "'", "]", ";\n"))
  }
  text.js <- paste(text.js, arrayRtojs(name="varTitle", value=varTitle))
  # if(class(legendTitle)=="list"){ # Fallaba cuando legendTitle era un array
  if(length(legendTitle)>1){
    text.js <- paste(text.js, arrayRtojs(name="legendTitle", value=legendTitle))
  }else{
    text.js <- paste(text.js, paste0("var legendTitle = {NaN:['", legendTitle, "']};\n"))
  }
  text.js <- paste(text.js, arrayRtojs(name="menuNames", value=menuNames)) 
  ####
  if(!missing(generalInformation)){
    text.js <- paste(text.js, generaltojs(name="generalInformation", value.ori=generalInformation))
  }else{
    text.js <- paste(text.js, paste0("var generalInformation = ", "undefined", ";\n"))
  }####
  if(!missing(generalInformationNames)){
    text.js <- paste(text.js, paste0("var generalInformationNames = ", "[", "'", paste(generalInformationNames, collapse="', '"), "'", "]", ";\n"))
  }else{
    text.js <- paste(text.js, paste0("var generalInformationNames = ", "undefined", ";\n"))
  }
  text.js <- paste(text.js, paste0("var extensionDownloadFile = '", extensionDownloadFile, "';\n"))
  text.js <- uglify_optimize(text.js)

  write(text.js, file=file, append = FALSE)
  return(text.js)
}

