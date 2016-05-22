# Place all the behaviors and hooks related to the matching controller here.
getCurrentResults = ()->
  $.ajax(url: "/get_current_result_number").done (json) ->
#    console.log json #-  for log
    if json.runing
      $("#upload_x2t_button").attr("disabled", true)
      $("#progress_sector").remove() # delete old progresbar
      $("#current_filename").remove() # delete old progresbar
      message = "Result for #{json.result} convertion"
      $("#results").append "<div id='progress_sector'><div class='progress'><div class='progress-bar progress-bar-success' role='progressbar' style='width: #{(json.current/json.all)*100}%'></div><div id='current_filename'></div></div><span>#{json.filename}</span>" if (json.runing)  # add new progresbar in element with id results
      $("#setting_buttons").attr("class", "nohidden")
    else
      $("progress").remove() # delete old progresbar
      $("#convert-all-button").attr("disabled", false)
      $("#upload_x2t_button").attr("disabled", false)
      $("#download-sector").attr("style", 'display: block;')
      $("#format-message").remove()
      $("#progress_sector").remove() # delete old progresbar
      $("#results").append "<div id='format-message'>#{json.result.split("/")[1].split(".zip")[0]}</div>"
      $("#setting_buttons").attr("class", "hidden")


setInterval(getCurrentResults, 4000)