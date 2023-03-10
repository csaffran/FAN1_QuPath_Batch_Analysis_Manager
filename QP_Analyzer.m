% QP_Analyzer
%
% This script calculates karyomegaly in cells per mm^2 and % of cells detected,
% and generates histograms. Running the script will open a dialogue that
% will permit the user to either select the data settings used in the study
% for which the script was authored (Choices 1 - 3), or to enter their own
% parameters (Choice 4).
%
% The required input are QuPath cell detection exports and the corresponding
% annotation exports (all as .txt docs), and these should be in the folder from
% where QuPath_Analyzer is launched.
%
% For example, let’s say you’re analyzing karyomegaly in the renal cortex and
% renal medulla of six mice, 3 WT controls, and 3 test anmials. You import six
% slide scans into a QuPath project, then select annotation regions
% corresponding to your tissues of interest (let’s say you name them “Cortex”
% and “Medulla”) and run cell detection (Analyze > Cell detection > Cell
% detection) for each sample. You will then need to export the annotations
% (Measure > Show annotation measurements > Save) because these contains the
% areas of the annotation regions, and the cell detections (Measure > Show
% detection measurements > Save) because these contain all the data from each
% cell in each annotation. You will end up with six short annotation files and
% six long detection files. Let’s say you name them as follows:
%
% Kidney_annotation_1.txt
% Kidney_annotation_2.txt
% Kidney_annotation_3.txt
% Kidney_annotation_4.txt
% Kidney_annotation_5.txt
% Kidney_annotation_6.txt
% Kidney_1.txt
% Kidney_2.txt
% Kidney_3.txt
% Kidney_4.txt
% Kidney_5.txt
% Kidney_6.txt
%
% The annotation files will contain a header, plus one line for every
% annotation (in this case, two lines). The detection files will contain a
% header plus one line for every cell (may be hundreds of thousands of lines).
%
% Move these files into the folder containing QuPath_Analyzer. Run
% QuPath_Analyzer and when prompted to select tissue enter “4” for User Input.
%
% When prompted, you would enter “Kidney_annotation” as the prefix for the
% annotation files, then “Cortex” for the first tissue, and enter “Kidney” for
% the prefix for the cell detection files. When asked whether you want to enter
% another tissue, you would enter “1” for YES, then “Medulla” for the next
% tissue, and “Kidney” again for the prefix for the cell detection files.
% You’re asked to enter the cell detection prefix this for each tissue in the
% event you’ve exported the cell detection files one tissue at a time to keet
% the file sizes manageable. But here, we’ve done both tissues together, so the
% column labeled Parent will indicate which tissue annotation each cell belongs
% to (in this case Cortex or Medulla), so the prefix is the same for all
% tissues. Finally, when asked if you want to enter another tissue you enter
% “2” for NO.
%
% Next you’ll be asked for the karyomegaly threshold you want to use. If you
% don’t know, just hit Enter, and you’ll be asked how many of your samples are
% WT controls. In this case, you would enter 3. Then QuPath_Analyzer will use
% the first three samples from each tissue to calculate a threshold that is 2
% SD above the mean.
%
% Once the threshold is established (either by you entering it, or it being
% calculated from the controls), QuPath_Analyzer will analyze your cell data
% and  calculate karyomegalic cells per mm^2 and percent karyomegalic cells.
%
% The summary data will be displayed on the screen as a table, and exported
% in an excel spreadsheet in the folder from where QuPath_Analyzer is launched.
% Histograms (if selected) will be generated and exported as PDFs to the same
% folder.
%
% The pertinent data is also saved as a .mat file with a unique file name
% based on the date and time, and as a default file called last_run.mat, so
% the data from the most recent run can always be readily retrieved.


% Housekeeping
clear
clc
query_tissue='Select tissue';
options_tissue={'Renal Cortex','Renal Medulla','Liver','User Input'};
response_tissue=ask(query_tissue,options_tissue);
query_type='Select run type';
options_type={'Histograms','Calculations','Histograms AND Calculations'};
response_type=ask(query_type,options_type);
skip_ask_type=0;
do_histos=0; 
num_samples=15;
auto_find_thresholds=0;
doc_type='.txt';
preset_histogram_ranges=1;
xhi=100;
yhi=[];
num_WT=3;
separate_tissues=0;

% User defined values
threshold=40;
switch response_tissue
    case{1}
        annotations_prefix='Kidney_Annotations';
        output_name='Cortex_R2_S';
        sample_prefix={'Cortex_R2_S'};
        tissues={'Cortex'};
        QPA_Annotation_Table=qpa_annotation_import(tissues,num_samples,annotations_prefix,...
            doc_type,sample_prefix);
        threshold=45.4; % for Cortex
        upper_bound=60000;
        yhi=3000;
    case{2}
        annotations_prefix='Kidney_Annotations'; 
        output_name='Medulla_R2_S';
        sample_prefix={'Medulla_R2_S'};
        tissues={'Medulla'};
        QPA_Annotation_Table=qpa_annotation_import(tissues,num_samples,annotations_prefix,...
            doc_type,sample_prefix);
        threshold=45.6; % for Cortex
        upper_bound=30000;
        yhi=1800;
    case{3}
        annotations_prefix='Liver_Annotations';
        output_name='Liver_R1_S';
        sample_prefix={'Liver_R1_S'};
        tissues={'Liver'};
        QPA_Annotation_Table=qpa_annotation_import(tissues,num_samples,annotations_prefix,...
            doc_type,sample_prefix);
        threshold=59;
        yhi=18000;
        upper_bound=160000;
    case{4}
        fprintf('\n\nHere you will be directed to enter information about the files you exported from Qupath.\nPut free text answers inside single quotes ''like this.''\n\n');
        annotations_prefix=ask('Enter the name prefix for the annotation files you exported from QuPath:');
        w=1;
        counter=1;
        tissue_ordinal='first';
        while w==1
            if counter>1
                tissue_ordinal='next';
            end
            this_tissue=ask(sprintf('Enter the name of the %s tissue (it should correspond to the annotation you selected in QuPath):',tissue_ordinal));
            tissues(counter)={this_tissue};
            this_sample_prefix=ask(sprintf('Enter %s the prefix for the sequential cell detection files you exported from QuPath\ncorresponding to this tissue/annotation. It MUST include the tissue/annotation in the name:',...
                tissue_ordinal));
            sample_prefix(counter)={this_sample_prefix}; %formerly csv_name_prefix
            w=ask('Would you like to enter another tissue?',{'YES','NO'});
            counter=counter+1;
        end
        output_name=ask('Enter the name prefix you want for your export files:');
        threshold=ask('Enter the karyomegaly threshold you want to use (or just hit enter and it will be calculated automatically):');
        if isempty(threshold)
            num_WT=ask('How many WT control samples are there (they must be the first samples):');
            auto_find_thresholds=1;
        end
        QPA_Annotation_Table=qpa_annotation_import(tissues,num_samples,annotations_prefix,...
            doc_type,sample_prefix);
        if counter>2
            separate_tissues=1;
        end
        upper_bound=[];
        yhi=[];
end

switch response_type
    case{1}
        do_histos=1;
        do_scramble=1;
    case{2}
        do_scramble=0;
        do_histos=0;
        upper_bound=[];
    case{3}
        do_histos=1;
        do_scramble=1;
        upper_bound=[];
        yhi=[];
end


% User settings
circ_threshold=0.89;
force_threshold=0; % if loading a previouos run, force_threshold will only affect the histograms, not the data
load_run=0;
num_z=2;
f_thresh=threshold;
show_mean=1;
show_median=1;
show_threshold=1;
num_bins=128;
combine_thresholds=1;

% Housekeeping 
variable_names={'Slide','Total_Cells','Calculated_Karyomegalic','Percent_Karyomegalic',...
    'Kcells_per_mm','Annotation_Area','Mean_Nuc_Area',...
    'Median_Nuc_Area','Mode_Nuc_Area','Std_Dev','Threshold','Z_score'};
w=1;
i=1;
j=1;
l=1;
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
if isempty(output_name)
    output_name='QPD_run';
end
hist_name{1}=strrep(sample_prefix{1},'_',' ');
dateindex=sprintf('%s',datetime);
dateindex=strrep(dateindex,':','');
edges=(0:num_bins)*xhi/num_bins;
[num_annotations,~]=size(QPA_Annotation_Table);

if isnumeric(load_run)&&load_run(1)==1
    
    % Updating user
    fprintf('\n\nLoading data from last run..');
    
    % load last run
    load('last_saved');
    if ~isempty(force_threshold)&&isnumeric(force_threshold)&&force_threshold(1)==1
        threshold=f_thresh;
    end
    
elseif ischar(load_run)&&~isempty(load_run)
    
    % Updating user
    fprintf('\n\nLoadding %s..',load_run);
    
    % load user requested run
    load(load_run);
    if ~isempty(force_threshold)&&isnumeric(force_threshold)&&force_threshold(1)==1
        threshold=f_thresh;
    end
else
    
    if auto_find_thresholds==1
        % Housekeeping 
        threshold_array=[];
        thresholds(length(sample_prefix))=0;
        J=1;
        threshold_grammar='Threshold is';
        clear import_table this_array thresholds

        for ww=1:length(sample_prefix)
        % Updating user
            fprintf('\n\nCalculating threshold for %s..',sample_prefix{ww});
            for I=1:num_WT
            
                % Import data
                if ww<=length(sample_prefix)
                    csv_name=sprintf('%s%s%s',sample_prefix{ww},num2str(I),doc_type);
                end
                import_table=readtable(csv_name);
                this_array=table2array(import_table(:,8));
                threshold_array=[threshold_array;this_array];
                
                % Generate threshold
                if combine_thresholds==1
                    if J==num_WT*length(sample_prefix)
                        m=mean(threshold_array);
                        z=std(threshold_array);
                        thresholds=m+(num_z*z);
                    end
                    J=J+1;
                else
                    if I==num_WT
                        m=mean(threshold_array);
                        z=std(threshold_array);
                        thresholds(ww)=m+(num_z*z);
                        if length(sample_prefix)>1
                            threshold_grammar='Thresholds are';
                        end
                    end
                    clear import_table this_array
                end
                
                % Updating user
                fprintf('.');
            end
        end
        
        % Updating user
        fprintf('\n\nDone!\n\n%s:',threshold_grammar);
        if combine_thresholds==1
            fprintf('\n\t%s:\t%0.4g',output_name,thresholds);
        else
            for I=1:length(sample_prefix)
                fprintf('\n\t%s:\t%0.4g',sample_prefix{I},thresholds(I));
            end
        end
        fprintf('\n\n');
    end
    
    % Updating user
    fprintf('\n\nImporting and processssing data..');
    
    while w<=length(sample_prefix)

        % Housekeeping
        clear import_table karyo_array karyomegalic_cells infiltrate_cell...
            infiltrate_array
        if auto_find_thresholds==1
            try
                threshold=thresholds(w);
            catch
                threshold=thresholds(1);
            end
        end

        % Updating user
        dots;

        % Import table
        if w<=length(sample_prefix)
            hist_name{w}=strrep(sample_prefix{w},'_',' ');
            csv_name=sprintf('%s%s%s',sample_prefix{w},num2str(i),doc_type);
        end
        
        try
            import_table=readtable(csv_name);
        catch
            if w>length(sample_prefix)
                break
            else
                w=w+1;
                i=1;
            end
        end

        % KARYOMEGALY
        if do_scramble==1
            import_table=scramble(import_table(:,[3,8,10]));
        end
        s=size(import_table);
        total_num_cells=s(1);
        karyo_array=[import_table.Nucleus_Area,import_table.Nucleus_Circularity];
        m=mean(karyo_array(:,1));
        d=median(karyo_array(:,1));
        o=mode(karyo_array(:,1));
        z=std(karyo_array(:,1));
        if isempty(threshold)
            threshold=m+(num_z*z);
        else
            num_z=(threshold-m)/z;
        end
        if ~isempty(force_threshold)&&isnumeric(force_threshold)&&force_threshold(1)==1
            threshold=f_thresh;
        end
        karyo_array(karyo_array(:,1)<threshold,:)=[];
        karyo_array(karyo_array(:,2)<circ_threshold,:)=[];
        karyomegalic_cells=karyo_array(:,1);
        [num_karyomegalic_cells,~]=size(karyomegalic_cells);
        percent_karyomegalic_cells=100*num_karyomegalic_cells/total_num_cells;
        this_area=QPA_Annotation_Table.Area(i);
        Kcells_per_mm=num_karyomegalic_cells/this_area*1000000;
        if ~isempty(upper_bound)&&s(1)>=upper_bound(w)
            import_table=import_table(1:upper_bound(w),:);
        end
        [num_cells,~]=size(import_table);
        if w==1
            karyo_array(num_cells,2)=0;
        elseif num_cells>length(karyo_array)
            karyo_array(num_cells,2)=0;
        end
        
        num_cells_list(i)=num_cells;
        clear karyo_array
        karyo_array=import_table.Nucleus_Area;
        class_array(num_cells,2)=0;
        for k=1:num_cells
            if ~isempty(upper_bound)&&k>=upper_bound(w)
                continue
            end
            hist_cell{w,i}(k,1)=karyo_array(k,1);
        end
        num_karyomegalic_class=sum(class_array(:,2));
        
        % Building cell array of data of interest
        C(j,:)={csv_name(1:end-4),num_cells,num_karyomegalic_cells,percent_karyomegalic_cells,...
            Kcells_per_mm, this_area,m,...
            d,o,z,threshold,num_z,};

        % Iterator
        i=i+1;
        j=j+1;
        l=l+1;
        if i==num_samples+1
            i=1;
            w=w+1;
        end
        
        if w==3
            break
        end
    end
    
    % Updating user
    fprintf('\n\nCOMPLETE!\n\nSaving results...');

    % Saving results
    dots;dots;
    save(output_name,'C','threshold','hist_cell','output_name','hist_name');
    save([output_name,' ',dateindex],'C','threshold','hist_cell','output_name','hist_name');
end

% Updating user
fprintf('\n\nCOMPLETE!\n\nGenerating tables...');
    
% Generate Table
T=cell2table(C);dots;
T.Properties.VariableNames=variable_names;dots;ds;
disp(T);

% Last run save
save('last_saved','C','T','threshold','hist_cell','output_name',...
        'hist_name');   % Data from the last run is automatically saved so the
                        % user can use the command load('last_saved.mat')
                        % to automatically retrieve that data.

% Export Descriptive Data
exportspreadsheet(T,output_name,1);
warning('ON', 'MATLAB:table:ModifiedAndSavedVarnames');

if do_histos==1
    
    % Generating Histograms
    [l,~]=size(hist_cell);
    [~,n]=size(hist_cell);
    YHI=[];
    emergency_cutoff=1;
    histo_retry_list{l}=[];
    for i=1:l(1)
        c=1;
        if ~isempty(yhi)
            YHI=yhi(i);
        end
        for j=1:n
            [hist_title,hist_output]=qpa_histo_plot(j,i,hist_cell,threshold,edges,xhi,YHI,show_mean,...
                show_median,show_threshold,hist_name,dateindex);  % This function 
                                                % plots the histogram. I made it 
                                                % a function because it gets repeated 
                                                % in the following try-catch block.
            try
                saveas(gcf,[hist_output,'.pdf']); % May throw an error if there are too many windows open
                fig_list(j)=gcf;
            catch
                fprintf('\n\nMATLAB threw an error processing the following histogram: %s\n\n',...
                    hist_title);
                fprintf('This was likely because there were too many open figure windows, which makes MATLAB unhappy.\n\n');
                fprintf('Closing the open figures now.\n\n');
                close all
                fprintf('Don''t worry, all %d of your figures are still exported as PDFs!\n\n',num_annotations);
                qpa_histo_plot(j,i,hist_cell,threshold,edges,xhi,YHI,show_mean,...
                    show_median,show_threshold,hist_name,dateindex);
                saveas(gcf,[hist_output,'.pdf']);
                fig_list(j)=gcf;
            end
            hold off
        end        
    end
end


% Function Definitions-----------------------------------------------------

function QPA_Annotation_Table=qpa_annotation_import(tissues,num_samples,...
    annotations_prefix,doc_type,sample_prefix)

% qpa_annotation_import imports annotation files from QuPath and assembles
% the salient data into a table.

% Housekeeping
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
num_tissues=length(tissues);
sample_counter=1;

for tn=1:num_tissues
    for sn=1:num_samples
        annotation_counter=1;
        qpl_name=sprintf('%s_%s%s',annotations_prefix,...
            num2str(sn),doc_type); % Name of current annotation to be imported
        this_qpl_import=readtable(qpl_name);
        [num_annotations,~]=size(this_qpl_import);
        for an=1:num_annotations
            if contains(lower(sample_prefix{tn}),lower(this_qpl_import.Name{an}))
                this_sample={sprintf('%s%s',sample_prefix{tn},num2str(sn))};
                QPA_Annotation_Cell(sample_counter,:)={this_sample,tissues{tn},...
                    this_qpl_import.Area_m_2(tn)};
                sample_counter=sample_counter+1;
                break
            end
        end
    end    
end

% Generate output
QPA_Annotation_Table=cell2table(QPA_Annotation_Cell);
QPA_Annotation_Table.Properties.VariableNames={'Sample_name','Tissue','Area'};
save('Last_Annotation.mat','QPA_Annotation_Table');
warning('ON', 'MATLAB:table:ModifiedAndSavedVarnames');
end


function RESPONSE=ask(STEM,OPTION,ASSIGN)

% ASK is a user-input generating interface.
%
% RESPONSE=ask(STEM,OPTION,ASSIGN) asks the user the question STEM and returns the
% user-entered value, RESPONSE. If OPTION is a cell populated with strings
% ask will list them in multiple choice form. If OPTION=[] or is not
% entered ask defaults to short-answer form (i.e., RESPONSE = whatever the
% user keys in).
%
% For multiple choice questions RESPONSE will evaluate to the numeric
% (scalar or array) answer the user enters, unless ASSIGN = 1, in which
% case RESPONSE will evaluate to the corresponding element(s) in OPTION as 
% either a char array (when RESPONSE is scalar) or a cell array (when
% RESPONSE is a vector).
%
% If the function is called without input, it will default to asking the
% user to enter a value.

if nargin==0||isempty(STEM)
    STEM='Enter value:';
end

% Housekeeping
multic=sprintf('\n%s\n\n',STEM);
w=1;

% Short-answer form (where "option" isn't used)

try
    if nargin==1
        % Asking the short-answer question
        shortans=sprintf('\n%s ',STEM);
        RESPONSE=input(shortans);
        return
    else

        % Going through "option" to make the multiple choices
        n=numel(OPTION);
        for i=1:n
            add_option='%s(%d)  %s\n\n';
            if i==n
                add_option='%s(%d)  %s\n'; % This allows the actual query to lead with a \n.
            end
            multic=sprintf(add_option,multic,i,OPTION{i});
        end

        % Asking the multiple-choice question
        fprintf(multic);

        while w==1

            % Soliciting user input

            RESPONSE=input('\nPlease enter the number corresponding to your answer: ');
            if max(RESPONSE)<=n&&isnumeric(RESPONSE)

                w=2;

            end

            if nargin==3&&ASSIGN==1
                if numel(RESPONSE)==1
                    response=OPTION{RESPONSE};
                else
                    response(:)=OPTION(RESPONSE);
                end
                RESPONSE=response;
            end
            
        end
    end
catch
    return
end

end

function dots(num_dots)
if nargin<1||~isnumeric
    fprintf('.');
else
    for i=1:num_dots(1)
        fprintf('.');
    end
end
end

function ds
fprintf('\n\n');
end

function NEWNAME=fixname(OLDNAME,PERIODS)

% FIXNAME fixes purtative file names that contain spaces, dashes,  
% ampersands, etc. and replaces them with an underscore so they can be used 
% as matlab file or variable names. A second argument can be used to deal 
% with periods. For aesthetics, when multiple underscore-generating
% features are replaced by a single underscore.
% 
% NEWNAME=fixname(OLDNAME) replaces the inappropriate characters in OLDNAME
% (except periods) with an underscore (& becomes "and", and % becomes
% "percent").
%
% NEWNAME=fixname(OLDNAME,PERIODS) also replaces the same inappropriate
% characters in OLDNAME as before, and deak with periods as follows

% Housekeeping
NEW={' ','-','@','#','&','''','!','^','*','(',')','%'};
NEWNAME=OLDNAME;

% Stepping through NEW and making replacements
for i=1:12
    
    if i==5
        NEWNAME = strrep(NEWNAME,NEW{i},'and'); % Special case of & --> 'and'
        n=length(NEWNAME);
    elseif i==12
        NEWNAME = strrep(NEWNAME,NEW{i},'_percent'); % Special case of % --> 'percent'
        n=length(NEWNAME);
        continue
    end
    
    NEWNAME = strrep(NEWNAME,NEW{i},'_');
    
end


if nargin==2
    switch PERIODS
        case {2,3} % 2 --> remove the suffix, 3 --> remove all periods but the suffix
            for i=n:-1:1 % Stepping backwards throughIN OUT until a period is found
                if NEWNAME(i)=='.'&&i>1 % Identifying the period associated withthe suffix
                n=i-1; % redefining n as the length of OUT before the suffix period
                    if PERIODS==2
                        NEWNAME=NEWNAME(1:n); % Removing the suffix
                    end
                    break
                end
            end     
    end
    out = strrep(NEWNAME(1:n),'.','_'); % Replacing the periods up to the suffix (if it's still there)
    NEWNAME(1:n)=out; % Note that if PERIOD = 2, out and OUT are both length n
end

for i=1:100
    NEWNAME = strrep(NEWNAME,'__','_'); % Getting rid of multiple underscores
end
end

function scrambled_array=scramble(ordered_array,add_layers,this_axis)

% DISORD=SCRAMBLE(ORD,I,A) takes some n-by-m ordered array ORD, and rearranges the
% values along the longest axis. If I=1, then additional layers of randomness will
% be added by cycling the rng eenine 1 to 60 times (depending on the time)
% before generating output. If A is enteerd, the ORD will be acrambled along 
% axis A.


% Housekeeping
s=size(ordered_array);
do_layers=1;
% Analyze input
if nargin<2||isempty(add_layers)||~isnumeric(add_layers)||add_layers(1)==0
    do_layers=0;
end
if nargin>2&&~isempty(this_axis)&&isnumeric(this_axis)&&this_axis(1)<=2&&round(this_axis(1))>0
    aoi=round(this_axis(1));
else
    if s(1)>=s(2)
        aoi=1; % Axis of intererst 
    else
        aoi=2;
    end
end
n=s(aoi); % number of entries along axis of intererst 
if aoi==2 % Format for scrambling along the M-axis
    ordered_array=rows2vars(ordered_array);
end

% Generate scrambled indices
if do_layers==1    % increase randomness by pre-generating a bunch of permutations
    c=clock;
    pregen_perms=c(6);
    for i=1:pregen_perms
        randperm(n);
    end
end
scrambled_indices=randperm(n);
scrambled_array=ordered_array(scrambled_indices',:);
if aoi==2 % returning scrambled array back to original inidices
    scrambled_array=rows2vars(scrambled_array);
end
end

function [hist_title,hist_output]=qpa_histo_plot(j,i,hist_cell,threshold,edges,xhi,yhi,show_mean,...
    show_median,show_threshold,hist_name,dateindex)

% This section of code gets repeated in a try-catch block, so I've made it
% a function.

this_hist=hist_cell{i,j}(:,1);
this_hist(this_hist==0)=[];
m=mean(this_hist);
d=median(this_hist);
legend_mean=(sprintf('Mean = %0.3g',m));
legend_median=(sprintf('Median = %0.3g',d));
legend_threshold=(sprintf('Threshold = %0.3g',threshold));
figure;
histogram(this_hist,edges);
hold on
if ~isempty(xhi)
    xlim([0,xhi]);
end
if ~isempty(yhi)
    ylim([0,yhi]);
end
if show_mean==1
    plot([m;m],[0;yhi],'LineWidth',4); % Show the mean on the histogram
end
if show_median==1
    plot([d;d],[0;yhi],'LineWidth',4); % Show the median on the histogram
end
if show_threshold==1
    plot([threshold;threshold],[0;yhi],'LineWidth',4); % Show the threshold on the histogram
end
hist_title=sprintf('%s%d',hist_name{i},j);
title(hist_title,'FontSize',30);
hist_output=sprintf('%s %s',hist_title,dateindex);
xlabel('Nuclear Area (um^2)');
ylabel(sprintf('%d Cells',length(this_hist)+1));
legend('Cells',legend_mean,legend_median,legend_threshold,'FontSize',30);
these_axes=gca;
these_axes.FontSize=30;

end
