# Ibotta-Data-Engineer-Take-Home-Project

This data pipeline is structured in such a way that whenver it is run, it downloads the data from the link and looks for any new data. If there is new data, its is added to the table. If the table itself doesn't exists, then a new table is created & theentire data is inserted into the table.  

And the pipeline is designed based on the data that was available in link when it was received. 

Data Google Drive Link: https://drive.google.com/drive/folders/1rtgDBrRIhJtMKgYZrnVGZ4MBG2ru9avP?usp=sharing

We will be sticking sticking to the database name 'Ibotta' as it has been used in various queries.  I haven't had the time to make it dynamic.  

For future development consideration:

1.  More data preprocessing is required, like the case summary is very disorganized. Needs more focus.
2. The data consists of verying data length limit than that was mentioned on the meta data file. In the future, I would like to automate the process of analysising the 
    max length of each and every column from the source and compare it with the current table's structure and make necessary changes.
3. Add more flexibilty to the Python datapipeline from where the data is read till how its processed. Like hadling the Upper case and lower case issues.
4. With much better understaniding of the data requiremnts, I would be able to design much more effective Clustered, Non-Clustered and Filtered Indexes. 
    And even use Indexed Views for non-frequently updated data for a robust read queries.
5. For Future developoment, we can try checking the light & road conditions against the Neighbourhood or the Offense type to better understand the cause of the surge in response     time.
6. Use additional data to udestand the nature of each and every case much better. For Example: Crime data cane be used to better understand why so many cases arise from a 
    particular neighborhood.
7. We can also use weather data to understan dthe seriousness/legitimacy of the call. Like if the call was related to the weather condition.
