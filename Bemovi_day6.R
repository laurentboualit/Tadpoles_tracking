###########################################################################################################
############################# Analysing swimming behavior #################################################
###########################################################################################################

library(bemovi)
library(xlsx)


rm(list=ls())
T5<-Sys.time() #time couting point 1

#I. Dataframe preparation


data <- read.xlsx("/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/DB/Suivi_tadpoles_multiple_days.xlsx", sheetIndex = 3)
data$file <- rep(c(1:6),20)


#1.  Let's add the numerical conc. 

conc <- c("CTL","C1","C2","C3","C4","DMSO")
nom_conc <- c("0","0.0001","0.001","0.01","0.1", "DMSO")
conc_nom_conc <- cbind(conc,nom_conc)
conc_nom_conc <- as.data.frame(conc_nom_conc)

for (i in 1:nrow(data)) {
  for (j in 1:nrow(conc_nom_conc)) {
    if (data$conc[i] == conc_nom_conc$conc[j]) {
      data$Nom_Conc[i] <- conc_nom_conc$nom_conc[j]
    }
  }
}


data_clean <- data

##II. VIDEO ANALYSIS

#Let's take the ten first video files for adjusting the threshold for all videos

#video.description <- data_clean[c(1:10),]
#write.table(x = video.description, file = "/home/laurent/Dropbox/Boulot/PHD/Projects/TAD_VS/TAD_VS_CPF/Test_avec_solvant/R_Script/Swimming_analyse/Fedora/0 _video_description/video.description.txt",sep = "\t", row.names = FALSE)

# project directory (you create this one yourself)

to.data <- "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/"

# you also have to provide two folders:
# the first contains the video description
# the second holds the raw videos
video.description.folder <- "0_video_description/"
video.description.file <- "video.description.txt"
raw.video.folder <- "1_raw/"

# the following intermediate directories are automatically created
particle.data.folder <- "2_particle_data/"
trajectory.data.folder <- "3_trajectory_data/"
temp.overlay.folder <- "4a_temp_overlays/"
overlay.folder <- "4_overlays/"
merged.data.folder <- "5_merged_data/"
ijmacs.folder <- "ijmacs/"


#UNIX example (adapt paths to your installation and avoid using the tilde symbol when specifying the paths)
IJ.path <- "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/ImageJ/"
to.particlelinker <- "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/"

# specify the amount of memory available to ImageJ and Java (in Mb)
memory.alloc <- c(40000)

# video frame rate (in frames per second)
fps <- 60

# size of a pixel in micrometer
pixel_to_scale <- 490/490

# use difference image segmentation
difference.lag <- 50

# uncomment the next line to use only threshold based segmentation
# difference.lag <- 0

# # specify threshold
# thresholds = c(42,255)
# 
# 
# check_threshold_values(to.data, raw.video.folder,
#                       ijmacs.folder, 0, difference.lag, thresholds,
#                       IJ.path, memory.alloc)

# Get the name of the videos and directory (to be adapted).

work_dir <- "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/"
MOV_names <- list.files("/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/Test/videos_final/Day6/")
MOV_FULLnames <- list.files("/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/Test/videos_final/Day6/", full.names = TRUE)

#PART I Let's start a loop for each video (use the video, crop it in 6 wells, convert to .avi, remove the MOV, analyse it with bemovi and remove the .avi)

for(i in 1:length(MOV_names)){ # Loop for each video 
  MOVFULL <- MOV_FULLnames[i] #path to the video
  MOV <- MOV_names[i] # video name
  MOV_sans_ext <- tools::file_path_sans_ext(MOV) #video name without the ext
  raw <- "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/1_raw/" # the path to the raw directory (to be adapted)
  
  #Remove the first minute (to be adapted) of each video as a acclimatation time and cp video in the 1_raw directory 
system(command = paste("ffmpeg  -i ", MOVFULL, " -ss 00:01:00 -t 00:10:00 -async 1 -strict -2 ", raw, "video_cut.MOV",  sep=""))
  
  #Declare y (margin from the top), w (the width of frames), h (the height of frames) and l (the well number) (to be adapted)
  
  l <- 1
  y <- 50
  
  # loop for both the horizontal well series
  for (j in 1:2) {
    
    x <- 190
    #loop for each well of the "horizontal well series"[i]
### 470:470:240:60 pour le premier puit, puis ajouter 505 dans les x et 520 pour y
    for (k in 1:3) {
      system(command = paste("ffmpeg -i ", raw, "video_cut.MOV -vf 'crop=490:490:", x, ":", y, "' -acodec copy -vcodec rawvideo ", raw, l,".avi", sep=""))
      
    l <- l + 1
    x <- x + 530
    }
  y <- y + 520  
  }
  
system(command = paste("rm ", raw, "video_cut.MOV", sep = ""))

#So now that we got the individual videos we can start the tracking part

#Let's create the file.description file
video.description <- data_clean[c(1:6),]
write.table(x = video.description, file = "/home/laurent/Dropbox/Boulot/PHD/Projects/ASTA/TAD_VS_CPF/Test_avec_solvant_2/Scripts/Swiming_behavior_extraction/0_video_description/video.description.txt",sep = "\t", row.names = FALSE)
data_clean <- data_clean[-c(1:6),] # Let's remove the 6 first lines for the next round

# check_threshold_values(to.data, raw.video.folder,
#                       ijmacs.folder, 0, difference.lag, thresholds,
#                       IJ.path, memory.alloc)

# specify threshold
thresholds = c(11,255)

locate_and_measure_particles(to.data, raw.video.folder, 
                             particle.data.folder, difference.lag, 
                             thresholds, min_size = 5, max_size = 1000,  # min and max size has to be tuned
                             IJ.path, memory.alloc)

link_particles(to.data, particle.data.folder, 
               trajectory.data.folder, linkrange = 50, 
               disp = 200, start_vid = 1, memory = memory.alloc)

merge_data(to.data, particle.data.folder, 
           trajectory.data.folder, video.description.folder, 
           video.description.file, merged.data.folder)

load(paste0(to.data,merged.data.folder,"Master.RData"))


trajectory.data.filtered <- trajectory.data #filter_data(trajectory.data,50,1,0.1,5)
trajectory.data.filtered$type <- "filtered data"
trajectory.data$type <- "raw data"
# 
morph_mvt <- summarize_trajectories(trajectory.data.filtered, write=T, calculate.median=F, to.data, merged.data.folder)

 
# create_overlays(to.data, merged.data.folder, raw.video.folder,
#                 temp.overlay.folder, overlay.folder,
#                 490,
#                 490,
#                 difference.lag,
#                 type="traj",
#                 predict_spec=F,
#                 IJ.path,
#                 contrast.enhancement = 1.0,
#                 memory = memory.alloc)

folder <- paste("video", i, "/", sep = "")

# system(command = paste("cd ", work_dir, 
#                        " && mkdir ", folder,  
#                        " && mv -t ", work_dir, folder, " ", particle.data.folder, " ", trajectory.data.folder, " ", merged.data.folder, " ", sep = ""
#                        )
#       )
#system(command = paste("cd ", Fedora, folder, 
#                       " && mv Master.RData ../Master", i , "RData && rm -rf ", Fedora, folder, sep = ""
#      )
#)


system(command = paste("rm ", raw, "*.avi", sep =""))

if (!exists("merge1")) {
  merge1 <- trajectory.data
} else{
  merge1 <- rbind(merge1, trajectory.data)
}
}

save(merge1, file = paste0(work_dir,"Master_day6.RData"))
system(command = "espeak -v fr 'Vidéos analysés'")

T6<-Sys.time() #time counting point 2




