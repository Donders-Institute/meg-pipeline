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

if nargin>3 || ~isempty(blinkartifact)
  createmask = true;
end

if nargin<5
  opts = [];
end

trltmp = prj_util_epochtrl(trl);

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
  cfg.display          = [0 0 1919 1079];
  data                 = eyelink_voltage2gaze(cfg, data);

  cfg            = [];
  cfg.display    = [1920 1080];
  cfg.screensize = [53 30];
  cfg.screendist = 80;
  data           = eyelink_gaze2degree(cfg, data);
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
opts.medfiltord = 0.075; 

cfg                                = [];
cfg.continuous                     = 'yes';
cfg.memory                         = 'high';

% processing heuristics for the optimal detection of (lateral) saccades, assuming
% that channel is the name of an EOG channel, or the name of the analog
% eyetracker channel that measured the x-position of the eye
cfg.artfctdef.zvalue.channel         = 'degX';
cfg.artfctdef.zvalue.cutoff          = 30;
cfg.artfctdef.zvalue.interactive     = 'yes';
cfg.artfctdef.zvalue.custom.funhandle = @prj_preproc_saccades; 
cfg.artfctdef.zvalue.custom.varargin  = opts;
%cfg.artfctdef.zvalue.artfctpeak       = 'yes';
%cfg.artfctdef.zvalue.artfctpeakrange  = [-0.01 0.01];
cfg.artfctdef.zvalue.zscore           = 'no';

cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0;
cfg.artfctdef.zvalue.artpadding    = 0.01;

cfg = ft_artifact_zvalue(cfg, data);

% compute the amplitude of the saccade
artifact = cfg.artfctdef.zvalue.artifact;
tmptrl   = artifact;
tmptrl(:,1) = tmptrl(:,1)-90;
tmptrl(:,2) = tmptrl(:,2)+90;
tmptrl = max(tmptrl,1);
tmptrl = min(tmptrl,max(data.sampleinfo(:)));
tmptrl(:,3) = 0;

tmpcfg = [];
tmpcfg.trl = tmptrl;
data = ft_redefinetrial(tmpcfg, data);
A = zeros(numel(data.trial),1);
xchan = match_str(data.label, 'degX');
for k = 1:numel(data.trial)
  pre = nanmedian(data.trial{k}(xchan,1:60));
  pst = nanmedian(data.trial{k}(xchan,(end-59):end));
  A(k,1) = pst-pre;
end

% add the estimated amplitude to the artifact description
cfg.artfctdef.zvalue.artifact(:, 3) = A;
