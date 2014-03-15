$addressInfo = $ '#address-info'
$form = $ 'form'
$video = $ 'video'
$canvas = $ '#qr-canvas'

getBalance = (address) ->
  $.get "https://blockchain.info/q/addressbalance/#{address}"

getRate = ->
  $.getJSON 'https://api.bitcoinaverage.com/ticker/global/EUR/'

DENOMINATIONS = [50000, 20000, 10000, 5000, 2000, 1000, 500,
                 200, 100, 50, 20, 10, 5, 2, 1]

getChange = (target) ->
  total = 0
  result = {}
  for denomination in DENOMINATIONS
    while total + denomination <= target
      result[denomination] ?= 0
      result[denomination] += 1
      total += denomination
  return result

getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp "[\\?&]" + name + "=([^&#]*)"
  results = regex.exec location.search
  if results is null then "" else decodeURIComponent(results[1].replace(/\+/g, " "))

display = (address, balance, rate) ->
  eurocents = Math.floor(rate * balance / 1000000)
  notesAndCoins = getChange eurocents
  $('#mBTC').html(balance / 100000)
  $('#EUR').html(eurocents / 100)
  for denomination in DENOMINATIONS
    if denomination of notesAndCoins
      for counter in [1..notesAndCoins[denomination]]
        extension = if denomination <= 200 then 'gif' else 'jpg'
        $('<img/>', {'src': "images/#{denomination}.#{extension}"}).appendTo($addressInfo)

showBalance = (address) ->
  $('#card').attr('src', "../cards/#{address}.png")
  $('#address').html(address)
  $addressInfo.show()
  $.when(
    getBalance(address)
    getRate()
  ).done (balanceResponse, rateResponse) ->
    balance = balanceResponse[0]
    rate = rateResponse[0].bid
    display address, balance, rate

showForm = ->
  $form.show()
  $('#scan').on 'click', -> initWebcam()

@initWebcam = ->
  gCtx = $canvas[0].getContext('2d')
  gCtx.scale(-1, 1)
  qrcode.callback = (a) ->
    $('#id_address').val a.replace(/^bitcoin:/, '')
    $form.submit()

  captureToCanvas = (stream) ->
    gCtx.drawImage $video[0], -800, 0
    try
      qrcode.decode()
      stream.stop()
      $canvas.hide()
    catch e
      console.log e
      setTimeout captureToCanvas, 100, stream

  navigator.getMedia = (navigator.getUserMedia ||
                        navigator.webkitGetUserMedia ||
                        navigator.mozGetUserMedia ||
                        navigator.msGetUserMedia)

  navigator.getMedia(
    # constraints
    {video: true, audio: false},
    # successCallback
    (localMediaStream) ->
      console.log 'getMedia success'
      $video.attr 'src', window.URL.createObjectURL localMediaStream
      $canvas.show()
      $video[0].onloadedmetadata = (e) ->
         setTimeout captureToCanvas, 500, localMediaStream
    # errorCallback
    (err) -> console.log "The following error occured: " + err
  )

$(document).ready ->
  address = getParameterByName 'address'
  if address
    showBalance address
  else
    showForm()
