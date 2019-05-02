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
                         from,
                         to,
                         api_key,
                         verbose = TRUE) {
  
    keywords <- gsub("\\s+", "+", keywords)
    keywords <- gsub('"', "%22", keywords, fixed = TRUE)
    
    response <- get_json(keywords = keywords,
                         section = section,
                         from = from,
                         to = to,
                         api_key = api_key,
                         verbose = verbose)
    out <- lapply(response, parse_to_df)
    out <- do.call(rbind, out)
    
    out$body <- vapply(out$body, parse_html, character(1))
    
    out$webPublicationDate <- as.POSIXct(
      gsub("T|Z", "", out$webPublicationDate),
      format = "%Y-%m-%d %H:%M:%S",
      tz = "GMT"
    )
    
    out$newspaperEditionDate <- as.POSIXct(
      gsub("T|Z", "", out$newspaperEditionDate),
      format = "%Y-%m-%d %H:%M:%S",
      tz = "GMT"
    )
    
    out$firstPublicationDate <- as.POSIXct(
      gsub("T|Z", "", out$firstPublicationDate),
      format = "%Y-%m-%d %H:%M:%S",
      tz = "GMT"
    )
    
    return(out)
}


#' @noRd
#' @importFrom utils download.file
#' @importFrom RCurl getURL
#' @importFrom rjson fromJSON
get_json <- function(keywords,
                     section = NULL,
                     from,
                     to,
                     api_key,
                     verbose) {
  
  request <- paste0(
    "http://content.guardianapis.com/search?q=", keywords, 
    if (!is.null(section)) "&section=", section, 
    "&from-date=", from, 
    "&to-date=", to,
    "&format=json", 
    "&show-fields=all&page=", 1,
    "&page-size=", 1, 
    "&api-key=", api_key
  )
  
  response <- getURL(request, timeout = 240, .encoding = 'UTF-8')
  
  json <- rjson::fromJSON(response, simplify = FALSE)
  
  if (json$response$status == "error") {
    stop(json$response$message)
  }
  
  total_found <- json$response$total
  pages <- ceiling(total_found / 100)
  
  if (verbose) {
      message(pages, " pages of results found. Retrieving...")
  }
  
  out <- lapply(seq(pages), function(page) {
    request <- paste0(
      "http://content.guardianapis.com/search?q=", keywords, 
      if (!is.null(section)) "&section=", section, 
      "&from-date=", from, 
      "&to-date=", to,
      "&format=json", 
      "&show-fields=all&page=", page,
      "&page-size=", 100, 
      "&api-key=", api_key
    )
    
    response <- getURL(request, timeout = 240, .encoding = 'UTF-8')
    
    json <- rjson::fromJSON(response, simplify = FALSE)
    if (verbose) {
      message("\t...page ", page)
    }
    
    return(json$response)
  })
  
  return(out)
}


#' @noRd
#' @importFrom tibble tibble
parse_to_df <- function(res) {
  select_vars <- c(
    "id",
    "type",
    "sectionId",
    "sectionName",
    "webPublicationDate",
    "webTitle",
    "webUrl",
    "apiUrl",
    "isHosted",
    "pillarId",
    "pillarName",
    "headline",
    "standfirst",
    "trailText",
    "byline",
    "main",
    "body",
    "newspaperPageNumber",
    "wordcount",
    "firstPublicationDate",
    "isInappropriateForSponsorship",
    "isPremoderated",
    "lastModified",
    "newspaperEditionDate",
    "productionOffice",
    "publication",
    "shortUrl",
    "shouldHideAdverts",
    "showInRelatedContent",
    "thumbnail",
    "legallySensitive",
    "sensitive",
    "lang",
    "bodyText",
    "charCount",
    "shouldHideReaderRevenue",
    "starRating",
    "commentCloseDate",
    "commentable" 
  )
  
  out <- lapply(res$results, function(r) {
    fields <- r[["fields"]]
    r[["fields"]] <- NULL
    df <- tibble::as_tibble(c(r, fields))
    df <- df[colnames(df) %in% select_vars]
    df[select_vars[!select_vars %in% colnames(df)]] <- NA
    df <- df[, select_vars] 
    return(df)
  })
  
  out <- do.call(rbind, out)
  
  return(out)
}


#' @noRd
#' @importFrom xml2 xml_text read_html
parse_html <- function(str) {
    str <- gsub("</p>", "\n</p>", str, fixed = TRUE)
    return(xml2::xml_text(xml2::read_html(str), trim = TRUE))
}
