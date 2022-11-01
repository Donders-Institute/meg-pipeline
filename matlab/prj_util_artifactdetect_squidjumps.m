function cfg = prj_util_artifactdetect_squidjumps(dataset, trl)

trltmp = prj_util_epochtrl(trl);

cfg                                = [];
cfg.dataset                        = dataset;
cfg.trl                            = trltmp;
cfg.continuous                     = 'yes';
cfg.memory                         = 'low';
cfg.artfctdef.zvalue.channel       = {'MEG'};

% processing heuristics for the optimal detection of squidjumps
cfg.artfctdef.zvalue.medianfilter  = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.cutoff        = 100;
cfg.artfctdef.zvalue.absdiff       = 'yes';
cfg.artfctdef.zvalue.interactive   = 'yes';

% padding options that depend a bit on the intended downstream analysis.
% There is no one shoe fits all. Specifically, the fltpadding requires
% a non-zero value of 0.5*the intended cfg.padding in ft_preprocessing, to
% avoid highpassfilter ringing caused by a squidjump to affect the relevant
% data. Note that this slows down the current processing step, but better
% safe than sorry. If a very wide definition of epochs is already used,
% then fltpadding could be specified to 0 (because sufficient data is
% processed for artifacts anyhow)
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0.1;
cfg.artfctdef.zvalue.artpadding    = 0.1;

cfg = ft_artifact_zvalue(cfg);
