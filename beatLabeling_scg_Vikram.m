% Script for manual annotation of assigned SCG beats

clear
close all;

% Annotator name
annotator = 'David';

% Subject numbers assigned
subjects = [122, 123, 133];


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
    
    %% Load the SCG beats
    load(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '.mat']);

    %% Show the user a visualization of beats
    % Create a black and white plot of the SCG beats stacked
    imagesc(scgBeats)
    map = contrast(scgBeats);
    colormap(map);
    xlabel('Sample (Fs = 2 kHz)')
    ylabel('Beat Index')
    colorbar
    
    %% Check to see if progress was saved for this subject
    % Progress is saved by saving a new .mat file with labels so far
    % upon execution completion. Hence, if such a file exists, that implies
    % that we should start from where the annotator left off
    if isfile(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'])
        % This implies that either the annotator is complete, or has
        % finished some but has a portion left.
        load(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'])
        
        % Have the user press enter to continue
        input(['You have already selected intervals of interest. ', ...
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
        numWarm = 1;
        
        for trial = 1:numWarm
            % Select a random beat from this subject's data
            beatInd = randi(size(scgBeats, 1));
            
            % Plot the beat
            plot(scgBeats(beatInd, :))
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel('Sample (Fs = 2 kHz)')
            % AO Interval
            xline(AObegin, 'b--');
            xline(AOend, 'b--');
            % AC Interval
            xline(ACbegin, 'r--');
            xline(ACend, 'r--');
            
            % Have the user press enter to continue
            input(['Warm-up beat ', num2str(trial), ...
                '. Press enter to continue ']);
        end
        
        %% Start labeling process
        
        % Checkpoints to have annotator label some previous beats to
        % assess intra-annotator agreement
        checkPoints = round(size(scgBeats, 1)/10):...
            round(size(scgBeats, 1)/10):size(scgBeats, 1);
        checkPoints(1) =2;
        % Start the beat counter from where annotator left off
        beatInd = size(scgLabels, 1) + 1;
        
        % Initialize user input
        userIn = '';
        
        % While the user still wants to continue labeling and hasn't
        % finished
        while ~strcmp(userIn, 'q') && beatInd <= size(scgBeats, 1)
            
            % If we reach a checkpoint, the annotator must re-annotate
            % y beats to help us assess intra-annotator agreement
            numReann = 1; %5;
            if ~isempty(find(abs(checkPoints - beatInd) < 0.1, 1))
                for ii = 1:numReann
                    % Select a random index from what has already been
                    % labeled
                    prevInd = randi(beatInd);
                    
                    % Plot the beat
                    plot(scgBeats(prevInd, :))
                    title(['Subject Number ', num2str(subjects(sub_ind)), ...
                        ' Beat Number ', num2str(prevInd)])
                    xlabel('Sample (Fs = 2 kHz)')
                    % AO Interval
                    xline(AObegin, 'b--');
                    xline(AOend, 'b--');
                    % AC Interval
                    xline(ACbegin, 'r--');
                    xline(ACend, 'r--');
             
                    % Annotate AO
                    t = get_ax_locations('ao');
                    AObegin_ann = t(1); AOend_ann = t(2);
                    xline(AObegin_ann, 'b', 'LineWidth', 2.0);
                    xline(AOend_ann, 'b', 'LineWidth', 2.0);

                    % Annotate AC
                    t = get_ax_locations('ac');
                    ACbegin_ann = t(1); ACend_ann = t(2);
                    xline(ACbegin_ann, 'r', 'LineWidth', 2.0);
                    xline(ACend_ann, 'r', 'LineWidth', 2.0);
                    
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
                        str2double(userIn) AObegin_ann AOend_ann ACbegin_ann ACend_ann];
                    reann_ao_ann = [reann_ao_ann;[AObegin_ann, AOend_ann]];
                    reann_ac_ann = [reann_ac_ann;[ACbegin_ann, ACend_ann]]; 
                end
            end
            
            currentBeat = scgBeats(beatInd, :);
            
            % Plot the beat
            plot(currentBeat)
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel('Sample (Fs = 2 kHz)')
            % AO Interval
            xline(AObegin, 'b--');
            xline(AOend, 'b--');
            % AC Interval
            xline(ACbegin, 'r--');
            xline(ACend, 'r--');

            % Annotate AO
            t = get_ax_locations('ao');
            AObegin_ann = t(1); AOend_ann = t(2);
            xline(AObegin_ann, 'b', 'LineWidth', 2.0);
            xline(AOend_ann, 'b', 'LineWidth', 2.0);

            % Annotate AC
            t = get_ax_locations('ac');
            ACbegin_ann = t(1); ACend_ann = t(2);
            xline(ACbegin_ann, 'r', 'LineWidth', 2.0);
            xline(ACend_ann, 'r', 'LineWidth', 2.0);
            
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
                ao_ann = [ao_ann; [AObegin_ann, AOend_ann]];
                ac_ann = [ac_ann; [ACbegin_ann, ACend_ann]];
            end
            
            % Increment beat index
            beatInd = beatInd + 1;
        end
        
        % Once we reach this portion of the code, we need to save whatever
        % progress has been made
        save(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
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


function ax_locs = get_ax_locations(type)
    % prompts the user to annotate for ao/ac values also performs input
    % validation checks to make sure valid inputs were selected 
    
    % if you want to change the pressed key you have to find the
    % corresponding ginput_key. For now only supports 'o' and 'c' presses
    if strcmp(type, 'ao')
        ax_msg = "Annotate AO interval: press 'o' once at the start and once at the end, then press 'Enter' ";
        ginput_key = 111; % this is the value matlab would see if 'o' was pressed during ginput
    elseif strcmp(type,'ac')
        ax_msg = "Annotate AC interval: press 'c' once at the start and once at the end, then press 'Enter' ";
        ginput_key = 99;
    end
    
    locs = [];
    buttons = [];
    valid = false;
    n_buttons = 2;
    
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