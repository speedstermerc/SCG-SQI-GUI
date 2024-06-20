% create a struct 

subject_directory = struct; 
subject_directory.('David') = struct; 
subject_directory.('David').('MIMS') = [3129];
subject_directory.('David').('DARPA') = [122, 123];

subject_directory.('Cem') = struct; 
subject_directory.('Cem').('DARPA') = [122, 123];

subject_directory.('Michael') = struct;
subject_directory.('Michael').('DARPA') = [108, 133];
