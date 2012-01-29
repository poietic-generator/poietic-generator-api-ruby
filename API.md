
# Poietic Generator API

## URI Conventions

<table>
    <th>
	<td>Notation</td>
	<td>Meaning</td>
	<td>Example</td>
    </th>
    <tr>
	<td>Curly brackets { }</td>
	<td>Required item</td>
	<td>api.tumblr.com/v2/blog/
	    {base-hostname}/posts
	    The blog hostname is required.
	</td>
    </tr>
    <tr>
	<td>Square brackets [ ]</td>
	<td>Optional item</td>
	<td>api.tumblr.com/v2/blog/
	    {base-hostname}/posts[/type]
	    Specifying a post type is optional.
	</td>
    </tr>
</table>


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


