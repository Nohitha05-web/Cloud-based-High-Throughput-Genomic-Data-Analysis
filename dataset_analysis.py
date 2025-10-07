import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import boto3
import io

# AWS S3 configuration (assumes EC2 IAM role has S3 access)
s3 = boto3.client('s3')
bucket = 'nohitha-genomics-hpc-zcpnbw61'
key = 'human_liver.tsv'

# Load dataset directly from S3 (no local download needed)
print("Downloading dataset from S3...")
obj = s3.get_object(Bucket=bucket, Key=key)
df = pd.read_csv(io.BytesIO(obj['Body'].read()), sep='\t')
print("Dataset loaded successfully!")

print("Columns (first 10):", df.columns.tolist()[:10], "...")
print(f"Dataset shape: {df.shape}")

# High-throughput: Stats per gene across samples (chunked for low memory)
chunk_size = 5000
chunks = pd.read_csv(io.BytesIO(obj['Body'].read()), sep='\t', low_memory=False, chunksize=chunk_size)

expression_cols = None
means = []
medians = []
vars_ = []
genes_list = []

for chunk in chunks:
    if expression_cols is None:
        expression_cols = chunk.columns[1:]  # All sample columns
    
    # Convert to numeric safely
    numeric_chunk = chunk[expression_cols].apply(pd.to_numeric, errors='coerce')
    
    # Compute stats per row (gene)
    means.append(numeric_chunk.mean(axis=1))
    medians.append(numeric_chunk.median(axis=1))
    vars_.append(numeric_chunk.var(axis=1))
    genes_list.append(chunk['genes'])
    
    print(f"Processed chunk: {len(chunk)} rows")

# Concatenate results
df_stats = pd.concat([pd.concat(genes_list), pd.concat(means, axis=0, ignore_index=True), 
                      pd.concat(medians, axis=0, ignore_index=True), 
                      pd.concat(vars_, axis=0, ignore_index=True)], axis=1)
df_stats.columns = ['genes', 'mean_expr', 'median_expr', 'var_expr']

# Top 100 highly expressed genes
significant = df_stats.nlargest(100, 'mean_expr')[['genes', 'mean_expr', 'median_expr', 'var_expr']]

print(f"Top 100 highly expressed genes:")
print(significant.head(10))

# Histogram plot (sample for plot)
sample_df = df_stats.sample(min(5000, len(df_stats)))
plt.figure(figsize=(10, 6))
sns.histplot(data=sample_df, x='mean_expr', bins=50, kde=True, color='skyblue', alpha=0.7)
plt.title('Distribution of Mean Gene Expression Across Liver Samples')
plt.xlabel('Mean Expression Level')
plt.ylabel('Number of Genes')
plt.axvline(significant['mean_expr'].iloc[0], color='red', linestyle='--', label='Top Expressed Gene')
plt.legend()
plt.tight_layout()
plt.savefig('expression_histogram.png', dpi=300, bbox_inches='tight')
print("Plot saved: expression_histogram.png")

# Export results
df_stats.to_csv('liver_expression_summary.csv', index=False)
significant.to_csv('top_expressed_genes.csv', index=False)
print("Results saved: liver_expression_summary.csv and top_expressed_genes.csv")