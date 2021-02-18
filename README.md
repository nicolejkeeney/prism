# prism

Some code for working with [prism climate data](https://prism.oregonstate.edu/). Includes a shell file for running the script in Berkeley HPC cluster, but since using the exactextractr package for gridding data to the shapefile, things are running quickly and I haven't needed to run it in the HPC.

## download_prism_data.R 
Download monthly prism data for variables of interest using the prism package for R (available from CRAN [here](https://cran.r-project.org/web/packages/prism/index.html)). See prism website for more information on data and units. 

## grid_prism_to_shapefile.R 
Grid prism variables of interest (precipitation, mean temperature, etc.) to an input shapefile and calculate mean values per grid cell. <br><br> *Note: To get monthly total precipitation by county in CA, you would want to compute the mean precip value across the collection of small (8km) prism grid cells that make up the larger grid cell defined by the county (given in the shapefile). We need to use **mean** when extracting the raster even when we want the total monthly sum; summing mean monthly rainfall for every 8km cell in the county would create an artificially high value.*

## combine_gridded_prism_files.R 
Combine output gridded csv files from grid_prism_to_shapefile.R into a single dataframe with some nice column names. Outputs another csv file with all variables combined. 
