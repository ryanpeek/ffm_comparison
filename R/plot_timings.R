# Compare -----------------------------------------------------------------


plot_timings <- function(stream_class){

  # get paths
  base_data_dir <- glue("{here()}/output/")
  load(glue("{base_data_dir}/ffm_combined_tidy.rda"))

  # filter to timing metrics only
  unique(df_all$flow_characteristic) # "Timing"         "Magnitude"      "Duration"       "Rate of change" "Frequency"
  flow_chx <- "Magnitude"
  ffm_flow <- df_all %>% filter(flow_characteristic==flow_chx)

  ffm_flow %>% group_by(class, ffc_version, ffm) %>%
    summarise(mean=mean(value, na.rm=T)) %>%
    pivot_wider(id_cols = c("class","ffm"), names_from="ffc_version", values_from="mean") %>%
    DT::datatable(caption = glue("Flow Characteristic: {flow_chx}"))

  # violin plots
  #stream_class <- "Class-1"
  (gg1 <- ggplot() +
      #geom_jitter(data=ffm_flow %>% filter(class==stream_class),
                 #aes(x = ffm, y=value, group=ffm), pch=16, alpha=0.1) +
      geom_boxplot(data=ffm_flow %>% filter(class==stream_class),
                  aes(x = ffm, y=value, fill=ffc_version, group=ffm),
                  alpha=0.9, show.legend = FALSE, outlier.alpha = 0.3)+
      coord_flip() + labs(x="", y="Value", subtitle = glue("{stream_class}: {flow_chx} Metrics")) +
      scale_fill_brewer(type = "qual") +
      theme_classic() +
      facet_wrap(~ffc_version))

  ggsave(gg1, path = glue("{here()}/output/{stream_class}_compare_boxplot.png"))
}
