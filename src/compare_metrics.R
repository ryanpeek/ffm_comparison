
# Compare Data ------------------------------------------------------------


# LIBRARIES ---------------------------------------------------------------

library(tidyverse)
library(purrr)
library(glue)
library(fs)

# Load Data ---------------------------------------------------------------


# version 2020, new
load("output/2020-10-20_CA_ffm_obs_tidy_df.rda")
# rename and remove old version
v20_df <- df_trim; rm(df_trim)

# version 1.0 (old)
load("output/2019-07-27_CA_ffm_obs_tidy_df.rda")
# rename and rm
v19_df <- df_trim; rm(df_trim)

# Bind into Single Dataset ------------------------------------------------

# makes plotting easier
df_all <- bind_rows(v19_df, v20_df) %>%
  mutate(version=factor(version))

# Summary
v19_df %>% filter(ffm=="Wet_Tim") %>% select(value) %>% summary()
v20_df %>% filter(ffm=="Wet_Tim") %>% select(value) %>% summary()

# Compare -----------------------------------------------------------------

# filter to nfa:
nfa <- df_all %>% filter(gage_id=="11427700")

# quick ggplot of timings
ggplot() +
  geom_violin(data=df_all %>% filter(ffm=="Wet_Tim"),
               aes(x = version, y=value, fill=version, group=version), alpha=0.3)

