##### R script for formatting data on ward movements to work with vistime

### Set working directory
setwd("~/Documents/science/covid19/analysis/ward_timelines")

### Load packages
library("tidyverse")

### Import data
import_data <- read.csv("ward_moves_mock_data_input.csv")
ward_codes <- read.csv("ward_conversion_mock_data.csv")

### Manipulations
## 1. Anonymise wards
ward_moves_ed1 <- import_data %>%
  mutate(across(ends_with('ward'), ~ deframe(ward_codes)[.])) %>%
  mutate(from_ward_date = str_sub(from_ward_date, 0, 10)) %>%
  mutate(to_ward_date = str_sub(to_ward_date, 0, 10))
ward_moves_ed1

## 2. Treat as dates
ward_moves_ed1$swab_date <- as.Date(ward_moves_ed1$swab_date, format = "%d/%m/%Y")
ward_moves_ed1$from_ward_date <- as.Date(ward_moves_ed1$from_ward_date, format = "%d/%m/%Y")
ward_moves_ed1$to_ward_date <- as.Date(ward_moves_ed1$to_ward_date, format = "%d/%m/%Y")
ward_moves_ed1


## 3. Remove rows where there is no ward movement ie from_ward == to_ward, and remove duplicate rows with different swab dates
ward_moves_ed2 <- ward_moves_ed1 %>%
  filter(from_ward != to_ward) %>%
  arrange(swab_date) %>% # order by swab date to keep the first one
  distinct(patient_study_id,from_ward,from_ward_date,to_ward,to_ward_date, .keep_all=T) %>% # note swab_date is not included in this list
  arrange(patient_study_id, from_ward_date)


## 4. Condense the from and to wards into a single ward name with from and to dates

## Loop through each patient
# Create numeric column for each patient
patient_num <- ward_moves_ed2 %>%
  group_by(patient_study_id) %>%
  group_indices
ward_moves_ed3 <- cbind(ward_moves_ed2, patient_num)
ward_moves_ed3$patient_num <- as.numeric(ward_moves_ed3$patient_num)
head(ward_moves_ed3)

patient_max <- max(ward_moves_ed3$patient_num)

# Run through the patient loop

mylist <- list() #create an empty list

for (p in 1:patient_max) {
  
  ## select a patient
  pat <- ward_moves_ed3 %>%
    filter(patient_num == p) %>%
    arrange(from_ward_date)
  
  ## Deal with the first ward separately, and make a list of the subsequent wards
  
  # How many wards are there
  all_wards <- c(as.character(pat$from_ward), as.character(pat$to_ward))
  ward_num <- as.numeric(n_distinct(all_wards))
  # Exclude Discharge as being a ward
  ward_num_nodis <- ifelse('Discharge' %in% all_wards,
                           ward_num-1,
                           ward_num)
  all_wards_unique <- unique(all_wards)
  
  ward_moves_temp <- data.frame(Ward = all_wards_unique) 
  ward_moves_middle <- ward_moves_temp %>%
    slice(-(nrow(ward_moves_temp))) %>%
    slice(-1)
  ward_moves_middle$Ward_num <- seq.int(nrow(ward_moves_middle))
  ward_moves_middle
  max_ward <- max(ward_moves_middle$Ward_num)
  
  ### Sort out first ward
  start_ward <- as.character(pat[1,3])
  start_ward_start <- as.Date(pat[1,4])
  start_ward_end <- as.Date(pat[1,6])
  start_ward_formatted <- data.frame(Ward = start_ward,
                                     start = start_ward_start,
                                     end = start_ward_end)
  
  
  # Loop through middle wards
  
  mylist2 <- list() #create an empty list
  
  for (w in 1:max_ward) {
    
    ward_next <- as.character(pat[w,5])
    ward_next_start <- as.Date(pat[w,6])
    ward_next_end <- as.Date(pat[(w+1),6])
    
    ward_info_df <- data.frame(Ward = ward_next,
                               start = ward_next_start,
                               end = ward_next_end)
    
    mylist2[[w]] <- ward_info_df #put all vectors in the list
  }
  
  middle_wards_formatted <- do.call("rbind", mylist2) #combine all vectors into a matrix
  middle_wards_formatted <- data.frame(middle_wards_formatted)
  middle_wards_formatted
  
  # Add first ward
  wards_formatted <- rbind(start_ward_formatted,middle_wards_formatted)
  
  # Add the patient
  patient <- unique(pat$patient_study_id)
  
  wards_formatted$Patient <- patient
  wards_formatted <- wards_formatted %>%
    select(Patient, Ward, start, end)
  wards_formatted
  
  mylist[[p]] <- wards_formatted #put all vectors in the list
}

all_wards_formatted <- do.call("rbind", mylist) #combine all vectors into a matrix
all_wards_formatted <- data.frame(all_wards_formatted)
all_wards_formatted



## 5. Tweaks to formatting
# Make it so people are in a ward for a minimum of 1 day

# Cases where start and end date are identical, I add 1 day to the end date so they're on the ward for 1 day in vistime
all_wards_formatted_2 <- all_wards_formatted %>%
  mutate(
    end_2 = case_when(
      start == end ~ end+1,
      start != end ~ end
    ))

# Adjust the start date of the next ward if the end date of the previous ward has been increased by 1 day
# First, flag up the wards where end date have changed
all_wards_formatted_3 <- all_wards_formatted_2 %>%
  mutate(
    flag = case_when(
      end != end_2 ~ "flag"
    ))

# Name the rows to keep track of order
all_wards_formatted_3$row_id <- seq.int(nrow(all_wards_formatted_3))
all_wards_formatted_3

# Get the rows that occur after a "flag"
i <- 1:1
ix <- rep(which(all_wards_formatted_3$flag == "flag"), each = length(i)) + i
rows_to_edit <- all_wards_formatted_3[unique(ix[ix > 0 & ix <= nrow(all_wards_formatted_3)]), ] 
rows_to_keep <- all_wards_formatted_3[-unique(ix[ix > 0 & ix <= nrow(all_wards_formatted_3)]), ] 
# Add 1 day to the rows to edit
rows_to_edit$start <- rows_to_edit$start+1
# Sub the edited rows back in
all_wards_formatted_4 <- rbind(rows_to_keep,rows_to_edit) %>%
  arrange(row_id) %>%
  select(-end, -flag, -row_id) %>%
  rename(end = end_2) 
all_wards_formatted_4


## 6. Get positive test dates and order patients by positive test
swab_dates <- ward_moves_ed3 %>%
  select(patient_study_id, swab_date) %>%
  distinct(patient_study_id, .keep_all=TRUE) %>%
  rename(Patient = patient_study_id)
swab_dates$patient_order <- seq.int(nrow(swab_dates))

all_wards_formatted_5 <- merge(swab_dates, all_wards_formatted_4, by="Patient", all.x=T, all.y=T) %>%
  arrange(patient_order, start) %>%
  select(-patient_order)
all_wards_formatted_5

### Save
#write.csv(all_wards_formatted_5, "ward_moves_mock_data_output.csv", row.names=F)




####### Plotting
### Preparing for plot
ward_moves <- all_wards_formatted_5

## Colours
# Define number of colours needed
cols_n <- as.numeric(n_distinct(ward_moves$Ward))
# Check we have enough colours
ifelse(cols_n>12, 
       "More than 12 wards - not enough colours!",
       "12 wards or fewer - using Set3 colours")
# Select the colours from Set3 palette in RColorBrewer
cols_to_use <- brewer.pal(n = cols_n, name = "Set3")

# Create mapping of colours to wards
col_ward_mapping <- data.frame(Ward=unique(c(as.character(ward_moves$Ward))), color=cols_to_use)
# merge in the mapping to the df
ward_moves_2 <- merge(ward_moves,
                      col_ward_mapping,
                      by="Ward",
                      all.x=T,all.y=T) %>%
  select(Patient, swab_date, Ward, start, end, color) %>%
  arrange(swab_date, Patient, start)
ward_moves_2

## Extract swab dates
swab_dates <- ward_moves_2 %>%
  select(Patient, swab_date) %>%
  distinct(Patient, .keep_all=TRUE) %>%
  arrange(swab_date)


### Plotting
# Produce the basic plot
plot_data <- gg_vistime(data = ward_moves_2,
                        col.group = "Patient", # Each row will be a patient
                        col.event = "Ward", # Rows will be coloured by the ward
                        show_labels = FALSE, # Remove labels indicating the ward
                        linewidth = 20,
                        title = "Ward movements timeline")

# Tweak the plot
plot_data <- plot_data + theme_bw() +
  ggplot2::theme(
    plot.title = element_text(size=14),
    axis.text.x = element_text(size = 12, color = "black", angle = 30, vjust = 1, hjust = 1),
    axis.text.y = element_text(size = 12, color = "black")) +
  scale_x_datetime(breaks = breaks_width("5 days"), labels = date_format("%b %d"))
plot_data

# Adding date of positive swab
plot_data <- plot_data +
  annotate("point", x = as.POSIXct(swab_dates[1,2]), y = 5, size = 5, colour = "black") +
  annotate("point", x = as.POSIXct(swab_dates[2,2]), y = 3, size = 5, colour = "black") +
  annotate("point", x = as.POSIXct(swab_dates[3,2]), y = 1, size = 5, colour = "black")
plot_data


### Create a legend
data_legend <- ward_moves_2 %>%
  distinct(Ward, .keep_all=T) %>%
  arrange(Ward)
data_legend$start <- as.Date("2020-01-01")
data_legend$end <- as.Date("2020-01-02")
data_legend$Patient <- "Key"
data_legend
plot_legend <- gg_vistime(data = data_legend,
                          col.group = "Patient",
                          col.event = "Ward",
                          show_labels = TRUE,
                          linewidth = 20,
                          title = "Legend")
plot_legend

# Tweak the legend plot
plot_legend <- plot_legend + theme_void() +
  ggplot2::theme(
    plot.title = element_text(size=11),
    axis.title.x=element_blank(),
    axis.text.x=element_blank(),
    axis.ticks.x=element_blank(),
    axis.title.y=element_blank(),
    axis.text.y=element_blank(),
    axis.ticks.y=element_blank())
plot_legend


### Combine the main plot and legend into a single figure
plot_combined <- plot_grid(plot_data, plot_legend,
                           rel_widths = c(1, 0.15))
plot_combined

### Save plot
#ggplot2::ggsave(plot_combined, file = "timeline_plot_mock_data.png", dpi=300, height=4, width=7, units="in")



