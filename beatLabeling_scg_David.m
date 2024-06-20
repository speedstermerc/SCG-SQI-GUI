% Script for manual annotation of assigned SCG beats

clear

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
        
        % We only need to continue onwards if the annotator has a portion left
        if size(scgLabels, 1) < size(scgBeats, 1)
            %% Show the user a visualization of beats for reminder
            % Create a black and white plot of the SCG beats stacked
            imagesc(scgBeats)
            map = contrast(scgBeats);
            colormap(map);
            xlabel('Sample (Fs = 2 kHz)')
            ylabel('Beat Index')
            colorbar
            
            % Have the user press enter to continue
            input(['You have already selected intervals of interest. ', ...
                'Enter any key to continue. ']);
            
            %% Plot some warm up beats to remind user of subject
            % Randomly select x beats from the dataset and have them enter
            % through them to make sure they understand what this subject's
            % data looks like in general
            numWarm = 30;
            
            for trial = 1:numWarm
                % Select a random beat from this subject's data
                beatInd = randi(size(scgBeats, 1));
                
                % Plot the beat
                plot(scgBeats(beatInd, :))
                title(['Subject Number ', num2str(subjects(sub_ind)), ...
                    ' Beat Number ', num2str(beatInd)])
                xlabel('Sample (Fs = 2 kHz)')
                % AO Interval
                xline(AObegin, 'b');
                xline(AOend, 'b');
                % AC Interval
                xline(ACbegin, 'r');
                xline(ACend, 'r');
                
                % Have the user press enter to continue
                input(['Warm-up beat ', num2str(trial), ...
                    '. Press enter to continue ']);
            end
            
            %% Start labeling process
            
            % Checkpoints to have annotator label some previous beats to
            % assess intra-annotator agreement
            checkPoints = round(size(scgBeats, 1)/10):...
                round(size(scgBeats, 1)/10):size(scgBeats, 1);
            
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
                        xlabel('Sample (Fs = 2 kHz)')
                        % AO Interval
                        xline(AObegin, 'b');
                        xline(AOend, 'b');
                        % AC Interval
                        xline(ACbegin, 'r');
                        xline(ACend, 'r');
                        % Request a label
                        userIn = input('Relabel this beat from 0 - 10: ', 's');
                        
                        % Store the index and the relabeled annotation
                        reann_indices = [reann_indices; prevInd];
                        reann_labels = [reann_labels; str2double(userIn)];
                    end
                end
                
                
                % Plot the beat
                plot(scgBeats(beatInd, :))
                title(['Subject Number ', num2str(subjects(sub_ind)), ...
                    ' Beat Number ', num2str(beatInd)])
                xlabel('Sample (Fs = 2 kHz)')
                % AO Interval
                xline(AObegin, 'b');
                xline(AOend, 'b');
                % AC Interval
                xline(ACbegin, 'r');
                xline(ACend, 'r');
                
                % Request user input for label
                userIn = input(['If you want to quit, enter q; ', ...
                    'otherwise, label the beat from 0 - 10: '], 's');
                
                % If the user doesn't want to quit, let's store the label they
                % entered
                if ~strcmp(userIn, 'q')
                    scgLabels = [scgLabels; str2double(userIn)];
                end
                
                % Increment beat index
                beatInd = beatInd + 1;
            end
            
            % Once we reach this portion of the code, we need to save whatever
            % progress has been made
            save(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
                '_labeled.mat'], 'scgBeats', 'scgLabels', ...
                'reann_labels', 'reann_indices', 'AObegin', 'AOend', ...
                'ACbegin', 'ACend')
            
            % If the user input was to quit ('q'), then we need to stop
            % execution of the code completely
            if strcmp(userIn, 'q')
                return
            end
            
        end
    else
        % The annotator is starting from scratch with this subject
        load(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '.mat'])
        
        %% Show the user a visualization of beats
        % Create a black and white plot of the SCG beats stacked
        imagesc(scgBeats)
        map = contrast(scgBeats);
        colormap(map);
        xlabel('Sample (Fs = 2 kHz)')
        ylabel('Beat Index')
        colorbar
        
        % Have the user choose interval of interest
        AObegin = input('Enter the start sample of your AO interval of interest: ');
        AOend = input('Enter the end sample of your AO interval of interest: ');
        ACbegin = input('Enter the start sample of your AC interval of interest: ');
        ACend = input('Enter the end sample of your AC interval of interest: ');
        
        %% Plot some warm up beats to get user familiar
        % Randomly select x beats from the dataset and have them enter
        % through them to make sure they understand what this subject's
        % data looks like in general
        numWarm = 30;
        
        for trial = 1:numWarm
            % Select a random beat from this subject's data
            beatInd = randi(size(scgBeats, 1));
            
            % Plot the beat
            plot(scgBeats(beatInd, :))
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel('Sample (Fs = 2 kHz)')
            % AO Interval
            xline(AObegin, 'b');
            xline(AOend, 'b');
            % AC Interval
            xline(ACbegin, 'r');
            xline(ACend, 'r');
            
            % Request user input for label
            input(['Warm-up beat ', num2str(trial), ...
                '. Press enter to continue ']);
        end
        
        
        %% Start labeling process
        
        % Checkpoints to have annotator label some previous beats to
        % assess intra-annotator agreement
        checkPoints = round(size(scgBeats, 1)/10):...
            round(size(scgBeats, 1)/10):size(scgBeats, 1);
        
        % Initialize scgLabels array
        scgLabels = [];
        
        % Initialize reannotation arrays
        reann_labels = [];
        reann_indices = [];
        
        % Initialize user input and beat index
        beatInd = 1;
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
                    xlabel('Sample (Fs = 2 kHz)')
                    % AO Interval
                    xline(AObegin, 'b');
                    xline(AOend, 'b');
                    % AC Interval
                    xline(ACbegin, 'r');
                    xline(ACend, 'r');
                    
                    % Request a label
                    userIn = input('Relabel this beat from 0 - 10: ', 's');
                    
                    % Store the index and the relabeled annotation
                    reann_indices = [reann_indices; prevInd];
                    reann_labels = [reann_labels; str2double(userIn)];
                end
            end
            
            
            % Plot the beat
            plot(scgBeats(beatInd, :))
            title(['Subject Number ', num2str(subjects(sub_ind)), ...
                ' Beat Number ', num2str(beatInd)])
            xlabel('Sample (Fs = 2 kHz)')
            % AO Interval
            xline(AObegin, 'b');
            xline(AOend, 'b');
            % AC Interval
            xline(ACbegin, 'r');
            xline(ACend, 'r');
            
            % Request user input for label
            userIn = input(['If you want to quit, enter q; ', ...
                'otherwise, label the beat from 0 - 10: '], 's');
            
            % If the user doesn't want to quit, let's store the label they
            % entered
            if ~strcmp(userIn, 'q')
                scgLabels = [scgLabels; str2double(userIn)];
            end
            
            % Increment beat index
            beatInd = beatInd + 1;
        end
        
        % Once we reach this portion of the code, we need to save whatever
        % progress has been made
        save(['S', num2str(subjects(sub_ind)), '_scg_', annotator, ...
            '_labeled.mat'], 'scgBeats', 'scgLabels', ...
                'reann_labels', 'reann_indices', 'AObegin', 'AOend', ...
                'ACbegin', 'ACend')
        
        % If the user input was to quit ('q'), then we need to stop
        % execution of the code completely
        if strcmp(userIn, 'q')
            return
        end
    end
end