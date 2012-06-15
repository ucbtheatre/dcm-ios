# Del Close Marathon mobile app

This is the native iOS app. There is also a [web app][1].

If you're interested in testing, you should sign up at TestFlight [here][2].

[1]: http://github.com/ucbtheatre/dcm-mobile
[2]: http://bit.ly/KyI9ZW

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

## Notes

Singleton DCMDatabase object. May reset the Core Data stack at any time; client view controllers should prepare to receive notification.

## License

Copyright (c) 2012 Upright Citizens Brigade LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
