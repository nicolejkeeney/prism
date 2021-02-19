## Script name: grid_prism_to_shapefile.R
##
## Purpose of script: grid prism data to input shapefile and compute monthly mean or sum for variable of interest
##
## Author: Nicole Keeney
##
## Date Created: 10-10-2020
## Last Modified: 02-17-2021
##
## Email: nicolejkeeney@gmail.com
##
## Notes: 
## This code is adapted from a script written by Sophie Phillips
## Make sure you check the column names of the input shapefile. You'll need to add this into the code within the function when you create the output csv.

library(rgdal)
library(raster)
library(prism)
library(sf)
library(sp)
library(parallel)
library(exactextractr)
options(stringsAsFactors = F)

# Define current working directory
#cwd <- "/global/scratch/nicolekeeney/cocci_project_savio" #working directory for cocci_project in savio 
cwd <- "/Users/nicolekeeney/github_repos/prism" #local machine

# Define shapefile of interest (use the folder name not the path to a shapefile)
shapefile <- 'tl_2016_06_tract'

# Define variables of interest 
# These must correspond to PRISM variables
vars <- c('tmean','ppt') 

calcByGrid <- function(var, shapefilePath, func = "mean", csvPath = getwd(), crs = 4326){
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
  begin <- Sys.time()
  print(paste0("Extracting data for ", var, "..."))
  
  #get path to folders containing prism data for variable 
  dataPath <- paste(cwd, "data", "prism_raw", var , sep = "/")
  
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
  
  # Check if data download from PRISM API worked. This has downloaded empty folders for me before. If this happens, just go to the PRISM website and download the bil folders directly, and put them in the correct location in the data folder to replace the empty folder. 
  lapply(list.files(dataPath), function(x){
    len_dir <- length(list.files(paste(dataPath,x,sep = '/')))
    if (grepl('provisional', x, fixed = TRUE)){ 
      stop(paste0("Error: ", x , " is a folder of provisional data. In order to run this script, delete provisional prism data from the prism_raw folder."))
    }
    if (len_dir==0){
      stop(paste0("Error: ", x , " is an empty folder. Download data from the prism website."))
    }
  })
  
  #apply function fun to list 
  prism_list <- parLapply(cl = cl, X = dataPath, fun = function(path) {
    options(prism.path = path)
    dat <- ls_prism_data() #get list of bil datatypes
    stacks <- prism_stack(dat[1:nrow(dat),]) #get a stack of prism files
    return(stacks)
  })
  stopCluster(cl)
  
  #load shapefile with grids 
  counties <- read_sf(shapefilePath)
  counties <- st_transform(counties, crs(prism_list[[1]])@projargs)
  ext <- raster::extent(counties)
  
  stack <- prism_list[[1]]
  res_list <- list()

  for(i in 1:length(stack@layers)) {
    #crop prism data to shapefile 
    prismData <- stack@layers[[i]]
    crop <- raster::crop(x = prismData, y = ext) 
    vals <- exactextractr::exact_extract(crop, counties, func)
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
  final_df$NAME<- rep(counties$NAME, length(unique(final_df$date)))
  final_df$GEOID <- rep(counties$GEOID, length(unique(final_df$date)))
  final_df$NAMELSAD <- rep(counties$NAMELSAD, length(unique(final_df$date)))
  write.csv(final_df,file = paste0(csvPath, "/", var, "_gridded.csv")) 
  end <- Sys.time()
  print(end - begin)
  print("complete!")
}

#shapefile path 
shapefilePath = paste0(cwd, '/data/shapefiles/', shapefile, '/', shapefile, '.shp')

#path to save csv files to 
csvPath <- paste(cwd, 'data', 'prism_gridded', sep = '/')

for (var in vars){ 
  #get mean max temp by grid cell 
  calcByGrid(var = var, func = "mean", shapefilePath = shapefilePath, csvPath = csvPath)
}
