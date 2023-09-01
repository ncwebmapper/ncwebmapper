#' @name Chunk
#' @author 
#' Borja Latorre Garcés \url{http://eead.csic.es/home/staffinfo?Id=215}; Soil and Water, EEAD, CSIC \url{http://www.eead.csic.es}
#' Fergus Reig Gracia \url{http://fergusreig.es}; Environmental Hydrology, Climate and Human Activity Interactions, Geoenvironmental Processes, IPE, CSIC \url{http://www.ipe.csic.es/hidrologia-ambiental}
#' Eduardo Moreno Lamana \url{https://apuntes.eduardofilo.es}; Environmental Hydrology, Climate and Human Activity Interactions, Geoenvironmental Processes, IPE, CSIC \url{http://www.ipe.csic.es/hidrologia-ambiental}
#' 
#' @details
#' \tabular{ll}{
#'   Version: \tab 1.0.0\cr
#'   License: \tab GPL version 3 or newer\cr
#' }
#'  
#' @description
#' From a netCDF file, generate two versions with the same data but with different chunk
#' configurations. In one case, favor the retrieval of temporal series of the main
#' variable in each pixel, and in the other, favor the retrieval of planes for each date.

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

#' @import ncdf4
#' @import hdf5r

library(ncdf4)
library(hdf5r)

# Constants
OFFSET_TYPE_SIZE = 8
SIZE_TYPE_SIZE = 4

#' Create the new netCDF file with chunk dimensions that favor obtaining temporal series
#' for each pixel.
#' @param in_file Original netCDF file
#' @param out_file netCDF file with the same information as the original but with new chunk structure.
#' @param lon_by Number of pixels horizontally that will be read as a block during the read/write loop. -1 to read all at once.
#' @param lat_by Number of pixels vertically that will be read as a block during the read/write loop. -1 to read all at once.
#' @param lon_name Name of longitude dimension.
#' @param lat_name Name of latitude dimension.
#' @export
#' @examples
#' write_nc_chunk_t(in_file="/path/ETo.nc", out_file="/path/ETo-t.nc", lon_by=100, lat_by=100, lon_name = "lon", lat_name = "lat")
write_nc_chunk_t = function(in_file, out_file, lon_by = -1, lat_by = -1, lon_name = "lon", lat_name = "lat") {
    # Open the original netCDF file
    nc_in_file = nc_open(in_file)

    var_name = nc_in_file$var[[1]]$name

    # Reads global attributes
    global_att = ncatt_get(nc_in_file, 0)

    # Read attributes of dimensions and variable
    lon_longname_att = ncatt_get(nc_in_file, lon_name, "long_name")
    lon_longname = if(lon_longname_att$hasatt) lon_longname_att$value else "longitude"
    lon_units_att = ncatt_get(nc_in_file, lon_name, "units")
    lon_units = if(lon_units_att$hasatt) lon_units_att$value else "m"

    lat_longname_att = ncatt_get(nc_in_file, lat_name, "long_name")
    lat_longname = if(lat_longname_att$hasatt) lat_longname_att$value else "latitude"
    lat_units_att = ncatt_get(nc_in_file, lat_name, "units")
    lat_units = if(lat_units_att$hasatt) lat_units_att$value else "m"

    time_longname_att = ncatt_get(nc_in_file, "time", "long_name")
    time_longname = if(time_longname_att$hasatt) time_longname_att$value else "time"
    time_units_att = ncatt_get(nc_in_file, "time", "units")
    time_units = if(time_units_att$hasatt) time_units_att$value else "days since 1970-01-01"
    time_calendar_att = ncatt_get(nc_in_file, "time", "calendar")
    time_calendar = if(time_calendar_att$hasatt) time_calendar_att$value else "gregorian"
    time_unlim = nc_in_file$dim$time$unlim

    var_longname_att = ncatt_get(nc_in_file, var_name, "long_name")
    var_longname = if(var_longname_att$hasatt) var_longname_att$value else NULL
    var_units_att = ncatt_get(nc_in_file, var_name, "units")
    var_units = if(var_units_att$hasatt) var_units_att$value else ""
    var_missval = nc_in_file$var[[var_name]]$missval

    # Reads the dimensions of the original file
    lon_data = ncvar_get(nc_in_file, lon_name)
    lat_data = ncvar_get(nc_in_file, lat_name)
    time_data = ncvar_get(nc_in_file, "time")

    # Sizes of dimensions
    lon_num = length(lon_data)
    lat_num = length(lat_data)
    time_num = length(time_data)

    # Checks the size of the read/write batches used for processing large files
    lon_by = if (lon_by < 1 || lon_by >= lon_num) lon_num else lon_by
    lat_by = if (lat_by < 1 || lat_by >= lat_num) lat_num else lat_by

    # Define the dimensions for the final file
    lon = ncdim_def(lon_name, lon_units, lon_data, longname=lon_longname)
    lat = ncdim_def(lat_name, lat_units, lat_data, longname=lat_longname)
    time = ncdim_def("time", time_units, time_data, unlim=time_unlim,
                     longname=time_longname, calendar=time_calendar)
    args = list(name=var_name, units=var_units, dim=list(lon, lat, time),
                chunksizes=c(1,1,time_num), compression=9)
    if (!is.null(var_longname))
        args$longname = var_longname
    if (!is.null(var_missval))
        args$missval = var_missval
    var = do.call(ncvar_def, args)

    # Final file creation
    nc_out_file = nc_create(out_file, list(var), force_v4 = TRUE)

    if (lon_by == lon_num && lat_by == lat_num) {
        # Read/write data at once
        var_data = ncvar_get(nc_in_file, var)
        ncvar_put(nc_out_file, var, var_data)
    } else {
        # Read/write data in batches
        for (x in seq(1, lon_num, by=lon_by)) {
            x_rest = lon_num - x + 1
            x_count = if (x_rest >= lon_by) lon_by else x_rest
            for (y in seq(1, lat_num, by=lat_by)) {
                y_rest = lat_num - y + 1
                y_count = if (y_rest >= lat_by) lat_by else y_rest
                var_data = ncvar_get(nc_in_file, var, start=c(x,y,1), count=c(x_count,y_count,time_num))
                ncvar_put(nc_out_file, var, var_data, start=c(x,y,1), count=c(x_count,y_count,time_num))
            }
        }
    }

    # Writes the global attributes to the final file
    for (name in names(global_att)) {
        ncatt_put(nc_out_file, 0, name, global_att[[name]])
    }

    nc_close(nc_out_file)
    nc_close(nc_in_file)
}


#' Create the new netCDF file with favorable chunk dimensions to obtain plans for each date.
#' @param in_file Original netCDF file
#' @param out_file netCDF file with the same information as the original but with new chunk structure.
#' @param time_by Number of dates that will be read as a block during the read/write loop. -1 to read all at once.
#' @param lon_name Name of longitude dimension.
#' @param lat_name Name of latitude dimension.
#' @export
#' @examples
#' write_nc_chunk_xy(in_file="/path/ETo.nc", out_file="/path/ETo-xy.nc", time_by=100, lon_name = "lon", lat_name = "lat")
write_nc_chunk_xy = function(in_file, out_file, time_by = -1, lon_name = "lon", lat_name = "lat") {
    # Open the original netCDF file
    nc_in_file = nc_open(in_file)

    var_name = nc_in_file$var[[1]]$name

    # Reads global attributes
    global_att = ncatt_get(nc_in_file, 0)

    # Read attributes of dimensions and variable
    lon_longname_att = ncatt_get(nc_in_file, lon_name, "long_name")
    lon_longname = if(lon_longname_att$hasatt) lon_longname_att$value else "longitude"
    lon_units_att = ncatt_get(nc_in_file, lon_name, "units")
    lon_units = if(lon_units_att$hasatt) lon_units_att$value else "m"

    lat_longname_att = ncatt_get(nc_in_file, lat_name, "long_name")
    lat_longname = if(lat_longname_att$hasatt) lat_longname_att$value else "latitude"
    lat_units_att = ncatt_get(nc_in_file, lat_name, "units")
    lat_units = if(lat_units_att$hasatt) lat_units_att$value else "m"

    time_longname_att = ncatt_get(nc_in_file, "time", "long_name")
    time_longname = if(time_longname_att$hasatt) time_longname_att$value else "time"
    time_units_att = ncatt_get(nc_in_file, "time", "units")
    time_units = if(time_units_att$hasatt) time_units_att$value else "days since 1970-01-01"
    time_calendar_att = ncatt_get(nc_in_file, "time", "calendar")
    time_calendar = if(time_calendar_att$hasatt) time_calendar_att$value else "gregorian"
    time_unlim = nc_in_file$dim$time$unlim

    var_longname_att = ncatt_get(nc_in_file, var_name, "long_name")
    var_longname = if(var_longname_att$hasatt) var_longname_att$value else NULL
    var_units_att = ncatt_get(nc_in_file, var_name, "units")
    var_units = if(var_units_att$hasatt) var_units_att$value else ""
    var_missval = nc_in_file$var[[var_name]]$missval

    # Reads the dimensions of the original file
    lon_data = ncvar_get(nc_in_file, lon_name)
    lat_data = ncvar_get(nc_in_file, lat_name)
    time_data = ncvar_get(nc_in_file, "time")

    # Sizes of dimensions
    lon_num = length(lon_data)
    lat_num = length(lat_data)
    time_num = length(time_data)

    # Checks the size of the read/write batches used for processing large files
    time_by = if (time_by < 1 || time_by >= time_num) time_num else time_by
 
    # Define the dimensions for the final file
    lon = ncdim_def(lon_name, lon_units, lon_data, longname=lon_longname)
    lat = ncdim_def(lat_name, lat_units, lat_data, longname=lat_longname)
    time = ncdim_def("time", time_units, time_data, unlim=time_unlim,
                     longname=time_longname, calendar=time_calendar)
    args = list(name=var_name, units=var_units, dim=list(lon, lat, time),
                chunksizes=c(lon_num,lat_num,1), compression=9)
    if (!is.null(var_longname))
        args$longname = var_longname
    if (!is.null(var_missval))
        args$missval = var_missval
    var = do.call(ncvar_def, args)

    # Final file creation
    nc_out_file = nc_create(out_file, list(var), force_v4 = TRUE)

    if (time_by == time_num) {
        # Read/write data at once
        var_data = ncvar_get(nc_in_file, var)
        ncvar_put(nc_out_file, var, var_data)
    } else {
        # Read/write data in batches
        for (t in seq(1, time_num, by=time_by)) {
            t_rest = time_num - t + 1
            t_count = if (t_rest >= time_by) time_by else t_rest
            var_data = ncvar_get(nc_in_file, var, start=c(1,1,t), count=c(lon_num,lat_num,t_count))
            ncvar_put(nc_out_file, var, var_data, start=c(1,1,t), count=c(lon_num,lat_num,t_count))
        }
    }

    # Writes the global attributes to the final file
    for (name in names(global_att)) {
        ncatt_put(nc_out_file, 0, name, global_att[[name]])
    }

    nc_close(nc_out_file)
    nc_close(nc_in_file)
}


#' Filename generator for rechunked nc and chunk directories.
#' @param file_name Original netCDF filename
#' @param sufix Optional suffix to be added to the end of the file name before the extension
#' @param ext File extension. If given the empty value, the original extension is maintained
#' @return New filename
#' @export
#' @examples
#' create_nc_name(file_name="ETo.nc", sufix="-t", ext=".bin")
create_nc_name = function(file_name, sufix="-t", ext="") {
    pos = unlist(gregexpr(".nc", file_name))
    ext_pos = pos[length(pos)]
    if (ext == "") {
        ext = substr(file_name, ext_pos, nchar(file_name))
    }
    return(paste0(substr(file_name, 1, ext_pos-1), sufix, ext))
}


#' Converts the data type of a variable or dimension of a netCDF to the data type codes used
#' by the struct library.
#' @param nc_type netCDF data type
#' @return struct data type
#' @examples
#' get_struct_typecode(nc_type="double")
get_struct_typecode = function(nc_type) {
    result = switch(
        nc_type,
        "float"= "f",
        "double"= "d",
        "int"= "i"
    )
    return(result)
}


#' Create the JSON ncEnv with meta-information about the netCDF file.
#' @param in_file Original netCDF file
#' @param folder folder for JSON file
#' @param lon_name Name of longitude dimension.
#' @param lat_name Name of latitude dimension.
#' @param ncEnv previous JSON
#' @param epsg file epsg
#' @export
#' @examples
#' write_nc_env(in_file="/path/ETo.nc", out_file="/path/ncEnv.js")
write_nc_env = function(in_file, folder, lon_name = "lon", lat_name = "lat", ncEnv, epsg) {
    # Open the original netCDF file
    nc_in_file = nc_open(in_file)

    ncEnvFile = "ncEnv.js"
    out_file = file.path(folder, ncEnvFile)

    if(!missing(in_file)){
        # nc name
        varName <- basename(gsub(".nc", "", in_file))
    }else{
        varName <- "NaN"
    }


    # read epsg
    if(missing(epsg))
    {
        epsg <- read_epsg(nc_in_file)
        if(epsg == 0)
        {
            cat("Error: EPSG not found\n")
            return()
        }
    }

    if(missing(ncEnv) || sum(!is.na(ncEnv))==0)
    {
        ncEnv <- list(lon_min=list(), lon_max=list(), lon_num=list(), lat_min=list(), lat_max=list(), lat_num=list(), var_type=list(), compressed=list(), offset_type="Q", size_type="I", projection=list(), fillvalue=list())
    }

    lon_data = ncvar_get(nc_in_file, lon_name)
    ncEnv$lon_min[[varName]] = lon_data[1]
    ncEnv$lon_max[[varName]] = lon_data[length(lon_data)]
    ncEnv$lon_num[[varName]] = length(lon_data)
    lat_data = ncvar_get(nc_in_file, lat_name)
    ncEnv$lat_min[[varName]] = lat_data[1]
    ncEnv$lat_max[[varName]] = lat_data[length(lat_data)]
    ncEnv$lat_num[[varName]] = length(lat_data)
    ncEnv$compressed[[varName]] = if(is.na(nc_in_file$var[[1]]$compression)) 0 else 1
    ncEnv$var_type[[varName]] = get_struct_typecode(nc_in_file$var[[1]]$prec)
    # projection = "+proj=utm +zone=30 +ellps=GRS80 +units=m +no_defs"
    ncEnv$projection[[varName]] = st_crs(st_sfc(st_point(c(0, 0)), crs = paste0("+init=epsg:", epsg)))$proj4string

    # Check if the missval attribute exists in the netCDF
    var_atts = ncatt_get(nc_in_file, varid = nc_in_file$var[[1]])
    ncEnv$fillvalue[[varName]] = if ("_FillValue" %in% names(var_atts)) nc_in_file$var[[1]]$missval else NaN

    text.js <- ""
    text.js <- paste(text.js, listRtojs(name="lon_min", value=ncEnv$lon_min))
    text.js <- paste(text.js, arrayRtojs(name="lon_max", value=ncEnv$lon_max, type="numeric"))
    text.js <- paste(text.js, arrayRtojs(name="lon_num", value=ncEnv$lon_num, type="numeric"))
    text.js <- paste(text.js, arrayRtojs(name="lat_min", value=ncEnv$lat_min, type="numeric"))
    text.js <- paste(text.js, arrayRtojs(name="lat_max", value=ncEnv$lat_max, type="numeric"))
    text.js <- paste(text.js, arrayRtojs(name="lat_num", value=ncEnv$lat_num, type="numeric")) 
    text.js <- paste(text.js, arrayRtojs(name="var_type", value=ncEnv$var_type, type="character")) 
    text.js <- paste(text.js, arrayRtojs(name="compressed", value=ncEnv$compressed, type="numeric")) 
    text.js <- paste0(text.js, "var offset_type = ", "'", ncEnv$offset_type, "'", "\n")  
    text.js <- paste0(text.js, "var size_type = ", "'", ncEnv$size_type, "'", "\n")    
    text.js <- paste(text.js, arrayRtojs(name="projection", value=ncEnv$projection, type="character")) 
    text.js <- paste(text.js, arrayRtojs(name="fillvalue", value=ncEnv$fillvalue, type="numeric"))

    nc_close(nc_in_file)

    text.js <- uglify_optimize(text.js)
    write(text.js, file=out_file, append=FALSE)

    return(ncEnv)
}


#' Create the binary chunks directory for the nc oriented to the time series of each pixel.
#' @param in_file netCDF file with chunking oriented to the time series of each pixel. 
#' @param out_file Chunks directory file.
#' @export
#' @examples
#' write_nc_t_chunk_dir(in_file="/path/ETo-t.nc", out_file="/path/ETo-t.bin")
write_nc_t_chunk_dir = function(in_file, out_file) {
    # Find out name of main variable with ncdf4
    nc_in_file = nc_open(in_file)
    var_name = nc_in_file$var[[1]]$name
    nc_close(nc_in_file)

    # Open the netCDF file with hdf5r
    nc_in_file = h5file(in_file, mode="r")

    # Open a binary file in write mode
    bin_out_file = file(out_file, "wb")

    lon_num = nc_in_file[[var_name]]$dims[[1]]
    lat_num = nc_in_file[[var_name]]$dims[[2]]
    time_num = nc_in_file[[var_name]]$dims[[3]]

    for (y in seq(1, lat_num)) {
        for (x in seq(1, lon_num)) {
            chunk_info = nc_in_file[[var_name]]$get_chunk_info_by_coord(c(0,y-1,x-1))
            # Write the number pairs to the binary file
            writeBin(as.integer(chunk_info$addr), bin_out_file, size = OFFSET_TYPE_SIZE, endian = "little")
            writeBin(as.integer(chunk_info$size), bin_out_file, size = SIZE_TYPE_SIZE, endian = "little")
        }
    }

    # Close files
    close(bin_out_file)
    nc_in_file$close()
}


#' Create the binary chunks directory for the nc oriented to the time series of each pixel
#' using the new H5Dchunk_iter function (https://docs.hdfgroup.org/hdf5/v1_14/group___h5_d.html#title6).
#' @param in_file netCDF file with chunking oriented to the time series of each pixel. 
#' @param out_file Chunks directory file.
#' @export
#' @examples
#' write_nc_t_chunk_dir_iter(in_file="/path/ETo-t.nc", out_file="/path/ETo-t.bin")
write_nc_t_chunk_dir_iter = function(in_file, out_file) {
    # Find out name of main variable with ncdf4
    nc_in_file = nc_open(in_file)
    var_name = nc_in_file$var[[1]]$name
    nc_close(nc_in_file)

    # Open the netCDF file with hdf5r
    nc_in_file = h5file(in_file, mode="r")

    # Open a binary file in write mode
    bin_out_file = file(out_file, "wb")

    lon_num = nc_in_file[[var_name]]$dims[[1]]
    lat_num = nc_in_file[[var_name]]$dims[[2]]
    time_num = nc_in_file[[var_name]]$dims[[3]]

    nc_in_file[[var_name]]$chunk_iter(function(chunk_info){
        lat_index = chunk_info$offset[[2]]
        lon_index = chunk_info$offset[[3]]
        dir_pos = (OFFSET_TYPE_SIZE + SIZE_TYPE_SIZE) * (lon_index + lat_index * lon_num)
        seek(bin_out_file, dir_pos)
        writeBin(as.integer(chunk_info$addr), bin_out_file, size = OFFSET_TYPE_SIZE, endian = "little")
        writeBin(as.integer(chunk_info$size), bin_out_file, size = SIZE_TYPE_SIZE, endian = "little")
    })

    # Close files
    close(bin_out_file)
    nc_in_file$close()
}


#' Create the binary chunks directory for the nc oriented to the maps of each date.
#' @param in_file netCDF file with chunking oriented to the maps of each date.
#' @param out_file Chunks directory file.
#' @export
#' @examples
#' write_nc_xy_chunk_dir(in_file="/path/ETo-xy.nc", out_file="/path/ETo-xy.bin")
write_nc_xy_chunk_dir = function(in_file, out_file) {
    # Find out name of main variable with ncdf4
    nc_in_file = nc_open(in_file)
    var_name = nc_in_file$var[[1]]$name
    nc_close(nc_in_file)

    # Open the netCDF file with hdf5r
    nc_in_file = h5file(in_file, mode="r")

    # Open a binary file in write mode
    bin_out_file = file(out_file, "wb")

    lon_num = nc_in_file[[var_name]]$dims[[1]]
    lat_num = nc_in_file[[var_name]]$dims[[2]]
    time_num = nc_in_file[[var_name]]$dims[[3]]

    for (t in seq(1, time_num)) {
        chunk_info = nc_in_file[[var_name]]$get_chunk_info_by_coord(c(t-1,0,0))
        # Write the number pairs to the binary file
        writeBin(as.integer(chunk_info$addr), bin_out_file, size = OFFSET_TYPE_SIZE, endian = "little")
        writeBin(as.integer(chunk_info$size), bin_out_file, size = SIZE_TYPE_SIZE, endian = "little")
    }

    # Close files
    close(bin_out_file)
    nc_in_file$close()
}


#' Create the binary chunks directory for the nc oriented to the maps of each date
#' using the new H5Dchunk_iter function (https://docs.hdfgroup.org/hdf5/v1_14/group___h5_d.html#title6).
#' @param in_file netCDF file with chunking oriented to the maps of each date.
#' @param out_file Chunks directory file.
#' @export
#' @examples
#' write_nc_xy_chunk_dir_iter(in_file="/path/ETo-xy.nc", out_file="/path/ETo-xy.bin")
write_nc_xy_chunk_dir_iter = function(in_file, out_file) {
    # Find out name of main variable with ncdf4
    nc_in_file = nc_open(in_file)
    var_name = nc_in_file$var[[1]]$name
    nc_close(nc_in_file)

    # Open the netCDF file with hdf5r
    nc_in_file = h5file(in_file, mode="r")

    # Open a binary file in write mode
    bin_out_file = file(out_file, "wb")

    lon_num = nc_in_file[[var_name]]$dims[[1]]
    lat_num = nc_in_file[[var_name]]$dims[[2]]
    time_num = nc_in_file[[var_name]]$dims[[3]]

    nc_in_file[[var_name]]$chunk_iter(function(chunk_info){
        time_index = chunk_info$offset[[1]]
        dir_pos = (OFFSET_TYPE_SIZE + SIZE_TYPE_SIZE) * time_index
        seek(bin_out_file, dir_pos)
        writeBin(as.integer(chunk_info$addr), bin_out_file, size = OFFSET_TYPE_SIZE, endian = "little")
        writeBin(as.integer(chunk_info$size), bin_out_file, size = SIZE_TYPE_SIZE, endian = "little")
    })

    # Close files
    close(bin_out_file)
    nc_in_file$close()
}


## Usage

# nc_route = "../viewer/nc"
# ncFile = "ETo.nc"
# file = file.path(nc_route, ncFile)
# t_file = file.path(nc_route, create_nc_name(ncFile))
# lon_by = 100
# lat_by = 100
# write_nc_chunk_t(in_file=file, out_file=t_file, lon_by=lon_by, lat_by=lat_by)


# nc_route = "../viewer/nc"
# ncFile = "ETo.nc"
# file = file.path(nc_route, ncFile)
# xy_file = file.path(nc_route, create_nc_name(ncFile, sufix="-xy"))
# time_by = 100
# write_nc_chunk_xy(in_file=file, out_file=xy_file, time_by=time_by)


# nc_route = "../viewer/nc"
# ncFile = "ETo.nc"
# file = file.path(nc_route, ncFile)
# ncEnv_route = "../viewer"
# ncEnvFile = "ncEnv.js"
# envFile = file.path(ncEnv_route, ncEnvFile)
# write_nc_env(in_file=file, out_file=envFile)


#nc_route = "/home/docker/workdir/proto_eto/viewer/nc"
#ncFile = "ETo-t.nc"
#file = file.path(nc_route, ncFile)
#bin_file = file.path(nc_route, create_nc_name(ncFile, ext="bin"))
#write_nc_t_chunk_dir(in_file = file, out_file = bin_file)
#  or
#write_nc_t_chunk_dir_iter(in_file = file, out_file = bin_file)


#nc_route = "/home/docker/workdir/proto_eto/viewer/nc"
#ncFile = "ETo-xy.nc"
#file = file.path(nc_route, ncFile)
#bin_file = file.path(nc_route, create_nc_name(ncFile, ext="bin"))
#write_nc_xy_chunk_dir(in_file = file, out_file = bin_file)
#  or
#write_nc_xy_chunk_dir_iter(in_file = file, out_file = bin_file)
