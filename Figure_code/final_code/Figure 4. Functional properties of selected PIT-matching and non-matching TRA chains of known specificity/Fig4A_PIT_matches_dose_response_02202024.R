rm(list = ls())
require(Biostrings)
require(limma)
require(plyr)
require(gdata)
library(reshape2)
library(psych)
library(ggplot2)
library(r2symbols)
library(stringdist)
library(scales)

setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/data/")

## load PIT matched junctions

lev = read.csv("Levenshtein_index_IAR_CD4_with_islet_TCRS_lv.lt9.csv", stringsAsFactors = F)

levSub = subset(lev, lv <2); nrow(levSub) # 1389

###########################
## peptide titration curves with and withoout PIT matches

## load specificity files

dr = read.csv("IAR_TCR_dose_reponse_curves.csv", stringsAsFactors = F)

dr$isletMatch = dr$junction_alpha %in% levSub$aJunc1
dr$PITmatch = dr$junction_alpha %in% levSub$aJunc1
dr$PITmatch = gsub("TRUE", "PIT-matched", dr$PITmatch)
dr$PITmatch = gsub("FALSE", "non-PIT-matched", dr$PITmatch)


dr = subset(dr, !broad_specificity == "HA")
dr$broad_specificity = gsub("GAD", "GAD65", dr$broad_specificity)
dr$broad_specificity = gsub("ZNP", "ZNT8", dr$broad_specificity)
dr$traJuncLen = nchar(dr$junction_alpha)
dr$trbJuncLen = nchar(dr$junction_beta)

if(dev.cur() >1) dev.off()

quartz(width=22,height=8)  ### open plotting window

#update_geom_defaults("line", aes(size = 8))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(dr, aes(x = log10(concentration), y = percent_proliferation, group = cloneID)) + geom_line(aes(colour = PITmatch), size = 2) + facet_grid(~broad_specificity)

last_plot() + scale_x_continuous(labels = scales::math_format(10^.x)) 
xlab = paste0("\nPeptide concentration, ", c("\u03BC"),"g","/ml")
ylab = "% Proliferation\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + scale_y_continuous(limits = c(-2,100), breaks = c(0,25, 50, 75,100))
last_plot() + scale_colour_manual(values=cbPalette)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = "Fig_4A_Peptide_titration_by_PITmatches.pdf"
ggsave(filename, p)
