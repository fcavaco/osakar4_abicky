library(RMeCab)
useOAuth <- TRUE
source("init.R")

# �擾����c�C�[�g���^�l
n <- 200

if (!file.exists("tweetVec.RData")) {
    # �t�H���[���񂾂���Ώۂɂ��� twitter.R �̊֐�
    ids <- getFriendsIDs(screenName)
    
    tweetVec <- sapply(ids, function(id) {
        print(id)
        # twitteR �� status �N���X���쐬 twitter.R �̊֐�
        tweets <- sapply(getTweets(id, n = n), buildStatus)
        # �S�Ẵc�C�[�g��1�̕�����Ɍ���
        paste(sapply(tweets, function(x) iconv(x@text, "utf-8", "cp932")), collapse = " ")
    })
    names(tweetVec) <- ids
    save(tweetVec, file = "tweetVec.RData")
} else {
    load("tweetVec.RData")
}

# �����̃c�C�[�g���ŏ��ɒǉ�
tweetVec <- c(paste(sapply(tweets[1:n], function(x) x@text), collapse = " "), tweetVec)
names(tweetVec)[1] <- screenName

# URL���폜
tweetVec <- gsub("http:\\/\\/[\\w.#&%@\\/\\-\\?=]*", " ", tweetVec, perl = TRUE)

# �n�b�V���^�O�i# �̎�O�ɉp�����܂��̓A���_�[�X�R�A���Ȃ����́j���폜
# �ʂɐ�ǂ݁E��ǂ݂��g��Ȃ��Ă�����
tweetVec <- gsub("(?<!\\w)#\\w+", " ", tweetVec, perl = TRUE)
# ��Osaka.R�̌�ɒm��������#�̌�ɐ������������Ȃ��ꍇ�̓n�b�V���^�O�Ƃ݂Ȃ���Ȃ��炵���E�E�E

# ���[�U���i@ �̎�O�ɉp�����܂��̓A���_�[�X�R�A���Ȃ��Č��ɃA�b�g�}�[�N�̂Ȃ����́j���폜
# �ʂɐ�ǂ݁E��ǂ݂��g��Ȃ��Ă�����
tweetVec <- gsub("(?<!\\w)@\\w+(?!@)", " ", tweetVec, perl = TRUE)

# �{���Ȃ�Unicode���K���Ƃ���������

# ���o����͎̂�����
pos <- c("������","�`�e��","�ڑ���","����","����","����","�A�̎�")

#tweetMat <- docMatrixDF(tweetVec, pos, minFreq = 2)
tweetMat <- docMatrixDF(tweetVec, pos)

# �L���݂̂̌`�ԑf���������߂̐��K�\���i���̂������݂̂����o�����j
#regexp <- "^[_`~!@#$%^&*()+-={}|\\;:'\"<>?,./\\[\\]]+$"
# �X�g�b�v���[�h����`�����������E�E�E
#stopWords <- c("����", "�Ȃ�", "����", "�v��", "�ł���", "�g��")
#tweetMat <- tweetMat[!grepl(regexp, rownames(tweetMat), perl = TRUE), ]

# IDF�l
idf <- globalIDF(tweetMat)
tweetMat <- tweetMat * idf
# ���K��
tweetMat <- t(t(tweetMat) * mynorm(tweetMat))

# LSI�D�t�H���[�������Ȃ����ĈӖ����Ȃ�����
# svdMats <- svd(tweetMat)
# ���ْl��1�����̃����N���폜
# index <- svdMats$d >= 1
# D <- docsvd$d[index]
# U <- docsvd$u[,index]
# V <- docsvd$v[,index]
# lsi <- t(t(U) * D) %*% t(V)


#-----------------------------------#
# �K�w�I�N���X�^�����O (���S�A���@) #
#-----------------------------------#

# �e�c�C�[�g�i���[�U�́j�̋����s����쐬
d <- dist(t(tweetMat))
# ���S�A���@
hc <- hclust(d)
# �f���h���O������\��
plot(hc)
# �N���X�^����5�ɂȂ�Ƃ���ŃJ�b�g
hclabel <- cutree(hc, k = 5)
# �N���X�^�̕��z
print(table(hclabel))


#------------------------#
# single-path clustering #
#------------------------#

# �A�J�E���g����ID���i�[
users <- names(tweetVec)
# �ގ��x�v�Z�p�̊֐� (�R�T�C���ގ��x)
sim <- function(x, y) {
    sum(x * y) / (sqrt(sum(x^2)) * sqrt(sum(y^2)))
}
# 臒l
th <- 0.1
# ���ʂ��i�[���邽�߂̕ϐ�
clusters <- list(centroid = list(), user = list())
set.seed(1000)
# �c�C�[�g�i�A�J�E���g�j�������_���ɒ��o
index <- sample(1:ncol(tweetMat))
clusters$user[[1]] <- users[index[1]]
clusters$centroid[[1]] <- tweetMat[,index[1]]
for (i in index[-1]) {
    x <- tweetMat[,i]
    # ��x�N�g���͔�΂�
    if (all(x == 0)) next
    # �����̃N���X�^�i�̃Z���g���C�h�j�Ƃ̗ގ��x
    sims <- sapply(clusters$centroid, sim, x)
    if (max(sims) < th) {
        target <- length(clusters$user) + 1
        clusters$user[[target]] <- users[i]
        clusters$centroid[[target]] <- x
    } else {
        target <- which.max(sims)
        clusters$user[[target]] <- c(clusters$user[[target]], users[i])
        # �Z���g���C�h���X�V
        clusters$centroid[[target]] <- clusters$centroid[[target]] + (x - clusters$centroid[[target]]) / length(clusters$user[[target]])
    }
}

# �N���X�^�̕��z
print(sapply(clusters$user, length))


#---------#
# k-means #
#---------#

# �N���X�^��5�ŃN���X�^�����O
km <- kmeans(t(tweetMat), 5)
# �N���X�^�̕��z
print(km$size)



#-------------------------------------------#
# ���܂� �`�����Ɨގ��x�̍������[�U��T��` #
#-------------------------------------------#

me <- tweetMat[,1]
others <- as.data.frame(tweetMat[,-1])
# ������̒N�ł��傤�H (ID���o��)
print(users[which.max(sapply(others, sim, me)) + 1])


# ID����N���킩��Ȃ��̂ŃA�C�R�����v���b�g
id <- users[which.max(sapply(others, sim, me)) + 1]
# twitter.R �̊֐�
who <- getUsers(as.integer(id))
imgUri <- who$profile_image_url
if (grepl("png", substr(imgUri, nchar(imgUri) -2, nchar(imgUri)), ignore.case = T)) {
    library(png); library(pixmap)
    png <- getURLContent(imgUri)
    img <- readPNG(png)
     plot(pixmapRGB(img))
} else {
    library(ReadImages)
    jpg <- file("tmp.jpg", "wb")
    writeBin(as.vector(getURLContent(imgUri)), jpg)
    close(jpg)
    # �����̊��ł� Internal error �ɂȂ�܂������C���܂��̕����Ȃ̂ŋ����Ă��������E�E�E
    jpg <- read.jpeg("tmp.jpg")
    plot(jpg)
}