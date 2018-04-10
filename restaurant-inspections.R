# restaurant-inspections.R
# download county inspection data, filter to city level, post to the portal

# Adam Scherling
# Last edited April 9, 2018

# change this to use pacman...
library(RSocrata)
library(dplyr)
library(magrittr)

# Download the data from the County open data portal
inspections <- read.socrata("https://data.lacounty.gov/resource/kpth-apsv.json")
violations <- read.socrata("https://data.lacounty.gov/resource/mfmj-mcsc.json")

# Filter inspections to just City of LA
inspections %<>% filter(facility_city=="LOS ANGELES")

# Sort by date
inspections %<>% arrange(desc(activity_date))

# Merge violations with inspections
# Otherwise restaurant name, date, etc. aren't available
violations %<>% merge(inspections, by="serial_number")
violations <- violations[!duplicated(violations),]

# Sort by date
violations %<>% arrange(desc(activity_date))

# Download the existing data from the City open data portal
city_inspections <- read.socrata("https://data.lacity.org/resource/ydjb-vh9c.json")

# If there are no changes, don't upsert
# I assume that the violation data will only change if the inspection data changes
upsert <- FALSE
if (nrow(inspections)!=nrow(city_inspections)) {
	# if the data have different number of rows, upsert
	upsert <- TRUE
} else if (!all.equal(sort(inspections$serial_number), sort(city_inspections$serial_number))) {
	# if there are any different serial numbers, upsert
	upsert <- TRUE
}

if (upsert) {
	# Upload inspections to Socrata
	write.socrata(dataframe = inspections,
	              dataset_json_endpoint = "https://data.lacity.org/resource/29fd-3paw.json",
	              update_mode = "UPSERT",
	              email = "adam.scherling@lacity.org",
	              password = user_password)

	# Upload violations to Socrata
	write.socrata(dataframe = violations,
	              dataset_json_endpoint = "https://data.lacity.org/resource/yf53-6au9.json",
	              update_mode = "UPSERT",
	              email = "adam.scherling@lacity.org",
	              password = user_password)
}


