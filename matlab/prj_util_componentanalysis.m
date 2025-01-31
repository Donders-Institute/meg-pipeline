function comp = prj_util_componentanalysis(cfg, data)

if nargin < 2
  hasdata = false;
  assert(isfield(cfg, 'inputfile'));
else
  hasdata = true;
end

if ~isfield(cfg, 'method')
  cfg.method = 'fastica';
  cfg.fastica.g = 'tanh';
  cfg.fastica.lastEig = 150;
  cfg.fastica.numOfIC = 50;
end
cfg.channel = 'MEG';

if hasdata
  comp = ft_componentanalysis(cfg, data);
else
  comp = ft_componentanalysis(cfg);
end
