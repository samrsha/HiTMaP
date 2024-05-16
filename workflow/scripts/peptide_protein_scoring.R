# ------------------------------ Package Loading ------------------------------
source("scripts/loading_packages.R")
loading_all_packages()

# ------------------------------ Sourcing funcitons from other R script ------------------------------
source("../R/Utilities_Cluster_image.R")
source("../R/Utilities_IMS_processing.R")
source("../R/Utilities_proteomics_annotation.R") #Do_PMF_search()
source("../R/Utilities_general.R") #topN_feature()
source("../R/workflow.R")

# ------------------------------ Setting parameter ------------------------------
datafile = snakemake@params[['datafile']]
Thread = snakemake@params[['Thread']]
Fastadatabase = snakemake@params[['Fastadatabase']]
mzrange = snakemake@params[['mzrange']]
threshold = snakemake@params[['threshold']]
ppm = snakemake@params[['ppm']]
IMS_analysis = snakemake@params[['IMS_analysis']]
Segmentation = snakemake@params[['Segmentation']]
Virtual_segmentation_rankfile = snakemake@params[['Virtual_segmentation_rankfile']]
Bypass_generate_spectrum = snakemake@params[['Bypass_generate_spectrum']]
spectra_segments_per_file = snakemake@params[['spectra_segments_per_file']]
Rotate_IMG = snakemake@params[['Rotate_IMG']]
Segmentation_ncomp = snakemake@params[['Segmentation_ncomp']]
score_method = snakemake@params[['score_method']]
Decoy_search = snakemake@params[['Decoy_search']]
Decoy_mode = snakemake@params[['Decoy_mode']]
adjust_score = snakemake@params[['adjust_score']]
peptide_ID_filter = snakemake@params[['peptide_ID_filter']]
Protein_desc_of_interest = snakemake@params[['Protein_desc_of_interest']]
plot_matching_score = snakemake@params[['plot_matching_score']]
FDR_cutoff = snakemake@params[['FDR_cutoff']]
Segmentation_def = snakemake@params[['Segmentation_def']]
Segmentation_variance_coverage = snakemake@params[['Segmentation_variance_coverage']]
preprocess = snakemake@params[['preprocess']]
projectfolder = snakemake@params[['projectfolder']]
Protein_feature_summary = snakemake@params[['Protein_feature_summary']]
Peptide_feature_summary = snakemake@params[['Peptide_feature_summary']]
Region_feature_summary = snakemake@params[['Region_feature_summary']]
PMFsearch=IMS_analysis

# ------------------------------ Package Loading + Setting working directory ------------------------------

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
  parallel=try(future::availableCores()/2) # detecting how many CPU this host (e.g. your laptop) and will use half of it for running
  if (parallel<1 | is.null(parallel)){parallel=1}
  BPPARAM=HiTMaP:::Parallel.OS(parallel)
  setCardinalBPPARAM(BPPARAM = BPPARAM)
}else{
  # if Thread is given, then will use the given Thread for BiocParallel running
  parallel=Thread 
  BPPARAM=HiTMaP:::Parallel.OS(parallel)
  setCardinalBPPARAM(BPPARAM = BPPARAM)
}

# ------------------------------ Select candidate list for IMS annotation  ------------------------------
if(IMS_analysis){
    message("Selecting candidate list for IMS annotation...")
    message(paste("1.", Fastadatabase,"was selected as database","\n2. Spectrum intensity threshold:",percent(threshold),"\n3. mz tolerance:",ppm,"ppm","Segmentation method:",Segmentation[1],
                "\n4. Manual segmentation def file:",ifelse(is.null(Virtual_segmentation_rankfile),"None",Virtual_segmentation_rankfile),"\n5. Bypass spectrum generation:",Bypass_generate_spectrum))
  
    #select candidate list for IMS annotation 
    message("\nLoading Reference Database...")
    Protein_feature_list<-read.csv("Summary folder/candidatelist.csv")
    Protein_feature_list$Modification[is.na(Protein_feature_list$Modification)]<-""
    Index_of_protein_sequence<<-read.csv("Summary folder/protein_index.csv")
    message(" ---> Reference Database loaded.\n")

    Peptide_Summary_searchlist<-unique(Protein_feature_list)
    Peptide_Summary_file<-IMS_data_process(workdir=getwd(),
                                           datafile=datafile, 
                                           Peptide_Summary_searchlist=Peptide_Summary_searchlist,
                                           segmentation_num=spectra_segments_per_file,
                                           threshold=threshold,
                                           rotate = Rotate_IMG,
                                           ppm=ppm,
                                           mzrange=mzrange,
                                           Segmentation=Segmentation,
                                           Segmentation_ncomp=Segmentation_ncomp,
                                           PMFsearch = PMFsearch,
                                           Virtual_segmentation_rankfile = Virtual_segmentation_rankfile,
                                           BPPARAM = BPPARAM,
                                           Bypass_generate_spectrum=Bypass_generate_spectrum,
                                           score_method = score_method,
                                           Decoy_mode=Decoy_mode,
                                           Decoy_search=Decoy_search,
                                           adjust_score=adjust_score,
                                           peptide_ID_filter=peptide_ID_filter,
                                           Protein_desc_of_interest=Protein_desc_of_interest,
                                           plot_matching_score_t=plot_matching_score,
                                           FDR_cutoff= FDR_cutoff,
                                           Segmentation_def=Segmentation_def,
                                           Segmentation_variance_coverage=Segmentation_variance_coverage,
                                           preprocess=preprocess)

}

# ------------------------------ Summarize the protein result across the datafiles and store these summarized files into the summary folder  ------------------------------
if(Protein_feature_summary){
  message("Protein feature summary...")
  Peptide_Summary_file<-NULL
  Protein_peptide_Summary_file<-NULL
  protein_feature_all<-NULL
  for (i in 1:length(datafile)){
    datafilename<-gsub(paste(workdir,"/",sep=""),"",gsub(".imzML", "", datafile[i]))
    currentdir<-paste0(workdir,"/",datafile[i]," ID")
    setwd(paste(currentdir,sep=""))
    protein_feature<-NULL
    for (protein_feature_file in dir()[stringr::str_detect(dir(),"Protein_segment_PMF_RESULT_")]){
      protein_feature<-fread(protein_feature_file)
    
      if(nrow(protein_feature)!=0){
        protein_feature$Source<-datafilename
        region_code<-str_replace(protein_feature_file,"Protein_segment_PMF_RESULT_","")
        region_code<-str_replace(region_code,".csv","")
        protein_feature$Region<-region_code
        protein_feature_all<-rbind(protein_feature_all,protein_feature)
      }
    
    }
    Peptide_Summary_file<-fread("Peptide_region_file.csv")
    Peptide_Summary_file$Source<-datafilename
    if(nrow(Peptide_Summary_file)!=0){
      Protein_peptide_Summary_file<-rbind(Protein_peptide_Summary_file,Peptide_Summary_file)
    }
    setwd("..") #set dir back to previous
  }
  message("Protein feature summary...Done.")
  if (dir.exists(paste(workdir,"/Summary folder",sep=""))==FALSE){dir.create(paste(workdir,"/Summary folder",sep=""))}

  write.csv(protein_feature_all,paste(workdir,"/Summary folder/Protein_Summary.csv",sep=""),row.names = F)
  write.csv(Protein_peptide_Summary_file,paste(workdir,"/Summary folder/Protein_peptide_Summary.csv",sep=""),row.names = F)
}

# ------------------------------ Summarize the protein and peptide result across the datafiles and store these summarized files into the summary folder  ------------------------------
if(Peptide_feature_summary){
  message("Peptide feature summary...")
  Peptide_Summary_file<-NULL
  Peptide_Summary_file_a<-NULL
  for (i in 1:length(datafile)){
    datafilename<-gsub(paste(workdir,"/",sep=""),"",gsub(".imzML", "", datafile[i]))
    currentdir<-paste0(workdir,"/",datafile[i]," ID")
    setwd(paste(currentdir,sep=""))
    Peptide_Summary_file<-fread("Peptide_region_file.csv")
    Peptide_Summary_file$Source<-gsub(".imzML", "", datafile[i])
    if(nrow(Peptide_Summary_file)!=0){
      Peptide_Summary_file_a<-rbind(Peptide_Summary_file_a,Peptide_Summary_file)
    }
    setwd("..") #set dir back to previous
  }
  Peptide_Summary_file_a<-unique(Peptide_Summary_file_a)
    message("Peptide feature summary...Done.")
    if (dir.exists(paste(workdir,"/Summary folder",sep=""))==FALSE){dir.create(paste(workdir,"/Summary folder",sep=""))}
    write.csv(Peptide_Summary_file_a,paste(workdir,"/Summary folder/Peptide_Summary.csv",sep=""),row.names = F)
    #Peptide_feature_summary_all_files_new(datafile,workdir,threshold = threshold)
  }


# ------------------------------ Summarize the mz feature list   ------------------------------
if(Region_feature_summary){
  message("Region feature summary...")
  Spectrum_summary<-NULL
  for (i in 1:length(datafile)){
    datafilename<-gsub(paste(workdir,"/",sep=""),"",gsub(".imzML", "", datafile[i]))
    currentdir<-paste0(workdir,"/",datafile[i]," ID")
    setwd(currentdir)
    name <-gsub(base::dirname(datafile[i]),"",gsub(".imzML", "", datafile[i]))
    message(paste("Region_feature_summary",gsub(".imzML", "", datafile[i])))

    if (dir.exists(paste(workdir,"/Summary folder",sep=""))==FALSE){dir.create(paste(workdir,"/Summary folder",sep=""))}
    
    match_pattern <- "Spectrum.csv"
    spectrum_file_table_sum<-NULL
    for (spectrum_file in dir(recursive = T)[str_detect(dir(recursive = T), match_pattern)]){
      spectrum_file_table=fread(spectrum_file)
      if (nrow(spectrum_file_table)>=1){
        spectrum_file_table$Region=gsub("/Spectrum.csv","",spectrum_file)
        spectrum_file_table$Source<-gsub(".imzML", "", datafile[i])
        spectrum_file_table_sum[[spectrum_file]] <- spectrum_file_table
      }
      
    }
    spectrum_file_table_sum <- do.call(rbind,spectrum_file_table_sum)
    Spectrum_summary[[datafile[i]]]=spectrum_file_table_sum
    setwd("..") #set dir back to previous
  }
  Spectrum_summary <- do.call(rbind,Spectrum_summary)
  write.csv(Spectrum_summary,file = paste(workdir,"/Summary folder/Region_feature_summary.csv",sep=""),row.names = F)

}

message("
                   /\\_/\\
                  ( o.o )
                   > ^ <

< Peak picking, scoring and ranking finished! >
")