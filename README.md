# ncwebmapper
Este es el código fuente del paquete de R ncwebmapper; aun no disponible en CRAN.

Se han intentado crear unas funciones que permitan crear una página web estática que sirva para visualizar los datos de ficheros estandar NetCDF, que contengan datos espacio-temporales.

Este paquete ha sido desarrollado dentro del trabajo de [LCSC: Climatology and Climate Services Laboratory](http://spread.csic.es) y es utilizado en varias de sus páginas webs.

Estas webs sirven de ejemplo de uso del paquete:
* Un ejemplo sencillo es la web [indecis.csic.es](https://indecis.csic.es) que parte de los datos disponibles en [indecis.csic.es/nc](https://indecis.csic.es/nc)
* Un ejemplo complejo es la web [spainndvi.csic.es](https://spainndvi.csic.es) que parte de los datos disponibles en [spainndvi.csic.es/nc](https://spainndvi.csic.es/nc) y del que se puede consultar el script completo necesario para su cálculo [ndvi.R](https://github.com/MuDestructor/tools/blob/master/ndvi.R)

# Instalación
Para instalar el paquete
```r
library(devtools)
install_github("ncwebmapper/ncwebmapper")
```