
Welcome to Poietic Generator API v2
===================================

Foreword
--------

### Base URI

Please add prefix `/api/v2` to all routes described bellow.

### URI Conventions

| Notation | Meaning |
|--- |--- |---
| Curly brackets `{x}` | `x` is a required item | 
| Square brackets `[x]`| `x` is an optional item |


Users
-----


Spaces
------

All operations on spaces requires admin privileges.

### List all spaces

### Create a space

```
POST /space
```


### Update a space

```
PUT /space
```

### Delete a space

```
DELETE /space
```

### POST /spaces


Sessions
--------

### List all sessions
 
Request

```
GET /spaces/:space_token/sessions
```

### Join session

```
POST /spaces/:space_token/sessions
```


## GET /update

### Parameters

### Response

### Example:

  result = {
      :events => events_collection,
      :strokes => strokes_collection,
      :messages => messages_collection,
      :stamp => (Time.now.to_i - @session_start)
  }


GET /snapshot
-------------

### Parameters

### Response

  result = {
      :users => users,
      :zones => zones,
      :zone_column_count => @config.board.width,
      :zone_line_count => @config.board.height,
      :start_date => @session_start,
      :duration => (Time.now.to_i - @session_start)
  }

### Example

