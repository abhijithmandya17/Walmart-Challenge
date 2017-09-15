#Call libraries used in the code
library(tidyverse)
library(anytime)
library(sqldf)
library(ggplot2)
library(dplyr)
library(reshape)
library(arules)
library(arulesViz)
library(igraph)

#Read tsv file, choose class as character to avoid loss of information in UPC, order_time and order_id variables
data <- read.delim('4729-2038.tsv', colClasses = "character")

#Unix timestamp comes with millisec information. 
#As they are all 0s, divide by 1000 and run the anytime package to give a usable format
data$order_time <- anytime(as.numeric(data$order_time)/1000)

#Strip order_time to give individual time points like, day, date, hour
data$DATE1=strptime(data$order_time, "%Y-%m-%d %H:%M:%S",tz="")
data$Day=format(data$DATE1, "%A")
data$DATE<-strftime(data$DATE,"%d/%m/%Y")
data$Hour=format(data$DATE1, "%H")
data$DATE1<-NULL

#convert required variables back to numeric since they were all imported as character
#to further process them 
cols = c("store_number", "department", "register","amount", "Hour");    
data[,cols] = apply(data[,cols], 2, function(x) as.numeric(x))

#Check summary of each variable to see if the basic statistics look right
summary(data)

#Turns out 938 or ~1% of the transactions were 0 or negative
#These transactions were most probably discounts/returns/free with another UPC
#Removing them gives a more accurate picture of the transactions
bad_transactions <- data[data$amount<=0,]
summary(bad_transactions)

#Remove all bad transactions from the data set
data <- data[!data$amount<=0, ]

#Department-wise inspection producecd a set of 231 transactions which were unusually high
#A deeper look confirmed that they were money transfers and not actual upc transactions for goods sold.
#there were 1430 transactions demarcated as department 35 or 38 which had a NULL description 
#I replaced those descriptions with the name to improve readability later on

dept_86 <- data[data$department == 86,]

for (i in 1:nrow(data)){
  if (data$description[i] == "NULL")
  {(data$description[i] = data$name[i])}
}

#I have removed them from this data set to avoid 
#any skew in data because of these small but significant transactions
data <- data[!data$department == 86, ]

#t <- filter(data, grepl("ria send",description, ignore.case = T))

#Analysis for store_number 2222 designated as walmart. Although it could easily be Sam's club
#2222 had ~75% of the transactions thus it made sense to investigate this first
##########################

#Subset data for store_number 2222
walmart <- data[data$store_number == 2222,]

#Since we have 2 days worth of data, an hour by hour trend analysis would make the most sense.
#the same kind of analysis could easily be applied across 
#any time period, type of stores, geographical location given data.
hour_bill_trend <- sqldf("select Day, Hour, count(distinct order_id) as unique_bills, 
                          sum(amount) as sales, count(upc) as products from walmart group by 1,2")

#The above summary contains Day-wise, hour-wise break up of the distinct bills cut, 
#Total sales in that period and number of products sold

#Atomize sales/hour to give a clear picture of the most productive hour across each day
hour_bill_trend$bill_value <- hour_bill_trend$sales/hour_bill_trend$unique_bills

#Plot produced is a hour wise line chart each day in the data set
ggplot(hour_bill_trend, aes(Hour,sales)) + geom_line(aes(color=Day, group=Day), size=2)+geom_smooth()+
scale_x_continuous(breaks = seq(min(hour_bill_trend$Hour), max(hour_bill_trend$Hour)))

ggplot(hour_bill_trend, aes(Hour,unique_bills)) + geom_line(aes(color=Day, group=Day), size=2)+geom_smooth()+
  scale_x_continuous(breaks = seq(min(hour_bill_trend$Hour), max(hour_bill_trend$Hour)))

ggplot(hour_bill_trend, aes(Hour,products)) + geom_line(aes(color=Day, group=Day), size=2)+geom_smooth()+
  scale_x_continuous(breaks = seq(min(hour_bill_trend$Hour), max(hour_bill_trend$Hour)))

#The other plots for products and bills don't seem to ass anything new
#to what information we can gain from sales plot itself


#Reading into it, it's clear the busiest time at the store is 
#between 4-7pm on a Saturday easily breaching the $20k/hour mark. Probably preparing for a party or dinner
#Further, since the total sales and bills cut on a weekend is roughly equal to the total sales on the weekdays 
#it's safe to assume this is probably the busiest day of the week barring, 
#Black Fridays or special discount weekends when the traffic could be higher
#We can see delayed onset on Friday, 7-9 would be it's peak 
#owing to the some last min shopping on their way back home for the weekend 
#Sunday afternoon matches it's Saturday counterpart but only at noon otherwise it seems to fall off sharply.
#I'd call this the death due to the Monday Morning Dread

###################################
#Lets see what sold on Saturday 4-7pm

###################################

peak <- data[walmart$Day == "Saturday" & walmart$Hour >= 16 & walmart$Hour < 19,]

#Those 3 hours make up a huge 15.67% of all sales in the given 48 hour period 
sum(peak$amount)/sum(data$amount)

#Summarize department trend based on sales.
department_trend_sat_peak <- sqldf("select department,sum(amount) as sales, 
                          count(distinct order_id) as unique_bills from peak group by 1")

#Check top 4 departments with combination of bills and sales
dept_95 <- peak[peak$department == 95,]
dept_2 <- peak[peak$department == 2,]
dept_40 <- peak[peak$department == 40,]
dept_92 <- peak[peak$department == 92,]

#Department 2 or Personal Care rakes in the highest sales and has 418 bills which is 2nd best after 
#Department 95 or Party snack and mixers. Probably preparing for evening/night ahead.
#Department 40 was Water, energy drinks, vitamins. Looks like people want to be well hydrated through the party
#Department 92 or homefoods like Ramen or cereal made up the rest of the majority

sat_peak_products <- sqldf("select department, description, count(description) as count, 
                           sum(amount) as sales from peak group by 1,2")
#Drilling down the most bought items were from the pharmacy and Gasoline, 

#Reproducing this for Friday and Sunday to see if there were any changes in buying patterns
#comapred to peak time on Saturday
sunday <- data[data$Day == "Sunday",]
friday <- data[data$Day == "Sunday",]

department_trend_sun <- sqldf("select department,sum(amount) as sales, 
                          count(distinct order_id) as unique_bills from sunday group by 1")

sun_products <- sqldf("select department, description, count(description) as count, 
                           sum(amount) as sales from sunday group by 1,2")


department_trend_fri <- sqldf("select department,sum(amount) as sales, 
                          count(distinct order_id) as unique_bills from friday group by 1")

fri_products <- sqldf("select department, description, count(description) as count, 
                           sum(amount) as sales from sunday group by 1,2")

#The top 4 departments and top products remained unchanged

###########################

#Investigating the register
###########################

#Summarize by register to check performance
registers <-group_by(walmart, register) %>% summarize(amount = n())

#As expected there is no linear relationship between the number, thus placement and sales
summary(lm(register~amount, data =registers))

###########################
#Market Basket
###########################

#Create summary of order_id and product
prod_id<-sqldf("select order_id as trans_id, description as prod_id from walmart group by 1,2")
write.csv(prod_id, "prod_id.csv",row.names=FALSE)

#Read it in as a transaction
WM = read.transactions("prod_id.csv", format = "single", sep = ",", cols = c(1,2))
#apply apriori package with a support minima of 0.001, and confidence limit of 95%
rules<-apriori(data=WM, parameter=list(supp=0.001,conf = 0.05,minlen=2,maxlen=2),control = list(verbose=F))
#sort rules by highest confidence
rules<-sort(rules, decreasing=TRUE,by="confidence")
#inspect top 5 rules 
inspect(rules[1:5])
#convert rules to dataframe for ease of view
final = as(rules, "data.frame")

#create a set of subrules to be visualized and plot using the igraph library
subrules2 <- head(sort(rules, by="lift"), 20)
plot(subrules2, method="graph")

#sel <- plot(rules, measure=c("support", "lift"), shading="confidence", interactive=TRUE)
