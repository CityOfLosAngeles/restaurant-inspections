# restaurant-inspections.R
# download county inspection data, filter to city level, post to the portal

# Adam Scherling, March 21 2018

# change this to use pacman...
library(RSocrata)
library(dplyr)
library(magrittr)

# change this to work on the server...
setwd('~/github/restaurant-inspections')

# get a list of the files in the directory before the data are downloaded
existingFiles <- list.files()

# download the zip file which contains inspection data
zipfileURL <- "http://ehservices.publichealth.lacounty.gov/LIVES/LABusinesses.zip"
download.file(zipfileURL, destfile="tmp.zip")

# unzip the file
unzip("tmp.zip")

# read in the files
businesses <- read.csv('businesses.csv', stringsAsFactors=F)
feed_info <- read.csv('feed_info.csv', stringsAsFactors=F)
inspections <- read.csv('inspections.csv', stringsAsFactors=F)
legend <- read.csv('legend.csv', stringsAsFactors=F)
violations <- read.csv('violations.csv', stringsAsFactors=F)

# remove all the files that didn't already exist
allFiles <- list.files()
newFiles <- setdiff(allFiles, existingFiles)
for (file in newFiles) {
	# change this to work on the server...
	system(paste0('rm ', file))
}

## INSPECTIONS

# fill in the inspection description column using the legend
for (i in 1:nrow(legend)) {
	legend_min <- legend$minimum_score[i]
	legend_max <- legend$maximum_score[i]
	legend_desc <- legend$description[i]
	within_range <- (inspections$score >= legend_min) & (inspections$score <= legend_max)
	inspections$description[within_range] <- legend_desc
}

# merge together businesses and inspections
business_inspections <- merge(businesses, inspections, by="business_id")

# rename a few variables for clarity
business_inspections %<>% rename(inspection_date=date,
								 inspection_score=score,
								 inspection_description=description,
								 inspection_type=type)

# filter to City of LA only
business_inspections %<>% filter(city=="LOS ANGELES")

# sort by date
business_inspections %<>% arrange(desc(inspection_date))

# read in the Socrata password for posting
user_password <- readLines("password.txt")

# write the data to Socrata
write.socrata(dataframe = business_inspections,
              dataset_json_endpoint = "https://data.lacity.org/resource/yvqx-p6dm.json",
              update_mode = "REPLACE",
              email = "adam.scherling@lacity.org",
              password = user_password)


## VIOLATIONS

# merge together businesses and violations
business_violations <- merge(businesses, violations, by="business_id")

# rename a few variables for clarity
business_violations %<>% rename(inspection_date=date,
								violation_code=code,
								violation_description=description)

# filter to City of LA only
business_violations %<>% filter(city=="LOS ANGELES")

# sort by date
business_violations %<>% arrange(desc(inspection_date))

# write the data to Socrata
write.socrata(dataframe = business_violations,
              dataset_json_endpoint = "https://data.lacity.org/resource/yf53-6au9.json",
              update_mode = "REPLACE",
              email = "adam.scherling@lacity.org",
              password = user_password)
