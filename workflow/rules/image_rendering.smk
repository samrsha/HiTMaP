configfile: 'config.yaml'
import os
def get_folder_ids(data_folder_path):
    folder_ids = []
    # Check if the path exists and is a directory
    if os.path.exists(data_folder_path) and os.path.isdir(data_folder_path):
        # Iterate through items in the directory
        for item in os.listdir(data_folder_path):
            item_path = os.path.join(data_folder_path, item)
            # Check if the item is a directory and ends with ' ID'
            if os.path.isdir(item_path) and item.endswith(" ID"):
                # Extract the part of the name without ' ID'
                folder_id = item[:-3]  # Remove last 3 characters (' ID')
                folder_ids.append(folder_id)
    else:
        print(f"The path {data_folder_path} does not exist or is not a directory.")
    return folder_ids

rule image_rendering:
    input: expand('data/{folder_id} ID/Peptide_region_file.csv', folder_id = get_folder_ids("data"))
    output: 'data/Summary folder/Protein_feature_list_trimmed.csv'
    params: 
        datafile = config['datafile'],
        Thread = config['Thread'],
        mzrange = config['mzrange'],
        ppm = config['ppm'],
        Rotate_IMG = config['Rotate_IMG'],
        Protein_desc_of_interest = config['Protein_desc_of_interest'],
        projectfolder = config['projectfolder'],
        plot_cluster_image_grid = config['plot_cluster_image_grid'],
        remove_score_outlier = config['remove_score_outlier'],
        Plot_score_abs_cutoff = config['Plot_score_abs_cutoff'],
        cluster_rds_path = config['cluster_rds_path'],
        Plot_score_IQR_cutoff = config['Plot_score_IQR_cutoff'],
        mzAlign_runs = config['mzAlign_runs'],
        deconv_peaklist = config['deconv_peaklist'],
        plot_unique_component = config['plot_unique_component'],
        peptide_ID_filter = config['peptide_ID_filter'],

        ClusterID_colname = config['ClusterID_colname'],
        componentID_colname = config['componentID_colname'],
        plot_layout = config['plot_layout'],
        export_Header_table = config['export_Header_table'],
        export_footer_table = config['export_footer_table'],
        attach_summary_cluster = config['attach_summary_cluster'],
        smooth_image = config['smooth_image'],
        Component_plot_coloure = config['Component_plot_coloure'],
        cluster_color_scale = config['cluster_color_scale'],
        img_brightness = config['img_brightness'],
        pixel_size_um = config['pixel_size_um'],
        Fastadatabase = config['Fastadatabase'],  
    script:
        '../scripts/image_rendering.R'