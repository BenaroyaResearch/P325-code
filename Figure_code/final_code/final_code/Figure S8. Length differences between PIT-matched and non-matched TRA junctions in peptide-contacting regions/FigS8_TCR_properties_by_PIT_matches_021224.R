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
library(Peptides)

setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/data") # folder containing data required to generate figures

## load PIT matched TCRs

levIAR1 = read.csv("Levenshtein_index_IAR_CD4_with_islet_TCRS_lv.lt9.csv", stringsAsFactors = F)
levIAR1$index = NULL
levIAR1$set = c("IAR1")

filename = ("Levenshtein_index_P324_P474_IAR_CD4_with_islet_TCRS_lv.lt6.csv")

levIAR2 = read.csv(filename, stringsAsFactors = F)
levIAR2$index1 = NULL
levIAR2$index2 = NULL
levIAR2$set = NULL
levIAR2$set = c("IAR2")

levSubIAR1 = subset(levIAR1, levIAR1$lv <2); nrow(levSubIAR1) # 1389 (573 unique) with IAR1; 1343 (555 unique(with IAR2)
levSubIAR2 = subset(levIAR2, levIAR2$lv <2); nrow(levSubIAR2) # 1389 (573 unique) with IAR1; 1343 (555 unique(with IAR2)

levSub = rbind(levSubIAR1, levSubIAR2) # 2732

#levSub = subset(levSub, set == "IAR1") # for troubleshooting. 1389. 
## load TCRs
## load IAR1 TCRs

IAR1Tcrs = read.csv("201512_TCR_MasterList_w_CloneIDs.csv", stringsAsFactors = F) # 5417
colnames(IAR1Tcrs) = gsub("tcrGraph_sharing_level", "sharing_level", colnames(IAR1Tcrs))

IAR1Tcrs = data.frame(IAR1Tcrs, set = "IAR1")

colNames = c("libid", "v_gene", "j_gene", "junction", "project", "donor_id", "set", "study_group")

IAR1Tcrs = IAR1Tcrs[c(colNames)]
IAR1Tcrs$study_group = gsub("early onset T1D", "newT1D", IAR1Tcrs$study_group)

## create IAR1 hla

hla = read_excel("subject_char_w_HLA.xlsx")

## correct donor id

hla$'Subject ID' = gsub('TID', "T1D", hla$'Subject ID')

## load ID key

idKey = read_excel("P91_P168 Sample_ID_key.xlsx")

idKey$tcrId = gsub("HC10, Ctrl10", "CTRL10", idKey$tcrId)

## remove whitespace

hla$'Subject ID' = stringr::str_trim(hla$'Subject ID')
idKey$suppTabId = stringr::str_trim(idKey$suppTabId)
IAR1Tcrs$donor_id = stringr::str_trim(IAR1Tcrs$donor_id)

## add suppTabId and then match HLA

IAR1Tcrs$suppTabId = idKey$suppTabId[match(IAR1Tcrs$donor_id, idKey$tcrId)]
IAR1Tcrs$hla = hla$DRB1[match(IAR1Tcrs$suppTabId, hla$"Subject ID")]

## check to see that HLA is present for most donors

temp = subset(IAR1Tcrs, is.na(IAR1Tcrs$hla)) # 0/5417. 
unique(temp$donor_id) #0

tempa = subset(hla, hla$"Subject ID" == "CTRL10")
tempb = subset(IAR1Tcrs, IAR1Tcrs$donor_id == "CTRL10")

tempa$'Subject ID'
unique(tempb$donor_id)

colNames1 = c("libid", "v_gene", "j_gene", "junction", "project", "donor_id", "set", "study_group", "hla")

IAR1Tcrs = IAR1Tcrs[c(colNames1)] # 5417

## load IAR2 TCRs

setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/data")

anno.filename = "P325_P474_comb_CD4+_anno_w_hla.txt"
tcrs.filename = "P325_P474_comb_CD4+_TCR_w_hla.txt"

test1 = read.delim(anno.filename, stringsAsFactors = F)
test2 = read.delim(tcrs.filename, stringsAsFactors = F)

test2$donor_id = test1$donorId[match(test2$libid, test1$libid)]
test2$study_group = test1$studyGroup2[match(test2$libid, test1$libid)]
test2$study_group = gsub("roT1D", "newT1D", test2$study_group)

test2 = subset(test2, !study_group == "estT1D")

IAR2Tcrs = data.frame(test2, set = "IAR2")
IAR2Tcrs$hla = test1$hla[match(IAR2Tcrs$donor_id, test1$donorId)]

colNames = c("libid", "v_gene", "j_gene", "junction", "project", "donor_id", "set", "study_group", "hla")

IAR2Tcrs = IAR2Tcrs[c(colNames)]

setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_code")

## combine set 1 amd set2

tcrsComb = rbind(IAR1Tcrs, IAR2Tcrs) # 7727

tcrsComb$studyGroup = tcrsComb$study_group

tcrsComb$studyGroup = factor(tcrsComb$studyGroup, levels = c("HC", "AAbNeg", "1AAb", "2AAb",  "newT1D", "T1D" ))

## save tcrsComb as Supplemental Table for manuscript

toSave = tcrsComb
toSave$set = gsub("IAR1", "Cohort1", toSave$set)
toSave$set = gsub("IAR2", "Cohort2", toSave$set)
table(toSave$set )

#setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/data")
#filename = "Table_S4_Compiled_and_filtered_TCR_sequences_used_in_this_study.csv"
#write.csv(toSave, filename)

## subset tcrsComb by HLA, if desired

#tcrsComb = subset(tcrsComb, tcrsComb$hla %in% grep("04", tcrsComb$hla, value = T)) # 3626 for "04"; 4101 for NOT 04

## determine expanded TCRs

no =  ddply(tcrsComb,.(junction), plyr::summarize, sum = length(libid)) # 6529 junctions, sum(no$sum) = 7727

cut <- 2
no.sub = subset(no, sum>=cut) # 474

E = subset(tcrsComb, junction %in% no.sub$junction) # 855 E junctions, 135 unique
libs = E$libid
E.cell = subset(tcrsComb, tcrsComb$libid %in% libs) # 956

E.cell$study_group = tcrsComb$study_group[match(E.cell$libid, tcrsComb$libid)] # 1954
	
frxn.e = length(unique(E.cell$libid))/length(unique(tcrsComb$libid)) # 24.4%
	
table(E.cell$studyGroup)

#HC AAbNeg   1AAb   2AAb newT1D    T1D 
# 284     23     56    101    812    678 # all tcrs, not subsetted
#   267      8     21     31    119    510 # hla  "04" subset
   
## add expanded cells to tcrsComb

tcrsComb$E = tcrsComb$libid %in% E.cell$libid # 1954 TRUE 5773 FALSE for junctions; 
tcrsComb$expanded = tcrsComb$E 
tcrsComb$expanded = gsub("TRUE", "E", tcrsComb$expanded)
tcrsComb$expanded = gsub("FALSE", "NE", tcrsComb$expanded)

tcrsComb$chainType = ifelse(tcrsComb$v_gene %in% grep("TRA", tcrsComb$v_gene, value = T), "TRA",
						ifelse(tcrsComb$v_gene %in% grep("TRB", tcrsComb$v_gene, value = T), "TRB","other"))

## remove iNKT and MAIT cell sequencces

iNkt1 = subset(tcrsComb, junction == "CVVSDRGSTLGRLYF")
iNkt2 = subset(tcrsComb, libid %in% iNkt1$libid)
mait1 = subset(tcrsComb, v_gene == "TRAV1-2" & (j_gene == "TRAJ33" | j_gene == "TRAJ20" | j_gene == "TRAJ12")) # 18
mait2 = subset(tcrsComb, libid %in% mait1$libid) # 45

tcrsCombSub3 = subset(tcrsComb, !junction %in% iNkt2$junction) # 
tcrsCombSub3 = subset(tcrsCombSub3, !junction %in% mait2$junction) # 7633

## modify combined TCRs

tcrsCombSub3$IARmatch = tcrsCombSub3$junction %in% levSubIAR1$aJunc1 | tcrsCombSub3$junction %in% levSubIAR2$aJunc1 # 1235 T, 6398 F
tcrsCombSub3$expanded = factor(tcrsCombSub3$expanded, levels = c("E", "NE")) # 

tcrsCombSub3Tra = subset(tcrsCombSub3, tcrsCombSub3$chainType == "TRA") # 1814
tcrsCombSub3Tra.u = tcrsCombSub3Tra[!duplicated(tcrsCombSub3Tra$junction),] # 1512

tcrsCombSub3.u = tcrsCombSub3[!duplicated(tcrsCombSub3$junction),] # 2967
tcrsTra = subset(tcrsCombSub3.u, chainType == "TRA") # 1512
tcrsTrb = subset(tcrsCombSub3.u, chainType == "TRB") # 1433

###########################
## compile IMGT parameters

setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/data") # folder containing data required to generate figures

imgtAA = read.delim("Combined_P91_P325_P474_AB_TCRs_5_AA-sequences.txt")
imgtNt = read.delim("Combined_P91_P325_P474_AB_TCRs_3_Nt-sequences.txt")

all(imgtAA$Sequence.ID == imgtNt$Sequence.ID)
#[1] TRUE

## add protein sequence to imgt

imgt = imgtNt

libids = data.frame(strsplit2(imgt$Sequence.ID, split = "_"))
colnames(libids) = c("libid", "junction")
all(imgt$junction == libids$junction)
#[1] TRUE # OK to combine

imgt$libid = libids$libid
imgt$junction = imgtAA$JUNCTION[match(imgt$Sequence.ID, imgtAA$Sequence.ID)]
imgt$PITmatch = imgt$junction %in% levSubIAR1$aJunc1 | imgt$junction %in% levSubIAR2$aJunc1 # 

imgt$chainType = ifelse(imgt$V.GENE.and.allele %in% grep("TRA", imgt$V.GENE.and.allele, value = T), "TRA", 
					ifelse(imgt$V.GENE.and.allele %in% grep("TRB", imgt$V.GENE.and.allele, value = T), "TRB", "other"))

table(imgt$PITmatch, imgt$chainType)

imgtTra = subset(imgt, chainType == "TRA")
aMatchT = subset(imgtTra, PITmatch == "TRUE") # 942
imgtTrb = subset(imgt, chainType == "TRB")
imgtTrb$PITmatch = imgtTrb$libid %in% aMatchT$libid

imgt = rbind(imgtTra, imgtTrb)
      
## calculate lengths

imgt$NRegion = nchar(imgt$N.REGION) + nchar(imgt$N1.REGION)
imgt$juncLen = nchar(imgt$JUNCTION) 
imgt$threeVRegion = nchar(imgt$X3.V.REGION) 
imgt$fiveJRegion = nchar(imgt$X5.J.REGION) 
imgt$JRegion = nchar(imgt$J.REGION) 
imgt$cdr1 = nchar(imgt$CDR1.IMGT)
imgt$cdr2 = nchar(imgt$CDR2.IMGT)
imgt$cdr3 = nchar(imgt$CDR3.IMGT)
imgt$fr1 = nchar(imgt$FR1.IMGT)
imgt$fr2 = nchar(imgt$FR2.IMGT)
imgt$fr3 = nchar(imgt$FR3.IMGT)
imgt$fr4 = nchar(imgt$FR4.IMGT)

imgt$hydro = hydrophobicity( imgt$junction, scale = "Eisenberg")

imgtTra = subset(imgt, chainType == "TRA") # 3226
imgtTrb = subset(imgt, chainType == "TRB") # 2863

table(imgt$PITmatch, imgt$chainType)

#       TRA  TRB
# FALSE 2322 2355
# TRUE   942  832 
  
## identify TRB chains that pair with PITmatched TRA chains & add PIT matching status for TRA chains.

traMatchT = subset(imgtTra,PITmatch == "TRUE") # 870
traMatchF = subset(imgtTra,PITmatch == "FALSE") # 2356

trbMatchT = subset(imgtTrb,PITmatch == "TRUE") # 739
trbMatchF = subset(imgtTrb,PITmatch == "FALSE") # 2124

## statistics
## summarize CDR1, CDR2, NRegion and threeV Region length 

summary(traMatchT$cdr1) # 18 median 
summary(traMatchF$cdr1) # 18 median

summary(traMatchT$cdr2) # 21
summary(traMatchF$cdr2) # 21

summary(traMatchT$cdr3) # 33
summary(traMatchF$cdr3) # 36

summary(traMatchT$NRegion) # 3 nt
summary(traMatchF$NRegion) # 5 nt

summary(traMatchT$threeVRegion) # 10 nt
summary(traMatchF$threeVRegion) # 11 nt

summary(traMatchT$fiveJRegion) # 27 nt
summary(traMatchF$fiveJRegion) # 25 nt

summary(traMatchT$fr1) # 78 nt
summary(traMatchF$fr1) # 78 nt

summary(traMatchT$fr2) # 51 nt
summary(traMatchF$fr2) # 51 nt

summary(traMatchT$fr3) # 102 nt
summary(traMatchF$fr3) # 102 nt

summary(trbMatchT$cdr1) # 15 median 
summary(trbMatchF$cdr1) # 15 median

summary(trbMatchT$cdr2) # 18
summary(trbMatchF$cdr2) # 18

summary(trbMatchT$NRegion) # 3 nt
summary(trbMatchF$NRegion) # 3 nt

summary(trbMatchT$threeVRegion) # 13 nt
summary(trbMatchF$threeVRegion) # 13 nt

summary(trbMatchT$fiveJRegion) # 17 nt
summary(trbMatchF$fiveJRegion) # 17 nt

## KS tests
test1 = ks.test(traMatchT$cdr1, traMatchF$cdr1, alternative = "two.sided"); test1 #p-value = 2.852e-11; 
test2 = ks.test(traMatchT$cdr2, traMatchF$cdr2, alternative = "two.sided"); test2 #p-value = 0.01747;
test3 = ks.test(traMatchT$cdr3, traMatchF$cdr3, alternative = "two.sided"); test3 #p-value = < 2.2e-16 ;
test4 = ks.test(traMatchT$NRegion, traMatchF$NRegion, alternative = "two.sided"); test4 #p-value = < 2.2e-16 
test5 = ks.test(traMatchT$threeVRegion, traMatchF$threeVRegion, alternative = "two.sided"); test5 #p-value = 5.551e-16 
test6 = ks.test(traMatchT$fiveJRegion, traMatchF$fiveJRegion, alternative = "two.sided"); test6 #p-value = 4.386e-10; 
test7a = ks.test(traMatchT$fr1, traMatchF$fr1, alternative = "two.sided"); test7a #p-value = 0.004903; 
test8a= ks.test(traMatchT$fr2, traMatchF$fr2, alternative = "two.sided"); test8a #p-value = 0.9972 ;
test9a = ks.test(traMatchT$fr3, traMatchF$fr3, alternative = "two.sided"); test9a #p-value = 1 ;
test10a = ks.test(traMatchT$hydro, traMatchF$hydro, alternative = "two.sided"); test10a #p-value 4.745e-11;

test7 = ks.test(trbMatchT$cdr1, trbMatchF$cdr1, alternative = "two.sided"); test7 #p-value = 1; 
test8 = ks.test(trbMatchT$cdr2, trbMatchF$cdr2, alternative = "two.sided"); test8 #p-value = 1 ;
test9 = ks.test(trbMatchT$cdr3, trbMatchF$cdr3, alternative = "two.sided"); test9 #p-value = 0.9668 ;
test10 = ks.test(trbMatchT$NRegion, trbMatchF$NRegion, alternative = "two.sided"); test10 #p-value = 0.3982
test11 = ks.test(trbMatchT$threeVRegion, trbMatchF$threeVRegion, alternative = "two.sided"); test11 #p-value = 0.1883 
test12 = ks.test(trbMatchT$fiveJRegion, trbMatchF$fiveJRegion, alternative = "two.sided"); test12 #p-value = 0.7459 
test13 = ks.test(trbMatchT$hydro, trbMatchF$hydro, alternative = "two.sided"); test13 #p-value = 0.3768; 

pAdj = p.adjust(c(2.85E-11, 0.01747, 2.20E-16, 2.20E-16, 5.55E-16, 4.39E-10, 0.004903, 0.9972, 1, 4.75E-11, 1, 1, 0.9668, 0.3982, 0.1883, 0.7459, 0.3768), method = "BH")
pAdj
#[1] 1.211250e-10 3.712375e-02 1.870000e-15 1.870000e-15
# [5] 3.145000e-15 1.243833e-09 1.190729e-02 1.000000e+00
# [9] 1.000000e+00 1.615000e-10 1.000000e+00 1.000000e+00
#[13] 1.000000e+00 6.154000e-01 3.556778e-01 1.000000e+00
#[17] 6.154000e-01

## use **** for both TRA juncLen and hydro; NS for both TRB juncLen and hydro

###################### 
## for TRA junctions

toPlotName = c("imgtTra")
toPlot = get(toPlotName) # select TRA or TRB chains
toPlot$PITmatch = gsub("TRUE", "PIT-matched", toPlot$PITmatch)
toPlot$PITmatch = gsub("FALSE", "non-PIT-matched", toPlot$PITmatch)

## CDR1

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = cdr1)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nCDR1 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$cdr1), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$xdr1), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(13,22))

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8A_", toPlotName, "_CDR1_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## CDR2

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = cdr2)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nCDR2 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$CDR2), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$CDR2), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(10,26), breaks = c(10,15,20,25))

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8B_", toPlotName, "_CDR2_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## cdr3

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = cdr3)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nCDR3 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$cdr3), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$cdr3), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8C_", toPlotName, "_cdr3_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## N Region

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = NRegion)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 0.5)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nN Region length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$NRegion), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$NRegion), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8D_", toPlotName, "_NRegion_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## threeVRegion

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = threeVRegion)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\n3'V Region length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$threeVRegion), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$threeVRegion), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(0,20), breaks = c(0, 5, 10,15,20))

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigSE_", toPlotName, "_threeVRegion_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## fiveJRegion

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = fiveJRegion)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\n5'J Region length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$fiveJRegion), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$fiveJRegion), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8F_", toPlotName, "_fiveJRegion_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## FR1

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = fr1)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nFR1 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$fr1), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$fr1), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(73,81))

p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8H_", toPlotName, "_FR1_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## FR2

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = fr2)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nFR2 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$fr2), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$fr2), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(45,55), breaks = c(45,50, 55))


p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8I_", toPlotName, "_FR2_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)

## FR3

if(dev.cur()>1) dev.off()
quartz(width=13,height=8, dpi=72)  ### open plotting window
update_geom_defaults("line", aes(size = 2))
update_geom_defaults("point", aes(size = 2))

theme_set(theme_bw(36) + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + theme(legend.key = element_blank()))

cbPalette = c('#66c2a5','#fc8d62', 'gray')

ggplot(toPlot, aes(x = fr3)) + geom_density(aes(fill = PITmatch), alpha = 0.5, adjust = 1)
#last_plot() + theme(legend.spacing.y = unit(0.5, 'cm')) + guides(fill = guide_legend(byrow = TRUE))

xlab = "\nFR3 length (nt)"
ylab = "Density\n"
last_plot() + labs(x = xlab, y = ylab)
last_plot() + geom_vline(xintercept = median(traMatchT$fr3), lty = "solid")
last_plot() + geom_vline(xintercept = median(traMatchF$fr3), lty = "dashed")
last_plot() + scale_fill_manual(values=cbPalette)
last_plot() + scale_x_continuous(limits = c(90,105), breaks = c(90,95, 100, 105))


p = last_plot()

forLab = ggplot_build(p)

Y = 0.9*(max(forLab$data[[1]]$density))
X = 1*(min((forLab$data[[1]]$x)))

label = paste("KS test, \np-value =", scientific(test1$p.value, 2), sep = " ")
#last_plot() + annotate("text", X, Y, label = label, size = 8, hjust = 0)

p = last_plot()
setwd("/Users/peterlinsley/Desktop/PIT_TCR_paper_code/Figure_PDFs/")
filename = paste0("FigS8J_", toPlotName, "_FR3_length_by_PITmatch.pdf") #TRA

ggsave(filename, p)
















