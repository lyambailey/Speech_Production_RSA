# Import neceaary libraries
library(dplyr)
library(BayesFactor)
library(ggplot2)
library(Rmisc)

# Set up top directory and load data
top_dir = file.path('D:', 'behavioural_data')
data_dir = file.path(top_dir, 'PE_behavioural_output')

load(file.path(data_dir, 'agg_PE_data_formatted_25_subjects.Rda'))

# Compute proportion of missed responses
n_missed = (length(df_group$response[df_group$response == "None"])) / length(df_group$response)

paste((n_missed * 100), '% responses missed')

# Drop rows containing missed responses
#df_group = df_group[df_group$response != "None",]

# Add column reflecting whether or not participants made an 'old' response
df_group$old = ifelse(df_group$response == 'a', 1, 0)

# Compute % OLD responses, averaged over words 
df_old = df_group %>%
  group_by(subject, condition) %>%
  dplyr::summarize(value=mean(old))


# Set up for Bayes ttest: extract % old for each condition
old_aloud = df_old$value[df_old$condition == 'aloud']
old_silent = df_old$value[df_old$condition == 'silent']
old_foil = df_old$value[df_old$condition == 'foil']

# Perform Bayes paired ttests
BayesFactor::ttestBF(x = old_aloud, y = old_silent, paired = T)
BayesFactor::ttestBF(x = old_aloud, y = old_foil, paired = T)
BayesFactor::ttestBF(x = old_silent, y = old_foil, paired = T)

# Conventional ttest for comparison
t.test(x=old_aloud, y=old_silent, paired=T)

# Plot results with ggplot
# Average over subjects

# Multiply value by 100 (to express %)
df_old$value = df_old$value*100

# Re-order conditions
df_old$condition = factor(df_old$condition, levels = c("aloud", "silent", "foil"))

# Compute means condition-wise
means = summarySEwithin(data = df_old, 
                  measurevar = 'value', 
                  withinvars = c('condition'),
                  idvar = 'subject')


# violin plot

# # Plot with individual data points (but very ugly):
ggplot(data=df_old, aes(x = condition, y = value, fill= condition)) +
  
  # Fix the y scale at 0-100
  scale_y_continuous(limits = c(0, 100)) +
  
  # Plot violin and box plots
  geom_violin(width = 0.5, trim = F, color=NA) +
  
  # Plot box plot 
  geom_boxplot(width = 0.05, fill = 'white', size=0.5) +
  
  # # Plot individual data points
  # geom_jitter(shape=2, position=position_jitter(0.1), size = 1, color='black') +
  # 
  # # Plot condition means and error bars
  # geom_point(data=means, aes(y = value), color='white') +
  # geom_errorbar(data = means, aes(ymin=value-se, ymax=value+se), width=0.05, size=0.5,
  #               position=position_dodge(.9), color='white') +
  
  # Set manual y-axis label and x-axis ticks
  labs(y= "Percentage OLD", x = "") +
  scale_x_discrete(labels = c('Aloud','Silent','Foil')) +
  
  # Set violin colours 
  scale_fill_manual(values = c("#56B4E9", "#E69F00", "#999999")) +
  
  # Use classic theme and remove color legend
  theme_classic() +
  theme(legend.position = "none") +
  
  # Reduce distance between plots
  theme(aspect.ratio = 1)



# Save to disk
ggsave(file.path(data_dir, 'Figure 4 - Percent OLD responses.png'))

