library(twitteR)
library(ggplot2)

# ����J���[�U�̏ꍇ�̓A���R�����g
#useOAuth <- TRUE
if (!exists("useOAuth")) {
    useOAuth <- FALSE
}

# %a�̕\�L���p��ɂ���
Sys.setlocale("LC_TIME", "ENG")
# ����RT�������̂Ŏ��ۂ�3200��菭�Ȃ��Ȃ�
screenName <- "Twitter�̃A�J�E���g��"
if (useOAuth) {
    source("twitter.R")
    source("json.R")
    # authenticated user
    # �A�N�Z�X�g�[�N���Ȃ�
    auser <- c(
               token = "Twitter�A�J�E���g�̃A�N�Z�X�g�[�N��",
               secret = "Twitter�A�J�E���g�̃A�N�Z�X�V�[�N���b�g"
               )
    # �R���V���[�}�L�[�Ȃ�
    key.consumer <- "�A�v���̃R���V���[�}�L�["
    secret.consumer <- "�A�v���̃R���V���[�}�V�[�N���b�g"

    user <- buildUser(getUsers(screenName))
    if (!file.exists("tweets.RData")) {
        tweets <- sapply(getTweets(screenName, n = 3200), buildStatus)
        # UTF-8���瑭�Ɍ���Shift_JIS�Ƃ����킯�̂킩��Ȃ������R�[�h�ɕϊ�
        for(i in 1:length(tweets)) {
            tweets[[i]]@text <- iconv(tweets[[i]]@text, "utf-8", "cp932")
        }        
        save(tweets, file = "tweets.RData")        
    } else {
        load("tweets.RData")
    }
} else {
    user <- getUser(screenName)
    if (!file.exists("tweets.RData")) {
        tweets <- userTimeline(screenName, n = 3200)
        # UTF-8���瑭�Ɍ���Shift_JIS�Ƃ����킯�̂킩��Ȃ������R�[�h�ɕϊ�
        for(i in 1:length(tweets)) {
            tweets[[i]]@text <- iconv(tweets[[i]]@text, "utf-8", "cp932")
        }        
        save(tweets, file = "tweets.RData")
    } else {
        load("tweets.RData")
    }
}