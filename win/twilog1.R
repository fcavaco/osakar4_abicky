# �֐��g��Ȃ��o�[�W����
# �u�����g���ǏC������ς������E�E�E

source("init.R")

#----------#
#  �����  #
#----------#
cat("�����\n")

# �c�C�[�g�����𒊏o�Dlapply ���ƃ��X�g�ŕԂ��Ă���̂ň����ɂ����D
dates <- sapply(tweets, function(x) x@created)
# �����I�u�W�F�N�g (POSIXct) �ɕϊ��Dsapply ���Ƒ�����������̂� structure �ő�����t��������
dates <- structure(dates, class = c("POSIXt", "POSIXct"), tzone = "Asia/Tokyo")
# dates ���o�͂���Ƃ��̃t�H�[�}�b�g
# (�擾�����c�C�[�g�̓����̍���1�N�ȏ�Ȃ�"�N/��/��"�C�����łȂ����"��/��")
form <- ifelse(difftime(dates[1], dates[length(dates)]) > 365, "%y/%m/%d", "%m/%d")
# ������ɕϊ�
days <- format(dates, form)
# �ł��Â��c�C�[�g����ŐV�̃c�C�[�g�܂ł̓��t�idays�Ɠ����\���`���j
alldays <- format(seq(as.Date(dates[length(dates)]), as.Date(dates[1]), by = "days"), format = form)
# days �̈��q�D�����Ƃ��� alldays ���w��
fdays <- factor(days, levels = alldays, order = TRUE)
# �������Ƃ̃J�E���g�i�����ɂ��Ȃ��ƂԂ₩�Ȃ������l������Ȃ��j
dtable <- table(fdays)
# �c�C�[�g���Ƃ̂Ԃ₫������
tnchar <- sapply(tweets, function(x) nchar(x@text))
# ���t���Ƃ̂Ԃ₫������
dnchar <- tapply(tnchar, fdays, sum)
dnchar <- ifelse(is.na(dnchar), 0, dnchar)

# ����"�^"���������\������Ȃ��E�E�E
data <- data.frame("���Ԃ₫��" = length(tweets),
                   "�Ԃ₢������" = length(unique(days)),
                   "�Ԃ₩�Ȃ���������" = sum(dtable == 0),
                   #"�Ԃ₩�Ȃ���������" = length(setdiff(alldays, days)),
                   "����̕��ςԂ₫��" = round(mean(dtable), 1),
                   "����̍ō��Ԃ₫��" = max(dtable),
                   "�Ԃ₫������" = sum(tnchar),
                   "�Ԃ₫�������^��" = round(mean(tnchar), 1),
                   "�Ԃ₫�����^��" = round(mean(dnchar)),
                   "�R�~���j�P�[�V������" = round(sum(grepl("(?<!\\w)@\\w+(?!@)", sapply(tweets, function(x) x@text), perl = TRUE)) / length(tweets), 3),
                   "�t�H�����[�^�t�H���[�䗦" = round(user@followersCount / user@friendsCount, 2),
                   "�t�H���[�^�t�H�����[�䗦" = round(user@friendsCount / user@followersCount, 2))
rownames(data) <- screenName

print(data)
readline("Press Enter to continue")



#----------------------#
#  �����Ƃ̂Ԃ₫��  #
#----------------------#
cat("�����Ƃ̂Ԃ₫��\n")

# �v���b�g���鎞�̃J���[
color <- "red"

# �ŋ�30����
cat("�ŋ�30����\n")
n <- 30
fdays30 <- fdays
# �Ԃ₫������n������������΃f�[�^�����
if (length(levels(fdays)) > n) {
    fdays30 <- fdays[!(fdays %in% levels(fdays)[1:(length(levels(fdays)) - n)]), drop = TRUE]
}

# plot.factor
cat("plot using plot.factor\n")
plot(fdays30, xlab = "", ylab = "", col = color, border = color, space = 0.7)
# same as
# barplot(table(fdays30), xlab = "", ylab = "", col = color, border = color, space= 0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(fdays30))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
c <- c + scale_x_discrete(breaks = levels(fdays30)[seq(1, length(levels(fdays30)), len = 15)])
print(c)
readline("Press Enter to continue")


# �ŋ�90����
cat("�ŋ�90����\n")
n <- 90
fdays90 <- fdays
if (length(levels(fdays)) > n) {
    fdays90 <- fdays[!(fdays %in% levels(fdays)[1:(length(levels(fdays)) - n)]), drop = TRUE]
}

# plot.factor
cat("plot using plot.factor\n")
plot(fdays90, xlab = "", ylab = "", col = color, border = color, space = 0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(fdays90))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
c <- c + scale_x_discrete(breaks = levels(fdays90)[seq(1, length(levels(fdays90)), len = 15)])
print(c)
readline("Press Enter to continue")


# �S����
cat("�S����\n")

# plot.factor
cat("plot using plot.factor\n")
plot(fdays, xlab = "", ylab = "", col = color, border = color, space = 0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(fdays))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
# ��������15�ɍi��
c <- c + scale_x_discrete(breaks = levels(fdays)[seq(1, length(levels(fdays)), len = 15)])
print(c)
readline("Press Enter to continue")



#----------------------#
#  �����Ƃ̂Ԃ₫��  #
#----------------------#
cat("�����Ƃ̂Ԃ₫��\n")

color <- "yellow3"
months <- format(dates, "%Y/%m")
fmonths <- factor(months, levels = rev(unique(months)), order = TRUE)

# plot.factor
cat("plot using plot.factor\n")
plot(fmonths, xlab = "", ylab = "", col = color, border = color, space=0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(fmonths))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
print(c)
readline("Press Enter to continue")



#------------------------#
#  �j�����Ƃ̂Ԃ₫��  #
#------------------------#
cat("�j�����Ƃ̂Ԃ₫��\n")

color <- "blue"
wdays <- format(dates, "%a")
fwdays <- factor(wdays, levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"), order = TRUE)

# plot.factor
cat("plot using plot.factor\n")
plot(fwdays, xlab = "", ylab = "", col = color, border = color, space=0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(fwdays))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
print(c)
readline("Press Enter to continue")



#------------------------#
#  ���Ԃ��Ƃ̂Ԃ₫��  #
#------------------------#
cat("���Ԃ��Ƃ̂Ԃ₫��\n")

color <- "chocolate1"
times <- format(dates, "%H")
times <- sub("^0", " ", times)
ftimes <- factor(times, levels = sprintf("%2d", 0:23), order = TRUE)

# plot.factor
cat("plot using plot.factor\n")
plot(ftimes, xlab = "", ylab = "", col = color, border = color, space=0.7)
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(data.frame(), aes(ftimes))
c <- c + geom_bar(fill = color, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
print(c)
readline("Press Enter to continue")



#----------------------#
#  ���v�Ԃ₫������  #
#----------------------#
cat("���v�Ԃ₫������\n")

color <- "green"
# ���v�Ԃ₫������
cumsums <- cumsum(table(fdays))
# �c���͈̔�
yrange <- c(0, cumsums[length(cumsums)])

# �ŋ�30����
cat("�ŋ�30����\n")
y <- cumsums[-(1:(length(cumsums) - 30))]

# plot.default
cat("plot using plot.default\n")
plot(y , ylim = yrange, col = color, type = "l", xaxt = "n", xlab = "", ylab = "")
axis(1, label = names(y), at = 1:min(30, length(cumsums)))
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(as.Date(levels(fdays30), format = form), y))
c <- c + geom_line(color = color) + xlab("") + ylab("") + ylim(yrange)
c <- c + scale_x_date(format = form)
print(c)
readline("Press Enter to continue")



# �ŋ�90����
cat("�ŋ�90����\n")
y <- cumsums[-(1:(length(cumsums) - 90))]

# plot.default
cat("plot using plot.default\n")
# plot.default �̏ꍇ�C���t�̕\�L���w�肷����@���킩��Ȃ������E�E�E
plot(y , ylim = yrange, col = color, type = "l", xaxt = "n", xlab = "", ylab = "")
axis(1, label = names(y), at = 1:min(90, length(cumsums)))
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(as.Date(levels(fdays90), format = form), y))
c <- c + geom_line(color = color) + xlab("") + ylab("") + ylim(yrange)
# �ڐ���̃t�H�[�}�b�g���w��
c <- c + scale_x_date(format = form)
print(c)
readline("Press Enter to continue")


# �S����
cat("�S����\n")
y <- cumsums

# plot.default
cat("plot using plot.default\n")
plot(y, ylim = yrange, col = color, type = "l", xaxt = "n", xlab = "", ylab = "")
axis(1, label = names(y), at = 1:length(cumsums))
readline("Press Enter to continue")

# ggplot2
cat("plot using ggplot2\n")
c <- ggplot(mapping = aes(as.Date(levels(fdays), format = form), y))
c <- c + geom_line(color = color) + xlab("") + ylab("") + ylim(yrange)
c <- c + scale_x_date(format = form)
print(c)