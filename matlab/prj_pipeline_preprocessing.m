
if ~exist(sub, 'var')
  error('subject needs to be defined');
end

if ~exist(ses, 'var')
  warning('session is not defined, assumed to be 1');
  ses = [];
end

%%
% define the struct that contains the subject's metadata
subj = prj_subjinfo(sub, ses);

%%
% define the epochs for artifact detection; this does not need to be a very
% constrained set of epochs, and ideally should be defined widely enough
% that all potentially relevant parts of the dataset are covered, ideally
% excluding the breaks etc. (which will be artifact rich anyhow). If
% nothing is defined here, the code below will explore the full dataset,
% excluding the first and last 5 seconds, to avoid file reading problems
% (beyond the edges of the datafile)

% %%
% hdr = ft_read_header(subj.dataset);
% trl = [5*hdr.Fs hdr.nSamples*hdr.nTrials-5*hdr.Fs 0];

%% 
% epoch definition for /project/3026001.01 (test project to write code in
% this repo) -> replace this with your own trl-definition machinery
val = repmat([10 30 50 70]',[1 4]) + repmat([3 4 6 8],[4 1]);
val = val(:);

cfg = [];
cfg.dataset             = subj.dataset;
cfg.trialdef.eventtype  = 'UPPT001';
cfg.trialdef.eventvalue = val;
cfg.trialdef.prestim    = 1; 
cfg.trialdef.poststim   = 1.5;
cfg = ft_definetrial(cfg);
trl = cfg.trl;


%%
% detect squidjumps
cfg = prj_util_artifactdetect_squidjumps(subj.dataset, trl);
filename = fullfile(subj.procdir, sprintf('%s_%s_squidjumps.mat', subj.subjname, subj.sessname));
save(filename, 'cfg');

% detect muscle artifacts
cfg = prj_util_artifactdetect_muscle(subj.dataset, trl);
filename = fullfile(subj.procdir, sprintf('%s_%s_muscle.mat', subj.subjname, subj.sessname));
save(filename, 'cfg');

% detect eyeblink artifacts
cfg = prj_util_artifactdetect_eyeblinks(subj.dataset, trl);
filename = fullfile(subj.procdir, sprintf('%s_%s_eyeblinks.mat', subj.subjname, subj.sessname));
save(filename, 'cfg');

% detect saccade artifacts
filename = fullfile(subj.procdir, sprintf('%s_%s_%s.mat', subj.subjname, subj.sessname, 'eyeblinks'));
load(filename);
cfg = prj_util_artifactdetect_saccades(subj.dataset, trl, [], cfg.artfctdef.zvalue.artifact);
filename = fullfile(subj.procdir, sprintf('%s_%s_saccades.mat', subj.subjname, subj.sessname));
save(filename, 'cfg');

%% 
% snippet of code to inspect the density of saccades (or eyeblinks) as a
% function of time after stimulus onset, requires a meaningful 'trl', and
% the below moreover assumes that all trls have the same time axis,
% otherwise some more complicated code will be needed
filename = fullfile(subj.procdir, sprintf('%s_%s_saccades.mat', subj.subjname, subj.sessname));
load(filename);
mask = artifact2mask(cfg .artfctdef.zvalue.artifact, trl, max(trl(:)));
tim  = (trl(1,3)+(0:(trl(1,2)-trl(1,1))))./1200; % assumes 1200 Hz sampling
figure;plot(tim, mean(cat(1,mask{:}))*100);
xlabel('time (s)'); ylabel('saccade density (%)');


%%
% reject the artifacts from the data, this requires a data-structure
% (non-resampled) to exist in memory

type = {'squidjumps' 'muscle' 'eyeblinks'};
for k = 1:numel(type)
  filename = fullfile(subj.procdir, sprintf('%s_%s_%s.mat', subj.subjname, subj.sessname, type{k}));
  if exist(filename, 'file')
    load(filename);
    artfctdef.(type{k}) = cfg.artfctdef.zvalue;
    clear cfg
  end
end

cfg                        = [];
cfg.artfctdef              = artfctdef;
cfg.artfctdef.reject       = 'nan'; % depends on what you want to do next
data                       = ft_rejectartifact(cfg, data);


% alternatively, we can also use the dss algorithm to identify
% eyeblink-related signal topographies, and remove them from the data
params.artifact = artfctdef.eyeblinks.artifact;
params.artifact(:,3) = 0;
params.demean   = true;

cfg                   = [];
cfg.method            = 'dss';
cfg.dss.denf.function = 'denoise_avg2';
cfg.dss.denf.params   = params;
cfg.dss.wdim          = 75;
cfg.numcomponent      = 10;
cfg.channel           = 'MEG';
cfg.cellmode          = 'yes';
dss                   = ft_componentanalysis(cfg, data);

