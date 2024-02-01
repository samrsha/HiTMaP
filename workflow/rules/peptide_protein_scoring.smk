configfile: 'config.yaml'

rule peptide_protein_scoring:
    input: 'data/Summary folder/candidatelist.csv',
           'data/Summary folder/protein_index.csv'
    output: 'data/{folder_id} ID/Peptide_region_file.csv'
    params: 
        datafile = config['datafile'],
        Thread = config['Thread'],
        mzrange = config['mzrange'],
        Decoy_search = config['Decoy_search'],
        Decoy_mode = config['Decoy_mode'],
        Fastadatabase = config['Fastadatabase'],
        threshold = config['threshold'],
        ppm = config['ppm'],
        IMS_analysis = config['IMS_analysis'],
        Segmentation = config['Segmentation'],
        Virtual_segmentation_rankfile = config['Virtual_segmentation_rankfile'],
        Bypass_generate_spectrum = config['Bypass_generate_spectrum'],
        spectra_segments_per_file = config['spectra_segments_per_file'],
        Rotate_IMG = config['Rotate_IMG'],
        Segmentation_ncomp = config['Segmentation_ncomp'],
        score_method = config['score_method'],
        adjust_score = config['adjust_score'],
        peptide_ID_filter = config['peptide_ID_filter'],
        Protein_desc_of_interest = config['Protein_desc_of_interest'],
        plot_matching_score = config['plot_matching_score'],
        FDR_cutoff = config['FDR_cutoff'],
        Segmentation_def = config['Segmentation_def'],
        Segmentation_variance_coverage = config['Segmentation_variance_coverage'],
        preprocess = config['preprocess'],
        projectfolder = config['projectfolder'],
        Protein_feature_summary = config['Protein_feature_summary'],
        Peptide_feature_summary = config['Peptide_feature_summary'],
        Region_feature_summary = config['Region_feature_summary']
    conda:
        "../env/conda_env.yaml"
    script:
        '../scripts/peptide_protein_scoring.R'