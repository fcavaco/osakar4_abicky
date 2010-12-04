# plot.factor �� factor ���v���b�g
plotFactor <- function(fdata, col, breaks = NULL, ...) {
    plot(fdata, xlab = "", ylab = "", col = col, border = color, space=0.7, ...)
}

# ggplot2 �� factor ���v���b�g
plotGG <- function(fdata, col, breaks = NULL) {
    # ���̖���data���w�肷�邩�����w�肷��K�v������
    #c <- ggplot(mapping = aes(fdata))
    #c <- ggplot(as.data.frame(fdata), aes(fdata))
    c <- ggplot(mapping = aes(fdata), environment = environment())
    c <- c + geom_bar(fill = col, alpha = 0.7, width = 0.7) + xlab("") + ylab("")
    if (!is.null(breaks) && breaks > 0) {
        c <- c + scale_x_discrete(breaks = levels(fdata)[seq(1, length(levels(fdata)), len = breaks)])
    }
    print(c)
}

# �ړI�̃O���t�ɍ����� factor ���쐬
makeFactor <- function(dates, type = c("days", "months", "weekdays", "times", "types"), levs = NULL) {
    type <- match.arg(type)
    form <- switch(type,
                   days = ifelse(difftime(dates[1], dates[length(dates)]) > 365, "%y/%m/%d", "%m/%d"),
                   months = "%Y/%m",
                   weekdays = "%a",
                   times = "%H",
                   types = "")
    data <- format(dates, form)
    if (type == "times") {
        data <- sub("^0", " ", data)
    }
    if (is.null(levs)) {
        levs <- rev(unique(data))
    }
    # return �͂ǂ�����H
    fdata <- factor(data, levels = levs, order = TRUE)
}

# �ړI�̃O���t���v���b�g
plotTwilog <- function(dates, type = c("days", "months", "weekdays", "times", "types"), col, levs = NULL, breaks = NULL, n = NULL, ...) {
    fdata <- makeFactor(dates, type, levs)
    if (!is.null(n) && n < length(levels(fdata))) {
        fdata <- fdata[!(fdata %in% levels(fdata)[1:(length(levels(fdata)) - n)]), drop = TRUE]
    }
    
    # plot.factor
    cat("plot using plot.factor\n")
    plotFactor(fdata, col = col)
    readline("Press Enter to continue")
    
    # ggplot2
    cat("plot using ggplot2\n")
    plotGG(fdata, col = col, breaks)
}

# ���v�Ԃ₫�����ڂ��v���b�g
plotTrans <-function(y, fdata, yrange, col = "green", n = NULL) {
    if (!is.null(n) && n < length(levels(fdata))) {
        fdata <- fdata[!(fdata %in% levels(fdata)[1:(length(levels(fdata)) - n)]), drop = TRUE]
    }
    
    # plot.default
    cat("plot using plot.default\n")
    plot(y , ylim = yrange, col = col, type = "l", xaxt = "n", xlab = "", ylab = "")
    axis(1, label = names(y), at = 1:min(n, length(cumsums)))
    readline("Press Enter to continue")
    
    # ggplot2
    cat("plot using ggplot2\n")
    c <- ggplot(mapping = aes(as.Date(levels(fdata), format = form), y), environment = environment())
    c <- c + geom_line(color = col) + xlab("") + ylab("") + ylim(yrange)
    c <- c + scale_x_date(format = form)
    print(c)
}