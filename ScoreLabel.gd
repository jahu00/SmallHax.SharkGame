extends Label

var value = 0.0
var display_value = 0.0
var min_speed = 5.0
var rate = 2.0

var interval = 0.1
var timer = 0

func _process(delta):
	if (display_value == value):
		timer = 0
		return
	
	timer += delta
	
	if (timer < interval):
		return
	
	timer = fmod(timer, interval)
	
	var difference = value - display_value
	var increase = max(difference / rate, min_speed)
	if (difference < increase):
		display_value = value
	else:
		display_value += increase
	text = str(int(display_value))
	pass
