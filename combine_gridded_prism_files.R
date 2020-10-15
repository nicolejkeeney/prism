## Script name: combine_gridded_prism_files.R
##
## Purpose of script: combine gridded prism data into one csv for Karen
##
## Author: Nicole Keeney
##
## Date Created: 10-15-2020
##
## Email: nicolejkeeney@gmail.com

library(plyr)

#load csv files from local machine
ppt <- read.csv("prism_gridded/ppt_counties.csv")
tmax <- read.csv("prism_gridded/tmax_counties.csv")
tmin <- read.csv("prism_gridded/tmin_counties.csv")

#check that dataframes have the same number of rows 
equalityCheck <- all(sapply(list(ppt,tmax,tmin), function(tbl) nrow(tbl) == nrow(ppt)))
print(paste('All files have the same row length?', equalityCheck, sep = ' '))

#merge files by grid
mergedDF <- Reduce(function(x,y) merge(x,y,sort = FALSE) ,list(ppt,tmax,tmin))

#rename columns
mergedDF <- rename(mergedDF, c("X"="grid cell", "sum.of.ppt"="total precip (mm)", "mean.of.tmax"="mean max temp (deg C)", "mean.of.tmin"="mean min temp (deg C)"))

#format date to match desired csv output 
datetimeDate <- as.Date(mergedDF$date, "%Y-%m-%d")
mergedDF$month <- format(datetimeDate, "%m")
mergedDF$year <- format(datetimeDate, "%Y")

#reorder columns
finalDF <- mergedDF[, c("grid cell", "month", "year", "total precip (mm)", "mean max temp (deg C)", "mean min temp (deg C)")]

#save csv to local machine 
write.csv(finalDF, file = "prism_gridded_all.csv", row.names=FALSE)