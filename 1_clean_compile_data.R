############################################
# Please make reference of this work as: Gabriel E. García-Peña, André V. Rubio, Hugo Mendoza, Miguel Fernández, Matthew T. Milholland, A. Alonso Aguirre, Gerardo Suzán, Carlos Zambrana-Torrelio. 2021. Land-use change and rodent-borne diseases: Hazards on the shared socioeconomic pathways. Phil. Trans. R. Soc. B.
# Code developer: Gabriel E. García-Peña
#
# OBJECTIVES OF THIS R CODE:
# 1) Read data obtained from the Global Biodiversity Information Facility (GBIF): https://doi.org/10.15468/dl.pqwhfw), 
# 2) Clean the data
# 3) Compile historical data on land-use with the location and year of each sample in the database.
#
#############################################

# Libraries used
  library(sp)
  library(raster)
  library(ncdf4)
  library(CoordinateCleaner)

# Set path to files
  path = "your working directory"
  setwd(path)

# This is number of query in GBIF
  k = "0056924-200613084148143"

# Read data from file in repository 0056924-200613084148143.rds
  sam<-readRDS(paste("~/LUCIDA/data/", k, ".rds", sep=""))
  subsam<-sam[is.na(sam$decimalLatitude)==F,]

# Clean the data
  Q = clean_coordinates(subsam
                     , lat="decimalLatitude"
                     , lon = "decimalLongitude"
                     , tests = c("capitals","centroids","gbif", "institutions","zeros")
                     , value="flagged")

# Select only data with a flag Q = TRUE
  subsam = subsam[Q==T,]

# Purge data with year = NA
  subsam = subsam[is.na(subsam$year)==F,]

# Select the minimum and maximum dates to sample
# Keep data with year > = 1699 and < = 2015
  subsam = subsam[subsam$year>=1699,] 
  subsam = subsam[subsam$year<=2015,]

# Data frame D
# Form working dataframe (D) and purge empty entires, with species = ""
  D<-data.frame(subsam)
  D<-D[D$species!="",]

# Avoid redundant computations. Data on land use change was asigned to each unique space/year registry. 

# Make the index of unique space / year cells
  D$id<-paste(D$decimalLatitude, D$decimalLongitude, D$year)
  id<-unique(D$id)
  lat<-D$decimalLatitude[match(unique(D$id), D$id)]
  lon<-D$decimalLongitude[match(unique(D$id), D$id)]
  year<-D$year[match(unique(D$id), D$id)]
  subsam1<-data.frame(id, lat, lon, year) # subsample of unique cells with records.

# Land use change data (file states.nc).
# Make a vector with the numbers of band corresponding to the sample year.

  band<-subsam1$year-850 # Note: the time series starts at the year 850
  x<-1:length(band)

# Define path to raster with values (states)
  path<-"~/LUCIDA/data/LUH2 v2h Release_10_14_16/states.nc"

# Function to extract raster values based on the sample year.
  f.band<-function(x){
    rasX<-raster(path, band=band[x], varname = varX)
    # rasX<-raster(path, band=band[x]) # READ BAND (year) OF RASTER (path)
    pts<-data.frame(subsam1$lon[x], subsam1$lat[x]) # GET COORDINATES OF THE SAMPLE
    extract(rasX, pts) # EXTRACT LUC DATA
  }
 
# Define path to raster with values (states)
  path<-"PATH TO RASTER states.nc"
 
# Apply function f.band to each raster variable of interest (varX)
  varX = "secdf"
  secdf<-sapply(x, f.band)

  varX = "primn"
  primn<-sapply(x, f.band)

  varX = "secdn"
  secdn<-sapply(x, f.band)

  varX = "primf"
  primf<-sapply(x, f.band)

  varX = "pastr"
  pastr<-sapply(x, f.band)

  varX = "urban"
  urban<-sapply(x, f.band)

  varX = "range"
  rangeland<-sapply(x, f.band)

  varX = "c3ann"
  c3ann<-sapply(x, f.band)

  varX = "c3per"
  c3per<-sapply(x, f.band)

  varX = "c4ann"
  c4ann<-sapply(x, f.band)

  varX = "c4per"
  c4per<-sapply(x, f.band)

  varX = "c3nfx"
  c3nfx<-sapply(x, f.band)

  varX = "secma"
  secma<-sapply(x, f.band)

  varX = "secmb"
  secmb<-sapply(x, f.band)


# Information on the historical dataset of the raster 
# DATA FROM 850 TO 2015
# (units    fraction    of    grid    cell    unless    otherwise    specified)
# primf: forested primary land
# primn: non-forested primary land
# secdf: potentially forested secondary land
# secdn: potentially non-forested secondary land
# pastr: managed pasture
# range: rangeland
# urban: urban land
# c3ann: C3 annual crops
# c3per: C3 perennial crops
# c4ann: C4 annual crops
# c4per: C4 perennial crops
# c3nfx: C3 nitrogen-fixing crops
# secma: secondary mean age (units: years)
# secmb: secondary mean biomass density (units: kg C/m^2)

# Save results
saveRDS(data.frame(primn
                   , primf, secdn, secdf, pastr, rangeland
                   , urban, c3ann, c3per, c4ann, c4per
                   , c3nfx), "subsam_luc.rds")
                   
# Compile data from subsam_luc.rds to data frame D, using the id variable as reference.
  primn.D<-primn[match(D$id, subsam1$id)]
  primf.D<-primf[match(D$id, subsam1$id)]
  secdn.D<-secdn[match(D$id, subsam1$id)]
  secdf.D<-secdf[match(D$id, subsam1$id)]
  pastr.D<-pastr[match(D$id, subsam1$id)]
  range.D<-rangeland[match(D$id, subsam1$id)]
  urban.D<-urban[match(D$id, subsam1$id)]
  c3ann.D<-c3ann[match(D$id, subsam1$id)]
  c3per.D<-c3per[match(D$id, subsam1$id)]
  c4ann.D<-c4ann[match(D$id, subsam1$id)]
  c4per.D<-c4per[match(D$id, subsam1$id)]
  c3nfx.D<-c3nfx[match(D$id, subsam1$id)]

  D$primn<-primn.D
  D$primf<-primf.D
  D$secdn<-secdn.D
  D$secdf<-secdf.D
  D$pastr<-pastr.D
  D$range<-range.D
  D$urban<-urban.D
  D$c3ann<-c3ann.D
  D$c3per<-c3per.D
  D$c4ann<-c4ann.D
  D$c4per<-c4per.D
  D$c3nfx<-c3nfx.D

# Save the data frame with the records of rodent specimens and the historical data on land use.
saveRDS(D, "data_gbif_luc.rds")
