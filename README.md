# download_and_grid_prism

Some code for working with [prism climate data](https://prism.oregonstate.edu/). 

## download_prism_data.R 
Download monthly prism data for variables of interest using the prism package for R (available from CRAN [here](https://cran.r-project.org/web/packages/prism/index.html). See prism website for more information on data and units. 

## grid_prism_to_shapefile.R 
Grid prism variables of interest (precipitation, mean temperature, etc.) to an input shapefile and calculate mean values per grid cell. <br> *Note:* To get monthly total precipitation by county in CA, you would want to compute the mean precip value across the collection of small (8km) prism grid cells that make up the larger grid cell defined by the county (given in the shapefile). We need to use **mean** when extracting the raster even when we want the total monthly sum; summing mean monthly rainfall for every 8km cell in the county would create an artificially high value. 