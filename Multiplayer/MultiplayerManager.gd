extends Node

enum Role {
	DRIVER,
	SHOOTER
}

var players: Dictionary[int, Role] = {}
const PORT = 42069

signal players_changed

var upnp: UPNP = UPNP.new()

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Peer connected with ID: %d" % id)
	set_player_role.rpc(id, Role.DRIVER if players.size() == 0 else Role.SHOOTER)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected with ID: %d" % id)
	players.erase(id)
	players_changed.emit()

func host_game() -> bool:
	if upnp.discover() != OK:
		return false
	if upnp.add_port_mapping(PORT, PORT, "LudoLongGameJam2025", "UDP") != OK:
		return false
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(PORT, 2) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	set_player_role(multiplayer.get_unique_id(), Role.DRIVER)
	return true

func close_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	players.clear()

func join_game(ip_address: String = "127.0.0.1") -> bool:
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip_address, PORT) == OK:
		multiplayer.multiplayer_peer = peer
		return true
	return false

@rpc("any_peer", "call_local")
func set_player_role(id: int, role: Role) -> void:
	players[id] = role
	players_changed.emit()
