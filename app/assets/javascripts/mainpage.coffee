# Place all the behaviors and hooks related to the matching controller here.
getCurrentResults = ()->
  $.ajax(url: "/get_current_result_number").done (json) ->
#    console.log json -  for log
    $("progress").remove() # delete old progresbar
    $("#results").append "<progress value=#{json.current} max=#{json.all}></progress>" if (json.runing)  # add new progresbar in element with id results
    $("#convert-all-button").attr("disabled", false) if !json.runing
setInterval(getCurrentResults, 1000)
