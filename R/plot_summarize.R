# Compare -----------------------------------------------------------------

flow_chx_dt <- function(flow_characteristic){
  # get paths
  base_data_dir <- glue("{here()}/output/")
  df_all <- read_fst(path = glue("{base_data_dir}/ffm_combined_tidy.fst"))

  # filter to timing metrics only
  unique(df_all$flow_characteristic) # "Timing"         "Magnitude"      "Duration"       "Rate of change" "Frequency"
  flow_chx <- flow_characteristic
  ffm_flow <- df_all %>% filter(flow_characteristic==flow_chx)

  dt1 <- ffm_flow %>% group_by(class, ffc_version, ffm) %>%
    summarise(mean=mean(value, na.rm=T)) %>%
    pivot_wider(id_cols = c("class","ffm"), names_from="ffc_version", values_from="mean") %>%
    DT::datatable(caption = glue("Flow Characteristic: {flow_chx}"))

return(dt1)

  }

plot_flow_chx <- function(stream_class, flow_characteristic){

  # get paths
  base_data_dir <- glue("{here()}/output/")
  read_fst(path = glue("{base_data_dir}/ffm_combined_tidy.fst"))

  # filter to timing metrics only
  unique(df_all$flow_characteristic) # "Timing"         "Magnitude"      "Duration"       "Rate of change" "Frequency"
  flow_chx <- flow_characteristic
  ffm_flow <- df_all %>% filter(flow_characteristic==flow_chx)

  # plot
  gg1 <- ggplot() +
      #geom_jitter(data=ffm_flow %>% filter(class==stream_class),
                 #aes(x = ffm, y=value, group=ffm), pch=16, alpha=0.1) +
      geom_boxplot(data=ffm_flow %>% filter(class==stream_class),
                  aes(x = ffm, y=value, fill=ffc_version, group=ffm),
                  alpha=0.9, show.legend = FALSE, outlier.alpha = 0.3)+
      coord_flip() + labs(x="", y="Value", subtitle = glue("{stream_class}: {flow_chx} Metrics")) +
      scale_fill_brewer(type = "qual") +
      theme_classic() +
      facet_wrap(~ffc_version)

  print(gg1)
  #ggsave(plot = gg1, filename = glue("{here()}/output/{stream_class}_compare_boxplot.png"),
  #       width = 8, height = 7, units = "in", dpi=300)

  }
