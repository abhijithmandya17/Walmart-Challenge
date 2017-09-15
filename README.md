# Walmart Challenge
Data Challenge working with a weekend data set to find interesting insights.

## Data
The provided data was anonymized and contained transactions from 2 stores, namley Walmart and Sam's Club, from 20:00 July 21nd 2017 to 20:00 July 23rd 2017. Other variables were, UPC, amount, description of product, unique, order+upc+item id, name, department to which the product belonged to and register where it was billed.

## Pre-processing
This was the most time consuming section of the challenge. 
- Data had to be read in as character to preserve the validity of the variables like the upc and order_time. Selective columns were then converted back to numeric. 
- Multiple iterations went in to quantify time from a unix output. 
- There were negative transactions mostly of returns and/or discounts. These were separated from the main data. 
- Further ~1% of the descriptions were NULL. These were surrogated from the name column.
- Department 86 was found to be money transfer rather than transactions.

## Walmart

[Hourly Sales trends were analysed.](Visualizations/Sales%20by%20Hour%20Fri-Sun.png) Reading into it, it's clear the busiest time at the store is between 4-7pm on a Saturday easily breaching the $20k/hour mark. Probably preparing for a party or dinner Further, since the total sales and bills cut on a weekend is roughly equal to the total sales on the weekdays it's safe to assume this is probably the busiest day of the week barring, Black Fridays or special discount weekends when the traffic could be higher We can see delayed onset on Friday, 7-9 would be it's peak owing to the some last min shopping on their way back home for the weekend Sunday afternoon matches it's Saturday counterpart but only at noon otherwise it seems to fall off sharply. I'd call this the death due to the Monday Morning Dread

### Peak Time analysis
Saturday evening 4-7pm is the busiest time of the weekend at this Walmart store. Those 3 hours make up a huge 15.67% of all sales in the given 48 hour period. The top 4 departments were Personal Care, Party snack and Mixers, Water and Energy drinks and Ready to eat foods like Ramen and cereal.

## Sam's Club
[A similar analysis showed a buying patters closer to noon compared to a Walmart store.](Visualizations/Sam's%20club%20Sales%20by%20hour%20Fri-Sun.png) Sale of fruits and vegetables is a runaway No. 1 Dept at Sam's Club.

## Register Performance
Since we had returned transactions, it was a slmall but interesting analysis of the register performance where I looked at the % error rate per register. Some were just used to return items but some in-use ones had an error rate up to 40%.

## Market Basket
Since we had transactions at hand, I felt it was a good idea toimplement and visualize a market basket analysis based on all bills cut. I chose a suport function of 0.001 to control the calculated probablities of smaller insignificant products. Also, a larger dataset with more transactions would warrant a smaller support function. I set the confidence limit at 95% and [vizualized it in a graphical format detailing the top 20 rules](Visualizations/Market%20Basket%20Top%2020%20rules.png)

## Conclusion and Way Forward
Buying patterns followed a usual trend seen in large retail stores. Peak hours being 4-7pm on a Saturday for a Walmart store. Sam's club being a wholesale agent had more transactions around noon which could point towards planned purcahses compared to a larger chunk of impulse purchases usually found on Friday and Saturday evenings. It would be useful to analyse cycical data (week, month, year) rather than a weekend snapshot to get a better idea of the behaviour of the store. More data from other stores across the country could enrich the analyses even further. Geo-locations of stores could be helpful in undertsanding the primary buyers in and around the area and a competition analysis too.

