## Proto CSV

Este proyecto contiene la prueba de concepto hecha sobre la idea de hacer peticiones HTTP con Range Request sobre el netCDF para luego manipular la respuesta en el navegador, convirtiendo el array binario obtenido en el CSV que descarga el usuario del pixel seleccionado.

El procedimiento para poner en marcha la prueba es el siguiente:

1. Descargamos este reposiorio a nuestra máquina:

    ```
    $ cd <directorio_trabajo>
    $ git clone git@github.com:lcsc/proto_csv.git
    ```

2. Instalamos el fichero netCDF en el subdirectorio `proto_csv/nc`. Durante el desarrollo, la prueba fue hecha con el netCDF del visor [speto](https://speto.csic.es): [https://speto.csic.es/nc/ETo.nc](https://speto.csic.es/nc/ETo.nc). El netCDF original hay que regenerarlo con una estructura de chunks específica para que luego podamos hacer la petición range request de la serie temporal de cada pixel. Esta regeneración se hace con el fichero [chunk.R](https://github.com/lcsc/ncwebmapper/blob/the_chunk_way/R/chunk.R) que hay en el branch [the_chunk_way](https://github.com/lcsc/ncwebmapper/tree/the_chunk_way) del repositorio [lcsc/ncwebmapper](https://github.com/lcsc/ncwebmapper) que instalaremos más adelante.
3. Escribimos un pequeño script R con la parametrización necesaria para trabajar con el netCDF de ETo y las llamadas a las funciones que hacen el trabajo. El script lo llamamos por ejemplo `script.R` y lo dejamos en el `<directorio_trabajo>`. El contenido será el siguiente:

    ```R
    library(ncwebmapper)

    # Common
    nc_route = "proto_csv/nc"
    nc_filename = "ETo.nc"

    # NC t chunks
    t_nc_filename = create_nc_name(nc_filename, sufix="-t")
    nc_file = file.path(nc_route, nc_filename)
    t_nc_file = file.path(nc_route, t_nc_filename)
    lon_by = 100
    lat_by = 100
    write_nc_chunk_t(in_file=nc_file, out_file=t_nc_file, lon_by=lon_by, lat_by=lat_by)

    # JSON NC env
    ncEnv_route = "proto_csv"
    ncEnvFile = "ncEnv.js"
    envFile = file.path(ncEnv_route, ncEnvFile)
    write_nc_env(in_file=nc_file, out_file=envFile)

    # BIN t chunks directory
    t_bin_filename = create_nc_name(nc_filename, sufix="-t", ext=".bin")
    t_bin_file = file.path(nc_route, t_bin_filename)
    write_nc_t_chunk_dir(in_file = t_nc_file, out_file = t_bin_file)


    # times.js
    library(raster)
    library(ncdf4)
    library(rworldmap)
    library(chron)

    ncDates = function(){
        start = chron("1/1/1961")
        datesMonths = seq(from = start, by="month", length=length(dim_time)/4)
        result = array(NA, dim=c(length(datesMonths)*4)) # 1, 9, 16, 23
        result[c(1:length(result)%%4)==1] = datesMonths
        result[c(1:length(result)%%4)==2] = datesMonths+8
        result[c(1:length(result)%%4)==3] = datesMonths+15
        result[c(1:length(result)%%4)==0] = datesMonths+22
        return(result)
    }

    nc <- nc_open(nc_file)
    dim_time <- ncvar_get(nc, "time")
    nc_close(nc)

    infoJs = NA
    zoom = 7
    epsg = "23030"
    dates = ncDates()
    varmin = 17.4
    varmax = 45.1
    varName = "ETo"
    legend = "NaN"
    write = TRUE
    infoJs = config_web(file = nc_file, folder = ncEnv_route, infoJs = infoJs, maxzoom = zoom, epsg = epsg, dates = dates, varmin = varmin, varmax = varmax, varName = varName, legend = legend, write = write)
    ```

4. Para ejecutar el script anterior necesitamos un entorno que contenga al menos la versión 1.12.0 de la librería [hdf5](https://www.hdfgroup.org/downloads/hdf5/). Ubuntu 22.04 empaqueta la versión 1.10.7, por lo que no sirve. Podemos crear un entorno con conda de la siguiente manera (la última línea tarda mucho porque tiene que resolver unos conflictos):

    ```
    $ conda create -n hdf5
    $ conda activate hdf5
    (hdf5) $ conda install -c conda-forge r-base r-curl r-stringi r-car pkg-config r-ragg r-pkgdown r-devtools r-ncdf4 r-sf r-raster r-jsonlite r-chron r-rworldmap
    (hdf5) $ conda install -c conda-forge hdf5=1.12.0
    ```

5. Dentro del entorno R anterior, necesitamos un fork del paquete `hdf5r` que desarrollamos nosotros para incluir las llamadas a 3 funciones relativas a los chunks que están en `hdf5` pero no en el paquete `hdf5r` que hace la envoltura R. El fork es [lcsc/hdf5r](https://github.com/lcsc/hdf5r) y las nuevas funciones se encuentran en el branch [chunk_functions](https://github.com/lcsc/hdf5r/tree/chunk_functions). De paso instalaremos nuestro paquete [ncwebmapper](https://github.com/lcsc/ncwebmapper) en el branch [the_chunk_way](https://github.com/lcsc/ncwebmapper/tree/the_chunk_way) que es el que contiene el nuevo fichero `chunk.R`. Instalaremos también el paquetes 'js' que no se encontró en conda-forge.

    ```
    (hdf5) $ R
    > library(devtools)
    > install.packages('js')
    > install_github("lcsc/hdf5r", ref="chunk_functions")
    > install_github("lcsc/ncwebmapper", ref="the_chunk_way")
    > q()
    ```

6. Ejecutamos el script creado en el punto 3. Si en el script se incluye la generación del directorio de chunks del nc tipo t, es decir la llamada a la función `write_nc_chunk_t`, tener en cuenta que la ejecución puede tardar mucho (13 horas en un fichero con alrededor de 1 millón de chunks como el ETo; con un cuarto de millón la cifra baja a 13 minutos; la relación no es lineal sino exponencial/logarítmica):

    ```
    (hdf5) $ Rscript script.R
    ```

7. Si todo ha ido bien, se deberían haber generado los siguientes ficheros dentro de `<directorio_trabajo>/proto_csv`:

    * `nc/ETo-t.nc`
    * `nc/ETo-t.bin`
    * `ncEnv.js`
    * `times.js`

8. Ya tenemos todos los ficheros necesarios para servir los datos de los CSVs. Sólo falta servir el directorio `<directorio_trabajo>/proto_csv` desde un servidor HTTP que soporte Range Request como Apache. Por ejemplo puede utilizarse el Dockerfile contenido en `<directorio_trabajo>/proto_csv/docker` compilándolo primero (una vez) y lanzándolo como se ve a continuación:

    ```
    $ cd <directorio_trabajo>/proto_csv
    $ docker build -t apache_ubuntu docker/
    $ docker container run --rm -p 8080:80 -v .:/var/www/html -d apache_ubuntu
    ```

9. Ya podremos visualizar la aplicación desde la ruta: [http://localhost:8080/](http://localhost:8080/)
