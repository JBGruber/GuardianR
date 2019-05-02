#' Search Guardian API for news articles that match the criteria
#'
#' @description The function get_guardian takes four variables (keyword(s),
#'   starting date, end date, and API-key) and returns a data frame with a
#'   column for every variable returned by the API columns, with the last column
#'   including the full text of the article.
#'
#'   Search criteria accepts single or multiple keywords. It also accepts
#'   Boolean queries with AND/OR/NOT between words to refine searches. For exact
#'   phrasesand matches, please encapsulate the keywords in double quotes or %22
#'   (e.g "%22Death+of+Margaret+Thatcher%22").
#'
#'   From version 0.5 onwards, the function get_guardian returns the full text
#'   of articles and requires a Guardian API-key. Guardian API-key can be
#'   obtained by registering at <http://open-platform.theguardian.com/access/>.
#'
#' @param keywords Keyword to search Guardian API. Example: "Thatcher". For
#'   multiple keywordsuse "Margaret+Hilda+Thatcher".
#' @param section Specifies news sections to narrow the query or NULL to search
#'   everywhere.
#' @param format either "json" or "xml".
#' @param from,to Start and end date of search (both are included in the
#'   search).
#' @param api_key A Guardian API-key is necessary to retrieve the full text of
#'   news articles. A Guardian API-key can be obtained by registering at
#'   <http://open-platform.theguardian.com/access/>
#' @param verbose Should progress and other messages be displayed (logical).
#'
#' @return data.frame with all variables delivered by the API
#' @export
#'
#' @examples
#' \dontrun{
#' results <- get_guardian(
#'     keywords = "Theresa May AND (Brexit OR EU)",
#'     from = "2019-01-16",
#'     to = "2019-01-30",
#'     api_key = "212d23d3-c7b2-4273-8f1b-289a0803ca4b"
#' )
#' }
get_guardian <- function(keywords,
                         section = NULL,
                         format = "json",
                         from,
                         to,
                         api_key,
                         verbose = TRUE) {
    keywords <- gsub("\\s+", "+", keywords)
    keywords <- gsub('"', "%22", keywords, fixed = TRUE)
    guardian.api.responses <- get_json(keywords, section, format, from, to, api_key, verbose)
    guardian.api.df <- parse_json_to_df(guardian.api.responses)
    return(guardian.api.df)
}


#' @noRd
#' @importFrom utils download.file
#' @importFrom RCurl getURL
#' @importFrom rjson fromJSON
get_json <- function(keywords,
                     section = NULL,
                     format = "json",
                     from,
                     to,
                     api_key,
                     verbose) {
  # pagination
  page.size <- 100
  this.page <- 1
  pages <- 1

  if (as.Date(as.character(to)) - as.Date(as.character(from)) > 31) {
    warning("Periods longer than 30 days might lead to API interruptions.")
  }

  # prepare list for storing api responses
  api.responses <- NULL

  # call guardian API
  while (this.page <= pages) {
    if (is.null(section)) {
      request <- paste("http://content.guardianapis.com/search?q=", keywords, "&from-date=", from, "&to-date=", to,
        "&format=", format, "&show-fields=all&page=", this.page, "&page-size=", page.size, "&api-key=", api_key,
        sep = ""
      )
    } else {
      request <- paste("http://content.guardianapis.com/search?q=", keywords, "&section=", section, "&from-date=", from, "&to-date=", to,
        "&format=", format, "&show-fields=all&page=", this.page,
        "&page-size=", page.size, "&api-key=", api_key,
        sep = ""
      )
    }
    # query api
    if (.Platform$OS.type == "windows") {
      if (!file.exists("cacert.perm")) download.file(url = "https://curl.haxx.se/ca/cacert.pem", destfile = "cacert.perm")
    }
    if (.Platform$OS.type == "windows") {
      json <- getURL(request, cainfo = "cacert.perm", timeout = 240, ssl.verifypeer = FALSE, .encoding = 'UTF-8')
    } else {
      json <- getURL(request, timeout = 240, .encoding = 'UTF-8')
    }
    #json <- fromJSON(json, simplify = FALSE, encoding = "UTF-8")
    json <- rjson::fromJSON(json, simplify = FALSE)

    this.api.response <- json$response
    stopifnot(!is.null(this.api.response))
    # if(this.page==1) { pages.total <<- this.api.response$pages }
    if (this.api.response$total == 0) {
        if (verbose) {
            message("No matches were found in the Guardian database for keyword '", keywords, "'")
        }
        this.page <- this.page + 1
    } else {
      stopifnot(!is.null(this.api.response))
      pages <- this.api.response$pages
      if (pages >= 1) {
        if (verbose) {
            message("Fetched page #", this.page, " of ", pages)
        }
        api.responses <- c(api.responses, this.api.response)
      } else {
          if (verbose) {
              print("Fetched page #1 of 1.")
          }
      }
      api.responses <- c(api.responses, this.api.response)
      this.page <- this.page + 1
    }
  }
  return(api.responses)
  if (.Platform$OS.type == "windows") {
    file.remove("cacert.perm")
  }
}


#' @noRd
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
parse_json_to_df <- function(api.responses) {

    out <- lapply(api.responses$results, function(r) {
        fields <- r[["fields"]]
        r[["fields"]] <- NULL
        df <- tibble::as_tibble(c(r, fields))
    })

    out <- dplyr::bind_rows(out)

    out$body <- parse_html(out$body)

    return(out)
}


#' @noRd
#' @importFrom xml2 xml_text read_html
parse_html <- function(str) {
    str <- gsub("</p>", "\n</p>", str, fixed = TRUE)
    return(xml2::xml_text(xml2::read_html(str)))
}
