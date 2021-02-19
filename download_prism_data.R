## Script name: download_prism_data.R
##
## Purpose of script: download monthly prism data for variables of interest
##
## Author: Nicole Keeney
##
## Date Created: 10-06-2020
## Last Modified: 02-17-2021 
##
## Email: nicolejkeeney@gmail.com
##
## Notes: 
## See link below for more info on prism climate data 
## https://prism.oregonstate.edu/recent/
## To run the script, make sure you have an empty prism_raw folder contained in the data folder

library(rgdal)
library(raster)
library(prism)
library(sf)
library(sp)
library(parallel)

# ------------------- define desired variable --------------

#vars <- c('tmax', 'tmin','ppt') # These must correspond to PRISM variables
vars <- c('tmean','ppt')

#years <- 1981:2017 # Desired range of years to get data for
years <- 2018:2020
  
mons <- 1:12 # Desired months to get data for

#define current working directory
#cwd <- "/global/scratch/nicolekeeney/cocci_project_savio" #working directory for cocci_project in savio 
cwd <- "/Users/nicolekeeney/github_repos/prism" #local machine

#----------------- download data for each variable ------------------

for(var in vars){

  #define directory path 
  dirPath <- paste(cwd, 'data', 'prism_raw', var, sep = '/')

  #download data 
  print(paste0('Downloading monthly data for ',var, ' ...'))
  print(paste0('Years: ', years[1], '-', tail(years, n = 1)))
  options(prism.path = dirPath) #set location for where to download data to
  get_prism_monthlys(var, year = years, mon = mons, keepZip = FALSE) #get data!
}

