## Script name: combine_gridded_prism_files.R
##
## Purpose of script: combine gridded prism data into one csv
##
## Author:Nicole Keeney
##
## Date Created: 10-15-2020
## Last Modified: 02-18-2021  
##
## Email: nicolejkeeney@gmail.com

library(plyr)

# read files from prism_gridded folder
files <- list.files("data/prism_gridded", full.names = TRUE, pattern = "\\gridded.csv$")

# load files into a list of dataframe objects 
data <- lapply(my_files, read.csv)

#merge files by grid
mergedDF <- Reduce(function(x,y) merge(x,y,sort = FALSE),data)

#format date to match desired csv output 
datetimeDate <- as.Date(mergedDF$date, "%Y-%m-%d")
mergedDF$month <- format(datetimeDate, "%m")
mergedDF$year <- format(datetimeDate, "%Y")

#remove unwanted columns 
mergedDF$X <- NULL #index column 
mergedDF$date <- NULL #date column
View(mergedDF)

#save csv to local machine 
write.csv(finalDF, file = "data/prism_gridded/prism_gridded_all.csv", row.names=FALSE)
