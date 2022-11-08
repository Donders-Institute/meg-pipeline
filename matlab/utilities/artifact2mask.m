function mask = artifact2mask(artifact, trl, endsample)

if nargin<3
  endsample = max(max(trl(:)),max(artifact(:)));
end

boolvec = artifact2boolvec(artifact, 'endsample', endsample);
  
tmpdata          = [];
tmpdata.trial{1} = boolvec;
tmpdata.time{1}  = (1:numel(boolvec));
tmpdata.label    = {'boolvec'};

tmpcfg     = [];
tmpcfg.trl = trl;
tmpdata    = ft_redefinetrial(tmpcfg, tmpdata);
mask       = tmpdata.trial;
