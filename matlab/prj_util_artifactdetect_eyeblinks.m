function cfg = prj_util_artifactdetect_eyeblinks(dataset, trl, channel)

if nargin<3
  channel = 'UADC007';
end

trltmp = prj_util_epochtrl(trl);

cfg                                = [];
cfg.dataset                        = dataset;
cfg.trl                            = trltmp;
cfg.continuous                     = 'yes';
cfg.memory                         = 'low';

% processing heuristics for the optimal detection of eyeblinks, assuming
% that channel is the name of an EOG channel, or the name of the analog
% eyetracker channel that measured the pupilsize
cfg.artfctdef.zvalue.channel         = channel;
cfg.artfctdef.zvalue.cutoff          = 4;
cfg.artfctdef.zvalue.interactive     = 'yes';
cfg.artfctdef.zvalue.bpfilter        = 'yes';
cfg.artfctdef.zvalue.bpfreq          = [1 10];
cfg.artfctdef.zvalue.bpfilttype      = 'firws';
cfg.artfctdef.zvalue.hilbert         = 'yes';

% padding options that depend a bit on the intended downstream analysis.
% There is no one shoe fits all. Specifically, the fltpadding requires
% a non-zero value of 0.5*the intended cfg.padding in ft_preprocessing, to
% avoid highpassfilter ringing caused by a squidjump to affect the relevant
% data. Note that this slows down the current processing step, but better
% safe than sorry. If a very wide definition of epochs is already used,
% then fltpadding could be specified to 0 (because sufficient data is
% processed for artifacts anyhow)
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0.2;
cfg.artfctdef.zvalue.artpadding    = 0.1;

cfg = ft_artifact_zvalue(cfg);
