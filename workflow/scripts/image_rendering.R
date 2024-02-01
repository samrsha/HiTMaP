message("Image rendering starts now ...")
# ------------------------------ Sourcing funcitons from other R script ------------------------------
source("scripts/loading_packages.R")
source("../R/Utilities_Cluster_image.R")
source("../R/Utilities_IMS_processing.R")
source("../R/Utilities_proteomics_annotation.R")
source("../R/Utilities_general.R")
source("../R/workflow.R")

# ------------------------------ Setting parameter ------------------------------
datafile = snakemake@params[['datafile']]
Thread = snakemake@params[['Thread']]
mzrange = snakemake@params[['mzrange']]
ppm = snakemake@params[['ppm']]
Rotate_IMG = snakemake@params[['Rotate_IMG']]
Protein_desc_of_interest = snakemake@params[['Protein_desc_of_interest']]
projectfolder = snakemake@params[['projectfolder']]
plot_cluster_image_grid = snakemake@params[['plot_cluster_image_grid']]
remove_score_outlier = snakemake@params[['remove_score_outlier']]
Plot_score_IQR_cutoff = snakemake@params[['Region_featurePlot_score_IQR_cutoff_summary']]
Plot_score_abs_cutoff = snakemake@params[['Plot_score_abs_cutoff']]
cluster_rds_path = snakemake@params[['cluster_rds_path']]
mzAlign_runs = snakemake@params[['mzAlign_runs']]
deconv_peaklist = snakemake@params[['deconv_peaklist']]
plot_unique_component = snakemake@params[['plot_unique_component']]


ClusterID_colname = snakemake@params[['ClusterID_colname']]
componentID_colname = snakemake@params[['componentID_colname']]
plot_layout = snakemake@params[['plot_layout']]
export_Header_table = snakemake@params[['export_Header_table']]
export_footer_table = snakemake@params[['export_footer_table']]
attach_summary_cluster = snakemake@params[['attach_summary_cluster']]
smooth.image = snakemake@params[['smooth_image']]
Component_plot_coloure = snakemake@params[['Component_plot_coloure']]
cluster_color_scale = snakemake@params[['cluster_color_scale']]
img_brightness = snakemake@params[['img_brightness']]
pixel_size_um = snakemake@params[['pixel_size_um']]
database = snakemake@params[['Fastadatabase']]
peptide_ID_filter = snakemake@params[['peptide_ID_filter']]
remove_cluster_from_grid = attach_summary_cluster

# ------------------------------ Package Loading + Setting working directory ------------------------------
loading_all_packages()

if (is.null(projectfolder)){
    workdir<-base::dirname(datafile[1])
    workdir <- paste(getwd(), "/data", sep = "")
}else{ workdir<-projectfolder }
datafile <- basename(datafile)
datafile <- gsub(".imzML$", "", datafile) # Get the image file name, e.g. /data/bolvin.imzML --> /data/bolvin
datafile_imzML <- paste0(datafile,".imzML")

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


# ------------------------------ Protein cluster image rendering ------------------------------
  
if(plot_cluster_image_grid){
    message(" ---> Cluster image rendering...")
    setwd(workdir[1])
    
    list_of_protein_sequence <- readAAStringSet(database,
                                            format="fasta",
                                            nrec=-1L, 
                                            skip=0L, 
                                            seek.first.rec=FALSE
                                            )
    # read protein-peptide features result
    
    Protein_feature_list=read.csv(file=paste(workdir[1],"/Summary folder/Protein_peptide_Summary.csv",sep=""),stringsAsFactors = F)
    
    # remove peptide score outlier from result
    
    if (remove_score_outlier){
      Protein_feature_list <- remove_pep_score_outlier(Protein_feature_list,abs_cutoff=Plot_score_abs_cutoff,IQR_LB = Plot_score_IQR_cutoff)
    }
    
    # extract the protein entries of interest
    
    if (sum(Protein_desc_of_interest!=".")>=1){
        Protein_feature_list_interest<-NULL
        num_of_interest<-numeric(0)
    
        for (interest_desc in Protein_desc_of_interest){
        idx_iterest_desc<-str_detect(Protein_feature_list$desc,regex(interest_desc,ignore_case = T))
        if(nrow(Protein_feature_list[idx_iterest_desc,])!=0){
        Protein_feature_list_interest<-rbind(Protein_feature_list_interest,Protein_feature_list[idx_iterest_desc,])
        }
        num_of_interest[interest_desc]<-length(unique(Protein_feature_list[idx_iterest_desc,"Protein"]))
        }
        
        Protein_feature_list=Protein_feature_list_interest
        message(paste(num_of_interest,"Protein(s) found with annotations of interest:",Protein_desc_of_interest,collapse = "\n"))
    }

    Protein_feature_list=as.data.frame(Protein_feature_list)

    # generate combined IMS data for multiple files or use a link to load the pre-processed IMS data

    if (!is.null(cluster_rds_path)){

        cluster_rds_path
        imdata=readRDS(paste0(workdir[1],"/",cluster_rds_path))
        message("Cluster imdata loaded.")
    
    }else{

        cluster_rds_path<-Load_IMS_decov_combine(datafile=datafile,workdir=workdir,import_ppm=ppm,SPECTRUM_batch="overall",mzAlign_runs=mzAlign_runs,
                                        ppm=ppm,threshold=0,rotate=Rotate_IMG,mzrange=mzrange,
                                        deconv_peaklist=deconv_peaklist,preprocessRDS_rotated=T,target_mzlist=sort(unique(as.numeric(Protein_feature_list$mz)),decreasing = F))


        imdata=readRDS(paste0(workdir[1],"/",basename(cluster_rds_path)))

        message("Cluster imdata generated and loaded.")
    }

    # test combined imdata
    if (class(imdata)[1]=="matrix"){
      
      do.call(Cardinal::cbind,imdata)->imdata
      
      saveRDS(imdata,paste0(workdir[1],"/combinedimdata.rds"),compress = T)
      
    }
    print("cody2")
    # Setup output folder and queue the R calls for cluster image randering
    outputfolder=paste(workdir,"/Summary folder/cluster Ion images/",sep="")
    if (dir.exists(outputfolder)==FALSE){dir.create(outputfolder)}

    if (!(plot_unique_component)){
        setwd(outputfolder)
        Protein_feature_list_trimmed<-Protein_feature_list
    }

    if (plot_unique_component){
        outputfolder=paste(workdir,"/Summary folder/cluster Ion images/unique/",sep="")

        if (dir.exists(outputfolder)==FALSE){dir.create(outputfolder)}
        setwd(outputfolder)
        Protein_feature_list_unique=Protein_feature_list %>% group_by(mz) %>% dplyr::summarise(num=length(unique(Protein)))
        Protein_feature_list_unique_mz<-Protein_feature_list_unique$mz[Protein_feature_list_unique$num==1]
        Protein_feature_list_trimmed<-Protein_feature_list[Protein_feature_list$mz %in% Protein_feature_list_unique_mz, ]
        #write.csv(Protein_feature_list_trimmed,paste("../../../Summary folder/Protein_feature_list_trimmed.csv",sep=""),row.names = F) #hard coding 
        write.csv(Protein_feature_list_trimmed,paste(workdir, "/Summary folder/Protein_feature_list_trimmed.csv",sep=""),row.names = F)
    }

    save(list=c("Protein_feature_list_trimmed",
                "imdata",
                "ClusterID_colname",
                "componentID_colname",
                "plot_layout",
                "export_Header_table",
                "export_footer_table",
                "attach_summary_cluster",
                "remove_cluster_from_grid",
                "smooth.image",
                "Component_plot_coloure",
                "cluster_color_scale",
                "list_of_protein_sequence",
                "outputfolder",
                "peptide_ID_filter",
                "ppm",
                "img_brightness",
                "pixel_size_um"
                ),
         file=paste0(workdir,"/cluster_img_grid.RData"))
    print(colnames(Protein_feature_list_trimmed))
    for (clusterID in unique(Protein_feature_list_trimmed$Protein)){
        cluster_desc<-unique(Protein_feature_list_trimmed$desc[Protein_feature_list_trimmed[[ClusterID_colname]]==clusterID])
        cluster_desc<-gsub(stringr::str_extract(cluster_desc,"OS=.{1,}"),"",cluster_desc)
        print(ClusterID_colname)
        print(Protein_feature_list_trimmed[[ClusterID_colname]]) #nihao

        n_component<-nrow(unique(Protein_feature_list_trimmed[Protein_feature_list_trimmed[[ClusterID_colname]]==clusterID,c(ClusterID_colname,componentID_colname,"moleculeNames","adduct","Modification")]))
        print("cody1")
        if (n_component>=peptide_ID_filter){
            if ('&'(file.exists(paste0(outputfolder,clusterID,"_cluster_imaging.png")),!plot_cluster_image_overwrite)){
                message("Cluster image rendering Skipped file exists: No.",clusterID," ",cluster_desc)
                next
            }else{
                fileConn<-file(paste0(workdir,"/cluster_img_scource.R"),)
                writeLines(c("suppressMessages(suppressWarnings(require(HiTMaP)))",
                        paste0("clusterID=",clusterID),
                        paste0("suppressMessages(suppressWarnings(load(file =\"", workdir,"/cluster_img_grid.RData\")))"),
                        "suppressMessages(suppressWarnings(cluster_image_grid(clusterID = clusterID,
                                            imdata=imdata,
                                            SMPLIST=Protein_feature_list_trimmed,
                                            ppm=ppm,
                                            ClusterID_colname=ClusterID_colname,
                                            componentID_colname=componentID_colname,
                                            plot_layout=plot_layout,
                                            export_Header_table=export_Header_table,
                                            export_footer_table=export_footer_table,
                                            attach_summary_cluster=attach_summary_cluster,
                                            remove_cluster_from_grid=remove_cluster_from_grid,
                                            plot_style=\"fleximaging\",
                                            smooth.image=smooth.image,
                                            Component_plot_coloure=Component_plot_coloure,
                                            cluster_color_scale=cluster_color_scale,
                                            list_of_protein_sequence=list_of_protein_sequence,
                                            workdir=outputfolder,
                                            pixel_size_um=pixel_size_um,
                                            img_brightness=img_brightness,
                                            Component_plot_threshold=peptide_ID_filter)))"),
                        fileConn)
                close(fileConn)
                system(paste0("Rscript \"",paste0(workdir,"/cluster_img_scource.R\"")))

                if(file.exists(paste0(outputfolder,clusterID,"_cluster_imaging.png"))){
                        message("Cluster image rendering Done: No.",clusterID," ",cluster_desc)

                }else{
                    retrytime=1
                    repeat{

                    message("Cluster image rendering failed and retry ",retrytime,": No.",clusterID," ",cluster_desc)
                    system(paste0("Rscript \"",paste0(workdir,"/cluster_img_scource.R\"")))

                    if (file.exists(paste0(outputfolder,clusterID,"_cluster_imaging.png"))){
                        message("Cluster image rendering Done: No.",clusterID," ",cluster_desc)

                        break
                    }else if(retrytime>=plot_cluster_image_maxretry){
                        message("Cluster image rendering reaches maximum Retry Attempts: No.",clusterID," ",cluster_desc)

                        break
                    }
                    retrytime=1+retrytime
                    }
                }
            }
        }
      }
}



message("
      ( (
       ) )
    ........
    |      |]
    \\      / 
     `----'
 < Workflow Done! >
")