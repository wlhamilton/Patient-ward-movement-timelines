# Patient-ward-movement-timelines
R script for visualising patient ward movements as timelines

This is an implementation of the vistimes package created by Saandro Raabe to generate patient ward movement timeline plots. These plots have been used to investigate hospital-onset COVID-19 infections. The plots show when patients were co-located on the same ward(s) within a hospital and when they first tested positive for COVID-19.

The script uses vistime to produce the plots. I wasn't able to produce a legend "in-house" so generate a separate legend "manually" and add it using cowplot.

All credit for the vistime package goes to its creator Saandro Raabe.
