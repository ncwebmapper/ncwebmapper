% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/config-web.R
\name{config_web}
\alias{config_web}
\title{write web configuration}
\usage{
config_web(
  file,
  folder,
  maxzoom,
  epsg,
  dates,
  formatdates,
  latIni,
  lonIni,
  latEnd,
  lonEnd,
  timeIni,
  timeEnd,
  varmin,
  varmax,
  varName,
  infoJs = NA,
  legend = "NaN",
  write = TRUE,
  zoom
)
}
\arguments{
\item{file}{file nc}

\item{folder}{folder}

\item{epsg}{epsg}

\item{dates}{dates}

\item{formatdates}{formatdates}

\item{latIni}{latIni}

\item{lonIni}{lonIni}

\item{latEnd}{latEnd}

\item{lonEnd}{lonEnd}

\item{timeIni}{timeIni}

\item{timeEnd}{timeEnd}

\item{varmin}{varmin}

\item{varName}{varName}

\item{infoJs}{infoJs}

\item{legend}{legend}

\item{write}{true si se escribe el fichero js al terminar la ejecución; implica que la web solo muestra un "mapa"; en otro caso se supone que la web tendrá más de un mapa}

\item{zoom}{zoom}

\item{maxZoom}{maxZoom}
}
\description{
write web configuration
}
