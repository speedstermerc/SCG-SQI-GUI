% Script for manual annotation of assigned SCG beats
addpath(genpath(pwd))
clear
close all;

limits_color = 'blue'; limits_lw  = 2;
limits_annot_color = 'red'; limits_annot_lw = 2;
%%
% generate struct that assigns subjects from various datasets to different
% annotators
subject_assignment

% MIMS dataset path
MIMS_tmp = ['InanResearchLab', filesep, 'IRL_Datasets', filesep, ...
    'MIMS', filesep, 'Processed_Data' filesep, 'Seismopatch', filesep, 'Nth_Beats', filesep, ...
    'Fifth_Beats', filesep];
    'MIMS';
MIMS_path = fullfile(pwd, '..', MIMS_tmp);

% DARPA dataset path 
DARPA_path = fullfile(pwd, 'Dummy_data/');

% ask user for annotator name and validate name
valid = false;
while valid == false
    annotator = input('Input annotator name: ', 's');
    if sum(ismember( fields(subject_directory), annotator)) == 1
        valid = true ;
    else
        disp([annotator, ' is not a valid annotator name or has not been set (try David)'])
    end
end

% ask user for dataset name and validate name
valid = false;
while valid == false
    dataset = input('Input Dataset: ', 's');
    if sum(ismember( fields(subject_directory.(annotator)), dataset)) == 1
        valid = true ;
    else
        disp([dataset, ' is not a valid dataset name or has not been set (try MIMS or DARPA)'])
    end
end

% set the sampling frequency (for plotting consistency) and file paths
% depending on the dataset chosen 
if strcmp(dataset, 'MIMS')
    fs_str = '500Hz';
    folder_name = MIMS_path;
else
    fs_str = '2kHz';
    folder_name = DARPA_path;
end

% Find the directory with .mat files
data_dir = dir([folder_name '*.mat']);
filenames = {data_dir.name};

% Define save path
save_path = ['Labels/' annotator '/'];

% Subject numbers assigned
subjects = subject_directory.(annotator).(dataset);

%% Please read instructions
% The directories below assume you will run
% this script from the folder it is in (i.e., you will not try running it
% by adding the folder to your path, but instead, go into the folder with
% the script and data saved and then run the script)

% Simply run this script and follow the instructions prompted to the
% command window

% If you want to quit and start again later, enter the letter q and your 
% progress will be saved. As long as you do not alter any files or this 
% script, running this script again will start you where you left off. Note
% that you are not allowed to quit during relabeling of previous beats


%% Loop through subjects assigned
for sub_ind = 1:length(subjects)
    
    %% Load the SCG beat file containing the subject number
    file_idx = contains(filenames, string(subjects(sub_ind)));
    assert(sum(file_idx) == 1, ['Subject ', num2str(subjects(sub_ind)), ' not found'])
    filename = filenames{file_idx};
    
    load([folder_name filename]);

    %%
    % MIMS data extraction to match original data format. If we want beats
    % that are truncated by the lowest heart rate, use
    % N_scgBeats_chopped.beats. If we want the beats with their original
    % legnths use N_scgBeats_cellArr
    if strcmp(dataset, 'MIMS')
        scgBeats = create_matrix(N_scgBeats_cellArr);
    end


    %% Show the user a visualization of beats
    % Create a black and white plot of the SCG beats stacked
    imagesc(scgBeats)
    map = contrast(scgBeats);
    colormap(map);
    xlabel(['Sample (Fs = ', fs_str,')'])
    ylabel('Beat Index')
    colorbar
    
    %% Check to see if progress was saved for this subject
    % Progress is saved by saving a new .mat file with labels so far
    % upon execution completion. Hence, if such a file exists, that implies
    % that we should start from where the annotator left off
    if isfile([save_path, filesep, 'S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'])
        % This implies that either the annotator is complete, or has
        % finished some but has a portion left.
        load(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'])
        
        % Have the user press enter to continue
        input([save_path, filesep, 'You have already selected intervals of interest. ', ...
            'Enter any key to continue. ']);

    else
        % Have the user choose interval of interest
        AObegin = input('Enter the start sample of your AO interval of interest: ');
        AOend = input('Enter the end sample of your AO interval of interest: ');
        ACbegin = input('Enter the start sample of your AC interval of interest: ');
        ACend = input('Enter the end sample of your AC interval of interest: ');

        % Initialize scgLabels array
        scgLabels = [];
        
        % Initialize reannotation arrays
        reann_labels = [];
        reann_indices = [];
        
        % Initialize AO/AC annotation arrays 
        ao_ann = []; ac_ann = [];
        reann_ao_ann = []; reann_ac_ann = [];

    end

    % We only need to continue onwards if the annotator has a portion left
    if size(scgLabels, 1) < size(scgBeats, 1)
        
        %% Plot some warm up beats to remind user of subject
        % Randomly select x beats from the dataset and have them enter
        % through them to make sure they understand what this subject's
        % data looks like in general
        numWarm = 10;
        
        for trial = 1:numWarm
            % Select a random beat from this subject's data
            beatInd = randi(size(scgBeats, 1));
            
            % Plot the beat
            plot(scgBeats(beatInd, :))
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel(['Sample (Fs = ', fs_str,')'])
            % AO Interval
            xline(AObegin, 'color', limits_color, 'LineWidth', limits_lw);
            xline(AOend, 'color', limits_color, 'LineWidth', limits_lw);
            % AC Interval
            xline(ACbegin, 'color', limits_color, 'LineWidth', limits_lw);
            xline(ACend, 'color', limits_color, 'LineWidth', limits_lw);

            
            % Have the user press enter to continue
            input(['Warm-up beat ', num2str(trial), ...
                '. Press enter to continue ']);
        end
        
        %% Start labeling process
        
        % Checkpoints to have annotator label some previous beats to
        % assess intra-annotator agreement
        checkPoints = round(size(scgBeats, 1)/10):...
            round(size(scgBeats, 1)/10):size(scgBeats, 1);
%         checkPoints(1) =2;
        % Start the beat counter from where annotator left off
        beatInd = size(scgLabels, 1) + 1;
        
        % Initialize user input
        userIn = '';
        
        % While the user still wants to continue labeling and hasn't
        % finished
        while ~strcmp(userIn, 'q') && beatInd <= size(scgBeats, 1)
            
            % If we reach a checkpoint, the annotator must re-annotate
            % y beats to help us assess intra-annotator agreement
            numReann = 5;
            if ~isempty(find(abs(checkPoints - beatInd) < 0.1, 1))
                for ii = 1:numReann
                    % Select a random index from what has already been
                    % labeled
                    prevInd = randi(beatInd);
                    
                    % Plot the beat
                    plot(scgBeats(prevInd, :))
                    title(['Subject Number ', num2str(subjects(sub_ind)), ...
                        ' Beat Number ', num2str(prevInd)])
                    xlabel(['Sample (Fs = ', fs_str,')'])
                    % AO Interval
                    xline(AObegin, 'color', limits_color, 'LineWidth', limits_lw);
                    xline(AOend, 'color', limits_color, 'LineWidth', limits_lw);
                    % AC Interval
                    xline(ACbegin, 'color', limits_color, 'LineWidth', limits_lw);
                    xline(ACend, 'color', limits_color, 'LineWidth', limits_lw);

                    % Annotate AO interval
                    t = get_ax_locations('ao_interval', 2);
                    AObegin_ann = t(1); AOend_ann = t(2);
                    xline(AObegin_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');
                    xline(AOend_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');

                    % Annotate AO point
                    t = get_ax_locations('ao_point', 1);
                    AOpoint_ann = t(1); 
                    hold on;
                    scatter(round(AOpoint_ann), currentBeat(round(AOpoint_ann)), 'r', 'filled');

                    % Annotate AC interval
                    t = get_ax_locations('ac_interval', 2);
                    ACbegin_ann = t(1); ACend_ann = t(2);
                    xline(ACbegin_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');
                    xline(ACend_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');

                    % Annotate AC point
                    t = get_ax_locations('ac_point', 1);
                    ACpoint_ann = t(1);
                    scatter(round(ACpoint_ann), currentBeat(round(ACpoint_ann)), 'r', 'filled');
                    hold off;

                    
                    % Request a label
                    valid = false;
                    while valid == false
                        % Request user input for label
                        userIn = input('Relabel this beat from 0 - 10: ', 's');
                        valid = check_input(userIn, false);    
                    end
                    %userIn = input('Relabel this beat from 0 - 10: ', 's');
                    
                    % Store the index and the relabeled annotation
                    reann_indices = [reann_indices; prevInd];
                    reann_labels = [reann_labels;...
                        str2double(userIn) AObegin_ann AOend_ann AOpoint_ann ACbegin_ann ACend_ann ACpoint_ann];
                    reann_ao_ann = [reann_ao_ann;[AObegin_ann, AOend_ann AOpoint_ann]];
                    reann_ac_ann = [reann_ac_ann;[ACbegin_ann, ACend_ann ACpoint_ann]]; 
                end
            end
            
            currentBeat = scgBeats(beatInd, :);
            
            % Plot the beat
            plot(currentBeat, 'k')
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel(['Sample (Fs = ', fs_str,')'])
            % AO Interval
            xline(AObegin, 'color', limits_color, 'LineWidth', limits_lw);
            xline(AOend, 'color', limits_color, 'LineWidth', limits_lw);
            % AC Interval
            xline(ACbegin, 'color', limits_color, 'LineWidth', limits_lw);
            xline(ACend, 'color', limits_color, 'LineWidth', limits_lw);

            % Annotate AO interval
            t = get_ax_locations('ao_interval', 2);
            AObegin_ann = t(1); AOend_ann = t(2);
            xline(AObegin_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');
            xline(AOend_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');

            % Annotate AO point
            t = get_ax_locations('ao_point', 1);
            AOpoint_ann = t(1); 
            hold on;
            scatter(round(AOpoint_ann), currentBeat(round(AOpoint_ann)), 'r', 'filled');

            % Annotate AC interval
            t = get_ax_locations('ac_interval', 2);
            ACbegin_ann = t(1); ACend_ann = t(2);
            xline(ACbegin_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');
            xline(ACend_ann, 'Color', limits_annot_color, 'LineWidth', limits_annot_lw, 'linestyle', '--');

            % Annotate AC point
            t = get_ax_locations('ac_point', 1);
            ACpoint_ann = t(1);
            scatter(round(ACpoint_ann), currentBeat(round(ACpoint_ann)), 'r', 'filled');
            hold off;
            
            valid = false;
            while valid == false
                % Request user input for label
                userIn = input(['If you want to quit, enter q; ', ...
                    'otherwise, label the beat from 0 - 10: '], 's');
                valid = check_input(userIn);    
            end
            
            % If the user doesn't want to quit, let's store the label they
            % entered
            if ~strcmp(userIn, 'q')
                scgLabels = [scgLabels; ...
                    str2double(userIn)];
                ao_ann = [ao_ann; [AObegin_ann, AOend_ann, AOpoint_ann]];
                ac_ann = [ac_ann; [ACbegin_ann, ACend_ann, ACpoint_ann]];
            end
            
            % Increment beat index
            beatInd = beatInd + 1;
        end
        
        % Once we reach this portion of the code, we need to save whatever
        % progress has been made
        save([save_path 'S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'], 'scgBeats', 'scgLabels', ...
            'reann_labels', 'reann_indices', 'AObegin', 'AOend', ...
            'ACbegin', 'ACend', 'ao_ann', 'ac_ann', 'reann_ao_ann', 'reann_ac_ann')

        
        % If the user input was to quit ('q'), then we need to stop
        % execution of the code completely
        if strcmp(userIn, 'q')
            return
        end
        
    end
end


function ax_locs = get_ax_locations(type, n_buttons)
    % prompts the user to annotate for ao/ac values also performs input
    % validation checks to make sure valid inputs were selected 
    
    % if you want to change the pressed key you have to find the
    % corresponding ginput_key. For now only supports 'o' and 'c' presses
    if strcmp(type, 'ao_interval')
        ax_msg = "Annotate AO interval: press 'o' once at the start and once at the end, then press 'Enter' ";
        ginput_key = 111; % this is the value matlab would see if 'o' was pressed during ginput
    elseif strcmp(type,'ac_interval')
        ax_msg = "Annotate AC interval: press 'c' once at the start and once at the end, then press 'Enter' ";
        ginput_key = 99;
    elseif strcmp(type,'ao_point')
        ax_msg = "Annotate AO point: press 'o' at the point, then press 'Enter' ";
        ginput_key = 111;
    elseif strcmp(type,'ac_point')
        ax_msg = "Annotate AC point: press 'c' at the point, then press 'Enter' ";
        ginput_key = 99;
    end
    
    locs = [];
    buttons = [];
    valid = false;
    
    % loops until the correct keystroke sequence was pressed 
    while valid == false
        disp(ax_msg)
        [x, ~, button] = ginput;
        [valid, err_msg] = check_button(button, n_buttons, x, ginput_key);
        if ~strcmp(err_msg, '')
            disp(err_msg);
        end
    end
    
    % parse to get locations of mouse location when key was pressed
    locs = [locs x'];                          
    buttons = [buttons button'];                
    key_presses = find(buttons == ginput_key);     
    ax_locs = sort(locs(key_presses));
    

end

function [valid, err_msg] = check_button(buttons, n_buttons, locations, key)
    % confirm that the number of buttons pressed matches n_buttons and 
    % the key value of that button all match key
    % TODO: still should check if locations are valid...
    valid = true; 
    err_msg = '';
    % check the correct number of buttons were pressed
    if length(buttons) ~= n_buttons
       valid = false; 
       err_msg = [num2str(length(buttons)), ' buttons pressed expected ', num2str(n_buttons), '. Please reinput'];
    
   % check the correct buttons were pressed
    elseif ~isempty(buttons(buttons ~= key))
        valid = false;
        if key == 111
            key_press = 'o';
        elseif key == 99
            key_press = 'c';
        else
            key_press = num2str(key);
        end
        err_msg = ['Expected only ', key_press, ' inputs', '. Please reinput'];
    end

end

function valid = check_input(userIn, check_quit)
    % check that userIn is a string from '0' to '10'
    % or userIn = 'q' indicating that we want to stop annotating for now (if we are not reannotating)
    
    if nargin < 2
        % if reannotating quitting is not an option
        check_quit = true;
    end
    
    % range of valid scores 
    valid_scores = 0:10;
    
    % check if user wants to quit (if applicable)
    if strcmp(userIn, 'q') & (check_quit == true) 
        valid = true;
    % checks that a valid score string was inputted
    elseif sum(valid_scores == str2double(userIn)) == 1
        valid = true;
    % invalid input display error to user
    else
        valid = false;
        add_input_options = '';
        if check_quit == true
            add_input_option = ' or input = q';
        end
        err_msg = ['Received: ' userIn, ' Expected input = a integer from 0-10', add_input_option];
        disp(err_msg)
    end

    
end

function scgBeats = create_matrix(struct_var)
    % confirm beats is in the structure
    assert(isfield(struct_var, 'beats'), 'beats must be in the struct')

    % 
    if iscell(struct_var.beats)
        max_length = max(cellfun(@(x) length(x),struct_var.beats));
        n_beats = length(struct_var.beats);
        scgBeats = zeros(n_beats, max_length);
        for i = 1:n_beats
            nan_vec = ones(1, max_length - length(struct_var.beats{i}) ) * 0;
            scgBeats(i, :) = [struct_var.beats{i}, nan_vec];
        end
    elseif ismatrix(struct_var.beats)
        scgBeats = struct_var.beats;
    end

end