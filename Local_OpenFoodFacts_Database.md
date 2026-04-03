# Local OpenFoodFacts Database

## Setup
### Create Database
1. download 0000.parquet from https://huggingface.co/datasets/openfoodfacts/product-database/tree/refs%2Fconvert%2Fparquet/default/food
2. create reduced sqlite db with this script (this is pretty slow and could probably be made faster with some pandas knowledge)
    ```py
    import pandas as pd
    import sqlite3
    import os

    in_db = "./dbs/0000.parquet"
    out_db = "./dbs/reduced.sqlite"

    def filter_lang(unfiltered_df: pd.DataFrame, lang="main"):
        rows_to_delete = []
        product_names = []
        for index, row in unfiltered_df.iterrows():
            if index % 10000 == 0:
                print(index)
            name_array = row["product_name"]
            if len(name_array) == 0:
                rows_to_delete.append(index)
            else:
                name = name_array[0]["text"]
                for entry in name_array:
                    if entry["lang"] == lang:
                        name = entry["text"]
                        break
                if not name:
                    rows_to_delete.append(index)
                else:
                    product_names.append(name)

        unfiltered_df.drop(rows_to_delete, inplace=True)
        unfiltered_df["product_name"] = product_names
        unfiltered_df.astype({"product_name": str})
        
    # keep only the columns "code" and "product name"
    db = pd.read_parquet(in_db, columns=["code", "product_name"])
    df = pd.DataFrame(db)


    # keep product name in only one language
    filter_lang(df)

    if os.path.exists(out_db):
        os.remove(out_db)
    cnx = sqlite3.connect(out_db)

    df.to_sql(name="food", con=cnx, if_exists="replace", dtype={'product_name': 'TEXT'})
    ```

### Use local database
3. copy the file to your phone
4. in the settings of OpenNutriTracker, in the "Data Sources" settings
    
    a. enable "local Database"
    
    b. select the database file

    c. click ok

5. When searching for products, the local database will now be queried.
6. When opening the meal details page, it will not have any content due to the reduced database. Click the refresh button in the top right to fetch the remaining data from OpenFoodFacts.



## TODO
- Smoother handling of product detail fetch
- filter products with missing nutrients from the local db (can't be used in the app anyways)
- support full local database so that OpenFoodFacts is not queried for product details
- better/fuzzy search

## Background
The OpenFoodFacts search API often is very slow and often down. See https://status.openfoodfacts.org/.
It seems the OpenFoodFacts team is working on a new API and improving the server, but right now it often is unusable.