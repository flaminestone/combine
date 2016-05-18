# Place all the behaviors and hooks related to the matching controller here.
getCurrentResults = ()->
  $.ajax(url: "/get_current_result_number").done (html) ->
    $("progress").remove()
    $("#results").append html

setInterval(getCurrentResults, 1000)
