2014 Fantasy Baseball Cheat Sheet
=================================

Scrapes data from [ESPN](http://games.espn.go.com/flb/tools/projections?display=alt) and formats data to fit
my point leagues and creates a csv for the draft.

To use:
* Clone repo
* cd into repo
* $ruby player_projections.rb csv_file

To do:
* Load all pitchers and hitters into csv_file order by total points

To customize scoring:
* Change weights in #hitter_total_points or #pitcher_total_points
