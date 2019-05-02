
<!-- README.md is generated from README.Rmd. Please edit that file -->

# GuardianR

<!-- badges: start -->

<!-- badges: end -->

GuardianR provides an interface to the Open Platform’s Content API of
the Guardian Media Group. It retrieves content from news outlets The
Observer, The Guardian, and guardian.co.uk from 1999 to current day. See
[CRAN](https://cran.r-project.org/web/packages/GuardianR/index.html) for
the original package.

## About this fork

In this fork I changed a few things in the functions to make them
compatible with my own work.

## Installation

You can install the released version of GuardianR from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("GuardianR")
```

You can intall this fork from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("JBGruber/GuardianR")
```

## Example

This is a basic example:

``` r
library("GuardianR")
results <- get_guardian(
  keywords = "Theresa May AND (Brexit OR EU)",
  from = "2019-01-16",
  to = "2019-01-30",
  api_key = "212d23d3-c7b2-4273-8f1b-289a0803ca4b"
)
#> Fetched page #1 of 5
#> Fetched page #2 of 5
#> Fetched page #3 of 5
#> Fetched page #4 of 5
#> Fetched page #5 of 5
results
#> # A tibble: 100 x 41
#>    id    type  sectionId sectionName webPublicationD… webTitle webUrl
#>    <chr> <chr> <chr>     <chr>       <chr>            <chr>    <chr> 
#>  1 poli… arti… politics  Politics    2019-01-19T19:3… Voters … https…
#>  2 poli… arti… politics  Politics    2019-01-22T09:3… Brexit … https…
#>  3 poli… arti… politics  Politics    2019-01-30T19:4… Theresa… https…
#>  4 poli… arti… politics  Politics    2019-01-28T21:0… Theresa… https…
#>  5 poli… arti… politics  Politics    2019-01-30T16:2… Theresa… https…
#>  6 poli… arti… politics  Politics    2019-01-30T13:0… Jeremy … https…
#>  7 poli… arti… politics  Politics    2019-01-18T20:0… Theresa… https…
#>  8 poli… arti… politics  Politics    2019-01-16T10:2… Theresa… https…
#>  9 poli… arti… politics  Politics    2019-01-17T00:5… Theresa… https…
#> 10 poli… arti… politics  Politics    2019-01-30T16:5… Brussel… https…
#> # … with 90 more rows, and 34 more variables: apiUrl <chr>,
#> #   isHosted <lgl>, pillarId <chr>, pillarName <chr>, headline <chr>,
#> #   standfirst <chr>, trailText <chr>, byline <chr>, main <chr>,
#> #   body <chr>, wordcount <chr>, firstPublicationDate <chr>,
#> #   isInappropriateForSponsorship <chr>, isPremoderated <chr>,
#> #   lastModified <chr>, newspaperEditionDate <chr>,
#> #   productionOffice <chr>, publication <chr>, shortUrl <chr>,
#> #   shouldHideAdverts <chr>, showInRelatedContent <chr>, thumbnail <chr>,
#> #   legallySensitive <chr>, sensitive <chr>, lang <chr>, bodyText <chr>,
#> #   charCount <chr>, shouldHideReaderRevenue <chr>,
#> #   showAffiliateLinks <chr>, newspaperPageNumber <chr>,
#> #   commentCloseDate <chr>, commentable <chr>, liveBloggingNow <chr>,
#> #   displayHint <chr>
```
