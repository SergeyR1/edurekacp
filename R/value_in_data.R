#loading required packages
require(ggplot2)
require(plyr) #it will mask some functions from dplyr!
require(dplyr)
fname <- c("_user_hive_warehouse_messages.db_smses_amount_day_000000_0")
#reading the data
mess <- read.csv2(fname,header = FALSE,sep = '\u0001', colClasses = c("factor",rep("numeric",4)))
#type conversion (factor -> string -> Integer)
#words_c <- data.frame(words$month,words$day, words$hour, as.integer(as.character(words$type)), 
#                     as.integer(as.character(words$love)), as.integer(as.character(words$kiss)), as.integer(as.character(words$thanks)))
colnames(mess) <- c("date","partner","sms_type","sms_num","sms_amount")
mess <- transform(mess, partner = factor(as.character(mess$partner),levels=c("1","2"),labels =c("Nastya","Serj")),
sms_type = factor(as.character(mess$sms_type),levels=c("1","2"),labels=c("SMS","MMS")))

#summary по сообщениям
summary(mess)

#removing outliers
messagg <- dplyr::group_by(mess,sms_type,partner)
stddev_amount <- dplyr::summarize(messagg,sd(sms_amount))
stddev_num <- dplyr::summarize(messagg,sd(sms_num))
mean_amount <- dplyr::summarize(messagg,mean(sms_amount))
mean_num <- dplyr::summarize(messagg,mean(sms_num))

dflist <- list(mess,mean_amount,stddev_amount)
mess_join <- join_all(dflist)
mess_join$ones <- 1

colnames(mess_join)[c(6,7,8)] <- c("mean_sms_amount","sd_sms_amount","ones")

non_outliers <- ((mess_join$sms_amount >= mess_join$mean_sms_amount - 3*mess_join$sd_sms_amount) & 
                   (mess_join$sms_amount <= mess_join$mean_sms_amount + 3*mess_join$sd_sms_amount)) # +- 3 std. dev

mess_clean <- mess_join[non_outliers,] 

summary(mess_clean[mess_clean$sms_type == "SMS" & mess_clean$partner == "Nastya",])
summary(mess_clean[mess_clean$sms_type == "SMS" & mess_clean$partner == "Serj",])
summary(mess_clean[mess_clean$sms_type == "MMS" & mess_clean$partner == "Nastya",])
summary(mess_clean[mess_clean$sms_type == "MMS" & mess_clean$partner == "Serj",])

#firstplot
qplot(partner,sms_amount,data = mess_clean[mess_clean$sms_type == "SMS",], geom = "boxplot",fill = partner,ylab = "Amount of messages", xlab = "Partner", main = "Messages summary SMS")
qplot(partner,sms_num,data = mess_clean[mess_clean$sms_type == "MMS",], geom = "boxplot",fill = partner,ylab = "Number of messages", xlab = "Partner", main = "Messages summary MMS")


qplot(sms_amount,data = mess_clean[mess_clean$sms_type == "SMS",], facets = .~partner+sms_type, fill = partner,ylab = "Days", xlab = "Messages", main = "SMS by partner") + geom_histogram( colour = "black")
qplot(sms_num,data = mess_clean[mess_clean$sms_type == "MMS",], facets = .~partner+sms_type, fill = partner,ylab = "Days", xlab = "Messages", main = "MMS by partner") + geom_histogram( colour = "black")

#tests
sms_serj <- mess_clean[mess_clean$sms_type == "SMS" & mess_clean$partner == "Serj",c("sms_amount","ones")]
sms_nastya <- mess_clean[mess_clean$sms_type == "SMS" & mess_clean$partner == "Nastya",c("sms_amount","ones")]

#Poisson lambda
ls <- round(mean(sms_serj$sms_amount))
ln <- round(mean(sms_nastya$sms_amount))

set.seed(314)
sms_serj$pois <- rpois(length(sms_serj$sms_amount),ls)
set.seed(547)
sms_nastya$pois <- rpois(length(sms_nastya$sms_amount),ln)

#plotting simulated
for_plot_serj <- melt(sms_serj, id.vars=c("ones"))
for_plot_nastya <- melt(sms_nastya, id.vars=c("ones"))

p1 <- ggplot(for_plot_serj, aes(x=value, fill = variable)) + geom_histogram(binwidth=.5, alpha=.5, position="identity")
p1 <- p1 + ggtitle("SMS + Simulated Poisson for Serg") + xlab("Messages") + ylab("Days")
p1

p2 <- ggplot(for_plot_nastya, aes(x=value, fill = variable)) + geom_histogram(binwidth=.5, alpha=.5, position="identity")
p2 <- p2 + ggtitle("SMS + Simulated Poisson for Nastya") + xlab("Messages") + ylab("Days")
p2



#doesn't look very poisson, and test's reject the H0

sms_serj_agg <- aggregate.data.frame(sms_serj$ones,by = list(sms_serj$sms_amount), sum)
sms_nastya_agg <- aggregate.data.frame(sms_nastya$ones,by = list(sms_nastya$sms_amount), sum)

colnames(sms_serj_agg) <- c("n","amount")
colnames(sms_nastya_agg) <- c("n","amount")

#correction for observations (31 and 29 are missing)
sms_serj_agg[c(32:36),] <- sms_serj_agg[c(31:35),]
sms_serj_agg[31,] <- c(31,0)

sms_nastya_agg[30,] <- sms_nastya_agg[29,]
sms_nastya_agg[29,] <- c(29,0) 

#Poisson probabilities
sms_serj_agg$p <- dpois(sms_serj_agg$n,ls)
sms_nastya_agg$p <- dpois(sms_nastya_agg$n,ln)

#we need to get 1 in sum of probs for goodnes of fit
sms_serj_agg$p[36] <- sms_serj_agg$p[36] + 1 - sum(sms_serj_agg$p)
sms_nastya_agg$p[30] <- sms_nastya_agg$p[30] + 1 - sum(sms_nastya_agg$p)

res_serj <- chisq.test(sms_serj_agg$amount,p=sms_serj_agg$p,simulate.p.value = TRUE)
res_nastya <- chisq.test(sms_nastya_agg$amount,p=sms_nastya_agg$p, simulate.p.value = TRUE)

#so we will use the bootstrap to evaluate the expenditures for messages
mms_price <- 2.5
sms_price <- 0.5
mess_clean$exp <- mess_clean$sms_num*mms_price*(mess_clean$sms_type == "MMS") + mess_clean$sms_amount*sms_price*(mess_clean$sms_type == "SMS")

mess_clean_agg <- aggregate.data.frame(mess_clean$exp, by = list(mess_clean$date,mess_clean$partner),sum)
colnames(mess_clean_agg) <- c("date","partner","exp")

g1 <- ggplot(mess_clean_agg, aes(x=exp, fill = partner)) + geom_histogram(colour="black") + facet_grid(.~partner)
g1 <- g1 + xlab("RUB") + ylab("Days")+ggtitle("Daily expenditures on messages")
g1

summary(mess_clean_agg[mess_clean_agg$partner == "Serj",])
summary(mess_clean_agg[mess_clean_agg$partner == "Nastya",])

#monthly expenditures

mess_clean$month <- as.factor(substr(mess_clean$date,0,7))
mess_clean_agg_month <- aggregate.data.frame(mess_clean$exp, by = list(mess_clean$month,mess_clean$partner),sum)
colnames(mess_clean_agg_month) <- c("month","partner","exp")

g2 <- ggplot(mess_clean_agg_month, aes(x=month, y = exp, fill = partner)) + geom_bar(colour="black", stat = "identity") + facet_grid(.~partner)
g2 <- g2 + xlab("Month") + ylab("RUB")+ggtitle("Monthly expenditures on messages") + theme(axis.text.x = element_text(angle = 45, hjust = 1))
g2

#bootstrap the mean and do the CI
serj_data <- mess_clean_agg_month[mess_clean_agg_month$partner == "Serj",c("exp")]
nastya_data <- mess_clean_agg_month[mess_clean_agg_month$partner == "Nastya",c("exp")]

res_serj <- boot(data = serj_data,statistic = boot_mean,R=500)
res_nastya <- boot(data = nastya_data,statistic = boot_mean,R=500)

plot(res_serj)
plot(res_nastya)

boot.ci(boot.out = res_serj, type = "all")
boot.ci(boot.out = res_nastya, type = "all")

#graphs
qplot(sms_amount,data = mess_clean, facets = .~partner+sms_type, fill = partner) + geom_histogram( colour = "black")
