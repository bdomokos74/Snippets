ggplot(performance, aes(x = Lambda, y = ErrorRate))+
  stat_summary(fun.data = 'mean_cl_boot', geom = 'errorbar')+
  stat_summary(fun.data = 'mean_cl_boot', geom = 'point')+
  scale_x_log10()