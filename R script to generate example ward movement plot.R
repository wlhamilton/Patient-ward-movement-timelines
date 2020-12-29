############# Producing patient ward movement timelines with vistime

### Set working directory
setwd("~/Documents/science/covid19/analysis/ward_timelines")

### Load packages
library("vistime")
library("tidyverse")
library("RColorBrewer")
library("scales")
library("cowplot")

### Generate input data
ward_moves <- data.frame(Patient = c("Patient_A", "Patient_A", "Patient_B", "Patient_B", "Patient_B", "Patient_C", "Patient_C", "Patient_C"),
                         Ward = c("Ward_4", "Ward_1", "ED", "Ward_1", "Ward_2", "Ward_5", "Ward_1", "Ward_3"),
                         start = c("2020-03-11", "2020-03-17", "2020-03-16", "2020-03-17", "2020-04-01", "2020-03-19", "2020-03-24", "2020-04-05"),
                         end = c("2020-03-17", "2020-03-30", "2020-03-17", "2020-04-01", "2020-04-15", "2020-03-24", "2020-04-05", "2020-04-15"),
                         swab_date = c("2020-03-22", "2020-03-22", "2020-03-31", "2020-03-31", "2020-03-31", "2020-04-04", "2020-04-04", "2020-04-04"))

### Preparing for plot
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
ggplot2::ggsave(plot_combined, file = "timeline_plot_mock_data.pdf", dpi=300, height=4, width=7, units="in")


