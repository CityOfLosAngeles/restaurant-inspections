# restaurant-inspections.R
# download county inspection data, filter to city level, post to the portal

# Adam Scherling, March 21 2018

library(RSocrata)

setwd('~/github/restaurant-inspections')

# get a list of the files in the directory before the data are downloaded
existingFiles <- list.files()

# download the zip file which contains inspection data
zipfileURL <- "http://ehservices.publichealth.lacounty.gov/LIVES/LABusinesses.zip"
download.file(zipfileURL, destfile="test.zip")

# unzip the file
unzip("test.zip")

# read in the files
businesses <- read.csv('businesses.csv', stringsAsFactors=F)
feed_info <- read.csv('feed_info.csv', stringsAsFactors=F)
inspections <- read.csv('inspections.csv', stringsAsFactors=F)
legend <- read.csv('legend.csv', stringsAsFactors=F)
violations <- read.csv('violations.csv', stringsAsFactors=F)

# merge together businesses and inspections
df <- merge(inspections, businesses, by="business_id")

# fill in the description column using the legend
for (i in 1:nrow(legend)) {
	legend_min <- legend$minimum_score[i]
	legend_max <- legend$maximum_score[i]
	legend_desc <- legend$description[i]
	df$description[df$score >= legend_min & df$score <= legend_max] <- legend_desc
}

# filter to City of LA only
df <- df[df$city=="LOS ANGELES",]

# sort by date
df <- df[order(df$date, decreasing=T),]

# read in the Socrata password for posting
user_password <- readLines("password.txt")

# write the data to Socrata
write.socrata(dataframe = df,
              dataset_json_endpoint = "https://data.lacity.org/resource/6bij-usfy.json",
              update_mode = "REPLACE",
              email = "adam.scherling@lacity.org",
              password = user_password)

# remove all the data files?

