#---------------------------------------------------------------------------------
# twitter.R
#
# The MIT License
#
# Copyright (c) 2010 Takeshi Arabiki (@a_bicky)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#---------------------------------------------------------------------------------
source("OAuth.R")
library(RJSONIO)

# make parameters for OAuth
makeParams <- function(uri, method, argv, auser) {
    nonce <- generateRandomString()
    timestamp <- as.integer(Sys.time())
    token <- auser['token']
    secret <- auser['secret']

    keys <- c("oauth_consumer_key",
              "oauth_signature_method",
              "oauth_timestamp",
              "oauth_nonce",
              "oauth_version",
              "oauth_token")
    values <- c(key.consumer, "HMAC-SHA1", timestamp, nonce, "1.0", token)
    if (!is.null(names(argv))) {
        keys <- c(keys, names(argv))
        values <- c(values, argv)
    }
    
    params <- data.frame(key=keys, value=values)
    signature <- signForOauth(uri, method, params, secret)
    rbind(params, data.frame(key="oauth_signature", value=signature))
}


# request to API and get the response
# twitterRequest(apiURI, method, argv, verbose)
# apiURI:   URI of Twitter API
# method:   "GET" or "POST"
# argv:     parameters for API  e.g. c(page = 2, count = 200)
# varbose:  whether to output HTTP response
twitterRequest <- function(uri, method = "GET", argv = c(), verbose = FALSE, auser) {
    if (missing(auser)) {
        auser <- evalq(auser, envir = globalenv())
    }
    query <- ""
    if (!is.null(names(argv))) {
        argv <- sapply(argv, function(x) uriEncode(as.character(x)))
        query <- paste(names(argv), argv, sep="=", collapse="&")
    }
    params <- makeParams(uri, method, argv, auser)
    
    if (method == "POST") {
        getURL(url = uri,
               verbose = verbose,
               httpheader = c(Expect = "",
                 Authorization = generateOauthHeader(params)),
               postfields = query)
    } else if (method == "GET") {
        getURL(url = ifelse(exists("query"), paste(uri, query, sep="?"), uri),
               verbose = verbose,
               httpheader = c(Expect = "",
                 Authorization = generateOauthHeader(params)))
    }
}


# request to API and get the response. If cannot get a desired response, try again.
# tryRequest(apiURI, method, argv, verbose, ntry)
# apiURI:   URI of Twitter API
# method:   "GET" or "POST"
# argv:     parameters for API  e.g. c(page = 2, count = 200)
# varbose:  whether to output HTTP response
# ntry:     upper limit for number of trials
tryRequest <- function(uri, method = "GET", argv = c(), verbose = FALSE, ntry = 3) {
    i <- 0
    while (i <= ntry) {
        i <- i + 1
        json <- twitterRequest(uri, method, argv, verbose)
        ## if receive string like "<!DOCTYPE html>..., try again
        ## unless number of trials is larger than ntry"
        if (substr(json, 1, 1) != "<") {
            break
        }
        json <- FALSE
    }
    json
}



# get user information
# getUsers(user = NULL, argv = c(), verbose = FALSE)
# users:    IDs (numeric vector) or screen names (string vector) whose information you want to get.
#           If the value is NULL, get the authenticated user's information.
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getUsers <- function(users = NULL, argv = c(), verbose = FALSE) {
    if (!is.null(users) || any(names(argv) %in% c("user_id", "screen_name"))) {
        uri <- "http://api.twitter.com/1/users/lookup.json"
        
        json <- rep(NA, (length(users) - 1) %/% 100 + 1)
        i <- 1
        while(length(users) > 0 || is.null(users)) {
            remainUsers <- users[-(1:100)]
            users <- setdiff(users, remainUsers)
            argv <- checkArgv(users, argv)
            
            tmpjson <- tryRequest(uri, "GET", argv, verbose)
            if (is.logical(tmpjson)) {
                warning("Couldn't get all data!")
            } else {
                if (tmpjson == "[]") {
                    break
                }
                tmpjson <- substr(tmpjson, 2, nchar(tmpjson) - 1)
                json[i] <- tmpjson
            }
            if (is.null(users)) {
                break
            }
            
            i <- i + 1
            users <- remainUsers
            argv <- argv[not(argv, c("user_id", "screen_name"))]
        }
        json <- json[!is.na(json)]
        json <- sprintf("[%s]", join(",", json))        
    } else {
        uri <- "http://api.twitter.com/1/account/verify_credentials.json"
        json <- tryRequest(uri, "GET", argv, verbose)
        if (is.logical(json)) {
            stop("Couldn't get data, please try again later!")
        }
    }
    
    # NULL文字があるとパースできない
    json <- gsub("\\\\u0000", " ", json)
    # {}があるとバグる
    json <- gsub("\\{\\}", "null", json)
    
    user <- fromJSON(json)
    if(length(user) == 1) {
        user[[1]]
    } else {
        user
    }
}



# get user's tweets 
# getTweets(user = NULL, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose tweets you want to get.
#           If the value is NULL, get the authenticated user's tweets.
# n:        number of tweets you want to get
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getTweets <- function(user = NULL, n = 20, argv = c(), verbose = FALSE) {
    uri <- "http://api.twitter.com/1/statuses/user_timeline.json"
    
    argv <- checkArgv(user, argv)
    n <- checkUInt(n)

    if ("count" %in% names(argv)) {
        warning("argv['count'] is ignored!")
    }
    if ("page" %in% names(argv)) {
        warning("argv['page'] is ignored!")
    }
    
    if (n > 200) {
        argv["count"] <- 200
    } else {
        argv["count"] <- n
    }
    argv["page"] <- 1


    limit <- 3200 - (as.numeric(argv["page"]) - 1) * 200
    if (n > limit) {
        warning(sprintf("only return up to %d statuses", limit))
        n <- limit
    }

    ## warning message
    wmsg <- sprintf("Couldn't get all data! user: %s", user)
    json <- rep(NA, (n - 1) %/% 200 + 1)
    i <- 1
    while (n > 0) {
        tmpjson <- tryRequest(uri, "GET", argv, verbose)
        if (is.logical(tmpjson)) {
            warning(wmsg)
        } else {
            if (tmpjson == "[]") {
                break
            }
            tmpjson <- substr(tmpjson, 2, nchar(tmpjson) - 1)
            json[i] <- tmpjson
        }

        argv["page"] <- as.numeric(argv["page"]) + 1
        i <- i + 1
        n <- n - 200
    }
    json <- json[!is.na(json)]
    json <- sprintf("[%s]", join(",", json))
    # NULL文字があるとパースできない
    json <- gsub("\\\\u0000", " ", json)
    # {}があるとバグる
    json <- gsub("\\{\\}", "null", json)
    
    fromJSON(json)
}



# get frineds' IDs
# getFriendsIDs(user = NULL, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose friends' IDs you want to get.
#           If the value is NULL, get the friends' IDs of the authenticated user.
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getFriendsIDs <- function(user = NULL, argv = c(), verbose = FALSE) {
    getFFIDs("friends", user, argv, verbose)
}

# get followers' IDs
# getFollowersIDs(user = NULL, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose followers' IDs you want to get.
#           If the value is NULL, get the followers' IDs of the authenticated user.
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getFollowersIDs <- function(user = NULL, argv = c(), verbose = FALSE) {
    getFFIDs("followers", user, argv, verbose)
}

# get frineds' informations
# getFriends(user = NULL, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose friends' informations you want to get.
#           If the value is NULL, get the friends' informations of the authenticated user.
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getFriends <- function(user = NULL, argv = c(), verbose = FALSE) {
    getFF("friends", user, argv, verbose)
}

# get followers' informations
# getFollowersIDs(user = NULL, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose followers' informations you want to get.
#           If the value is NULL, get the followers' informations of the authenticated user.
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getFollowers <- function(user = NULL, argv = c(), verbose = FALSE) {
    getFF("friends", user, argv, verbose)
}

# get user's favorites
# getFavs(user = NULL, n = 20, n = 20, argv = c(), verbose = FALSE)
# user:     ID (numeric) or screen name (string) whose favorites you want to get.
#           If the value is NULL, get the authenticated user's tweets.
# n:        number of favorites you want to get
# argv:     other parameters for API
# varbose:  whether to output HTTP response
getFavs <- function(user = NULL, n = 20, argv = c(), verbose = FALSE) {
    n <- checkUInt(n)
    limit <- n
    
    if ("id" %in% names(argv)) {
        if (!is.null(user)) {
            warning("argv['id'] is ignored!")
        } else {
            user <- argv["id"]
            argv <- argv[not(argv, "id")]
        }
    }

    if (is.null(user)) {
        uri <- "http://api.twitter.com/1/favorites.json"
        wmsg <- "Couldn't get all data!"
    } else {
        uri <- sprintf("http://api.twitter.com/1/favorites/%s.json", user)
        wmsg <- sprintf("Couldn't get all data! user: %s", user)
    }

    if ("page" %in% names(argv)) {
        warning("argv['page'] is ignored!")
    }
    argv["page"] <- 1

    i <- 1
    json <- rep(NA, n %/% 200 + 1)
    while (n > 0) {
        tmpjson <- tryRequest(uri, "GET", argv, verbose)
        if (is.logical(tmpjson)) {
            warning(wmsg)
        } else {
            ## if there is no more data, return "[]"
            if (tmpjson == "[]") {
                break
            }
            tmpjson <- substr(tmpjson, 2, nchar(tmpjson) - 1)
            json[i] <- tmpjson
        }
        
        argv["page"] <- as.numeric(argv["page"]) + 1
        i <- i + 1
        n <- n - 20
    }

    json <- json[!is.na(json)]
    json <- sprintf("[%s]", join(",", json))
    # NULL文字があるとパースできない
    json <- gsub("\\\\u0000", " ", json)
    # {}があるとバグる
    json <- gsub("\\{\\}", "null", json)

    fromJSON(json)[1:limit]

}

getFF <- function(type, user, argv, verbose) {
    uri <- sprintf("http://api.twitter.com/1/statuses/%s.json", type)
    argv <- checkArgv(user, argv)
    if ("cursor" %in% names(argv)) {
        warning("argv['cursor'] is ignored!")
    }

    users <- list()
    argv["cursor"] <- "-1"
    while (argv["cursor"] != "0") {
        json <- tryRequest(uri, "GET", argv, verbose)
        # NULL文字があるとパースできない
        json <- gsub("\\\\u0000", " ", json)
        # {}があるとバグる
        json <- gsub("\\{\\}", "null", json)
        
        res <- fromJSON(json)
        ## sometimes 'users' may be '<NA>', so specify the index
        ## {}が原因だったっぽい
        users <- c(users, res$users)
        ##users <- c(users, res[[1]])
        argv["cursor"] <- res$next_cursor_str
    }
    
    users
}

getFFIDs <- function(type, user, argv, verbose) {
    uri <- sprintf("http://api.twitter.com/1/%s/ids.json", type)

    argv <- checkArgv(user, argv)
    
    json <- tryRequest(uri, "GET", argv, verbose)
    if (is.logical(json)) {
        stop("Couldn't get data, please try again later!")
    }
    # NULL文字があるとパースできない
    json <- gsub("\\\\u0000", " ", json)
    # {}があるとバグる
    json <- gsub("\\{\\}", "null", json)    

    unlist(fromJSON(json))
}







not <- function(x, name) {
    -which(names(x) %in% name)
}

is.int <- function(n) {
    if (!is.numeric(n)) {
        FALSE
    } else {
        n %% 1 == 0
    }
}

join <- function(collapse, str) {
    paste(str, collapse = collapse)
}

checkArgv <- function(user, argv) {
    check <- function(argv) {
        if ("user_id" %in% names(argv)) {
            warning("user_id specified in argv is ignored!")
            argv <- argv[not(argv, "user_id")]
        }
        if ("screen_name" %in% names(argv)) {
            warning("screen_name specified in argv is ignored!")
            argv <- argv[not(argv, "screen_name")]
        }
        argv
    }
    
    if (is.numeric(user)){
        argv <- check(argv)
        argv["user_id"] <- join(", ", user)
    } else if (is.character(user)) {
        argv <- check(argv)
        argv["screen_name"] <- join(", ", user)
    } else if (!is.null(user)) {
        stop("Error: invalid arguments!")
    }

    argv    
}

checkUInt <- function(n) {
    nName <- substitute(n)
    if (!is.numeric(n)) {
        n <- as.numeric(n)
        if (is.na(n)) {
            stop(sprintf("'%s' is an invalid value!", as.character(nName)))
        }    
    }
    
    if (n <= 0) {
        stop(sprintf("'%s' must be a positive value!", as.character(nName)))
    } else if (!is.int(n)) {
        warning(sprintf("'%s' is casted to integer!", as.character(nName)))
        n <- as.integer(n)
    }

    n
}
