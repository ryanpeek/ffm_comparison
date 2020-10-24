# make
source("R/packages.R")
source("R/data_unzip.R")
source("R/data_raw_combine.R")
source("R/data_merge.R")
source("R/data_plot_summarize.R")
source("R/plan.R")

vis_drake_graph(the_plan)
make(the_plan)

# options(clustermq.scheduler = "multicore") # optional parallel computing
#config <- drake_config(the_plan, verbose = 1)
#r_outdated(config)
#make_impl(config = config)
#clean()
#r_make()
