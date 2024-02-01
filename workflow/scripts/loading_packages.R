loading_all_packages<-function(){
    suppressMessages(suppressWarnings(require(Biostrings)))
    suppressMessages(suppressWarnings(require(cleaver)))
    suppressMessages(suppressWarnings(require(protViz)))
    suppressMessages(suppressWarnings(require(rcdk)))
    suppressMessages(suppressWarnings(require(BiocParallel)))
    suppressMessages(suppressWarnings(require(OrgMassSpecR)))

    suppressMessages(suppressWarnings(library(rJava)))
    suppressMessages(suppressWarnings(require(HiTMaP)))

    suppressMessages(suppressWarnings(require(rcdklibs)))
    suppressMessages(suppressWarnings(require(grid)))
    suppressMessages(suppressWarnings(require(stringr)))
    suppressMessages(suppressWarnings(require(parallel)))
    suppressMessages(suppressWarnings(require(Cardinal)))
    suppressMessages(suppressWarnings(require(scales)))
    suppressMessages(suppressWarnings(require("pacman")))
    suppressMessages(suppressWarnings(require(dplyr)))
}