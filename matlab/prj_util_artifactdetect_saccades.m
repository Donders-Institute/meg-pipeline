function cfg = prj_util_artifactdetect_saccades(dataset, trl, channel, blinkartifact)

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
  channel = 'UADC005';
end

if nargin>3
  createmask = true;
end

trltmp = prj_util_epochtrl(trl);

cfg                                = [];
cfg.dataset                        = dataset;
cfg.trl                            = trltmp;
cfg.continuous                     = 'yes';
cfg.memory                         = 'high';

hdr = ft_read_header(cfg.dataset);

opts = [];
opts.fsample = hdr.Fs;
opts.medfiltord = 0.05;

if createmask
  opts.mask  = artifact2mask(blinkartifact, trl, hdr.nSamples*hdr.nTrials);
end

% processing heuristics for the optimal detection of (lateral) saccades, assuming
% that channel is the name of an EOG channel, or the name of the analog
% eyetracker channel that measured the x-position of the eye
cfg.artfctdef.zvalue.channel         = channel;
cfg.artfctdef.zvalue.cutoff          = 1.5;
cfg.artfctdef.zvalue.interactive     = 'yes';
cfg.artfctdef.zvalue.custom.funhandle = @prj_preproc_saccades;
cfg.artfctdef.zvalue.custom.varargin  = opts;
cfg.artfctdef.zvalue.artfctpeak       = 'yes';
cfg.artfctdef.zvalue.artfctpeakrange  = [-0.01 0.01];
% the value for artfctpeakrange depends a bit on what is going to be done
% downstream: if only the fast flank is to be marked, then the values need
% to be small. If it's intended to discard some larger portion after the
% end of the saccade, obviously the second element needs to be extended a
% bit


% padding options that depend a bit on the intended downstream analysis.
% There is no one shoe fits all. Specifically, the fltpadding requires
% a non-zero value of 0.5*the intended cfg.padding in ft_preprocessing, to
% avoid highpassfilter ringing caused by a squidjump to affect the relevant
% data. Note that this slows down the current processing step, but better
% safe than sorry. If a very wide definition of epochs is already used,
% then fltpadding could be specified to 0 (because sufficient data is
% processed for artifacts anyhow)
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0;
cfg.artfctdef.zvalue.artpadding    = 0;

cfg = ft_artifact_zvalue(cfg);
