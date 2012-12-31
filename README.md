To give auth (It does not store your password)

    ./hubtime.rb auth

To see what repositiories it will pull from

    ./hubtime.rb repositories
    
To ignore some of those

    ./hubtime.rb ignore bleonard/rails
    
Caching is heavily used to not kill Github and speed things up. Caching is done at the sha, time window per repo, and the full history levels.
Specifically, if you add another repo or something, you'll want to do this

    ./hubtime.rb clear activity

If things are generally messed up and you want to start again, clear it all

    ./hubtime.rb clear all
    
#### To show table of commits and such

    ./hubtime.rb table
    ./hubtime.rb table --months 3
    ./hubtime.rb table --unit day
    ./hubtime.rb table --unit day --months 1
    ./hubtime.rb table --unit year
    
    ./hubtime.rb table --unit month
    +---------+---------+--------+-----------+-----------+
    | Month   | Commits | Impact | Additions | Deletions |
    +---------+---------+--------+-----------+-----------+
    | 2012-01 | 241     | 29581  | 15324     | 14257     |
    | 2012-02 | 250     | 15518  | 7844      | 7674      |
    | 2012-03 | 181     | 16647  | 12036     | 4611      |
    | 2012-04 | 130     | 14755  | 12213     | 2542      |
    | 2012-05 | 178     | 40102  | 22883     | 17219     |
    | 2012-06 | 91      | 9870   | 7279      | 2591      |
    | 2012-07 | 50      | 5017   | 4677      | 340       |
    | 2012-08 | 110     | 10124  | 5214      | 4910      |
    | 2012-09 | 49      | 3632   | 2535      | 1097      |
    | 2012-10 | 153     | 54326  | 34419     | 19907     |
    | 2012-11 | 183     | 27958  | 22602     | 5356      |
    | 2012-12 | 123     | 21099  | 13897     | 7202      |
    +---------+---------+--------+-----------+-----------+

#### Graph a piece of data

    ./hubtime.rb graph
    ./hubtime.rb graph impact
    ./hubtime.rb graph deletions
    ./hubtime.rb graph additions --user otherlogin
    
    ./hubtime.rb graph commits --months 3

![Commit Graph](https://raw.github.com/bleonard/hubtime/master/readme/graph.png)
    
#### All of those work with a stacked graph to see if broken up by repository

    ./hubtime.rb graph --stacked
    
    ./hubtime.rb graph impact --stacked
    
![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/stacked.png)
    
#### Impact Graph like on Github

    ./hubtime.rb impact
    
    ./hubtime.rb impact --months 12

![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/impact.png)
    
#### Pie chart of repositories

    ./hubtime.rb pie
    ./hubtime.rb pie impact
    
    ./hubtime.rb pie --months 3

![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/pie.png)
    
#### Sparklines in the console

    ./hubtime.rb spark
    ./hubtime.rb spark commits
    
    ./hubtime.rb spark impact
    ▄▂▂▂▅▁▁▁▇▇▄▃
    
