#' Create named list of allowed GA metrics/dimensions
#' 
#' @param type Type of parameter to create
#' @param subType to restrict to only those in this type
#' @param callAPI This will update the meta table (Requires online authorization)
#' 
#' This is useful to expand goalXCompletions to all the possiblilties,
#'   as well as restricting to those that variables that work with your API call.
#' 
#' Use internal meta table, but you have option to update to the latest version.
#'   
#' @return A named list of parameters for use in API calls
#' @export
allowed_metric_dim <- function(type = c("METRIC", "DIMENSION"),
                               subType = c("all","segment","cohort"),
                               callAPI = FALSE){
  type <- match.arg(type)
  subType <- match.arg(subType)
  
  if(callAPI){
    meta <- google_analytics_meta()
  } else {
    meta <- googleAnalyticsR::meta
  }

  ## where to restrict what dims/metrics are chosen from, todo
  filtered_md <- switch(subType,
                        all = meta,
                        segment = meta[grepl("true",meta$allowedInSegments),],
                        cohort = meta[grepl("Lifetime Value and Cohort", meta$group),])
  
  ## only public (not deprecated) varaibles
  filtered_md <- filtered_md[filtered_md$type == type & 
                               filtered_md$status == "PUBLIC",]
  
  ## replace XX with 1 to 20
  meta_ex <- filtered_md[grepl("XX",filtered_md$name),]
  
  f <- function(y) vapply(1:20, function(x) gsub("XX", x, meta_ex$name[y]), character(1))
  meta_expanded <- unlist(lapply(seq_along(meta_ex$name), f))
  
  ## repeat with names
  f2 <- function(y) vapply(1:20, function(x) gsub("XX", x, meta_ex$uiName[y]), character(1))
  meta_expanded_names <- unlist(lapply(seq_along(meta_ex$uiName), f2))
  
  
  ## take out XX from filtered_md
  out <- c(filtered_md$name[!filtered_md$name %in% meta_ex$name],
           meta_expanded)
  names(out) <- c(filtered_md$uiName[!filtered_md$uiName %in% meta_ex$uiName],
                  meta_expanded_names)
  
  out
}

#' Allow unit lists
#' 
#' If you need a list but only get one element, make it a list.
#' 
#' Makes it easier for users to use some functions by not worrying about list wrapping. 
#' 
#' @param perhaps_list A list or an element that will be wrapped in list()
#' 
#' @return A list
#' @keywords internal
unitToList <- function(perhaps_list){
  
  if(is.null(perhaps_list)){
    return(NULL)
  }
  
  if(inherits(perhaps_list, "list")){
    out <- perhaps_list
  } else {
    if(length(perhaps_list) == 1){
      out <- list(perhaps_list)
    } else {
      stop("Needs to be a list or a length 1 object")
    }

  }
  
  out
}


 #' Test Type in a list
#' 
#' @param listthing A list of things
#' @param types A vector of types we want
#' @param null_ok Is it ok to have a NULL listhing?
#' @keywords internal
expect_list_of_type <- function(listthing, types, null_ok=FALSE){
  
  if(null_ok){
    expect_null_or_type(listthing, "list")
    return()
  } else {
    testthat::expect_type(listthing, "list")
  }

  res <- mapply(function(thing, type) {
    class(thing)==type
    }, listthing, types)
  
  if(!any(res)){
    stop(paste(types, collapse = " "), " is not found in list")
  }
  
}

#' Test S3 Class in a list
#' 
#' @param listthing A list of things
#' @param types A vector of s3 class we want
#' @param null_ok Is it ok to have a NULL listhing?
#' @keywords internal
expect_list_of_class <- function(listthing, types, null_ok=FALSE){
  
  if(null_ok){
    expect_null_or_type(listthing, "list")
    return()
  } else {
    testthat::expect_s3_class(listthing, "list")
  }
  
  res <- mapply(function(thing, type) {
    class(thing)==type
  }, listthing, types)
  
  if(!any(res)){
    stop(paste(types, collapse = " "), " is not found in list")
  }
  
}

#' Testthat in a list
#' 
#' @param f The testthat function
#' @param listthing A list of things
#' @param types A vector of types we want
#' @param null_ok Is it ok to have a NULL listhing?
#' @keywords internal
expect_list_of_this <- function(f, listthing, types, null_ok=FALSE){
  
  if(null_ok){
    expect_null_or_type(listthing, "list")
    return()
  } else {
    f(listthing, "list")
  }
  
  res <- mapply(function(thing, type) {
    class(thing)==type
  }, listthing, types)
  
  if(!any(res)){
    stop(paste(types, collapse = " "), " is not found in list")
  }
  
}

#' Expect NULL or type
#' 
#' wraps testthat::expect_type() to run if not NULL
#' @keywords internal
expect_null_or_type <- function(thing, type){
  if(!is.null(thing)){
    testthat::expect_type(thing, type)
  }
}

#' Expect NULL or class (s3)
#' 
#' wraps testthat::expect_type() to run if not NULL
#' @keywords internal
expect_null_or_s3_class <- function(thing, s3class){
  if(!is.null(thing)){
    testthat::expect_s3_class(thing, s3class)
  }
}


#' @importFrom magrittr %>%
#' @export
#' @keywords internal
magrittr::`%>%`

#' A helper function that tests whether an object is either NULL _or_
#' a list of NULLs
#'
#' @keywords internal
is.NullOb <- function(x) is.null(x) | all(sapply(x, is.null))

#' Recursively step down into list, removing all such objects
#'
#' @keywords internal
rmNullObs <- function(x) {
  x <- Filter(Negate(is.NullOb), x)
  lapply(x, function(x) if (is.list(x)) rmNullObs(x) else x)
}

#' check it starts with ga: and if not puts it on
#'
#' @keywords internal
checkPrefix <- function(x, prefix=c("ga", "mcf")){
  prefix <- match.arg(prefix)
  
  prefix_reg <- paste0("^",prefix,":")
  
  if(grepl(prefix_reg, x)) x else paste0(prefix,":",x)
}

#' Add name of list entry of dataframe to dataframe colum
#'
#' @keywords internal
listNameToDFCol <- function(named_list, colName = "listName"){
  lapply(names(named_list),
         function(x) {named_list[[x]][colName] <- x
         named_list[[x]]
         })
}

#' Is this a try error?
#'
#' Utility to test errors
#'
#' @param test_me an object created with try()
#'
#' @return Boolean
#'
#' @keywords internal
is.error <- function(test_me){
  inherits(test_me, "try-error")
}

#' Get the error message
#'
#' @param test_me an object that has failed is.error
#'
#' @return The error message
#'
#' @keywords internal
error.message <- function(test_me){
  if(is.error(test_me)) attr(test_me, "condition")$message
}

#' Idempotency
#'
#' A random code to ensure no repeats
#'
#' @return A random 15 digit hash
#' @keywords internal
idempotency <- function(){
  paste(sample(c(LETTERS, letters, 0:9), 15, TRUE),collapse="")
}


#' Customer message log level
#' 
#' @param ... The message(s)
#' @param level The severity
#' 
#' @details 0 = everything, 1 = debug, 2=normal, 3=important
myMessage <- function(..., level = 2){
  
  compare_level <- getOption("googleAuthR.verbose")
  
  if(level >= compare_level){
    message(...)
  }
  
}
