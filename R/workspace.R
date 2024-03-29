#' @include multiprocessing.R
NULL

#' Create a workspace or a multi-processing
#'
#' Functions to create a 'JDemetra+' workspace (\code{.jws_new()}) and
#' to add a new multi-processing (\code{.jws_multiprocessing_new()}).
#'
#' @param modelling_context the context (from [rjd3toolkit::modelling_context()]).
#' @param jws a workspace object.
#' @param name character name of the new multiprocessing.
#'
#' @examples
#' # To create an empty 'JDemetra+' workspace
#' wk <- .jws_new()
#' mp <- .jws_multiprocessing_new(wk, "sa1")
#'
#'
#' @name .jws_new
#' @rdname .jws_new
#' @export
.jws_new<-function(modelling_context=NULL){
    jws<-.jnew("jdplus/sa/base/workspace/Ws")
  if (! is.null(modelling_context)){
    set_context(jws, modelling_context)
  }
  return (jws)
}

#' @name .jws_new
#' @export
.jws_multiprocessing_new<-function(jws, name){
  return (.jcall(jws, "Ljdplus/sa/base/workspace/MultiProcessing;", "newMultiProcessing", name))
}

#' Set Context of a Workspace
#'
#' @inheritParams .jws_new
#' @inheritParams .jws_open
#' @export
set_context <- function(jws, modelling_context = NULL) {
  if (!is.null(set_context)) {
    jcontext <- rjd3toolkit::.r2jd_modellingcontext(modelling_context)
    .jcall(jws, "V", "setContext", jcontext)
  }
}
#' Get Context from Workspace
#'
#' @param jws the workspace.
#'
#' @export
get_context<-function(jws){
  jcntxt <- .jcall(jws, "Ljdplus/toolkit/base/api/timeseries/regression/ModellingContext;", "getContext")
  rjd3toolkit::.jd2r_modellingcontext(jcntxt)
}

#' Count the number of objects inside a workspace or multiprocessing
#'
#' Functions to count the number of multiprocessing inside a workspace (`jws_multiprocessing_count`) or
#' the number of SaItem inside a multiprocessing (`jmp_sa_count`).
#'
#' @param jws,jmp the workspace or the multiprocessing.
#'
#' @name count
#' @rdname count
#' @export
.jws_multiprocessing_count<-function(jws){
  return (.jcall(jws, "I", "getMultiProcessingCount"))
}



#' Extract a Multiprocessing or a SaItem
#'
#' @param jws,jmp the workspace or the multiprocessing.
#' @param idx index of the object to extract.
#'
#' @export
.jws_multiprocessing<-function(jws, idx){
  return (.jcall(jws, "Ljdplus/sa/base/workspace/MultiProcessing;", "getMultiProcessing", as.integer(idx-1)))
}




#' Load a 'JDemetra+' workpace
#'
#' `.jws_open()` loads a workspace and `.jws_compute()` computes it (to be able to get all the models).
#'
#' @param file the path to the 'JDemetra+' workspace to load.
#' By default a dialog box opens.
#' @param jws the workspace.
#'
#' @seealso [load_workspace()] to directly load a workspace and import all the models.
#'
#' @export
.jws_open<-function(file){
  if (missing(file) || is.null(file)) {
    if (Sys.info()[['sysname']] == "Windows") {
      file <- utils::choose.files(caption = "Select a workspace",
                                  filters = c("JDemetra+ workspace (.xml)", "*.xml"))
    }else{
      file <- base::file.choose()
    }
    if (length(file) == 0)
      stop("You have to choose a file !")
  }
  if (!file.exists(file) | length(grep("\\.xml$",file)) == 0)
    stop("The file doesn't exist or isn't a .xml file !")

  jws<-.jcall("jdplus/sa/base/workspace/Ws", "Ljdplus/sa/base/workspace/Ws;", "open", file)
  return (jws)
}

#' @name .jws_open
#' @export
.jws_compute<-function(jws){
  .jcall(jws, "V", "computeAll")
}




#' Read all SaItems
#'
#' Functions to read all the SAItem of a multiprocessing (`jmp_load()`)
#' or a workspace (`load_workspace()`).
#'
#' @inheritParams .jws_open
#' @param jmp a multiprocessing.
#'
#' @export
load_workspace<-function(file){
  if (missing(file) || is.null(file)) {
    if (Sys.info()[['sysname']] == "Windows") {
      file <- utils::choose.files(caption = "Select a workspace",
                                  filters = c("JDemetra+ workspace (.xml)", "*.xml"))
    }else{
      file <- base::file.choose()
    }
    if (length(file) == 0)
      stop("You have to choose a file !")
  }
  if (!file.exists(file) | length(grep("\\.xml$",file)) == 0)
    stop("The file doesn't exist or isn't a .xml file !")

  jws<-.jws_open(file)
  .jws_compute(jws)
  n<-.jws_multiprocessing_count(jws)
  jmps<-lapply(1:n, function(i){.jmp_load(.jws_multiprocessing(jws,i))})
  names<-lapply(1:n, function(i){.jmp_name(.jws_multiprocessing(jws, i))})
  names(jmps)<-names
  cntxt <- get_context(jws)

  return (list(processing=jmps, context=cntxt))

}

#' Save Workspace
#'
#' @param jws the workspace object to export.
#' @param file the path where to export the 'JDemetra+' workspace (.xml file).
#' @param replace boolean indicating if the workspace should be replaced if it already exists.
#' @examples
#' dir <- tempdir()
#' jws <- .jws_new()
#' jmp1 <- .jws_multiprocessing_new(jws, "sa1")
#' y <- rjd3toolkit::ABS$X0.2.09.10.M
#' add_sa_item(jmp1, name = "x13", x = y, rjd3x13::spec_x13())
#' save_workspace(jws, file.path(dir, "workspace.xml"))
#'
#' @export
save_workspace <- function(jws, file, replace = FALSE) {
  # version <- match.arg(tolower(version)[1], c("jd3", "jd2"))
  version <- "jd3"
  .jcall(jws, "Z", "saveAs", file, version, !replace)
}



#' Add Calendar to Workspace
#'
#' @inheritParams set_context
#' @param name the name of the calendar to add.
#' @param calendar the calendar to add.
#' @export
add_calendar <- function(jws, name, calendar) {
  pcal<-rjd3toolkit:::.r2p_calendar(calendar)
  jcal<-rjd3toolkit:::.p2jd_calendar(pcal)
  jcal <- .jcast(jcal, "jdplus/toolkit/base/api/timeseries/calendars/CalendarDefinition")

  .jcall(jws, "V", "addCalendar",
         name,
         jcal)
}

#' Add Variable to Workspace
#'
#' @inheritParams set_context
#' @param group,name the group and the name of the variable to add.
#' @param y the variable (a `ts` object).
#' @export
add_variable <- function(jws, group, name, y) {
  .jcall(jws, "V", "addVariable", group,
         name, rjd3toolkit::.r2jd_ts(y))
}
