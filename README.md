## Hubtime

I wanted to be able to see how things went this year, but Github didn't give a graph across all the repositories. I used their API to generate some graphs.

### Commands

First, you need to install the gem:

    gem install hubtime

Note: `hubtime` will add the file `hubtime_config.yml` and the directory `data` on the directory you run the command.

To give auth (It will store your password encrypted on disk)

    hubtime auth

To see what repositiories it will pull from

    hubtime repositories
    
To ignore some of those

    hubtime ignore bleonard/rails
    
Caching is heavily used to not kill Github and speed things up. Caching is done at the sha, time window per repo, and the full history levels.
Specifically, if you add another repo or something, you'll want to do this

    hubtime clear activity

If things are generally messed up and you want to start again, clear it all

    hubtime clear all
    
#### To show table of commits and such

    hubtime table
    hubtime table --months 3
    hubtime table --unit day
    hubtime table --unit day --months 1
    hubtime table --unit year
    
    hubtime table --unit month
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

    hubtime graph
    hubtime graph impact
    hubtime graph deletions
    hubtime graph additions --user otherlogin
    
    hubtime graph commits --months 3

![Commit Graph](https://raw.github.com/bleonard/hubtime/master/readme/graph.png)
    
#### All of those work with a stacked graph to see if broken up by repository

    hubtime graph --stacked
    
    hubtime graph impact --stacked
    
![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/stacked.png)
    
#### Impact Graph like on Github

    hubtime impact
    
    hubtime impact --months 12

![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/impact.png)
    
#### Pie chart of repositories

    hubtime pie
    hubtime pie impact
    
    hubtime pie --months 3

![Stacked Graph](https://raw.github.com/bleonard/hubtime/master/readme/pie.png)
    
#### Sparklines in the console

    hubtime spark
    hubtime spark commits
    
    hubtime spark impact
    ▄▂▂▂▅▁▁▁▇▇▄▃
    
#### Development

I use rvm and bundler. Check out this repo and `bundle install` to get started.
All of the above commands would need `bundle exec` prepended to work in development.
    

