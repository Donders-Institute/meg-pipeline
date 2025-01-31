function cfg = prj_util_artifactdetect_saccades(dataset, trl, channel, blinkartifact, opts)

% clear the persistent variable in the lower-level function. Note that this
% is a bit of a hacky solution, to allow a blink mask to be passed to the
% function (and to be correctly applied). The function preproc loops across
% input trials, but cannot pass additional trial-specific information (e.g.
% said blink mask). In order to be able to apply it, prj_preproc_saccades
% keeps track of a counter, which indexes the current trial. It is
% important that this variable is cleared (only once) before a new outer
% loop across trials is executed. Note that if you have renamed the
% prj_preproc_saccades function, you need to change the below line as well.
clear prj_preproc_saccades

if nargin<3 || isempty(channel)
  channel = {'UADC005';'UADC006'};
end
if ischar(channel)
  channel = {channel};
end

if nargin>3 || ~isempty(blinkartifact)
  createmask = true;
else 
  createmask = false;
end

if nargin<5
  opts = [];
end

opts.display    = ft_getopt(opts, 'display',    [1920 1080]); % width x height in pixels
opts.screensize = ft_getopt(opts, 'screensize', [53 30]); % width x height in the same units as screen distance
opts.screendist = ft_getopt(opts, 'screendist', 80);
opts.fsample    = ft_getopt(opts, 'fsample',    1200); % for the trial cutting
opts.maxdur     = ft_getopt(opts, 'maxdur',     5);    % for the trial cutting

if isstruct(dataset)
  hasdata = true;
  data = dataset;

  cfg = [];
  cfg.channel = channel;
  data = ft_selectdata(cfg, data);

else
  hasdata = false;

  %use the supplied dataset and trl matrix to load in the data
  if istable(trl)
    trl = table2array(trl(:,1:3));
  end

  trltmp = prj_util_epochtrl(trl, opts.fsample, opts.maxdur);

  hdr = ft_read_header(dataset);

  cfg            = [];
  cfg.dataset    = dataset;
  cfg.trl        = trltmp;
  cfg.continuous = 'yes';
  cfg.channel    = channel;
  data           = ft_preprocessing(cfg);
  data           = removefields(data, {'elec'});

  if endsWith(dataset, 'ds')
    % voltage channel data, convert to degrees of visual angle
    cfg                  = [];
    cfg.analog_dac_range = [-5 5];
    cfg.analog_x_range   = [0 1];
    cfg.analog_y_range   = [0 1];
    cfg.display          = [0 0 opts.display-1];
    data                 = eyelink_voltage2gaze(cfg, data);

    cfg            = [];
    cfg.display    = opts.display;
    cfg.screensize = opts.screensize;
    cfg.screendist = opts.screendist;
    data           = eyelink_gaze2degree(cfg, data);
  end
  channel = {'degX' 'degY'};
end

if createmask
  % mask out the blinks with nans
  cfg = [];
  cfg.artfctdef.zvalue.artifact = blinkartifact;
  cfg.artfctdef.reject          = 'nan';
  data = ft_rejectartifact(cfg, data);
end

% Do the processing steps within ft_artifact_zvalue, which allows for a
% better appreciation of the saccades in the interactive figure
% cfg = [];
% cfg.medianfilter  = 'yes';
% cfg.medianfiltord = 2*round(0.05.*hdr.Fs./2)+1;
% data = ft_preprocessing(cfg, data);
% 
% cfg            = [];
% cfg.derivative = 'yes';
% data_vel       = ft_preprocessing(cfg, data); % currently, this computes derivative as deltaY/sample
% 
% cfg           = [];
% cfg.operation = 'multiply';
% cfg.scalar    = data_vel.fsample;
% cfg.parameter = 'trial';
% data_vel      = ft_math(cfg, data_vel);

opts.fsample    = data.fsample;
opts.medfiltord = ft_getopt(opts, 'medfiltord', 0.075); 

cfg                                = [];
cfg.continuous                     = 'yes';
cfg.memory                         = 'high';

% processing heuristics for the optimal detection of (lateral) saccades, assuming
% that channel is the name of an EOG channel, or the name of the analog
% eyetracker channel that measured the x-position of the eye
cfg.artfctdef.zvalue.channel         = channel;
cfg.artfctdef.zvalue.cutoff          = opts.cutoff;
cfg.artfctdef.zvalue.interactive     = 'yes';
cfg.artfctdef.zvalue.custom.funhandle = @prj_preproc_saccades; 
cfg.artfctdef.zvalue.custom.varargin  = opts;
%cfg.artfctdef.zvalue.artfctpeak       = 'yes';
%cfg.artfctdef.zvalue.artfctpeakrange  = [-0.01 0.01];
cfg.artfctdef.zvalue.zscore           = 'no';

cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0;
cfg.artfctdef.zvalue.artpadding    = 0.01;
cfg.artfctdef.zvalue.interactive   = ft_getopt(opts, 'interactive', 'yes');

cfg = ft_artifact_zvalue(cfg, data);

% compute the amplitude of the saccade
artifact = cfg.artfctdef.zvalue.artifact;
tmptrl   = artifact;
tmptrl(:,1) = tmptrl(:,1)-90;
tmptrl(:,2) = tmptrl(:,2)+90;
tmptrl = max(tmptrl,1);
tmptrl = min(tmptrl,max(data.sampleinfo(:)));
tmptrl(:,3) = -artifact(:,1)+tmptrl(:,1);

tmpcfg = [];
tmpcfg.trl = tmptrl;
if isfield(data, 'trialinfo') && istable(data.trialinfo)
  % occasionally very funky tables might confuse ft_redefinetrial
  data = rmfield(data, 'trialinfo');
end
data = ft_redefinetrial(tmpcfg, data);
A = zeros(numel(data.trial),1);
xchan = match_str(data.label, channel{1});
for k = 1:numel(data.trial)
  pre = nanmedian(data.trial{k}(xchan,61:90));
  pst = nanmedian(data.trial{k}(xchan,(end-89):(end-60)));
  A(k,1) = pst-pre;
  %A(k,2) = 
end

% add the estimated amplitude to the artifact description
cfg.artfctdef.zvalue.artifact(:, 3) = A;
