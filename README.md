# sql-and-nlp-based-project
## Sales Profit Analysis
- connected progreSQL with python using SQLAlchemy
- cleaned data using Excel, pandas
- use SQL query to retrieve data for initial EDA and futher analyse to answer these related question:
  - top 10 cities and states with the most orders
  - unit price for each product
  - top most profitable subcategories and products
  - top most sold product by quantity/volume
  - most returned products
  - total sales for each day of week
  - monthly sales and profits of store
  - year-on-year Growth of Sales and Profits
  - customer segmentation: RFM analysis
- visualised the result using matplotlib, seaborn, plotly
- wordcloud for product names

## Product Classification
task: catogorise product into three group: furniture; office supply; technology, given product name as input
- cleaned the product name data -- removing duplicates
- made use of NLTK to pre-process/tokenise text data
- created a tagged document for product and its category
- employed Doc2Vec to build up a vocabulary from the tagged document and trained the model on those vocabs
- prepared embedding word matrix from Doc2Vec model
- implemented LSTM and loaded the so-called embedding matrix to tensorflow embedding layers
- compared performances compare to the model without the embedding matrix from pre-trained Doc2Vec model
