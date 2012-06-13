# Del Close Marathon mobile app

If you're interested in testing, you should sign up at TestFlight [here](http://bit.ly/KyI9ZW).

## Goals

### Before the Marathon

- Browse the schedule, make a list of favorite shows

### During the Marathon

- See what's happening now at various venues
- See when and where your next favorite show is happening
- Get directions to each venue

### After the Marathon

- Delete it from your phone

## Tabs

- Happening Now - for each venue, current and next show
- Favorites - list of favorited showtimes (auto-scroll to now)
- All Shows - list of shows, alphabetically
- Venues - list of venues
  - Venue Detail - photo, address, list of shows

# Notes

Singleton DCMDatabase object. May reset the Core Data stack at any time; client view controllers should prepare to receive notification.
