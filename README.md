# Patient-ward-movement-timelines
R script for visualising patient ward movements as timelines

This is an implementation of the R package vistime created by Sandro Raabe - https://github.com/shosaco/vistime.

The script generates patient ward movement timeline plots. These plots have been used to investigate hospital-onset COVID-19 infections (e.g. Figure 5 in Meredith & Hamilton et al., 2020: https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(20)30562-4/fulltext). The plots show when patients were co-located on the same ward(s) within a hospital and when they first tested positive for COVID-19. This can be helpful for investigations of possible hospital acquired infections.

The script uses gg_vistime to produce the timeline plots with ggplot2 syntax for tweaks, and data manipulations using the tidyverse. I wasn't able to produce a legend "in-house" with vistime so generate a separate legend "manually" and add it using cowplot. Date of positive test result for COVID-19 are indicated by black dots. Colour scheme uses RColorBrewer "Set3" but this could easily be changed. 

## Files:
* **`R script to generate example ward movement plot.R`**
  * This is an R script that generates a ward movement timeline plot from mock data encoded in the script. The output is `timeline_plot_mock_data.pdf`.
* **`R script for formatting ward movement data.R`**
  * This R script generates an identical plot but the input data is in the format produced by the electronic patient records system (Epic) used in my hospital. The script first re-formats this into the right format for vistime. In addition it anonymises the ward names, as would be needed when working with real patient data.
* **`ward_moves_mock_data_input.csv`** = mock patient ward movement data in same format as Epic produces
* **`ward_conversion_mock_data.csv`** = conversion code for anonymised ward names

All credit for the vistime package goes to its creator Sandro Raabe.
