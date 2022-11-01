function cfg = prj_util_artifactdetect_muscle(dataset, trl)

trltmp = prj_util_epochtrl(trl);

cfg                              = [];
cfg.dataset                      = dataset;
cfg.trl                          = trltmp;
cfg.continuous                   = 'yes';
cfg.memory                       = 'low';

cfg.artfctdef.zvalue.interactive = 'yes';
cfg.artfctdef.zvalue.channel     = {'MEG'};
cfg.artfctdef.zvalue.bpfilter    = 'no';
cfg.artfctdef.zvalue.hilbert     = 'no';
cfg.artfctdef.zvalue.rectify     = 'yes';
cfg.artfctdef.zvalue.hpfilter    = 'yes';
cfg.artfctdef.zvalue.hpfreq      = 80;
cfg.artfctdef.zvalue.cutoff      = 10;
cfg.artfctdef.zvalue.demean      = 'yes';
cfg.artfctdef.zvalue.boxcar      = 0.5;
cfg.artfctdef.zvalue.fltpadding  = 0;
cfg.artfctdef.zvalue.trlpadding  = 0;
cfg.artfctdef.zvalue.artpadding  = 0.1; % .1 sec padding

cfg = ft_artifact_zvalue(cfg);
