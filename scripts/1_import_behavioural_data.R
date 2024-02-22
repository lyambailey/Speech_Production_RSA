# Import necessary libraries
library(Rmisc)
library(ggplot2)


# Set up top  and output directories
top_dir = file.path('D:', 'behavioural_data')
out_dir = file.path(top_dir, 'PE_behavioural_output')
dir.create(out_dir, showWarnings = FALSE)

# Define list of subjects 1-30. Format for subjects 1-9 is "subject-00"; for 10-30 "subject-0"
subjects = c(paste('subject-00', 1:9, sep=''), paste('subject-0', 10:30, sep=''))

# Define bad subjects to remove
bads = c('subject-001', 'subject-002', 'subject-008', 'subject-015', 'subject-018')
subjects = subjects[! subjects %in% bads];

# Define columns of test data that we want to load in in the loop below
cols_to_keep = c('condition', 'tested_word', 'test_resp.keys')

# Define sensible headers for the above columns
headers = c('condition', 'word',  'response', 'subject')

# Define a dataframe to hold everyone's data
df_group = data.frame()


# Loop through subjects, reading in and formatting test data for each, and appending it to group_df
for (subject in subjects) {
  
  # Define path to test data
  test_data_fn= file.path(top_dir, 'fmri_runs1', subject, sprintf('%s_test.csv', subject))
  

  # Load data
  df = read.csv(test_data_fn)[cols_to_keep]
  
  # Remove empty lines
  df = df[!df$condition=="",]
  
  # Add a column containing the subject label
  df = merge(df, subject)
  
  # Add senisble headers
  colnames(df) = headers
  
  # Convert columns to factors
  df$condition = as.factor(df$condition)
  df$word = as.factor(df$word)
  df$subject = as.factor(df$subject)
  
  
  # Append df to group_df
  df_group = rbind(df_group, df)
  
  
}

# Save group_df to disk
save(df_group, file = file.path(out_dir, sprintf('agg_PE_data_formatted_%s_subjects.Rda', length(subjects))))

