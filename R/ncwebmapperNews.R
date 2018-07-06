#' @title ncwebmapper
#' 
#' @description Show the NEWS file of the \pkg{ncwebmapper} package.
#'
#' @details (See description)
#' 
#' @export
#' 
indecisNews <- function() {
    file <- file.path(system.file(package="ncwebmapper"), "NEWS.md")
    file.show(file)
}