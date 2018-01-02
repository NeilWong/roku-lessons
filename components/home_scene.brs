function init()
	? "[home_scene] init"
	m.category_screen = m.top.findNode("category_screen")
	m.content_screen = m.top.findNode("content_screen")
	m.details_screen = m.top.findNode("details_screen")
	m.error_dialog = m.top.findNode("error_dialog")
	m.videoplayer = m.top.findNode("videoplayer")
	initializeVideoPlayer()

	m.category_screen.observeField("category_selected", "onCategorySelected")
	m.content_screen.observeField("content_selected", "onContentSelected")
	m.details_screen.observeField("play_button_pressed", "onPlayButtonPressed")

	m.category_screen.setFocus(true)
	loadConfig()
end function

sub onCategorySelected(obj)
    ? "onCategorySelected field: ";obj.getField()
    ? "onCategorySelected data: ";obj.getData()
    list = m.category_screen.findNode("category_list")
    ? "onCategorySelected checkedItem: ";list.checkedItem
    ? "onCategorySelected selected ContentNode: ";list.content.getChild(obj.getData())
    item = list.content.getChild(obj.getData())
    loadFeed(item.feed_url)
end sub

sub onContentSelected(obj)
    selected_index = obj.getData()
    m.selected_media = m.content_screen.findNode("content_grid").content.getChild(selected_index)
    m.details_screen.content = m.selected_media
    m.content_screen.visible = false
    m.details_screen.visible = true
end sub

sub initializeVideoPlayer()
	m.videoplayer.EnableCookies()
	m.videoplayer.setCertificatesFile("common:/certs/ca-bundle.crt")
	m.videoplayer.InitClientCertificates()
	m.videoplayer.notificationInterval=1
	m.videoplayer.observeFieldScoped("position", "onPlayerPositionChanged")
	m.videoplayer.observeFieldScoped("state", "onPlayerStateChanged")
end sub

sub onPlayerPositionChanged(obj)
	? "Player Position: ", obj.getData()
end sub

sub onPlayerStateChanged(obj)
	state=obj.getData()
	? "onPlayerStateChanged :"; state
	if state="error"
		?"Error Message: "; m.videoplayer.errorMSG
		?"Error Code: ";m.videoplayer.errorCode
		showErrorDialog(m.videoplayer.errorMSG + chr(10) + "Error Code: " + m.videoplayer.errorCode.toStr())
	else if state="finished"
		closeVideo()
	end if
end sub

sub closeVideo()
	m.videoplayer.control="stop"
	m.videoplayer.visible=false
	m.details_screen.visible=true
end sub

sub showErrorDialog(message)
	m.error_dialog.title = "ERROR"
	m.error_dialog.message = message
	m.error_dialog.visible=true
	m.top.dialog = m.error_dialog
end sub

sub onPlayButtonPressed(obj)
	m.details_screen.visible = false
	m.videoplayer.visible = true
	m.videoplayer.setFocus(true)
	m.videoplayer.content = m.selected_media
	m.videoplayer.control = "play"
end sub

sub loadFeed(url)
	m.feed_task = createObject("roSGNode", "load_feed_task")
	m.feed_task.observeField("response", "onFeedResponse")
	m.feed_task.observeField("error", "onFeedError")
	m.feed_task.url = url
	m.feed_task.control = "RUN"
end sub

sub onFeedResponse(obj)
	response = obj.getData()
	data = parseJSON(response)
	if data <> Invalid and data.items <> invalid
        m.category_screen.visible = false
        m.content_screen.visible = true
		m.content_screen.feed_data = data
	else
		? "FEED RESPONSE IS EMPTY!"
	end if
end sub

sub onFeedError(obj)
	?"onFeedError for feed"
	showErrorDialog(obj.getData())
end sub

sub loadConfig()
    m.config_task = createObject("roSGNode", "load_config_task")
    m.config_task.observeField("error", "onConfigError")
    m.config_task.observeField("filedata", "onConfigResponse")
    m.config_task.filepath = "resources/config.json"
    m.config_task.control="RUN"
end sub

sub onConfigError(obj)
	showErrorDialog(obj.getData())
end sub

sub onConfigResponse(obj)
    params = {config:obj.getData()}
    m.category_screen.callFunc("updateConfig",params)
end sub

function onKeyEvent(key, press) as Boolean
	? "[home_scene] onKeyEvent", key, press
	if key = "back" and press
		if m.content_screen.visible
			m.content_screen.visible=false
			m.category_screen.visible=true
			m.category_screen.setFocus(true)
			return true
		else if m.details_screen.visible
			m.details_screen.visible=false
			m.content_screen.visible=true
			m.content_screen.setFocus(true)
			return true
		else if m.videoplayer.visible
			m.videoplayer.visible=false
			m.details_screen.visible=true
			m.details_screen.setFocus(true)
			return true
		end if
	end if
  return false
end function
