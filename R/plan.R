# PLAN
library(drake)

the_plan <-
  drake_plan(
    unzip19 = data_unzip("2019"),
    unzip20 = data_unzip("2020"),
    combine19 = data_raw_combine("2019"),
    combine20 = data_raw_combine("2020"),
    df_all = data_merge(combine19, combine20),
    p1 = plot_flow_chx(df_all, "Class-1","Magnitude", save = T),
    p2 = plot_flow_chx(df_all, "Class-2","Magnitude", save = T),
    p3 = plot_flow_chx(df_all, "Class-3", "Magnitude", save=F),
    tmagnitude = flow_chx_dt(df_all, "Magnitude")
  )

