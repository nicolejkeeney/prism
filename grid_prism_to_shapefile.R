## Script name: grid_prism_to_shapefile.R
##
## Purpose of script: grid prism data to input shapefile and compute monthly mean or sum for variable of interest
##
## Author: Nicole Keeney
##
## Date Created: 10-10-2020
##
## Email: nicolejkeeney@gmail.com
##
## Notes: 
## This code is adapted from a script written by Sophie Phillips
##

library(rgdal)
library(raster)
library(prism)
library(sf)
library(sp)
library(parallel)
options(stringsAsFactors = F)

#define current working directory
cwd <- "/global/scratch/nicolekeeney/cocci_project_savio" #working directory for cocci_project in savio 
#cwd <- "/Users/nicolekeeney/github_repos/cocci_project" #local machine

calcByGrid <- function(var, shapefilePath, func = "mean", csvPath = getwd()){
  # Calculate mean or sum of input var by grid cell for input raster prism data and shapefile
  # Assumes prism data is loaded into "prism/" + var (see download_prism_data.R)
  #
  # Args: 
  #   - var (character): name of prism variable-- must have corresponding folder of data 
  #   - shapefilePath (character): path to shapefile
  #   - func (character, optional): function to perform on data in each grid (must be either mean or sum, default to mean)
  #   - csvPath (character, optional): path to save output csv to (default to current working directory)
  #
  # Returns: 
  # saves csv file to machine
  
  #get path to folders containing prism data for variable 
  dataPath <- paste(cwd,"prism",var,sep = "/")
  
  #check to make sure inputs are valid 
  stopifnot((tolower(func) == "mean") | (tolower(func) == "sum"))
  stopifnot(dir.exists(dataPath)) 
  stopifnot(file.exists(shapefilePath))
  
  #column name
  dataName <- paste(func, "of", tolower(var), sep = " ")
  
  #used to detect CPU cores and make cluster 
  ncores <- detectCores()
  cl <- makeCluster(ncores)
  
  #parallelize computer with cluster cl
  #load desired packages into each cluster
  clusterEvalQ(cl, {library(prism)}) 
  
  #apply function fun to list 
  prism_list <- parLapply(cl = cl, X = dataPath, fun = function(path) {
    options(prism.path = path)
    dat <- ls_prism_data() #get list of bil datatypes
    stacks <- prism_stack(dat[1:nrow(dat),]) #get a stack of prism files
    return(stacks)
  })
  stopCluster(cl)
  
  #load shapefile with grids 
  counties <- readOGR(shapefilePath)
  counties <- spTransform(counties,crs(prism_list[[1]])@projargs)
  ext <- raster::extent(counties)
  
  stack <- prism_list[[1]]
  res_list <- list()
  
  begin <- Sys.time()
  for( i in 1:length(stack@layers)) {
    #crop prism data to shapefile 
    prismData <- stack@layers[[i]]
    crop <- raster::crop(x = prismData, y = ext) 
    
    if(tolower(func) == "mean"){
      vals <- raster::extract(crop, counties, base::mean, na.rm = TRUE)
    }
    if(tolower(func) == "sum"){
      vals <- raster::extract(crop, counties, base::sum, na.rm = TRUE)
    }
    vals <- as.list(vals)
    
    #create data frame of data
    df <- data.frame(vals) %>% tidyr::gather(key = "date", value = "data")
    colnames(df)[2] <- dataName
    
    #replace date column with columns for month and year
    date <- names(stack[[i]])
    date <- readr::parse_number(gsub(".*4kmM3_", "", date))
    date <- as.Date(paste0(date, "01"), "%Y%m%d")
    df$date <- date
    
    #add df to list 
    res_list[[i]] <- df
    gc()
  }
  
  final_df <- do.call(rbind, res_list)
  final_df$County<- rep(counties$NAMELSAD, length(unique(final_df$date)))
  final_df$Geoid <- rep(counties$GEOID, length(unique(final_df$date)))
  write.csv(final_df,file = paste0(csvPath, "/", var, "_counties.csv")) 
  end <- Sys.time()
  print(end - begin)
}

#shapefile path 
shapefilePath = paste0(cwd,"/lim_CA_grid/lim_CA_grid.shp")

#path to save csv files to 
csvPath = paste(cwd, "prism_gridded", sep = '/')

#get mean max temp by grid cell 
calcByGrid(var = "tmax", func = "mean", shapefilePath = shapefilePath, csvPath = csvPath)

#get mean min temp by grid cell 
calcByGrid(var = "tmin", func = "mean", shapefilePath = shapefilePath, csvPath = csvPath)

#get total monthly precip by grid cell 
calcByGrid(var = "ppt", func = "sum", shapefilePath = shapefilePath, csvPath = csvPath)
