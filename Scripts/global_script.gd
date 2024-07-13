extends Node


var thread: Thread

var network_position = Vector2.ZERO
var udp := PacketPeerUDP.new()
var connected = false
var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = "/home/sujith/Documents/programs/pyenv/bin/python"
var pyscript_path = DIR.path_join("pyfiles/main.py")
var udp_terminated = false
var _temp_message
var _split_message
var t_x
var t_y
var process

func _ready():
    udp.connect_to_host("127.0.0.1", 8000)
    thread = Thread.new()
    thread.start(python_thread)

func _process(delta: float) -> void:
    if udp.get_available_packet_count() > 0:
        _temp_message = udp.get_packet().get_string_from_utf8()
        udp.put_packet('connected'.to_utf8_buffer())
        if _temp_message == "stop":
            udp_terminated = true
        elif _temp_message == "none":
            pass
        else:
            _split_message = _temp_message.split(",")
            var net_x = float(_split_message[0])
            var net_y = float(_split_message[1])
            if net_x+600 < 10:
                net_x = 10
            if net_y+400 < 10:
                net_y = 10

            if net_y > 620:
                net_y = 620
            if net_x > 1120:
                net_x = 1120
            network_position = Vector2(net_x, net_y) + Vector2(600, 400)  
            connected = true


func python_thread():
    var output = []
    print('thread function')
    OS.execute(interpreter_path, [pyscript_path], output)
    print(output)
