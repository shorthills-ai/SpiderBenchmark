# Spider2 Evaluation Suite V2 - Internal Working Documentation

## Overview

This document explains the internal working of the `evaluate_v2.py` script, which provides comprehensive evaluation capabilities for SQL query results with robust column and row comparison functionality.

## Architecture Overview

The evaluation system operates in two main modes:

**SQL Mode**: Executes predicted SQL queries and compares results with gold standards

**Execution Result Mode**: Directly compares CSV result files with gold standards

#### Sqlite Database Link

* [spider2-localdb.zip](https://shorthillstech-my.sharepoint.com/:u:/g/personal/aman_shorthills_ai/EbLcIHjnYydGh1_7pzP1UBMBNiHkAG7i-4CBfnHT6zN0iw?e=bj99yM)

## Core Components

### 1. Column Normalization System

The system uses a sophisticated column normalization approach to handle variations in column naming:

#### Synonym Mapping

```python
SYNONYM_MAP = {
    'unique': 'distinct',
    'avg': 'average',
    'sum': 'total',
    'count': 'number',
    'qty': 'quantity',
    'amt': 'amount',
    'desc': 'description',
    # ... and many more
}
```

#### Stopword Removal

```python
WORDS_TO_REMOVE = {'of', 'the', 'a', 'an'}
```

#### Normalization Process

The `normalize_column_name()` function performs the following steps:

1. Convert to lowercase and trim whitespace
2. Replace underscores with spaces
3. Remove common stopwords
4. Apply synonym harmonization word-by-word

**Example:**

- Input: `"Customer_ID_Number"`
- After lowercase + trim: `"customer_id_number"`
- After underscore replacement: `"customer id number"`
- After stopword removal: `"customer id number"`
- After synonym mapping: `"customer identifier number"`

### 2. Column Comparison Logic

The `compare_columns()` function implements precision/recall/F1 scoring for column matching:

#### Process Flow

1. **Normalization**: Both predicted and gold column sets are normalized using the shared normalizer
2. **Set Operations**:
   - True Positives (TP): Intersection of predicted and gold columns
   - False Positives (FP): Predicted columns not in gold (extra columns)
   - False Negatives (FN): Gold columns not in predicted (missing columns)
3. **Metric Calculation**:
   - Precision = TP / (TP + FP) - Penalizes extra columns
   - Recall = TP / (TP + FN) - Penalizes missing columns
   - F1 = 2 × (Precision × Recall) / (Precision + Recall)

#### Key Features

- **Case-insensitive**: Handles variations like "Customer" vs "customer"
- **Synonym-aware**: Recognizes "count" and "number" as equivalent
- **Whitespace-tolerant**: Handles "customer_id" vs "customer id"
- **Stopword-insensitive**: Ignores articles like "the", "a", "an"

### 3. Row Comparison Logic

The `compare_rows()` function implements sophisticated row matching with the following stages:

#### Stage 1: Column Alignment

1. **Common Column Identification**: Find columns that exist in both dataframes after normalization
2. **Subset Selection**: Extract only common columns from both dataframes
3. **Column Name Standardization**: Ensure both dataframes use the same column names for comparison

#### Stage 2: Value Normalization

The `normalize_value()` function handles different data types:

```python
def normalize_value(val):
    if pd.isna(val):
        return "NaN"
    elif isinstance(val, (int, float)):
        if isinstance(val, float):
            return str(round(val, int(-math.log10(tolerance))))
        return str(val)
    else:
        str_val = str(val)
        return str_val if case_sensitive else str_val.lower()
```

**Normalization Features:**

- **Float Tolerance**: Configurable precision (default: 0.01)
- **Case Handling**: Optional case-sensitive string comparison
- **Type Conversion**: Consistent string representation for comparison
- **NaN Handling**: Special handling for missing values

#### Stage 3: Greedy Row Matching

The system uses a greedy one-to-one matching algorithm:

1. **Row Conversion**: Convert normalized dataframes to row tuples
2. **Index Tracking**: Maintain separate index lists for predicted and gold rows
3. **Matching Process**:
   - For each gold row, find the first matching predicted row
   - Remove matched predicted row index to handle duplicates correctly
   - Track matched indices for detailed analysis

#### Stage 4: Metric Calculation

- **True Positives (TP)**: Successfully matched rows
- **False Positives (FP)**: Unmatched predicted rows (extra rows)
- **False Negatives (FN)**: Unmatched gold rows (missing rows)

### 4. Multi-Table Comparison

The `compare_multi_pandas_table()` function handles cases where multiple gold standard dataframes exist:

#### Process

1. **Iterative Comparison**: Compare predicted results against each gold standard
2. **Best Match Tracking**: Track the best column and row metrics across all comparisons
3. **Early Return**: Return immediately if a perfect match is found
4. **Fallback Metrics**: Return best available metrics if no perfect match exists

### 5. Database Execution Layer

The system supports multiple database backends:

#### SQLite

- **In-Memory Execution**: Uses backup to avoid locking issues
- **Chunked Processing**: Handles large result sets efficiently
- **CSV Streaming**: Optional output to CSV files

#### BigQuery

- **Credential Management**: Uses service account credentials
- **Usage Tracking**: Monitors GB processed for cost analysis
- **Error Handling**: Comprehensive error logging with context

#### Snowflake

- **Connection Management**: Configurable database connections
- **Result Processing**: Direct DataFrame conversion
- **Error Context**: Detailed error logging

## Evaluation Workflow

### 1. Data Loading

```python
# Load evaluation standards and metadata
eval_standard_dict = load_jsonl_to_dict("spider2lite_eval.jsonl")
spider2sql_metadata = load_jsonl_to_dict("spider2-lite.jsonl")
```

### 2. Instance Processing

For each instance ID:

1. **SQL Mode**: Execute predicted SQL and compare with gold results
2. **Execution Mode**: Direct CSV comparison
3. **Multi-Table Handling**: Support for multiple gold standards per instance

### 3. Metrics Collection

- **Column Metrics**: Precision, recall, F1 for column matching
- **Row Metrics**: Precision, recall, F1 for row matching
- **Overall Metrics**: Combined micro-averaged metrics

### 4. Output Generation

- **Summary Statistics**: Average metrics across all instances
- **Detailed Results**: Per-instance breakdown with all metrics
- **CSV Export**: List of correctly answered instances
- **JSON Export**: Comprehensive metrics for further analysis

## Key Optimizations

### 1. Column Normalization Reuse

- Column names are normalized once and reused for both column and row comparisons
- Ensures consistency across all comparison stages
- Improves performance by avoiding redundant normalization

### 2. Efficient Row Comparison

- Only compares rows on columns that exist in both dataframes
- Avoids unnecessary processing of non-overlapping columns
- Greedy matching algorithm handles duplicates correctly

### 3. Memory Management

- SQLite uses in-memory connections to avoid file locking
- Large result sets are processed in chunks
- Optional CSV output reduces memory footprint

## Error Handling and Logging

### 1. Structured Logging

```python
def log_error(message: str, context=None) -> None:
    context_json = json.dumps(context or {}, default=str)
    logging.error(f"{message} | context={context_json}")
```

### 2. Exception Context

- Captures detailed context for debugging
- Preserves error information for analysis
- Non-blocking error handling ensures evaluation continues

### 3. Error Categories

- **Execution Errors**: Database connection or query failures
- **Comparison Errors**: Data processing or comparison failures
- **System Errors**: File I/O or memory issues

## Configuration and Usage

### Command Line Interface

```bash
# SQL mode evaluation
python evaluate_v2.py --mode sql --result_dir results --gold_dir gold

# Execution result mode evaluation
python evaluate_v2.py --mode exec_result --result_dir temp --gold_dir gold
```

### Key Parameters

- `--mode`: Evaluation mode (sql/exec_result)
- `--result_dir`: Directory containing predicted results
- `--gold_dir`: Directory containing gold standard data
- `--is_sql_debug`: Enable SQL debugging mode

## Output Files

### 1. Summary Reports

- Console output with average metrics
- Performance breakdown by metric type
- Error statistics and analysis

### 2. Detailed Metrics JSON

- Per-instance column and row metrics
- Overall combined metrics
- True positive/negative/false positive breakdowns

### 3. Correct Instance Lists

- CSV file with correctly answered instance IDs
- Formatted for submission systems
- Database-specific ID transformations

## Performance Considerations

### 1. Memory Usage

- Large datasets processed in chunks
- In-memory database operations for SQLite
- Optional CSV output for memory-intensive scenarios

### 2. Processing Speed

- Efficient set operations for column comparison
- Optimized row matching algorithms
- Parallel processing capabilities for large datasets

### 3. Scalability

- Handles datasets with thousands of instances
- Configurable chunk sizes for memory management
- Efficient file I/O operations

## Future Enhancements

### 1. Advanced Matching

- Order-agnostic row comparison
- Fuzzy string matching for column names
- Semantic similarity for value comparison

### 2. Performance Improvements

- Parallel processing for independent instances
- Caching of normalized column names
- Optimized data structures for large datasets

### 3. Additional Metrics

- Execution time analysis
- Query complexity scoring
- Database-specific performance metrics

## Troubleshooting

### Common Issues

1. **Column Mismatches**: Check synonym mapping and normalization
2. **Row Comparison Failures**: Verify data types and tolerance settings
3. **Memory Issues**: Reduce chunk sizes or enable CSV output
4. **Database Connection Errors**: Verify credentials and connection parameters

### Debug Mode

Enable SQL debugging with `--is_sql_debug` flag for detailed execution information.

## Conclusion

The Spider2 Evaluation Suite V2 provides a robust, scalable, and comprehensive evaluation framework for SQL query results. Its sophisticated column and row comparison logic ensures accurate assessment while maintaining performance and providing detailed insights into model performance.
