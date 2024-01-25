configfile: 'config.yaml'

rule reference_database_generation:
    output: 'data/Summary folder/candidatelist.csv',
            'data/Summary folder/protein_index.csv'
    params: 
        datafile = config['datafile'],
        Digestion_site = config['Digestion_site'],
        Thread = config['Thread'],
        Fastadatabase = config['Fastadatabase'],
        mode = config['mode'],
        mzrange = config['mzrange'],
        adducts = config['adducts'],
        Multiple_mode = config['Multiple_mode'],
        Decoy_adducts = config['Decoy_adducts'],
        Decoy_search = config['Decoy_search'],
        Decoy_mode = config['Decoy_mode'],
        use_previous_candidates = config['use_previous_candidates'],
        missedCleavages = config['missedCleavages'],
        Substitute_AA = config['Substitute_AA'],
        Modifications = config['Modifications'],
        projectfolder = config['projectfolder']
    script:
        '../scripts/reference_database.R'
        #'../scripts/debugg.R'