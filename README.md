# CS 121 Final Project - Grocery Store Database
by Grace Lu (glu@caltech.edu) and Jaeyoon Kim (jaeyoonk@caltech.edu)

This is a MySQL + Python application that simulates the inner working systems of an American grocery store. We tried to come up with an application that allows different ways that different stakeholders could manipulate the data in a way that protects the integrity of the data but still allows different types of users to access and edit the database based on their privilege level. The motivation for this is when we walked through a grocery store and marveled at the complexity of a grocery store with the thousands of products and tens of aisles. 

### Files
- *.csv
    - Contains the initial data used to populate the database
    - Selected from the dataset at https://www.p8105.com/dataset_instacart.html, which was a dataset originally from https://www.instacart.com/datasets/grocery-shopping-2017.
- app.py
    - The python file used to interact with the application.
    - This commandline application is the primary method with which users interact with the database.
    - Run this file.
- grant-permissions.sql
    - SQL file that gives persmission to the admin to make changes to the database
- load-data.sql
    - SQL script that finds the csv files and loads them into the tables within the \'final\' database.
- pw-tester.sql
    - SQL script that tests the logic behind the user authentication methods.
- queries.sql
    - SQL file with many queries, procedures, triggers, and UDFs for imagined user interactions.
- setup-passwords.sql
    - SQL script that contains the logic behind the user authentication methodds.
- setup.sql
    - DDL for the database.
