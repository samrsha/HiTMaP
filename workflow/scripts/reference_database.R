# ------------------------------ Sourcing funcitons from other R script ------------------------------
source("scripts/loading_packages.R")
source("../R/Canidate_processing.R")
source("../R/Utilities_Cluster_image.R")

# ------------------------------ Package Loading ------------------------------
loading_all_packages()

# ------------------------------ Setting parameter ------------------------------
datafile = snakemake@params[['datafile']]
Digestion_site = snakemake@params[['Digestion_site']]
Thread = snakemake@params[['Thread']]
Fastadatabase = snakemake@params[['Fastadatabase']]
mode = snakemake@params[['mode']]
mzrange = snakemake@params[['mzrange']]
adducts = snakemake@params[['adducts']]
Multiple_mode = snakemake@params[['Multiple_mode']]
Decoy_adducts = snakemake@params[['Decoy_adducts']]
Decoy_search = snakemake@params[['Decoy_search']]
Decoy_mode = snakemake@params[['Decoy_mode']]
use_previous_candidates = snakemake@params[['use_previous_candidates']]
missedCleavages = snakemake@params[['missedCleavages']]
Substitute_AA = snakemake@params[['Substitute_AA']]
Modifications = snakemake@params[['Modifications']]
projectfolder = snakemake@params[['projectfolder']]

# ------------------------------ Setting up the workign directory ------------------------------
if (missing(datafile)) stop("Missing data file, Choose single or multiple imzml file(s) for analysis")
# retrieve/parse the working dir info, and convert the filenames
if (is.null(projectfolder)){
    workdir<-base::dirname(datafile[1])
}else{ workdir<-projectfolder }

datafile <- basename(datafile)
datafile <- gsub(".imzML$", "", datafile) # Get the image file name, e.g. /data/bolvin.imzML --> /data/bolvin
datafile_imzML <- paste0(datafile,".imzML")
setwd("data/") # this is a bit hardcoding cody

# ------------------------------ Setting up Biocparallel param ------------------------------
if (is.null(Thread)){
  # setting up number of thread/worker if Thread is not given
  parallel=try(detectCores()/2) # detecting how many CPU this host (e.g. your laptop) and will use half of it for running
  if (parallel<1 | is.null(parallel)){parallel=1}
  BPPARAM=HiTMaP:::Parallel.OS(parallel)
  setCardinalBPPARAM(BPPARAM = BPPARAM)
}else{
  # if Thread is given, then will use the given Thread for BiocParallel running
  parallel=Thread 
  BPPARAM=HiTMaP:::Parallel.OS(parallel)
  setCardinalBPPARAM(BPPARAM = BPPARAM)
}

message("Parallel Worker Set up Finshed: ")
message(paste("    -",try(detectCores()), "Cores detected."))
message(paste("    -",parallel, "threads will be used for computing.\n"))

message("File Selection Finshed: ")
message(paste("    -", length(datafile), "imzML files were selected and will be used for Searching."))
message(paste("    -", Fastadatabase, "was selected as database.", "Candidates will be generated through",mode[1] ,"mode\n"))

Protein_feature_list <- Protein_feature_list_fun(
                                                 database=Fastadatabase,
                                                 Digestion_site=Digestion_site,
                                                 missedCleavages=missedCleavages,
                                                 adducts=adducts,
                                                 BPPARAM = BPPARAM,
                                                 Decoy_adducts=Decoy_adducts,
                                                 Decoy_search=Decoy_search,
                                                 Decoy_mode = Decoy_mode,
                                                 use_previous_candidates=use_previous_candidates,
                                                 Substitute_AA=Substitute_AA,
                                                 Modifications=Modifications,
                                                 mzrange=mzrange)

message("
                  _______
                 /      /,
                /      //
               /______//
              (______(/
< Reference database generation completed! >
")