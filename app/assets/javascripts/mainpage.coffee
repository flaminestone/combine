# Place all the behaviors and hooks related to the matching controller here.
getCurrentResults = ()->
  $.ajax(url: "/get_current_result_number").done (json) ->
#    console.log json #-  for log
    if json.runing
      $("#upload_x2t_button").attr("disabled", true)
      $("#progress_sector").remove() # delete old progresbar
      message = "Result for #{json.result} convertion"
      $("#results").append "<div id='progress_sector'><progress value=#{json.current} max=#{json.all}></progress><p>#{message}</p></div>" if (json.runing)  # add new progresbar in element with id results
    else
      $("progress").remove() # delete old progresbar
      $("#convert-all-button").attr("disabled", false)
      $("#upload_x2t_button").attr("disabled", false)
      $("#download-sector").attr("style", 'display: block;')
      $("#format-message").remove()
      $("#results").append "<div id='format-message'><p>#{json.result.split("/")[1].split(".zip")[0]}</p></div>"

setInterval(getCurrentResults, 4000)
